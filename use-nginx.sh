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
     proxy_hostname="###PROJECT_NAME###-{{ \$key_value }}_###PROJECT_NAME###-{{ \$key_value }}"
     proxy_hostname_blue="###PROJECT_NAME###-blue_###PROJECT_NAME###-blue"
   else
     proxy_hostname="###PROJECT_NAME###-{{ \$key_value }}"
     proxy_hostname_blue="###PROJECT_NAME###-blue"
   fi


    if [[ ${protocol} = 'http' ]]; then

    echo "[NOTICE] NGINX template (.docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl) is now being created."

    cat > .docker/nginx/ctmpl/http/nginx.conf.ctmpl <<EOF

server {

     listen ###EXPOSE_PORT### default_server;
     listen [::]:###EXPOSE_PORT### default_server;

     server_name localhost;

     error_page 497 http://\$host:\$server_port\$request_uri;

     client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;

     location / {
         add_header Pragma no-cache;
         add_header Cache-Control no-cache;
         {{ with \$key_value := keyOrDefault "###CONSUL_KEY###" "blue" }}
             {{ if or (eq \$key_value "blue") (eq \$key_value "green") }}
                 proxy_pass http://$proxy_hostname:###APP_PORT###;
             {{ else }}
                 proxy_pass http://$proxy_hostname_blue:###APP_PORT###;
             {{ end }}
         {{ end }}
         proxy_set_header Host \$http_host;
         proxy_set_header X-Scheme \$scheme;
         proxy_set_header X-Forwarded-Protocol \$scheme;
         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
         proxy_set_header X-Real-IP \$remote_addr;
         proxy_http_version 1.1;
         proxy_read_timeout 300s;
         proxy_connect_timeout 75s;
     }

     ###USE_NGINX_RESTRICTED_LOCATION###

     access_log /var/log/nginx/access.log;
     error_log /var/log/nginx/error.log;
}
EOF

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/http/nginx.conf.ctmpl <<EOF

server {

     listen $i default_server;
     listen [::]:$i default_server;

     server_name localhost;

     error_page 497 http://\$host:\$server_port\$request_uri;

     client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;

     location / {
         add_header Pragma no-cache;
         add_header Cache-Control no-cache;
         {{ with \$key_value := keyOrDefault "###CONSUL_KEY###" "blue" }}
             {{ if or (eq \$key_value "blue") (eq \$key_value "green") }}
                 proxy_pass http://$proxy_hostname:$i;
             {{ else }}
                 proxy_pass http://$proxy_hostname_blue:$i;
             {{ end }}
         {{ end }}
         proxy_set_header Host \$http_host;
         proxy_set_header X-Scheme \$scheme;
         proxy_set_header X-Forwarded-Protocol \$scheme;
         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
         proxy_set_header X-Real-IP \$remote_addr;
         proxy_http_version 1.1;
         proxy_read_timeout 300s;
         proxy_connect_timeout 75s;
    }

     access_log /var/log/nginx/access.log;
     error_log /var/log/nginx/error.log;
}
EOF
   done

   else

    echo "[NOTICE] NGINX template (.docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl) is now being created."

    cat > .docker/nginx/ctmpl/https/nginx.conf.ctmpl <<EOF
server {

    listen ###EXPOSE_PORT### default_server ssl;
    listen [::]:###EXPOSE_PORT### default_server ssl;

    http2 on;
    server_name localhost;

    error_page 497 https://\$host:\$server_port\$request_uri;

    client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;


    ssl_certificate /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.chained.crt;
    ssl_certificate_key /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';


    location / {
        add_header Pragma no-cache;
        add_header Cache-Control no-cache;
        {{ with \$key_value := keyOrDefault "###CONSUL_KEY###" "blue" }}
            {{ if or (eq \$key_value "blue") (eq \$key_value "green") }}
                proxy_pass $app_https_protocol://$proxy_hostname:###APP_PORT###;
            {{ else }}
                proxy_pass $app_https_protocol://$proxy_hostname_blue:###APP_PORT###;
            {{ end }}
        {{ end }}
        proxy_set_header Host \$http_host;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Protocol \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    ###USE_NGINX_RESTRICTED_LOCATION###

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/https/nginx.conf.ctmpl <<EOF

server {
    listen $i default_server ssl;
    listen [::]:$i default_server ssl;

    http2 on;

    server_name localhost;

    error_page 497 https://\$host:\$server_port\$request_uri;

    client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;


    ssl_certificate /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.chained.crt;
    ssl_certificate_key /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';

    location / {
        add_header Pragma no-cache;
        add_header Cache-Control no-cache;
        {{ with \$key_value := keyOrDefault "###CONSUL_KEY###" "blue" }}
            {{ if or (eq \$key_value "blue") (eq \$key_value "green") }}
                proxy_pass $app_https_protocol://$proxy_hostname:$i;
            {{ else }}
                proxy_pass $app_https_protocol://$proxy_hostname_blue:$i;
            {{ end }}
        {{ end }}
        proxy_set_header Host \$http_host;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Protocol \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }


    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF
   done

   fi
}

create_nginx_contingency_conf(){

   local proxy_hostname=

   if [[ ${orchestration_type} == 'stack' ]]; then
     proxy_hostname="###PROJECT_NAME###-###APP_STATE###_###PROJECT_NAME###-###APP_STATE###"
   else
     proxy_hostname="###PROJECT_NAME###-###APP_STATE###"
   fi

    local app_https_protocol="https";
    if [[ ${redirect_https_to_http} = 'true' ]]; then
       app_https_protocol="http"
    fi


    if [[ ${protocol} = 'http' ]]; then

    echo "[NOTICE] NGINX template (.docker/nginx/ctmpl/${protocol}/nginx.conf.contingency) is now being created."

    cat > .docker/nginx/ctmpl/http/nginx.conf.contingency <<EOF

server {

     listen ###EXPOSE_PORT### default_server;
     listen [::]:###EXPOSE_PORT### default_server;

     server_name localhost;

     error_page 497 http://\$host:\$server_port\$request_uri;

     client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;

     location / {
         add_header Pragma no-cache;
         add_header Cache-Control no-cache;

         proxy_pass http://$proxy_hostname:###APP_PORT###;

         proxy_set_header Host \$http_host;
         proxy_set_header X-Scheme \$scheme;
         proxy_set_header X-Forwarded-Protocol \$scheme;
         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
         proxy_set_header X-Real-IP \$remote_addr;
         proxy_http_version 1.1;
         proxy_read_timeout 300s;
         proxy_connect_timeout 75s;
     }

     ###USE_NGINX_RESTRICTED_LOCATION###

     access_log /var/log/nginx/access.log;
     error_log /var/log/nginx/error.log;
}
EOF

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/http/nginx.conf.contingency <<EOF

server {

     listen $i default_server;
     listen [::]:$i default_server;

     server_name localhost;

     error_page 497 http://\$host:\$server_port\$request_uri;

     client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;

     location / {
         add_header Pragma no-cache;
         add_header Cache-Control no-cache;

         proxy_pass http://$proxy_hostname:$i;

         proxy_set_header Host \$http_host;
         proxy_set_header X-Scheme \$scheme;
         proxy_set_header X-Forwarded-Protocol \$scheme;
         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
         proxy_set_header X-Real-IP \$remote_addr;
         proxy_http_version 1.1;
         proxy_read_timeout 300s;
         proxy_connect_timeout 75s;
    }

     access_log /var/log/nginx/access.log;
     error_log /var/log/nginx/error.log;
}
EOF
   done

   else

    echo "[NOTICE] NGINX template (.docker/nginx/contingency/${protocol}/nginx.conf.contingency) is now being created."

    cat > .docker/nginx/ctmpl/https/nginx.conf.contingency <<EOF
server {

    listen ###EXPOSE_PORT### default_server ssl;
    listen [::]:###EXPOSE_PORT### default_server ssl;

    http2 on;
    server_name localhost;

    error_page 497 https://\$host:\$server_port\$request_uri;

    client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;


    ssl_certificate /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.chained.crt;
    ssl_certificate_key /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';


    location / {
        add_header Pragma no-cache;
        add_header Cache-Control no-cache;

        proxy_pass $app_https_protocol://$proxy_hostname:###APP_PORT###;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Protocol \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    ###USE_NGINX_RESTRICTED_LOCATION###

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/https/nginx.conf.contingency <<EOF

server {
    listen $i default_server ssl;
    listen [::]:$i default_server ssl;

    http2 on;

    server_name localhost;

    error_page 497 https://\$host:\$server_port\$request_uri;

    client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;


    ssl_certificate /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.chained.crt;
    ssl_certificate_key /etc/nginx/ssl/###COMMERCIAL_SSL_NAME###.key;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';

    location / {
        add_header Pragma no-cache;
        add_header Cache-Control no-cache;

        proxy_pass $app_https_protocol://$proxy_hostname:$i;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Forwarded-Protocol \$scheme;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_http_version 1.1;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }


    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF
   done

   fi
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

      echo "[NOTICE] As !NGINX_RESTART is true, which means there will be a short-downtime for Nginx, build the ${project_name}-nginx image (using cache)."
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
