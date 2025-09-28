#!/bin/bash
set -eu

remote_deployment_connect_and_save_binary(){

  local output_dir="./.docker/binary"
  local output_file="${output_dir}/${project_name}"

  if [ ! -f "${output_file}" ]; then
    echo "[ERROR] Local binary file not found: ${output_file}" && exit 1
  fi

  if [ -z "${remote_deployment_ip_address_list}" ]; then
    echo "[NOTICE] REMOTE_DEPLOYMENT_* is empty. Skipping remote distribution." && return
  fi

  check_yq_installed

  local ip_len=$(echo ${remote_deployment_ip_address_list} | bin/yq eval 'length')
  local port_len=$(echo ${remote_deployment_port_number_list} | bin/yq eval 'length')
  local key_len=${ip_len}

  if [[ ${ip_len} -eq 0 || ${port_len} -eq 0 || ${key_len} -eq 0 ]]; then
    echo "[ERROR] One of remote lists/values is empty. (ip_len=${ip_len}, port_len=${port_len}, key_len=${key_len})" && exit 1
  fi

  if [[ ${ip_len} -ne ${port_len} || ${ip_len} -ne ${key_len} ]]; then
    echo "[ERROR] REMOTE_DEPLOYMENT_* list lengths mismatch. (ip=${ip_len}, port=${port_len}, key=${key_len})" && exit 1
  fi

  if [[ -z "${remote_deployment_runner_path}" ]]; then
    echo "[ERROR] REMOTE_DEPLOYMENT_RUNNER_PATH is empty." && exit 1
  fi

  local remote_bin_dir="${remote_deployment_runner_path}/.docker/binary"

  for ((i=1; i<=${ip_len}; i++))
  do
    local ip_item=$(echo ${remote_deployment_ip_address_list} | bin/yq -r '.['$((i-1))']' | xargs)
    local port_item=$(echo ${remote_deployment_port_number_list} | bin/yq -r '.['$((i-1))']' | xargs)
    local key_item="${remote_deployment_ssh_private_key_local_path_with_file}"

    if [[ -z "${ip_item}" || -z "${port_item}" || -z "${key_item}" ]]; then
      echo "[ERROR] One of remote entries is empty. (ip='${ip_item}', port='${port_item}', key='${key_item}')" && exit 1
    fi

    local remote_host="${ip_item}"
    if [[ "${ip_item}" != *@* ]]; then
      local user_part="${remote_deployment_ssh_user:-root}"
      remote_host="${user_part}@${ip_item}"
    fi

    echo "[NOTICE] Checking connectivity to ${remote_host}:${port_item}"
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -p "${port_item}" -i "${key_item}" "${remote_host}" "echo yes" >/dev/null 2>&1 || (echo "[ERROR] SSH connection failed: ${remote_host}:${port_item}" && exit 1)
  done

  for ((i=1; i<=${ip_len}; i++))
  do
    local ip_item=$(echo ${remote_deployment_ip_address_list} | bin/yq -r '.['$((i-1))']' | xargs)
    local port_item=$(echo ${remote_deployment_port_number_list} | bin/yq -r '.['$((i-1))']' | xargs)
    local key_item="${remote_deployment_ssh_private_key_local_path_with_file}"

    local remote_host="${ip_item}"
    if [[ "${ip_item}" != *@* ]]; then
      local user_part="${remote_deployment_ssh_user:-root}"
      remote_host="${user_part}@${ip_item}"
    fi

    echo "[NOTICE] Creating remote directory: ${remote_host}:${remote_bin_dir}"
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -p "${port_item}" -i "${key_item}" "${remote_host}" "mkdir -p '${remote_bin_dir}'" || (echo "[ERROR] Failed to create remote directory: ${remote_host}:${remote_bin_dir}" && exit 1)

    echo "[NOTICE] Sending binary to ${remote_host}:${remote_bin_dir}/${project_name}"
    scp -o StrictHostKeyChecking=no -P "${port_item}" -i "${key_item}" "${output_file}" "${remote_host}:${remote_bin_dir}/${project_name}" >/dev/null 2>&1 || (echo "[ERROR] Failed to transfer binary to ${remote_host}" && exit 1)
  done

  echo "[NOTICE] Successfully distributed binary to all remotes."
}

remote_deployment_run_on_remotes(){

  if [[ -z "${remote_deployment_failure_strategy}" ]]; then
    echo "[NOTICE] REMOTE_DEPLOYMENT_FAILURE_STRATEGY is empty. Skipping remote execution." && return
  fi

  if [[ -z "${remote_deployment_ip_address_list}" ]]; then
    echo "[ERROR] REMOTE_DEPLOYMENT_IP_ADDRESS_LIST is empty." && exit 1
  fi

  check_yq_installed

  local ip_len=$(echo ${remote_deployment_ip_address_list} | bin/yq eval 'length')
  local port_len=$(echo ${remote_deployment_port_number_list} | bin/yq eval 'length')

  if [[ ${ip_len} -eq 0 || ${port_len} -eq 0 ]]; then
    echo "[ERROR] One of remote lists is empty. (ip_len=${ip_len}, port_len=${port_len})" && exit 1
  fi

  if [[ ${ip_len} -ne ${port_len} ]]; then
    echo "[ERROR] REMOTE_DEPLOYMENT_* list lengths mismatch. (ip=${ip_len}, port=${port_len})" && exit 1
  fi

  if [[ -z "${remote_deployment_runner_path}" ]]; then
    echo "[ERROR] REMOTE_DEPLOYMENT_RUNNER_PATH is empty." && exit 1
  fi

  local allowed_strategy=$(echo "${remote_deployment_failure_strategy}" | tr '[:upper:]' '[:lower:]')
  if [[ "${allowed_strategy}" != "stop" && "${allowed_strategy}" != "rollback" && "${allowed_strategy}" != "go" ]]; then
    echo "[ERROR] REMOTE_DEPLOYMENT_FAILURE_STRATEGY must be one of: stop | rollback | go" && exit 1
  fi

  local success_count=0

  for ((i=1; i<=${ip_len}; i++))
  do
    local ip_item=$(echo ${remote_deployment_ip_address_list} | bin/yq -r '.['$((i-1))']' | xargs)
    local port_item=$(echo ${remote_deployment_port_number_list} | bin/yq -r '.['$((i-1))']' | xargs)
    local key_item="${remote_deployment_ssh_private_key_local_path_with_file}"

    local user_part="${remote_deployment_ssh_user:-root}"
    local remote_host="${user_part}@${ip_item}"

    local sudo_prefix=""
    if [[ "${with_sudo}" == "true" ]]; then
      sudo_prefix="sudo "
    fi

    echo "[NOTICE] (Pre-check) git_image_load_from=file on remote? ${remote_host}:${port_item}"
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -p "${port_item}" -i "${key_item}" "${remote_host}" \
      "set -eu; cd '${remote_deployment_runner_path}'; grep -q '^GIT_IMAGE_LOAD_FROM=file$' .env" \
      || {
        echo "[ERROR] Remote pre-check failed (GIT_IMAGE_LOAD_FROM=file not set) at ${remote_host}";
        if [[ "${allowed_strategy}" == "stop" ]]; then exit 1; fi
        if [[ "${allowed_strategy}" == "rollback" ]]; then
          echo "[NOTICE] Running rollback on ${remote_host}";
          ssh -o StrictHostKeyChecking=no -p "${port_item}" -i "${key_item}" "${remote_host}" "cd '${remote_deployment_runner_path}' && sudo bash rollback.sh" || true
        fi
        continue
      }

    echo "[NOTICE] (Pre-check) user has sudo? ${remote_host}:${port_item}"
    if [[ "${with_sudo}" == "true" ]]; then
      ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=8 -p "${port_item}" -i "${key_item}" "${remote_host}" "sudo -n true" \
        || {
          echo "[ERROR] Remote pre-check failed (sudo not available) at ${remote_host}";
          if [[ "${allowed_strategy}" == "stop" ]]; then exit 1; fi
          if [[ "${allowed_strategy}" == "rollback" ]]; then
            echo "[NOTICE] Running rollback on ${remote_host}";
            ssh -o StrictHostKeyChecking=no -p "${port_item}" -i "${key_item}" "${remote_host}" "cd '${remote_deployment_runner_path}' && ${sudo_prefix}bash rollback.sh" || true
          fi
          continue
        }
    fi

    echo "[NOTICE] Running remote deploy: ${sudo_prefix}bash run.sh at ${remote_host}"
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=30 -p "${port_item}" -i "${key_item}" "${remote_host}" \
      "set -eu; cd '${remote_deployment_runner_path}' && ${sudo_prefix}bash run.sh" \
      && success_count=$((success_count+1)) \
      || {
        echo "[ERROR] Remote deploy failed at ${remote_host}";
        if [[ "${allowed_strategy}" == "stop" ]]; then exit 1; fi
        if [[ "${allowed_strategy}" == "rollback" ]]; then
          echo "[NOTICE] Running rollback on ${remote_host}";
          ssh -o StrictHostKeyChecking=no -p "${port_item}" -i "${key_item}" "${remote_host}" "cd '${remote_deployment_runner_path}' && ${sudo_prefix}bash rollback.sh" || true
        fi
        # go: do nothing and continue
      }
  done

  if [[ ${success_count} -gt 0 ]]; then
    echo "[NOTICE] Remote deploy run completed. Success: ${success_count}/${ip_len}"
  else
    echo "[ERROR] No remote deployments succeeded."
    if [[ "${allowed_strategy}" == "stop" ]]; then exit 1; fi
  fi
}


