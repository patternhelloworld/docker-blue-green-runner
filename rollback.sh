#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -e
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."

git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh

cache_global_vars

# 1) Nginx rollback

if [ ${nginx_restart} = "true" ]; then
  echo "[NOTICE] Change the 'previous' tagged Nginx image to the 'latest' tagged image."
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:latest || echo "[NOTICE] ${project_name}-nginx:previous image does NOT exist."

  sleep 2

  echo "[NOTICE]  Start the Nginx latest tagged container"
  docker-compose -f docker-compose-${project_name}-nginx.yml up -d ${project_name}-nginx
fi

# 2) App rollback

echo "[NOTICE] Change the previous app image to the ${new_state} image for rollback."
docker tag ${project_name}:previous ${project_name}:${new_state} || echo "[NOTICE] ${project_name}:previous image does NOT exist."

sleep 2

echo "[NOTICE] Start the ${new_state} container."
docker-compose -f docker-compose-${project_name}-${app_env}.yml up -d ${project_name}-${new_state}


#if [[ ${app_env} == 'local' ]]; then
 # sleep 5
  #docker exec -it ${project_name}-${new_state}  bash -c 'bash '${project_location}'/.docker/sh/update/local/'${project_name}'.sh'
#fi

echo "[NOTICE] Wait until the ${new_state} container is fully up."
if [[ $(check_availability_inside_container ${new_state} 60 5 | tail -n 1) != 'true' ]]; then
  echo "[ERROR] Failed to start the new app ${new_state} container." && exit 1
fi


./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}

echo "[NOTICE] Shut down the existing ${state} container."
docker-compose -f docker-compose-${project_name}-${app_env}.yml stop ${project_name}-${state}
