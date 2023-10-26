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

# Load necessary things from util.sh
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

consul_down_and_up(){

    echo "[NOTICE] As !CONSUL_RESTART is true, which means there will be a short-downtime for CONSUL, terminate CONSUL container and network."

    echo "[NOTICE] Stop & Remove CONSUL Container."
    docker-compose -f docker-compose-consul.yml down || echo "[NOTICE] The previous Consul & Registrator Container has been stopped, if exists."
    docker network disconnect -f consul consul && docker container stop consul && docker container rm consul || echo "[NOTICE] The previous Consul Container has been  removed, if exists."
    docker container rm -f consul || echo "[NOTICE] The previous Consul Container has been removed, if exists."
    docker container rm -f registrator || echo "[NOTICE] The previous Registrator Container has been  removed, if exists."

    sleep 5

     echo "[NOTICE] We will remove the network Consul and restart it."
     docker network rm -f consul || echo "[NOTICE] Failed to remove Consul Network. You can ignore this message, or if you want to restart it, please terminate other projects that share the Consul network."
     docker system prune -f

    if [[ ${orchestration_type} != 'stack' ]]; then
      echo "[DEBUG] orchestration_type : ${orchestration_type} / A"
      docker network create consul || (echo "[ERROR] Consul Network has NOT been removed. You need to remove all containers and re-create the consul network manually." && exit 1)
    else
      docker network create --driver overlay  --attachable consul || (echo "[ERROR] Consul Network has NOT been removed. You need to remove all containers and re-create the consul network manually." && exit 1)
      echo "[DEBUG] orchestration_type : ${orchestration_type} / B"
    fi


    echo "[NOTICE] Up CONSUL container"
    # https://github.com/hashicorp/consul/issues/17973
    docker-compose -p consul -f docker-compose-consul.yml up -d || echo "[NOTICE] Consul has already been created. You can ignore this message."

    sleep 5

    docker system prune -f
}

consul_down_and_up
