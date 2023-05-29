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
      # new 이미지가 있을 경우
      echo "[NOTICE] Docker tag 'new' 'previous'"
      docker tag ${project_name}:new ${project_name}:previous && return  || echo "[NOTICE] There is no 'new' tag image to backup the app."
  fi

  # new 이미지가 없을 경우
  echo "[NOTICE] Since there is no 'new' tag image for the app, we will check the blue or green container and use the image of the container that is running properly as the backup image."
  if [[ $(docker exec ${project_name}-blue printenv SERVICE_NAME 2> /dev/null) == 'blue' ]]
  then
      echo "[NOTICE] Checking if the blue container is running..."
      if [[ $(check_availability_inside_container 'blue' 10 5 | tail -n 1) == 'true' ]]; then
          echo "[NOTICE] Docker tag 'blue' 'previous'"
          docker tag ${project_name}:blue ${project_name}:previous && return || echo "[NOTICE] No 'blue' tagged image."
      fi
  fi

  if [[ $(docker exec ${project_name}-green printenv SERVICE_NAME 2> /dev/null) == 'green' ]]
  then
      echo "[NOTICE] Checking if the green container is running..."
      if [[ $(check_availability_inside_container 'green' 10 5 | tail -n 1) == 'true' ]]; then
        echo "[NOTICE] Docker tag 'green' 'previous'"
        docker tag ${project_name}:green ${project_name}:previous && return || echo "[NOTICE] No 'green' tagged image."
      fi
  fi

  echo "[NOTICE] Since there are no 'new', 'blue', and 'green' images, we will attempt to back up the latest image as previous"
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
  echo "[NOTICE] To facilitate access from an IDE to Docker's internal permissions, we grant host permissions locally and set them to 777."
  sudo chgrp -R ${host_root_gid} ${host_root_location}
  sudo chmod -R 777 ${host_root_location}
}

terminate_whole_system(){
  if [[ ${docker_layer_corruption_recovery} == true ]]; then
    docker rmi -f ${project_name}-nginx:latest
    docker rmi -f ${project_name}-nginx:new
    docker rmi -f ${project_name}-nginx:previous

    docker rmi -f ${project_name}:latest
    docker rmi -f ${project_name}:new
    docker rmi -f ${project_name}:previous
    docker rmi -f ${project_name}:blue
    docker rmi -f ${project_name}:green

    docker-compose -f docker-compose-app-local.yml down || echo "[NOTICE] docker-compose-app-local.yml down failure"
    docker-compose -f docker-compose-app-real.yml down || echo "[NOTICE] docker-compose-app-real.yml down failure"
    docker-compose -f docker-compose-consul.yml down || echo "[NOTICE] docker-compose-app-consul.yml down failure"
    docker-compose -f docker-compose-nginx.yml down || echo "[NOTICE] docker-compose-app-nginx.yml down failure"
    docker-compose down || echo "[NOTICE] docker-compose.yml down failure"
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

# TO DO : 폐쇄망 모듈
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

      echo "[NOTICE] Build the ${project_name}-nginx image (using cache)."
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

    #  이미지 파일을 load 하지 않고 Dockerfile 을 활용하는 경우
    echo "[NOTICE] Build the image with ${docker_file_location}/Dockerfile.${app_env} (using cache)"
    if [[ ${docker_layer_corruption_recovery} == true ]]; then
      cd ${docker_file_location} && docker build --no-cache --tag ${project_name}:latest --build-arg server="${app_env}" -f Dockerfile.${app_env} . || exit 1
      cd -
    else
       cd ${docker_file_location} && docker build --build-arg DISABLE_CACHE=${CUR_TIME} --tag ${project_name}:latest --build-arg server="${app_env}" -f Dockerfile.${app_env} . || exit 1
       cd -
    fi

  fi

  # 자 이제, ${project_name}:latest 이미지가 생성되었다.

  if [[ $(docker images -q ${project_name}:previous 2> /dev/null) == '' ]]
  then
     docker tag ${project_name}:latest ${project_name}:previous
  fi

  docker tag ${project_name}:latest ${project_name}:blue
  docker tag ${project_name}:latest ${project_name}:green
}

inject_env_real() {
  echo "[NOTICE] To use the current project's .env, execute the command 'cp -f .env ./.docker/env/real/.env'."
  sudo cp -f .env ./.docker/env/real/.env
}

nginx_restart(){

   echo "[NOTICE] Terminate NGINX container and network."

   # docker-compose -f docker-compose-app-${app_env}.yml down || echo "[DEBUG] A1"
   docker-compose -f docker-compose-nginx.yml down || echo "[DEBUG] N1"

   docker network rm ${project_name}_app || echo "[DEBUG] NA"

   echo "[NOTICE] NGINX 를 컨테이너로 띄웁니다."
   PROJECT_NAME=${project_name} docker-compose -f docker-compose-nginx.yml up -d ${project_name}-nginx || echo "[ERROR] Critical - ${project_name}-nginx UP failure"
}

consul_restart(){

    echo "[NOTICE] Terminate CONSUL container and network."

    #docker-compose -f docker-compose-app-${app_env}.yml down || echo "[DEBUG] C-A1"
    #docker-compose -f docker-compose-nginx.yml down || echo "[DEBUG] C-N1"
    docker-compose -f docker-compose-consul.yml down || echo "[DEBUG] C-1"

    docker network rm consul || echo "[DEBUG] CA"

    docker network create consul || echo "[NOTICE] Consul Network has already been created. You can ignore this message, or if you want to restart it, please terminate other projects that share the Consul network."

    echo "[NOTICE] Run CONSUL container"
    docker-compose -p consul -f docker-compose-consul.yml up -d || echo "[NOTICE] Consul has already been created. You can ignore this message."
    sleep 10
}

# 위에서 이미지들을 load 했으니, 해당 이미지들을 바탕으로 컨테이너 들을 load 한다.
load_all_containers(){

  # In the past, restarting Nginx before App caused error messages like "upstream not found" in the Nginx configuration file. This seems to have caused a 502 error on the socket side.
  # Therefore, it is safer to restart the containers in the order of App -> Consul -> Nginx.
  echo "[NOTICE] Run the app as a ${new_state} container. (This doesn't stop the running container since this is a BLUE-GREEN deployment.)"

  docker network create consul || echo "[NOTICE] Consul Network has already been created. You can ignore this message."
  docker-compose -f docker-compose-app-${app_env}.yml up -d ${project_name}-${new_state} || echo "[ERROR] Critical - App ${new_state} UP failure"

  if [[ ${app_env} == 'local' ]]; then
     re=$(check_availability_inside_container ${new_state} 600 30 | tail -n 1) || exit 1;
  else
     re=$(check_availability_inside_container ${new_state} 120 5 | tail -n 1) || exit 1;
    #dynamic_timeout=5000
    #sleep 5
    #docker exec -it ${project_name}-${new_state}  bash -c 'bash '${project_location}'/'${project_name}'/.docker/sh/update/local/'${project_name}'.sh'
  fi

  if [[ ${re} != 'true' ]]; then
    echo "[ERROR] Failed in running the ${new_state} container. Run 'docker logs -f ${project_name}-${new_state}' to check errors (Return : ${re})" && exit 1
  fi

  if [[ ${consul_restart} == 'true' ]]; then

      consul_restart

  fi

  if [[ ${nginx_restart} == 'true' ]]; then

      nginx_restart

  fi

}

check_availability_out_of_container(){

  echo "[NOTICE] Check the status from the outside of the container."  >&2
  sleep 1

  for retry_count in {1..6}
  do
    status=$(curl ${app_url}/${app_health_check_path} -o /dev/null -k -Isw '%{http_code}' --connect-timeout 10)
    available_status_cnt=$(echo ${status} | egrep -i '^2[0-9]+|3[0-9]+$' | wc -l)

    if [[ ${available_status_cnt} < 1 ]]; then

      echo "Bad HTTP response in the ${new_state} app: ${status}"  >&2

      if [[ ${retry_count} -eq 5 ]]
      then
         echo "[ERROR] Health Check Failed. (If you are not accessing an external domain (=closed network setting environment), you need to check if APP_URL is the value retrieved by ifconfig on the Ubuntu host. Access to the ip output by the WIN ipconfig command may fail. Or you need to check the network firewall."  >&2
         echo "false"
         return
      fi

    else
      echo "[NOTICE] Success. (Status (2xx, 3xx) : ${status})"  >&2
      break
    fi

    echo "[NOTICE] Retry once every 3 seconds for a total of 5 times..."  >&2
    sleep 3
  done

  echo 'true'
  return

}

backup_to_new_images(){
    # 성공 시 현재 도커 이미지를 previous 로 하여 rollback 시 시용
    echo "[NOTICE] docker tag latest new"
    docker tag ${project_name}:latest ${project_name}:new || echo "[NOTICE] the ${project_name}:latest image does NOT exist."
    echo "[NOTICE] docker tag latest new (NGINX)"
    docker tag ${project_name}-nginx:latest ${project_name}-nginx:new || echo "[NOTICE] ${project_name}-nginx:latest does NOT exist."
}


_main() {

  check_necessary_commands

  cache_global_vars

  check_env_integrity

  apply_env_service_name_onto_app_yaml
  apply_ports_onto_nginx_yaml
  create_nginx_ctmpl

  backup_app_to_previous_images
  backup_nginx_to_previous_images

  # 필요한 폴더들의 생성과 권한 설정
  if [[ ${app_env} == 'local' ]]; then
      # 권한이 적합하지 않을 경우 앱이 작동하는 상황에서 오류 발생
      give_host_group_id_full_permissions
  else
      # docker-compose-app-real.yml 참조
      create_host_folders_if_not_exists
  fi


  #echo "[NOTICE] docker system prune -f 명령어를 통해 도커 구조를 효율화 합니다."
  #docker system prune -f
  if [[ ${docker_layer_corruption_recovery} == true ]]; then
    terminate_whole_system
  fi

  # 웹 Docker 이미지를 만든다
  load_app_docker_image

  # Consul Docker 이미지를 만든다.
  load_consul_docker_image

  # Nginx Docker 이미지를 만든다.
  load_nginx_docker_image

  if [[ ${app_env} == 'real' ]]; then
    inject_env_real
    sleep 2
  fi
  # 위에서 이미지들을 load 했으니, 해당 이미지들을 바탕으로 컨테이너 들을 load 한다.
  load_all_containers

  # Consul 과 연동하여 Blue-Green 세팅을 한다.
  ./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}

  # 컨테이너 밖에서 app_url 을 호출하여 유효성을 확인한다.
  re=$(check_availability_out_of_container | tail -n 1);
  if [[ ${re} != 'true' ]]; then
    echo "[ERROR] Failed to call app_url outside container. Consider running bash rollback.sh. (result value : ${re})" && exit 1
  fi

  ## 여기까지 도달하면 성공으로 간주

  # 성공 시 현재 도커 이미지를 previous 로 하여 rollback 시 시용
  backup_to_new_images

  # 성공 시 이전 컨테이너 종료
  echo "[NOTICE] The previous (${state}) container exits because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
  docker-compose -f docker-compose-app-${app_env}.yml stop ${project_name}-${state}

  echo "[NOTICE] Delete <none>:<none> images."
  docker rmi $(docker images -f "dangling=true" -q) || echo "[NOTICE] If any images are in use, they will not be deleted."
}

_main
