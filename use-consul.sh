#!/bin/bash
set -eu

git config apply.whitespace nowarn
git config core.filemode false


consul_down_and_up(){

    echo "[NOTICE] As !CONSUL_RESTART is true, which means there will be a short-downtime for CONSUL, terminate CONSUL container and network."

    echo "[NOTICE] Forcefully Stop & Remove CONSUL Container."
    docker-compose -f docker-compose-consul.yml down || echo "[NOTICE] The previous Consul & Registrator Container has been stopped, if exists."
    docker container rm -f consul || echo "[NOTICE] The previous Consul Container has been removed, if exists."
    docker container rm -f registrator || echo "[NOTICE] The previous Registrator Container has been removed, if exists."

    echo "[NOTICE] Up CONSUL container"
    # https://github.com/hashicorp/consul/issues/17973
    docker-compose -p consul -f docker-compose-consul.yml up -d || echo "[NOTICE] Consul has already been created. You can ignore this message."

    sleep 7
}

consul_down_and_up_with_network(){

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
load_consul_docker_image(){


    if [ ${git_image_load_from} = "registry" ]; then

      # Almost all of clients use this deployment.

      echo "[NOTICE] Attempt to log in to the Registry."
      docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} ${git_image_load_from_host}

      echo "[NOTICE] Pull the Registrator image stored in the Registry."
      docker pull ${registrator_image_name_in_registry} || exit 1
      docker tag ${registrator_image_name_in_registry} gliderlabs/registrator:v7 || exit 1
      docker rmi -f ${registrator_image_name_in_registry} || exit 1

      echo "[NOTICE] Pull the Consul image stored in the Registry."
      docker pull ${consul_image_name_in_registry} || exit 1
      docker tag ${consul_image_name_in_registry} hashicorp/consul:1.14.11 || exit 1
      docker rmi -f ${consul_image_name_in_registry} || exit 1
    fi

    # Since there is no Dockerfile, unlike the 'load_nginx_docker_image' and 'load_app_docker_image' functions, there is no 'build' command.


}