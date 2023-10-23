#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -eu

sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 3
source ./util.sh


# Back-up priority : new > blue or green > latest
backup_app_to_previous_images(){
  # App
  echo "[NOTICE] Docker tag 'previous' 'previous2'"
  docker tag ${project_name}:previous ${project_name}:previous2 || echo "[NOTICE] the 'previous' image does NOT exist."

  if [[ $(docker images -q ${project_name}:new 2> /dev/null) != '' ]]
  then

      echo "[NOTICE] Docker tag 'new' 'previous'"
      docker tag ${project_name}:new ${project_name}:previous && return  || echo "[NOTICE] There is no 'new' tag image to backup the app."
  fi

  echo "[NOTICE] Since there is no 'new' tag image for the app, depending on 'cache_all_states' previously run in the 'cache_global_vars' stage, we will back ${state} up."
  docker tag ${project_name}:${state} ${project_name}:previous && return || echo "[NOTICE] No ${state} tagged image."

  echo "[NOTICE] Since there is no ${state} images, we will attempt to back up the latest image as previous"
  docker tag ${project_name}:latest ${project_name}:previous || echo "[NOTICE] No 'latest' tagged image."

}

backup_nginx_to_previous_images(){
  # NGINX
  echo "[NOTICE] Before creating the 'previous' tagged image of Nginx, if there is an existing 'previous' tagged image, we will proceed with backing it up as the 'previous2' tagged image."
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:previous2 || echo "[NOTICE] No 'previous' tagged image."

  if [[ $(docker images -q ${project_name}-nginx:new 2> /dev/null) != '' ]]
  then

    echo "[NOTICE] Docker tag 'new' 'previous' (NGINX)"
    docker tag ${project_name}-nginx:new ${project_name}-nginx:previous && return || echo "[NOTICE] No Nginx 'new' tagged image."

  fi

  echo "[NOTICE] Since there is no existing Nginx 'new' image, we will attempt to back up the latest image as 'previous'."
  docker tag ${project_name}-nginx:latest ${project_name}-nginx:previous || echo "[NOTICE] No Nginx 'latest' tagged image."

}

create_host_folders_if_not_exists() {

  arr_variable=("${host_shared_path}/apache2-access-logs" "${host_shared_path}/apache2-error-logs" "${host_shared_path}/laravel-access-logs" "${host_system_log_path}/redis" "${host_system_log_path}/apache2" "${host_system_log_path}/supervisor")

  ## now loop through the above array
  for val in "${arr_variable[@]}"; do
    if [[ -d $val ]]; then
      echo "[NOTICE] The directory of '$val' already exists."
    else
      if [ -z $val ]; then
        echo "[NOTICE] The variable '$val' is empty"
        exit 1
      fi

      sudo mkdir -p $val

      echo "[NOTICE] The directory of '$val' has been created."

      chgrp -R ${host_root_gid} $val
      echo "[NOTICE] The directory of '$val' has been given the ${host_root_gid} group permission."
    fi
  done
}

give_host_group_id_full_permissions(){

  # By default, all volume folders are granted 'permission for the user's group of the host (not the root user, but the current user)'.
  # Then, the permissions for the App using the folder in the container (such as www-data, redis, etc.)
  # are given in the Dockerfile or ENTRYPOINT.
  # This is because, in the development environment,
  # volume folders may need to be modified by IDEs or other tools on the host,
  # so permissions are given to the host, and permissions are also required for the libraries to access each folder inside Docker
  # (permissions inside Docker are executed in the ENTRYPOINT script)
  echo "[NOTICE] !! APP_ENV=local Only : To facilitate access from an IDE to Docker's internal permissions, we grant host permissions locally and set them to 777."
  sudo chgrp -R ${host_root_gid} ${host_root_location}
  sudo chmod -R 777 ${host_root_location}
}

terminate_whole_system(){
  if [[ ${docker_layer_corruption_recovery} == true ]]; then
    docker rmi -f ${project_name}-nginx:latest
    docker rmi -f ${project_name}-nginx:new
    docker rmi -f ${project_name}-nginx:previous
    docker rmi -f ${project_name}-nginx:previous2

    docker rmi -f ${project_name}:latest
    docker rmi -f ${project_name}:new
    docker rmi -f ${project_name}:previous
    docker rmi -f ${project_name}:previous2
    docker rmi -f ${project_name}:blue
    docker rmi -f ${project_name}:green

    docker-compose -f docker-${orchestration_type}-${project_name}-local.yml down || echo "[NOTICE] docker-${orchestration_type}-${project_name}-local.yml down failure"
    docker-compose -f docker-${orchestration_type}-${project_name}-real.yml down || echo "[NOTICE] docker-${orchestration_type}-${project_name}-real.yml down failure"
    docker-compose -f docker-${orchestration_type}-consul.yml down || echo "[NOTICE] docker-${orchestration_type}-${project_name}-consul.yml down failure"
    docker-compose -f docker-compose-${project_name}-nginx.yml down || echo "[NOTICE] docker-compose-${project_name}-nginx.yml down failure"

    docker network rm consul

    docker network rm consul

    docker system prune -f
  fi
}


load_consul_docker_image(){

  if [[ $(docker exec consul echo 'yes' 2> /dev/null) == '' ]]
  then
      echo '[NOTICE] Since the Consul container is not running, we consider it as consul_restart=true and start from loading the image again. (The .env file will not be changed.)'
      consul_restart=true

      # Since there is no Dockerfile, unlike the 'load_nginx_docker_image' and 'load_app_docker_image' functions, there is no 'build' command.
  fi

  if [ ${consul_restart} = "true" ]; then

    if [ ${git_image_load_from} = "registry" ]; then

      # Almost all of clients use this deployment.

      echo "[NOTICE] Attempt to log in to the Registry."
      docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} ${git_image_load_from_hostname}:5050/${git_image_load_from_pathname}

      echo "[NOTICE] Pull the Registrator image stored in the Registry."
      docker pull ${load_from_registry_image_with_env}-registrator-${app_version}|| exit 1
      docker tag ${load_from_registry_image_with_env}-registrator-${app_version} gliderlabs/registrator:latest || exit 1
      docker rmi -f ${load_from_registry_image_with_env}-registrator-${app_version}|| exit 1

      echo "[NOTICE] Pull the Consul image stored in the Registry."
      docker pull ${load_from_registry_image_with_env}-consul-${app_version}|| exit 1
      docker tag ${load_from_registry_image_with_env}-consul-${app_version} consul:latest || exit 1
      docker rmi -f ${load_from_registry_image_with_env}-consul-${app_version}|| exit 1
    fi

    # Since there is no Dockerfile, unlike the 'load_nginx_docker_image' and 'load_app_docker_image' functions, there is no 'build' command.

  fi

}


load_nginx_docker_image(){

  if [[ $(docker exec ${project_name}-nginx echo 'yes' 2> /dev/null) == '' ]]
  then
      echo "[NOTICE] Since the '${project_name}-nginx:latest' container is not running, we consider it as 'nginx_restart=true' and start from building again."
      nginx_restart=true
  fi

  if [ ${nginx_restart} = "true" ]; then

    if [ ${git_image_load_from} = "registry" ]; then

      echo "[NOTICE] Attempt to log in to the Registry."
      docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} "${git_image_load_from_hostname}:5050/${git_image_load_from_pathname}"

      echo "[NOTICE] Pull the Nginx image stored in the Registry."
      docker pull ${load_from_registry_image_with_env}-nginx-${app_version}|| exit 1
      docker tag ${load_from_registry_image_with_env}-nginx-${app_version} ${project_name}-nginx:latest || exit 1
      docker rmi -f ${load_from_registry_image_with_env}-nginx-${app_version}|| exit 1
    else

      echo "[NOTICE] As !NGINX_RESTART is true, which means there will be a short-downtime for Nginx, build the ${project_name}-nginx image (using cache)."
      docker build --build-arg DISABLE_CACHE=${CUR_TIME}  --build-arg protocol="${protocol}" --tag ${project_name}-nginx -f ./.docker/nginx/Dockerfile . || exit 1

    fi

  fi
}

# Image name: ${project_name} (utilizing 4 tags for Blue-Green deployment: ${project_name}:latest, ${project_name}:previous, ${project_name}:blue, ${project_name}:green)
load_app_docker_image() {

  if [ ${git_image_load_from} = "registry" ]; then

    echo "[NOTICE] Attempt to log in to the Registry."
    docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} ${git_image_load_from_hostname}:5050/${git_image_load_from_pathname}

    echo "[NOTICE] Pull the app image stored in the Registry."
    docker pull ${load_from_registry_image_with_env}-app-${app_version}|| exit 1
    docker tag ${load_from_registry_image_with_env}-app-${app_version} ${project_name}:latest || exit 1
    docker rmi -f ${load_from_registry_image_with_env}-app-${app_version}|| exit 1
  else


    echo "[NOTICE] Build the image with ${docker_file_location}/${docker_file_name} (using cache)"
    local env_build_args=$(make_docker_build_arg_strings)
    echo "[NOTICE] DOCKER_BUILD_ARGS on the .env : ${env_build_args}"

    if [[ ${docker_layer_corruption_recovery} == true ]]; then
       echo "[NOTICE] Docker Build Command : docker build --no-cache --tag ${project_name}:latest --build-arg server="${app_env}" ${env_build_args} -f ${docker_file_name} ."
       cd ${docker_file_location} && docker build --no-cache --tag ${project_name}:latest --build-arg server="${app_env}" ${env_build_args} -f ${docker_file_name} . || exit 1
       cd -
    else
       echo "[NOTICE] Docker Build Command : docker build --build-arg DISABLE_CACHE=${CUR_TIME} --tag ${project_name}:latest --build-arg server="${app_env}" --build-arg HOST_IP="${HOST_IP}" ${env_build_args} -f ${docker_file_name} ."
       cd ${docker_file_location} && docker build --build-arg DISABLE_CACHE=${CUR_TIME} --tag ${project_name}:latest --build-arg server="${app_env}" --build-arg HOST_IP="${HOST_IP}" ${env_build_args} -f ${docker_file_name} . || exit 1
       cd -
    fi

  fi

  if [[ $(docker images -q ${project_name}:previous 2> /dev/null) == '' ]]
  then
     docker tag ${project_name}:latest ${project_name}:previous
  fi

  docker tag ${project_name}:latest ${project_name}:blue
  docker tag ${project_name}:latest ${project_name}:green
}

app_down_and_up(){

    if [[ ${orchestration_type} == 'stack' ]]; then
      echo "[NOTICE] Down & Up '${project_name}-${new_state} stack'."
      docker stack rm ${project_name}-${new_state} || echo "[NOTICE] The ${project_name}-${new_state} stack has been removed, if exists."
      docker stack deploy --compose-file docker-${orchestration_type}-${project_name}-${app_env}.yml ${project_name}-${new_state} || (echo "[ERROR] Service ${new_state} UP failure, however that does NOT affect the current deployment, as this is Blue-Green Deployment. (command : docker stack deploy --compose-file docker-${orchestration_type}-${project_name}-${app_env}.yml ${project_name})" && exit 1)

      # [TO DO] docker stack takes a long time to be up. it needs to use a good logic instead of sleep.
      sleep 20

    else
      echo "[NOTICE] Down & Up '${project_name}-${new_state} container'."
      docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml stop ${project_name}-${new_state} || echo "[NOTICE] The previous ${new_state} Container has been stopped, if exists."
      docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml rm -f ${project_name}-${new_state} || echo "[NOTICE] The previous ${new_state} Container has been removed, if exists."
      docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml up -d ${project_name}-${new_state} || (echo "[ERROR] App ${new_state} UP failure, however that does NOT affect the current deployment, as this is Blue-Green Deployment." && exit 1)
      echo "[NOTICE] '${project_name}-${new_state} container' : successfully UP."
    fi

}

nginx_down_and_up(){

   echo "[NOTICE] As !NGINX_RESTART is true, which means there will be a short-downtime for Nginx, terminate Nginx container and network."

   echo "[NOTICE] Stop & Remove NGINX Container."
   docker-compose -f docker-compose-${project_name}-nginx.yml down || echo "[NOTICE] The previous Nginx Container has been stopped & removed, if exists."

   echo "[NOTICE] Up NGINX Container."
   PROJECT_NAME=${project_name} docker-compose -f docker-compose-${project_name}-nginx.yml up -d || echo "[ERROR] Critical - ${project_name}-nginx UP failure"

}

consul_down_and_up(){

    echo "[NOTICE] As !CONSUL_RESTART is true, which means there will be a short-downtime for CONSUL, terminate CONSUL container and network."


    echo "[NOTICE] Forcefully Stop & Remove CONSUL Container."
    docker-compose -f docker-compose-consul.yml down || echo "[NOTICE] The previous Consul & Registrator Container has been stopped, if exists."
    docker container rm -f consul || echo "[NOTICE] The previous Consul Container has been  removed, if exists."
    docker container rm -f registrator || echo "[NOTICE] The previous Registrator Container has been  removed, if exists."

    set_network_driver_for_orchestration_type

    echo "[NOTICE] Up CONSUL container"
    # https://github.com/hashicorp/consul/issues/17973
    docker-compose -p consul -f docker-compose-consul.yml up -d || echo "[NOTICE] Consul has already been created. You can ignore this message."

   #fi


    sleep 10
}

check_one_container_loaded(){

      if [ "$(docker ps -q -f name=^${1})" ]; then
          echo "[NOTICE] Supporting container ( ${1} ) running checked."
        else
          echo "[ERROR] Supporting container ( ${1} ) running not found."
        fi
}

check_supporting_containers_loaded(){
  all_container_names=("consul" "registrator" "${project_name}-nginx")
  for name in "${all_container_names[@]}"; do
    check_one_container_loaded ${name}
  done
}


load_all_containers(){
  # app, consul, nginx
  # In the past, restarting Nginx before App caused error messages like "upstream not found" in the Nginx configuration file. This seems to have caused a 502 error on the socket side.
  # Therefore, it is safer to restart the containers in the order of Consul -> App -> Nginx.
  if [[ ${consul_restart} == 'true' ]]; then

      consul_down_and_up

  fi

  echo "[NOTICE] Creating consul network..."
  if [[ ${orchestration_type} != 'stack' ]]; then
   docker network create consul || echo "[NOTICE] Consul Network has already been created. You can ignore this message."
  else
      docker network create --driver overlay consul || echo "[NOTICE] Consul Network has already been created. You can ignore this message."
  fi


  echo "[NOTICE] Run the app as a ${new_state} container. (As long as NGINX_RESTART is set to 'false', this won't stop the running container since this is a BLUE-GREEN deployment.)"
  app_down_and_up

  #if [[ ${orchestration_type} != 'stack' ]]; then
    echo "[NOTICE] Check the integrity inside the '${project_name}-${new_state} container'."
    if [[ ${app_env} == 'local' ]]; then
       re=$(check_availability_inside_container ${new_state} 600 30 | tail -n 1) || exit 1;
    else
       re=$(check_availability_inside_container ${new_state} 120 5 | tail -n 1) || exit 1;
    fi

    if [[ ${re} != 'true' ]]; then
      echo "[ERROR] Failed in running the ${new_state} container. Run ' docker logs -f ${project_name}-${new_state} (compose), docker service ps ${project_name}-${new_state}}_${project_name}-${new_state} (stack) ' to check errors (Return : ${re})" && exit 1
    fi
  #else
   # echo "[NOTICE] Check the integrity from Consul to the '${project_name}-${new_state} stack'."
   # if [[ ${app_env} == 'local' ]]; then
   #    re=$(check_availability_from_consul_to_container ${new_state} 30 | tail -n 1) || exit 1;
   # else
   #    re=$(check_availability_from_consul_to_container ${new_state} 5 | tail -n 1) || exit 1;
   # fi
   #sleep 20
   # echo "aaa"
    #if [[ ${re} != 'true' ]]; then
    #  echo "[ERROR] Failed in running the ${new_state} container. Run 'docker logs -f ${project_name}-${new_state}' to check errors (Return : ${re})" && exit 1
    #fi
 # fi


  if [[ ${nginx_restart} == 'true' ]]; then

      nginx_down_and_up

  fi

  check_supporting_containers_loaded || (echo "[ERROR] Fail in loading supporting containers." && exit 1)

}

backup_to_new_images(){

    echo "[NOTICE] docker tag latest new"
    docker tag ${project_name}:latest ${project_name}:new || echo "[NOTICE] the ${project_name}:latest image does NOT exist."
    echo "[NOTICE] docker tag latest new (NGINX)"
    docker tag ${project_name}-nginx:latest ${project_name}-nginx:new || echo "[NOTICE] ${project_name}-nginx:latest does NOT exist."
}


_main() {

  # [A] Get mandatory variables
  check_necessary_commands
  cache_global_vars
  # The 'cache_all_states' in 'cache_global_vars' function decides which state should be deployed. If this is called later at a point in this script, states could differ.
  local initially_cached_old_state=${state}
  check_env_integrity

  echo "[NOTICE] Finally, !! Deploy the App as !! ${new_state} !!, we will now deploy '${project_name}' in a way of 'Blue-Green'"

  # [B] Set mandatory files
  # These are all about passing variables from the .env to the docker-${orchestration_type}-${project_name}-local.yml
  initiate_docker_compose
  apply_env_service_name_onto_app_yaml
  apply_ports_onto_nginx_yaml
  apply_docker_compose_environment_onto_app_yaml

  # Refer to .env.*.real
  if [[ ${app_env} == 'real' ]]; then
    apply_docker_compose_volumes_onto_app_real_yaml
  fi

  apply_docker_compose_volumes_onto_app_nginx_yaml

  create_nginx_ctmpl

  if [[ ${skip_building_app_image} != 'true' ]]; then
    backup_app_to_previous_images
  fi
  backup_nginx_to_previous_images

  if [[ ${app_env} == 'local' ]]; then

      give_host_group_id_full_permissions
  #else

     # create_host_folders_if_not_exists
  fi

  if [[ ${docker_layer_corruption_recovery} == 'true' ]]; then
    terminate_whole_system
  fi

  # [B] Build Docker images for the App, Nginx, Consul
  if [[ ${skip_building_app_image} != 'true' ]]; then
    load_app_docker_image
  fi
    load_consul_docker_image
    load_nginx_docker_image

  if [[ ${only_building_app_image} == 'true' ]]; then
    echo "[NOTICE] Successfully built the App image : ${new_state}" && exit 0
  fi

  local cached_new_state=${new_state}
  cache_all_states
  if [[ ${cached_new_state} != "${new_state}" ]]; then
    (echo "[ERROR] Just checked all states shortly after the Docker Images had been done built. The state the App was supposed to be deployed as has been changed. (Original : ${cached_new_state}, New : ${new_state}). For the safety, we exit..." && exit 1)
  fi

  # [C] docker-compose up the App, Nginx, Consul & * Internal Integrity Check for the App
  load_all_containers

  # [D] Set Consul
  ./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}

  # [E] External Integrity Check, if fails, 'emergency-nginx-down-and-up.sh' will be run.
  re=$(check_availability_out_of_container | tail -n 1);
  if [[ ${re} != 'true' ]]; then
    echo "[WARNING] ! ${new_state}'s availability issue found. Now we are going to run 'emergency-nginx-down-and-up.sh' immediately."
    bash emergency-nginx-down-and-up.sh

    re=$(check_availability_out_of_container | tail -n 1);
    if [[ ${re} != 'true' ]]; then
      echo "[ERROR] Failed to call app_url on .env outside the container. Consider running bash rollback.sh. (result value : ${re})" && exit 1
    fi
  fi


  # [F] Finalizing the process : from this point on, regarded as "success".
  if [[ ${skip_building_app_image} != 'true' ]]; then
    backup_to_new_images
  fi

  echo "[DEBUG] state : ${state}, new_state : ${new_state}, initially_cached_old_state : ${initially_cached_old_state}"

  echo "[NOTICE] For safety, finally check Consul pointing before stopping the previous container (${initially_cached_old_state})."
  local consul_pointing=$(docker exec ${project_name}-nginx curl ${consul_key_value_store}?raw 2>/dev/null || echo "failed")
  if [[ ${consul_pointing} != ${initially_cached_old_state} ]]; then
    if [[ ${orchestration_type} != 'stack' ]]; then
      docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml stop ${project_name}-${initially_cached_old_state}
      echo "[NOTICE] The previous (${initially_cached_old_state}) container (initially_cached_old_state) has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
    else
       docker stack rm ${project_name}-${initially_cached_old_state}
       echo "[NOTICE] The previous (${initially_cached_old_state}) service (initially_cached_old_state) has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
    fi
  else
    echo "[NOTICE] The previous (${initially_cached_old_state}) container (initially_cached_old_state) has NOT been stopped because the current Consul Pointing is ${consul_pointing}."
  fi

  echo "[NOTICE] Delete <none>:<none> images."
  docker rmi $(docker images -f "dangling=true" -q) || echo "[NOTICE] Any images in use will not be deleted."

  echo "[NOTICE] APP_URL : ${app_url}"
}

_main
