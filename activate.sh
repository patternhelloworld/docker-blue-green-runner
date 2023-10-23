#!/usr/bin/env bash
set -e
sudo sed -i -e "s/\r$//g" $(basename $0)

source ./util.sh

#cache_global_vars
cache_non_dependent_global_vars

new_state=$1
old_state=$2
new_upstream=$3
consul_key_value_store=$4

echo "[NOTICE] new_state : ${new_state}, old_state : ${old_state}, new_upstream : ${new_upstream}, consul_key_value_store : ${consul_key_value_store}"
was_state=$(docker exec ${project_name}-nginx curl ${consul_key_value_store}?raw) || (echo "[EMERGENCY] Errors on Consul Network. This usually occurs when the physical machine has been restarted. (Solution : run bash 'stop-all-containers.sh' & 'emergency-consul-down-and-up.sh' & 'run.sh')" && exit 1)
echo "[NOTICE] CONSUL (${consul_key_value_store}) is currently pointing to : ${was_state}"
if [[ ${old_state} != ${was_state} ]]; then
  echo "[WARNING] Was State (${was_state}, currently pointed from CONSUL) is different from Old State (${old_state}, checked at the first stage of the mother script.)"
fi

# The meaning of "${pid_was} != '-'" is that when Nginx has fully started, the BLUE-GREEN change operation is performed in CONSUL.
echo "[NOTICE] Check if Nginx is completely UP."
for retry_count in {1..5}; do
  pid_was=$(docker exec ${project_name}-nginx pidof nginx 2>/dev/null || echo '-')

  if [[ ${pid_was} != '-' ]]; then
    echo "[NOTICE] Nginx is completely UP."
    break
  else
    echo "[NOTICE] Retrying... (pid_was : ${pid_was})"

  fi

  if [[ ${retry_count} -eq 4 ]]; then
    echo "[ERROR] Failed to verify if Nginx is completely up and running. Retry attempt also failed. The script will now maintain the existing state and terminate."
    exit 1
  fi

  echo "[NOTICE] Retrying every 3 seconds... (Retrying ${retry_count} round)"
  sleep 3
done

echo "[NOTICE] Activate ${new_state} CONSUL. (old Nginx pids: ${pid_was})"
echo "[NOTICE] ${new_state} is stored in CONSUL."
docker exec ${project_name}-nginx curl -X PUT -d ${new_state} ${consul_key_value_store} >/dev/null

sleep 1

echo "[NOTICE] The PID of NGINX has been confirmed. Now, checking if CONSUL has been replaced with ${new_upstream} string in the NGINX configuration file."
count=0
while [ 1 ]; do
  lines=$(docker exec ${project_name}-nginx nginx -T | grep ${new_state} | wc -l | xargs)
  if [[ ${lines} == '0' ]]; then
    count=$((count + 1))
    if [[ ${count} -eq 10 ]]; then
          echo "[WARNING] Since ${new_upstream} string is not found in the NGINX configuration file, we will revert CONSUL to ${old_state} (although it should already be ${old_state}, we will save it again to ensure)"
          old_state_container_name=
          if [[ ${orchestration_type} == 'stack' ]]; then
            old_state_container_name=$(docker ps -q --filter "name=^${project_name}-${old_state} " | shuf -n 1)
          else
            old_state_container_name=${project_name}-${old_state}
          fi

          echo "[DEBUG] old_state_container_name : ${old_state_container_name}, ${orchestration_type}"

          is_run=$(docker exec ${old_state_container_name}  echo 'yes' 2>/dev/null || echo 'no')
          if [[ ${is_run} == 'yes' ]]; then
              if [[ ${orchestration_type} != 'stack' ]]; then
                if [[ $(check_availability_inside_container_speed_mode ${old_state} 10 5 | tail -n 1) == 'true' ]]; then
                  is_run='yes'
                else
                  is_run='no'
                fi
              else
                if [[ $(check_availability_inside_container_speed_mode ${old_state} 5 | tail -n 1) == 'true' ]]; then
                  is_run='yes'
                else
                  is_run='no'
                fi
              fi
          fi

          if [[ ${is_run} == 'yes' ]]; then
            ./reset.sh ${consul_key_value_store} ${old_state} ${new_state}
          else
            echo "[WARNING] We won't revert, as ${old_state} is NOT running as well."
          fi

      exit 1
    fi
    echo 'Wait for the new configuration'
    sleep 3
  else
    echo 'The new configuration was loaded'
    break
  fi
done
