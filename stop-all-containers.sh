#!/bin/bash
source use-common.sh
check_yq_installed
check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_git_docker_compose_commands_exist

sudo sed -i -e "s/\r$//g" $(basename $0)

git config apply.whitespace nowarn
git config core.filemode false

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 2

cache_non_dependent_global_vars

echo "[NOTICE] Delete all containers and networks related to the project. Ignore any error messages that may appear if the items do not exist."

docker-compose -f docker-compose-${project_name}-${app_env}.yml down || echo "[DEBUG] A-L"
docker-compose -f docker-compose-${project_name}-nginx.yml down || echo "[DEBUG] N"

docker container stop ${project_name}-blue || echo "[DEBUG] A-L 2"
docker container rm ${project_name}-blue || echo "[DEBUG] A-L 3"
docker container stop ${project_name}-green || echo "[DEBUG] A-L 4"
docker container rm ${project_name}-green || echo "[DEBUG] A-L 5"

docker stack rm ${project_name}-blue || echo "[DEBUG] F"
docker stack rm ${project_name}-green || echo "[DEBUG] F-2"

docker-compose -f docker-compose-consul.yml down || echo "[DEBUG] C"

docker-compose down || echo "[DEBUG] G"
docker system prune -f