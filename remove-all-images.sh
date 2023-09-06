#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -e

git config apply.whitespace nowarn
git config core.filemode false

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 3
source ./util.sh

cache_non_dependent_global_vars

echo "[NOTICE] Delete all containers and networks related to the project. Ignore any error messages that may appear if the items do not exist."

docker rmi -f ${project_name}-nginx:latest
docker rmi -f ${project_name}-nginx:new
docker rmi -f ${project_name}-nginx:previous

docker rmi -f ${project_name}:latest
docker rmi -f ${project_name}:new
docker rmi -f ${project_name}:previous
docker rmi -f ${project_name}:previous2
docker rmi -f ${project_name}:blue
docker rmi -f ${project_name}:green