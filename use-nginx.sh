#!/bin/bash
set -eu

git config apply.whitespace nowarn
git config core.filemode false

initiate_nginx_docker_compose_file(){
  cp -f docker-compose-app-nginx-original.yml docker-compose-${project_name}-nginx.yml || (echo "[ERROR] Failed to copy docker-${orchestration_type}-app-nginx-original.yml" && exit 1)
  echo "[DEBUG] successfully copied docker-compose-app-nginx-original.yml"
}
apply_env_service_name_onto_nginx_yaml(){
  bin/yq -i "with(.services; with_entries(select(.key ==\"*-nginx\") | .key |= \"${project_name}-nginx\"))" docker-compose-${project_name}-nginx.yml || (echo "[ERROR] Failed to apply the service name in the Nginx YML as ${project_name}." && exit 1)
}
apply_ports_onto_nginx_yaml(){

     check_yq_installed

     echo "[NOTICE] PORTS on .env is now being applied to docker-compose-${project_name}-nginx.yml."
     bin/yq -i '.services.'${project_name}'-nginx.ports = []' docker-compose-${project_name}-nginx.yml
     bin/yq -i '.services.'${project_name}'-nginx.ports += "'${expose_port}':'${expose_port}'"' docker-compose-${project_name}-nginx.yml

     for i in "${additional_ports[@]}"
     do
        [ -z "${i##*[!0-9]*}" ] && (echo "[ERROR] Wrong port number on .env : ${i}" && exit 1);
        bin/yq -i '.services.'${project_name}'-nginx.ports += "'$i:$i'"' docker-compose-${project_name}-nginx.yml
     done

}

check_docker_compose_nginx_host_volumes_directories() {

    local volumes=$(echo "${docker_compose_nginx_selective_volumes[@]}" | tr -d '[]"')

    for volume in ${volumes}
    do
        # Extract the local directory path before the colon (:)
        local_dir="${volume%%:*}"

        # Check if the directory or file exists
        if [[ ! -f "$local_dir" && ! -d "$local_dir" ]]; then
            echo "[ERROR] The local path '$local_dir' specified in DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES does not exist. Exiting..."
            exit 1
        fi
    done
}


apply_docker_compose_volumes_onto_app_nginx_yaml(){

   check_yq_installed

    if [[ ${docker_compose_host_volume_check} == 'true' ]]; then
       check_docker_compose_nginx_host_volumes_directories
    fi

   echo "[NOTICE] DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES on .env is now being applied to docker-compose-${project_name}-nginx.yml."

    for volume in "${docker_compose_nginx_selective_volumes[@]}"
    do
        bin/yq -i '.services.'${project_name}'-'nginx'.volumes += '${volume}'' ./docker-compose-${project_name}-nginx.yml
    done

}

set_origin_file() {
    local customized_file=$1
    local default_file=$2

    if [[ ${use_my_own_nginx_origin} = 'true' ]]; then
      if [[ -f $customized_file ]]; then
        echo $customized_file
      else
        echo $default_file
      fi
    else
      echo $default_file
    fi
}

save_nginx_ctmpl_template_from_origin(){

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

    local nginx_template_file=".docker/nginx/template/ctmpl/${protocol}/nginx.conf.ctmpl"

    echo "[NOTICE] NGINX template (${nginx_template_file}) is now being created."

    local app_origin_file=$(set_origin_file ".docker/nginx/origin/conf.d/${protocol}/app/nginx.conf.ctmpl.origin.customized" \
                                        ".docker/nginx/origin/conf.d/${protocol}/app/nginx.conf.ctmpl.origin")

    echo "[DEBUG] ${app_origin_file} will be added to Template (${nginx_template_file})"

    sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
        -e "s|!#{proxy_hostname_blue}|${proxy_hostname_blue}|g" \
        -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
        "${app_origin_file}" > "${nginx_template_file}"


    echo "" >> "${nginx_template_file}"

    local additionals_origin_file=$(set_origin_file ".docker/nginx/origin/conf.d/${protocol}/additionals/nginx.conf.ctmpl.origin.customized" \
                                        ".docker/nginx/origin/conf.d/${protocol}/additionals/nginx.conf.ctmpl.origin")

    echo "[DEBUG] ${additionals_origin_file} will be added to Template (${nginx_template_file})"

    if [ ${#additional_ports[@]} -eq 0 ]; then
        echo "[DEBUG] However, no additional_ports found. it will not be added to ${nginx_template_file}"
    else
      for i in "${additional_ports[@]}"
      do

           sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
               -e "s|!#{proxy_hostname_blue}|${proxy_hostname_blue}|g" \
               -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
               -e "s|!#{additional_port}|${i}|g" \
               "${additionals_origin_file}" >> "${nginx_template_file}"

           echo "" >> ${nginx_template_file}
      done
    fi

   sed -i -e "s|!#{EXPOSE_PORT}|${expose_port}|g" \
       -e "s|!#{APP_PORT}|${app_port}|g" \
       -e "s|!#{PROJECT_NAME}|${project_name}|g" \
       -e "s|!#{CONSUL_KEY}|${consul_key}|g" \
       -e "s|!#{NGINX_CLIENT_MAX_BODY_SIZE}|${nginx_client_max_body_size}|g" \
       "${nginx_template_file}"


   if [[ ${use_nginx_restricted_location} = 'true' ]]; then

       sed -i -e "/!#{USE_NGINX_RESTRICTED_LOCATION}/c \
           location ${nginx_restricted_location} { \
               add_header Pragma no-cache; \
               add_header Cache-Control no-cache; \
       \
                               auth_basic           \"Restricted\"; \
                               auth_basic_user_file /etc/nginx/custom-files/.htpasswd; \
       \
              {{ with \$key_value := keyOrDefault \"${consul_key}\" \"blue\" }} \
                  {{ if or (eq \$key_value \"blue\") (eq \$key_value \"green\") }} \
                       proxy_pass ${protocol}://${project_name}-{{ \$key_value }}:${app_port}; \
                {{ else }} \
                       proxy_pass ${protocol}://${project_name}-blue:${app_port}; \
                   {{ end }} \
               {{ end }}  \
               proxy_set_header Host \$http_host; \
               proxy_set_header X-Scheme \$scheme; \
               proxy_set_header X-Forwarded-Protocol \$scheme; \
               proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; \
               proxy_set_header X-Real-IP \$remote_addr; \
               proxy_http_version 1.1; \
               proxy_read_timeout 300s; \
               proxy_connect_timeout 75s; \
           }" "${nginx_template_file}"
   else

     sed -i -e "s/!#{USE_NGINX_RESTRICTED_LOCATION}//" "${nginx_template_file}"

   fi
}

save_nginx_contingency_template_from_origin(){

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


   local nginx_contingency_template_temp_file=".docker/nginx/template/ctmpl/${protocol}/nginx.conf.contingency"
   local nginx_contingency_template_blue_file=".docker/nginx/template/ctmpl/${protocol}/nginx.conf.contingency.blue"
   local nginx_contingency_template_green_file=".docker/nginx/template/ctmpl/${protocol}/nginx.conf.contingency.green"

   echo "[NOTICE] NGINX template (${nginx_contingency_template_temp_file}) is now being created."

   sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
       -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
       .docker/nginx/origin/conf.d/${protocol}/app/nginx.conf.contingency.origin > ${nginx_contingency_template_temp_file}

    echo "" >> ${nginx_contingency_template_temp_file}

    for i in "${additional_ports[@]}"
    do
         sed -e "s|!#{proxy_hostname}|${proxy_hostname}|g" \
              -e "s|!#{app_https_protocol}|${app_https_protocol}|g" \
              -e "s|!#{additional_port}|${i}|g" \
             .docker/nginx/origin/conf.d/${protocol}/additionals/nginx.conf.contingency.origin >> ${nginx_contingency_template_temp_file}

         echo "" >> ${nginx_contingency_template_temp_file}
    done


    sed -i -e "s|!#{EXPOSE_PORT}|${expose_port}|g" \
       -e "s|!#{APP_PORT}|${app_port}|g" \
       -e "s|!#{PROJECT_NAME}|${project_name}|g" \
       -e "s|!#{CONSUL_KEY}|${consul_key}|g" \
       -e "s|!#{NGINX_CLIENT_MAX_BODY_SIZE}|${nginx_client_max_body_size}|g" \
       ${nginx_contingency_template_temp_file}



      if [[ ${use_nginx_restricted_location} = 'true' ]]; then

        sed -i -e "/!#{USE_NGINX_RESTRICTED_LOCATION}/c \
            location ${nginx_restricted_location} { \
                add_header Pragma no-cache; \
                add_header Cache-Control no-cache; \
        \
                                auth_basic           \"Restricted\"; \
                                auth_basic_user_file /etc/nginx/custom-files/.htpasswd; \
        \
                proxy_pass ${protocol}://${project_name}-!#{APP_STATE}:${app_port}; \
                proxy_set_header Host \$http_host; \
                proxy_set_header X-Scheme \$scheme; \
                proxy_set_header X-Forwarded-Protocol \$scheme; \
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; \
                proxy_set_header X-Real-IP \$remote_addr; \
                proxy_http_version 1.1; \
                proxy_read_timeout 300s; \
                proxy_connect_timeout 75s; \
            }" ${nginx_contingency_template_temp_file}

      else

        sed -i -e "s/!#{USE_NGINX_RESTRICTED_LOCATION}//" ${nginx_contingency_template_temp_file}

      fi


    echo "[NOTICE] Creating 'nginx.conf.contingency.blue', 'nginx.conf.contingency.green''."
    cp -f ${nginx_contingency_template_temp_file} ${nginx_contingency_template_blue_file}
    sed -i -e "s/!#{APP_STATE}/blue/" ${nginx_contingency_template_blue_file}
    cp -f ${nginx_contingency_template_temp_file} ${nginx_contingency_template_green_file}
    sed -i -e "s/!#{APP_STATE}/green/" ${nginx_contingency_template_green_file}

}

save_nginx_logrotate_template_from_origin(){

   echo "[NOTICE] NGINX LOGROTATE template (.docker/nginx/template/logrotate/nginx) is now being created."

   sed -e "s|!#{NGINX_LOGROTATE_FILE_NUMBER}|${nginx_logrotate_file_number}|g" \
       -e "s|!#{NGINX_LOGROTATE_FILE_SIZE}|${nginx_logrotate_file_size}|g" \
       -e "s|!#{SHARED_VOLUME_GROUP_NAME}|${shared_volume_group_name}|g" \
       .docker/nginx/origin/logrotate/nginx > .docker/nginx/template/logrotate/nginx

}


save_nginx_main_template_from_origin(){

   echo "[NOTICE] NGINX Main template (.docker/nginx/template/nginx.conf.main) is now being created."

   local main_origin_file=$(set_origin_file ".docker/nginx/origin/nginx.conf.main.origin.customized" \
                                       ".docker/nginx/origin/nginx.conf.main.origin")

   echo "[DEBUG] ${main_origin_file} will be processed into Template (.docker/nginx/template/nginx.conf.main)"

   cp -f ${main_origin_file} .docker/nginx/template/nginx.conf.main

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

nginx_down(){

   echo "[NOTICE] Stop & Remove NGINX Container."
   docker-compose -f docker-compose-${project_name}-nginx.yml down || echo "[NOTICE] The previous Nginx Container has been stopped & removed, if exists."

}

nginx_up(){

   echo "[NOTICE] Up NGINX Container."
   PROJECT_NAME=${project_name} docker-compose -f docker-compose-${project_name}-nginx.yml up -d || echo "[ERROR] Critical - ${project_name}-nginx UP failure."

}

nginx_down_and_up(){

   echo "[NOTICE] As !NGINX_RESTART is true, which means there will be a short-downtime for Nginx, terminate Nginx container and network."

   nginx_down
   nginx_up
}

check_nginx_templates_integrity(){

  echo "[NOTICE] Now we'll create a temporary NGINX image to test parsed settings in '.docker/nginx/template/ctmpl'"
  docker build --build-arg DISABLE_CACHE=${CUR_TIME} --build-arg protocol="${protocol}" --build-arg shared_volume_group_id="${shared_volume_group_id}" --build-arg shared_volume_group_name="${shared_volume_group_name}" --tag ${project_name}-nginx-test -f ./.docker/nginx/Dockerfile -m ${docker_build_memory_usage} . || exit 1
  echo "[NOTICE] Now we'll create a temporary NGINX container to test parsed settings in '.docker/nginx/template/ctmpl'"

  stop_and_remove_container "${project_name}-nginx-test"

  docker run -d -it --name ${project_name}-nginx-test \
    -e SERVICE_NAME=nginx \
    --network=consul \
    --env-file .env \
    ${project_name}-nginx-test:latest

  sleep 3

  echo "[NOTICE] Now we'll run 'nginx -t' to verify the syntax of '.docker/nginx/template/nginx.conf.main & ctmpl'"
  output=$(docker exec ${project_name}-nginx-test nginx -t 2>&1 || echo "[ERROR] ${project_name}-nginx-test failed to run. But don't worry. this is testing just before restarting Nginx. Check settings in '.docker/nginx/origin & .docker/nginx/template'")

  if echo "$output" | grep -q "successful"; then

      echo "[NOTICE] Testing for NGINX configuration was successful. Now we'll apply it to the real NGINX Container."
      stop_and_remove_container "${project_name}-nginx-test"

  elif echo "$output" | grep -q "host not found in upstream \"${project_name}"; then

        echo "[NOTICE] host not found in upstream (${project_name}) regarded as NOT a syntax issue. that is ignored. Now we'll apply it to the real NGINX Container."
        stop_and_remove_container "${project_name}-nginx-test"

  else
      echo "[ERROR] NGINX configuration test failed. But don't worry. this is testing just before restarting NGINX. Check settings in '.docker/nginx/origin,'"
      echo "Output:"
      echo "$output"
      stop_and_remove_container "${project_name}-nginx-test"
      exit 1
  fi

}