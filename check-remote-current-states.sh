#!/bin/bash
set -eu

source ./use-common.sh

# Read required env values directly to avoid heavy checks
runner_path=$(get_value_from_env "REMOTE_DEPLOYMENT_RUNNER_PATH")
ip_list=$(get_value_from_env "REMOTE_DEPLOYMENT_IP_ADDRESS_LIST")
port_list=$(get_value_from_env "REMOTE_DEPLOYMENT_PORT_NUMBER_LIST")
key_file=$(get_value_from_env "REMOTE_DEPLOYMENT_SSH_PRIVATE_KEY_LOCAL_PATH_WITH_FILE")
ssh_user=$(get_value_from_env "REMOTE_DEPLOYMENT_SSH_USER")

if [[ -z "${runner_path}" ]]; then
  echo "[ERROR] REMOTE_DEPLOYMENT_RUNNER_PATH is empty." && exit 1
fi

if [[ -z "${ip_list}" || -z "${port_list}" || -z "${key_file}" ]]; then
  echo "[ERROR] One or more required REMOTE_DEPLOYMENT_* variables are empty. (IP, PORT, KEY)" && exit 1
fi

check_yq_installed

ip_len=$(echo ${ip_list} | bin/yq eval 'length')
port_len=$(echo ${port_list} | bin/yq eval 'length')

if [[ ${ip_len} -eq 0 || ${port_len} -eq 0 ]]; then
  echo "[ERROR] IP/PORT list is empty. (ip_len=${ip_len}, port_len=${port_len})" && exit 1
fi

if [[ ${ip_len} -ne ${port_len} ]]; then
  echo "[ERROR] REMOTE_DEPLOYMENT_* list lengths mismatch. (ip=${ip_len}, port=${port_len})" && exit 1
fi

echo "[NOTICE] Running 'check-current-states.sh' on ${ip_len} remote host(s)..."

for ((i=1; i<=${ip_len}; i++))
do
  ip_item=$(echo ${ip_list} | bin/yq -r '.['$((i-1))']' | xargs)
  port_item=$(echo ${port_list} | bin/yq -r '.['$((i-1))']' | xargs)

  if [[ -z "${ip_item}" || -z "${port_item}" ]]; then
    echo "[ERROR] Invalid remote at index $((i-1)). (ip='${ip_item}', port='${port_item}')" >&2
    continue
  fi

  user_part="${ssh_user:-root}"
  remote_host="${ip_item}"
  if [[ "${ip_item}" != *@* ]]; then
    remote_host="${user_part}@${ip_item}"
  fi

  echo "[NOTICE] (${i}/${ip_len}) ${remote_host}:${port_item} - connectivity check"
  if ! ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -p "${port_item}" -i "${key_file}" "${remote_host}" "echo yes" >/dev/null 2>&1; then
    echo "[ERROR] SSH connection failed: ${remote_host}:${port_item}" >&2
    continue
  fi

  echo "[NOTICE] (${i}/${ip_len}) ${remote_host}:${port_item} - running 'bash check-current-states.sh'"
  ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=30 -p "${port_item}" -i "${key_file}" "${remote_host}" \
    "set -eu; cd '${runner_path}' && bash check-current-states.sh" \
    | sed -e "s/^/[${ip_item}] /" || echo "[ERROR] Command failed on ${remote_host}" >&2
done

echo "[NOTICE] Remote 'check-current-states.sh' calls completed."


