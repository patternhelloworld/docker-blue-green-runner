#!/bin/bash
# This is a private shell script. Do NOT use this directly.
set -eu

source use-common.sh
source ./use-app.sh

#cache_global_vars
cache_non_dependent_global_vars

new_state=$1
old_state=$2
new_upstream=$3

echo "[NOTICE] new_state : ${new_state}, old_state : ${old_state}, new_upstream : ${new_upstream}"


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

echo "[NOTICE] Activate ${new_state} in the Nginx config file. (old Nginx pids: ${pid_was})"
echo "[NOTICE] ${new_state} is stored in the Nginx config file."

echo "![NOTICE] Setting ${new_state} in nginx.conf... (from '/etc/templates/nginx.conf.prepared.${new_state}')"
docker exec ${project_name}-nginx cp -f /etc/templates/nginx.conf.prepared.${new_state} /etc/nginx/conf.d/nginx.conf
docker exec ${project_name}-nginx sh -c 'service nginx reload || service nginx restart || [EMERGENCY] Nginx Prepared Plan failed. Correct /etc/nginx/conf.d/nginx.conf directly in the Nginx container and Run "service nginx restart".'

sleep 1

re=$(check_availability_out_of_container_speed_mode | tail -n 1);
if [[ ${re} != 'true' ]]; then
    echo "![NOTICE] Setting ${new_state} on nginx.conf according to the Nginx Prepared Plan."
    docker exec ${project_name}-nginx cp -f /etc/templates/nginx.conf.prepared.${new_state} /etc/nginx/conf.d/nginx.conf || docker exec ${project_name}-nginx cp -f /conf.d/${protocol}/nginx.conf.prepared.${new_state} /etc/nginx/conf.d/nginx.conf
    docker exec ${project_name}-nginx sh -c 'service nginx reload || service nginx restart || [EMERGENCY] Nginx Prepared Plan failed as well. Correct /etc/nginx/conf.d/nginx.conf directly and Run "service nginx restart".'
fi

echo "[NOTICE] The PID of NGINX has been confirmed. Now, checking if ${new_upstream} string is in the NGINX configuration file."
count=0
while [ 1 ]; do
  lines=$(docker exec ${project_name}-nginx nginx -T | grep ${new_state} | wc -l | xargs)
  if [[ ${lines} == '0' ]]; then
    count=$((count + 1))
    if [[ ${count} -eq 10 ]]; then
          echo "[WARNING] Since ${new_upstream} string is not found in the NGINX configuration file, we will revert to ${old_state} (although it should already be ${old_state}, we will save it again to ensure)"
          old_state_container_name=
          if [[ ${orchestration_type} == 'stack' ]]; then
            old_state_container_name=$(docker ps -q --filter "name=^${project_name}-${old_state} " | shuf -n 1)
          else
            old_state_container_name=${project_name}-${old_state}
          fi

          echo "[DEBUG] old_state_container_name : ${old_state_container_name}, ${orchestration_type}"

          is_run=$(docker exec ${old_state_container_name} echo 'yes' 2>/dev/null || echo 'no')
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
            ./nginx-blue-green-reset.sh ${old_state} ${new_state}
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
