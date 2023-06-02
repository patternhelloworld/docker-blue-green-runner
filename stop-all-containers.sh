#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -e

git config apply.whitespace nowarn
git config core.filemode false


echo "[NOTICE] Delete all containers and networks related to the project. Ignore any error messages that may appear if the items do not exist."

docker-compose -f docker-compose-app-local.yml down || echo "[DEBUG] A-L"
docker-compose -f docker-compose-app-real.yml down || echo "[DEBUG] A-R"
docker-compose -f docker-compose-nginx.yml down || echo "[DEBUG] N"
docker-compose -f docker-compose-consul.yml down || echo "[DEBUG] C"

docker-compose down || echo "[DEBUG] G"
docker system prune -f