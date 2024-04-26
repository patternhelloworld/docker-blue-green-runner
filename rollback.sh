#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -e
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."

git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh
source ./use-app.sh

cache_global_vars

with_nginx="${1:-}"
if [[ "$with_nginx" == "1" ]]; then
    nginx_restart=true
else
    nginx_restart=false
fi

# Nginx Rollback
if [[ ${nginx_restart} == 'true' ]]; then
  echo "[NOTICE] Change the 'previous' tagged Nginx image to the 'latest' tagged image."
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:latest || echo "[NOTICE] ${project_name}-nginx:previous image does NOT exist."

  sleep 2

  echo "[NOTICE] Run 'emergency-nginx-restart.sh'"
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
