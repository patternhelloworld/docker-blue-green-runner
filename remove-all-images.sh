#!/bin/bash
sudo sed -i -e 's/\r$//' *.sh
sudo sed -i -e 's/\r$//' *.sh
sudo bash prevent-crlf.sh

sleep 3
source ./util.sh

cache_global_vars

set -e

echo "[NOTICE] Delete all containers and networks related to the project. Ignore any error messages that may appear if the items do not exist."

docker rmi -f ${project_name}-nginx:latest
docker rmi -f ${project_name}-nginx:new
docker rmi -f ${project_name}-nginx:previous

docker rmi -f ${project_name}:latest
docker rmi -f ${project_name}:new
docker rmi -f ${project_name}:previous
docker rmi -f ${project_name}:blue
docker rmi -f ${project_name}:green