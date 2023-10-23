#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -e
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."

git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh

cache_global_vars

# 1) App rollback
echo "[NOTICE] Change the previous app image to the ${new_state} image for rollback."
docker tag ${project_name}:previous ${project_name}:${new_state} || echo "[NOTICE] ${project_name}:previous image does NOT exist."

sleep 2

echo "[NOTICE] Down & Up ${new_state} container."
docker-compose -f docker-compose-${project_name}-${app_env}.yml stop ${project_name}-${new_state} || echo "[NOTICE] The ${new_state} Container has been stopped, if exists."
docker-compose -f docker-compose-${project_name}-${app_env}.yml rm -f ${project_name}-${new_state} || echo "[NOTICE] The ${new_state} Container has been removed, if exists."
docker-compose -f docker-compose-${project_name}-${app_env}.yml up -d ${project_name}-${new_state}

echo "[NOTICE] Wait until the ${new_state} container is fully up."
if [[ $(check_availability_inside_container ${new_state} 60 5 | tail -n 1) != 'true' ]]; then
  echo "[ERROR] Failed to rollback to the ${new_state} container." && exit 1
fi

# 2) Nginx rollback
if [ ${nginx_restart} = "true" ]; then
  echo "[NOTICE] Change the 'previous' tagged Nginx image to the 'latest' tagged image."
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:latest || echo "[NOTICE] ${project_name}-nginx:previous image does NOT exist."

  sleep 2

  echo "[NOTICE] Up the Nginx latest tagged container"
  docker-compose -f docker-compose-${project_name}-nginx.yml up -d ${project_name}-nginx
fi

./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}


if [[ ${orchestration_type} != 'stack' ]]; then
  echo "[NOTICE] Shut down the existing ${state} container."
  docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml stop ${project_name}-${state}
else
  echo "[NOTICE] Remove the existing ${state} stack."
  docker stack rm ${project_name}-${state}
fi
