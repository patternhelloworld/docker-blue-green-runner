#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."
bash prevent-crlf.sh

set -e

source ./util.sh

app_env=$(get_value_from_env "APP_ENV")
project_name=$(get_value_from_env "PROJECT_NAME")
orchestration_type=$(get_value_from_env "ORCHESTRATION_TYPE")

consul_key_value_store=$1
state=$2
new_state=$3

echo "[NOTICE] Point Nginx back to ${state} from reset.sh."
docker exec ${project_name}-nginx curl -X PUT -d ${state} ${consul_key_value_store} > /dev/null || {
   echo "[ERROR] Setting ${state} on '/etc/nginx/conf.d/nginx.conf' directly according to the Nginx Contingency Plan."
   docker exec ${project_name}-nginx cp -f /etc/consul-templates/nginx.conf.contingency.${state} /etc/nginx/conf.d/nginx.conf
   docker exec ${project_name}-nginx sh -c 'service nginx reload || service nginx restart || [EMERGENCY] Nginx Contingency Plan failed as well. Correct /etc/nginx/conf.d/nginx.conf directly and Run "service nginx restart".'
}




echo "[NOTICE] Stopping the ${new_state} ${orchestration_type}"
if [[ ${orchestration_type} != 'stack' ]]; then
  docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml stop ${project_name}-${new_state}
  echo "[NOTICE] The previous (${new_state}) container has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
else
  docker stack rm ${project_name}-${new_state}
  echo "[NOTICE] The previous (${new_state}) service has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
fi

exit 1
