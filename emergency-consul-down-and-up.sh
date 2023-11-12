#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -eu

sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 3
source ./util.sh
source ./use-consul.sh


cache_non_dependent_global_vars
check_env_integrity

echo "[STRONG WARNING] This process removes all Containers in the Consul network, which means your running Apps will be stopped."
echo "[WARNING] This will re-create your network according to the orchestration_type on .env. (stack : swarm, compose : local). The current orchestration_type is '${orchestration_type}'"

network_name="consul"

docker stack rm ${project_name}-blue || echo "[DEBUG] D"
docker stack rm ${project_name}-green || echo "[DEBUG] E"

container_ids=($(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' "$network_name")) || echo "[NOTICE] THe network name ${network_name} has NOT been found."

for container_id in "${container_ids[@]}"; do
    echo "[NOTICE] Stopping & Removing containers for removing the Consul network : $container_id"
    docker network disconnect -f "$network_name" "$container_id"
    docker stop "$container_id"
    docker container rm "$container_id"
done

sleep 5

consul_down_and_up_with_network
