#!/bin/bash
set -eu

source ./util.sh
check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_git_docker_compose_commands_exist

sudo sed -i -e "s/\r$//g" $(basename $0)

echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."
sudo bash prevent-crlf.sh
git config apply.whitespace nowarn || echo "[WARN] A supporting command 'git config apply.whitespace nowarn' has NOT been run."
git config core.filemode false || echo "[WARN] A supporting command 'git config core.filemode false' has NOT been run."


source ./use-app.sh

check_git_docker_compose_commands_exist
cache_global_vars

with_nginx="${1:-}"
if [[ "$with_nginx" == "1" ]]; then
    nginx_restart=true
else
    nginx_restart=false
fi


# App rollback
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

# Nginx Rollback
if [[ ${nginx_restart} == 'true' ]]; then
  echo "[NOTICE] Change the 'previous' tagged Nginx image to the 'latest' tagged image."
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:latest || echo "[NOTICE] ${project_name}-nginx:previous image does NOT exist."

  sleep 2

  echo "[NOTICE] Run 'emergency-nginx-restart.sh' "
  bash emergency-nginx-restart.sh
fi

./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}


if [[ ${orchestration_type} != 'stack' ]]; then
  echo "[NOTICE] Stop the previous ${state} container."
  docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml stop ${project_name}-${state}
else
  echo "[NOTICE] Remove the previous ${state} stack."
  docker stack rm ${project_name}-${state}
fi
