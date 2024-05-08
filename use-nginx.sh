#!/bin/bash
set -eu

git config apply.whitespace nowarn
git config core.filemode false

initiate_nginx_docker_compose_file(){
  cp -f docker-compose-app-nginx-original.yml docker-compose-${project_name}-nginx.yml || (echo "[ERROR] Failed to copy docker-${orchestration_type}-app-nginx-original.yml" && exit 1)
  echo "[DEBUG] successfully copied docker-compose-app-nginx-original.yml"
}
apply_env_service_name_onto_nginx_yaml(){
  yq -i "with(.services; with_entries(select(.key ==\"*-nginx\") | .key |= \"${project_name}-nginx\"))" docker-compose-${project_name}-nginx.yml || (echo "[ERROR] Failed to apply the service name in the Nginx YAML as ${project_name}." && exit 1)
}
apply_ports_onto_nginx_yaml(){

   if [[ ${nginx_restart} == 'true' ]]; then

     check_yq_installed

     echo "[NOTICE] PORTS on .env is now being applied to docker-compose-${project_name}-nginx.yml."
     yq -i '.services.'${project_name}'-nginx.ports = []' docker-compose-${project_name}-nginx.yml
     yq -i '.services.'${project_name}'-nginx.ports += "'${expose_port}':'${expose_port}'"' docker-compose-${project_name}-nginx.yml

     for i in "${additional_ports[@]}"
     do
        [ -z "${i##*[!0-9]*}" ] && (echo "[ERROR] Wrong port number on .env : ${i}" && exit 1);
        yq -i '.services.'${project_name}'-nginx.ports += "'$i:$i'"' docker-compose-${project_name}-nginx.yml
     done

   fi

}
apply_docker_compose_volumes_onto_app_nginx_yaml(){

   check_yq_installed

   echo "[NOTICE] DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES on .env is now being applied to docker-compose-${project_name}-nginx.yml."

    for volume in "${docker_compose_nginx_selective_volumes[@]}"
    do
        yq -i '.services.'${project_name}'-'nginx'.volumes += '${volume}'' ./docker-compose-${project_name}-nginx.yml
    done

}

create_nginx_ctmpl(){

   local proxy_hostname=
   local proxy_hostname_blue=

   if [[ ${orchestration_type} == 'stack' ]]; then
     proxy_hostname="!#{PROJECT_NAME}-{{ \$key_value }}_!#{PROJECT_NAME}-{{ \$key_value }}"
     proxy_hostname_blue="!#{PROJECT_NAME}-blue_!#{PROJECT_NAME}-blue"
   else
     proxy_hostname="!#{PROJECT_NAME}-{{ \$key_value }}"
     proxy_hostname_blue="!#{PROJECT_NAME}-blue"
   fi

   local app_https_protocol="https";
   if [[ ${redirect_https_to_http} = 'true' ]]; then
      app_https_protocol="http"
   fi

   echo "[NOTICE] NGINX template (.docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl) is now being created."

   sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
       -e "s|!#{proxy_hostname_blue}|${proxy_hostname_blue}|g" \
       -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
       .docker/nginx/origin/conf.d/${protocol}/app/nginx.conf.ctmpl.origin > .docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl

   echo "" >> .docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl

    for i in "${additional_ports[@]}"
    do
         sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
             -e "s|!#{proxy_hostname_blue}|${proxy_hostname_blue}|g" \
             -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
             -e "s|!#{additional_port}|${i}|g" \
             .docker/nginx/origin/conf.d/${protocol}/additionals/nginx.conf.ctmpl.origin >> .docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl

         echo "" >> .docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl
    done
}

create_nginx_contingency_conf(){

   local proxy_hostname=

   if [[ ${orchestration_type} == 'stack' ]]; then
     proxy_hostname="!#{PROJECT_NAME}-!#{APP_STATE}_!#{PROJECT_NAME}-!#{APP_STATE}"
   else
     proxy_hostname="!#{PROJECT_NAME}-!#{APP_STATE}"
   fi

    local app_https_protocol="https";
    if [[ ${redirect_https_to_http} = 'true' ]]; then
       app_https_protocol="http"
    fi


   echo "[NOTICE] NGINX template (.docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl) is now being created."

   sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
       -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
       .docker/nginx/origin/conf.d/${protocol}/app/nginx.conf.contingency.origin > .docker/nginx/ctmpl/${protocol}/nginx.conf.contingency

    echo "" >> .docker/nginx/ctmpl/${protocol}/nginx.conf.contingency

    for i in "${additional_ports[@]}"
    do
         sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
              -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
              -e "s|!#{additional_port}|${i}|g" \
             .docker/nginx/origin/conf.d/${protocol}/additionals/nginx.conf.contingency.origin >> .docker/nginx/ctmpl/${protocol}/nginx.conf.contingency

         echo "" >> .docker/nginx/ctmpl/${protocol}/nginx.conf.contingency
    done
}

load_nginx_docker_image(){

    if [ ${git_image_load_from} = "registry" ]; then

      echo "[NOTICE] Attempt to log in to the Registry."
      docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} ${git_image_load_from_host}

      echo "[NOTICE] Pull the Nginx image stored in the Registry."
      docker pull ${nginx_image_name_in_registry} || exit 1
      docker tag ${nginx_image_name_in_registry} ${project_name}-nginx:latest || exit 1
      docker rmi -f ${nginx_image_name_in_registry} || exit 1
    else

      echo "[NOTICE] As !NGINX_RESTART is true, which means there will be a short-downtime for Nginx, before that, we are now building the ${project_name}-nginx image (using cache)."
      docker build --build-arg DISABLE_CACHE=${CUR_TIME} --build-arg protocol="${protocol}" --build-arg shared_volume_group_id="${shared_volume_group_id}" --build-arg shared_volume_group_name="${shared_volume_group_name}" --tag ${project_name}-nginx -f ./.docker/nginx/Dockerfile -m ${docker_build_memory_usage} . || exit 1

    fi


}

nginx_down_and_up(){

   echo "[NOTICE] As !NGINX_RESTART is true, which means there will be a short-downtime for Nginx, terminate Nginx container and network."

   echo "[NOTICE] Stop & Remove NGINX Container."
   docker-compose -f docker-compose-${project_name}-nginx.yml down || echo "[NOTICE] The previous Nginx Container has been stopped & removed, if exists."

   echo "[NOTICE] Up NGINX Container."
   PROJECT_NAME=${project_name} docker-compose -f docker-compose-${project_name}-nginx.yml up -d || echo "[ERROR] Critical - ${project_name}-nginx UP failure"

}
