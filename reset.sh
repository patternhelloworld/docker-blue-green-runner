#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."
bash prevent-crlf.sh

set -e

source ./util.sh

#cache_global_vars
app_env=$(get_value_from_env "APP_ENV")
project_name=$(get_value_from_env "PROJECT_NAME")

consul_key_value_store=$1
state=$2
new_state=$3

echo "[NOTICE] Be stored as ${state} in Consul."
docker exec ${project_name}-nginx curl -X PUT -d ${state} ${consul_key_value_store} > /dev/null

echo "[NOTICE] Stopping the ${new_state} container"
docker-compose -f docker-compose-app-${app_env}.yml stop ${project_name}-${new_state}

exit 1
