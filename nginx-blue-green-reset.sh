#!/bin/bash
# This is a private shell script. Do NOT use this directly.
source use-common.sh

project_name=$(get_value_from_env "PROJECT_NAME")
orchestration_type=$(get_value_from_env "ORCHESTRATION_TYPE")

state=$1
new_state=$2

echo "[NOTICE] Point Nginx back to ${state} from nginx-blue-green-reset.sh."
echo "[ERROR] Setting ${state} on '/etc/nginx/conf.d/nginx.conf' directly according to the Nginx Prepared Plan."
docker exec ${project_name}-nginx cp -f /etc/templates/nginx.conf.prepared.${state} /etc/nginx/conf.d/nginx.conf
docker exec ${project_name}-nginx sh -c 'service nginx reload || service nginx restart || [EMERGENCY] Nginx Prepared Plan failed as well. Correct /etc/nginx/conf.d/nginx.conf directly and Run "service nginx restart".'

echo "[NOTICE] Stopping the ${new_state} ${orchestration_type}"
if [[ ${orchestration_type} != 'stack' ]]; then
  docker-compose -f docker-${orchestration_type}-${project_name}.yml stop ${project_name}-${new_state}
  echo "[NOTICE] The previous (${new_state}) container has been stopped because the deployment was successful. (If NGINX_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
else
  docker stack rm ${project_name}-${new_state}
  echo "[NOTICE] The previous (${new_state}) service has been stopped because the deployment was successful. (If NGINX_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
fi

exit 1
