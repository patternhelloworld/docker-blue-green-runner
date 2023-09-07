#!/bin/bash
set -eu

git config apply.whitespace nowarn
git config core.filemode false


cache_all_states() {

  echo '[NOTICE] Checking which container, blue or green, is running.'

  blue_is_up=$(docker exec ${project_name}-blue echo 'yes' 2>/dev/null || echo 'no')
  if [[ ${blue_is_up} == 'yes' ]]; then
      if [[ $(check_availability_inside_container_speed_mode 'blue' 10 5 | tail -n 1) == 'true' ]]; then

        echo '[DEBUG] Checking State : A (Blue is currently running)'

        state='blue'
        new_state='green'
        new_upstream=${green_upstream}

      else

        green_is_up=$(docker exec ${project_name}-green echo 'yes' 2>/dev/null || echo 'no')
        if [[ ${green_is_up} == 'yes' ]]; then
            if [[ $(check_availability_inside_container_speed_mode 'green' 10 5 | tail -n 1) == 'true' ]]; then

              echo '[DEBUG] Checking State : B (Green is currently running)'

              state='green'
              new_state='blue'
              new_upstream=${blue_upstream}
            else

              echo '[DEBUG] Checking State : C (Blue and Green are up but both failed in the Internal Integrity Check. Whichever is OK to be deployed.)'

              state='blue'
              new_state='green'
              new_upstream=${green_upstream}

            fi
        else
              echo '[DEBUG] Checking State : D (Both failed in the Internal Integrity Check, but Blue is currently only up.)'

              state='blue'
              new_state='green'
              new_upstream=${green_upstream}
        fi

      fi
  else

      green_is_up=$(docker exec ${project_name}-green echo 'yes' 2>/dev/null || echo 'no')
      if [[ ${green_is_up} == 'yes' ]]; then
          if [[ $(check_availability_inside_container_speed_mode 'green' 10 5 | tail -n 1) == 'true' ]]; then

            echo '[DEBUG] Checking State : E (Green is currently running)'

            state='green'
            new_state='blue'
            new_upstream=${blue_upstream}
          else

            echo '[DEBUG] cache_all_states : F (Both failed in the Internal Integrity Check, but Green is currently only up.)'

            state='green'
            new_state='blue'
            new_upstream=${blue_upstream}
          fi
      else
          echo '[DEBUG] cache_all_states : G (Both failed in the Internal Integrity Check and are down. Whichever is OK to be deployed.)'

          state='green'
          new_state='blue'
          new_upstream=${blue_upstream}

      fi

  fi

  echo "[NOTICE] Finally, ! ${new_state} will be deployed."
}

set_expose_and_app_port(){

  if [[ -z ${1} ]]
    then
      echo "[ERROR] The 'project_port' has not been passed. Terminate the entire process to prevent potential errors." && exit 1
  fi

  if echo "${1}" | grep -Eq '^\[[0-9]+,[0-9]+\]$'; then
      expose_port=$(echo "$project_port" | yq e '.[0]' -)
      app_port=$(echo "$project_port" | yq e '.[1]' -)
  else
      expose_port="$project_port"
      app_port="$project_port"
  fi
}

cache_non_dependent_global_vars() {

  check_necessary_commands

  HOST_IP=$(get_value_from_env "HOST_IP")

  host_root_location=$(get_value_from_env "HOST_ROOT_LOCATION")
  docker_file_location=$(get_value_from_env "DOCKER_FILE_LOCATION")

  project_name=$(get_value_from_env "PROJECT_NAME")
  project_location=$(get_value_from_env "PROJECT_LOCATION")
  project_port=$(echo "$(get_value_from_env "PROJECT_PORT")" | tr -d '[:space:]')
  if ! echo "$project_port" | grep -Eq '^\[[0-9]+,[0-9]+\]$|^[0-9]+$'; then
    echo "[ERROR] project_port on .env is a wrong type. (ex. [30000,3000] or 8888 formats are available)" && exit 1
  fi

  app_url=$(get_value_from_env "APP_URL")
  protocol=$(echo ${app_url} | awk -F[/:] '{print $1}')
  port_extracted_from_app_url=$(echo "$app_url" | awk -F':' '{print $NF}')

  set_expose_and_app_port ${project_port}
  echo "[DEBUG] app_port : ${app_port}, expose_port : ${expose_port}"

  if [ "$port_extracted_from_app_url" != "$expose_port" ]; then
     echo "[ERROR] The extracted port ($port_extracted_from_app_url) for APP_URL and PROJECT_PORT ($expose_port) must be the same." && exit 1
  fi

  additional_ports=(`echo $(get_value_from_env "ADDITIONAL_PORTS") | cut -d ","  --output-delimiter=" " -f 1-`)
  echo "[DEBUG] ADDITIONAL_PORTS : ${additional_ports[@]}"

  docker_compose_environment=$(get_value_from_env "DOCKER_COMPOSE_ENVIRONMENT")
  docker_build_args=$(get_value_from_env "DOCKER_BUILD_ARGS")

  consul_key_value_store=$(get_value_from_env "CONSUL_KEY_VALUE_STORE")

  app_health_check_path=$(get_value_from_env "APP_HEALTH_CHECK_PATH")
  bad_app_health_check_pattern=$(get_value_from_env "BAD_APP_HEALTH_CHECK_PATTERN")
  good_app_health_check_pattern=$(get_value_from_env "GOOD_APP_HEALTH_CHECK_PATTERN")

  app_env=$(get_value_from_env "APP_ENV")
  if [[ ! (${app_env} == 'real' || ${app_env} == 'local') ]]; then
     echo "[ERROR] app_env is only local or real." && exit 1
  fi

  docker_file_name="Dockerfile.${app_env}"

  if [ -f "${docker_file_location}/${docker_file_name}" ]; then
      docker_file_name="Dockerfile.${app_env}"
  else
      if [ -f "${docker_file_location}/Dockerfile" ]; then
        docker_file_name="Dockerfile"
      else
         echo "[ERROR] Couldn't find any of 'Dockerfile.${app_env} and Dockerfile' in ${docker_file_location}" && exit 1
      fi
  fi

  if [[ ${app_env} == 'real' ]]; then
    docker_compose_real_selective_volumes=$(get_value_from_env "DOCKER_COMPOSE_REAL_SELECTIVE_VOLUMES")
  fi

  docker_compose_nginx_selective_volumes=$(get_value_from_env "DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES")

  docker_layer_corruption_recovery=$(get_value_from_env "DOCKER_LAYER_CORRUPTION_RECOVERY")


  if [[ ${protocol} = 'https' ]]; then
    use_commercial_ssl=$(get_value_from_env "USE_COMMERCIAL_SSL")
    commercial_ssl_name=$(get_value_from_env "COMMERCIAL_SSL_NAME")
  fi

  nginx_restart=$(get_value_from_env "NGINX_RESTART")
  consul_restart=$(get_value_from_env "CONSUL_RESTART")

  use_my_own_app_yml=$(get_value_from_env "USE_MY_OWN_APP_YML")
}

cache_global_vars() {
  
  cache_non_dependent_global_vars

  host_root_uid=$(id -u)
  host_root_gid=$(id -g)

  CUR_TIME=$(date +%s)

  if [[ ${protocol} = 'https' ]]; then
    blue_upstream=$(concat_safe_port "https://${project_name}-blue")
    green_upstream=$(concat_safe_port "https://${project_name}-green")
  else
    blue_upstream=$(concat_safe_port "http://${project_name}-blue")
    green_upstream=$(concat_safe_port "http://${project_name}-green")
  fi

  cache_all_states


  # In real env, for Jenkins & customer servers
  git_image_load_from=$(get_value_from_env "GIT_IMAGE_LOAD_FROM")
  git_image_load_from_hostname=$(get_value_from_env "GIT_IMAGE_LOAD_FROM_HOSTNAME")
  git_image_load_from_pathname=$(get_value_from_env "GIT_IMAGE_LOAD_FROM_PATHNAME")
  docker_image_env_concatenate=":"
  if [[ ${git_image_load_from} == 'registry' ]] && [[ ! -z ${git_image_load_from_hostname} ]] && [[ ! -z ${git_image_load_from_pathname} ]]; then
    load_from_registry_image_with_env="${git_image_load_from_hostname}:5050/$(echo ${git_image_load_from_pathname} | awk '{ print tolower($0); }')${docker_image_env_concatenate}${app_env}"
  fi
  git_token_image_load_from_username=$(get_value_from_env "GIT_TOKEN_IMAGE_LOAD_FROM_USERNAME")
  git_token_image_load_from_password=$(get_value_from_env "GIT_TOKEN_IMAGE_LOAD_FROM_PASSWORD")

  # sync_app_version_real

}

check_yq_installed(){
    command -v yq >/dev/null 2>&1 ||
    { echo >&2 "[ERROR] yq is NOT installed. Proceed with it.";

      sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
      sudo chmod a+x /usr/local/bin/yq
    }
}

initiate_docker_compose(){

    if [[ ${use_my_own_app_yml} == true ]]; then
      cp -f docker-compose-${project_name}-${app_env}-original-ready.yml docker-compose-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to copy docker-compose-${project_name}-${app_env}-original-ready.yml" && exit 1)
      echo "[DEBUG] successfully copied docker-compose-${project_name}-${app_env}-original-ready.yml"
      echo "[NOTICE] As USE_MY_OWN_APP_YML is set 'true', we will use your customized 'docker-compose-${project_name}-${app_env}-original-ready.yml'"
    else
      cp -f docker-compose-app-${app_env}-original.yml docker-compose-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to copy docker-compose-app-${app_env}-original.yml" && exit 1)
      echo "[DEBUG] successfully copied docker-compose-app-${app_env}-original.yml"
    fi
    cp -f docker-compose-app-nginx-original.yml docker-compose-${project_name}-nginx.yml || (echo "[ERROR] Failed to copy docker-compose-app-nginx-original.yml" && exit 1)
    echo "[DEBUG] successfully copied docker-compose-app-nginx-original.yml"

    sleep 1
}

apply_env_service_name_onto_app_yaml(){

  check_yq_installed

  echo "[NOTICE] PROJECT_NAME on .env is now being applied to docker-compose-${project_name}-${app_env}.yml."
  yq -i "with(.services; with_entries(select(.key ==\"*-blue\") | .key |= \"${project_name}-blue\"))" docker-compose-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to apply the blue service name in the app YAML as ${project_name}." && exit 1)
  sleep 2
  yq -i "with(.services; with_entries(select(.key ==\"*-green\") | .key |= \"${project_name}-green\"))" docker-compose-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to apply the green service name in the app YAML as ${project_name}." && exit 1)

  yq -i "with(.services; with_entries(select(.key ==\"*-nginx\") | .key |= \"${project_name}-nginx\"))" docker-compose-${project_name}-nginx.yml || (echo "[ERROR] Failed to apply the service name in the Nginx YAML as ${project_name}." && exit 1)
}

apply_ports_onto_nginx_yaml(){

   check_yq_installed

   echo "[NOTICE] PORTS on .env is now being applied to docker-compose-${project_name}-nginx.yml."
   yq -i '.services.'${project_name}'-nginx.ports = []' docker-compose-${project_name}-nginx.yml
   yq -i '.services.'${project_name}'-nginx.ports += "'${expose_port}':'${expose_port}'"' docker-compose-${project_name}-nginx.yml

   for i in "${additional_ports[@]}"
   do
      [ -z "${i##*[!0-9]*}" ] && (echo "[ERROR] Wrong port number on .env : ${i}" && exit 1);
      yq -i '.services.'${project_name}'-nginx.ports += "'$i:$i'"' docker-compose-${project_name}-nginx.yml
   done
}

apply_docker_compose_environment_onto_app_yaml(){

   check_yq_installed

   echo "[NOTICE] DOCKER_COMPOSE_ENVIRONMENT on .env is now being applied to docker-compose-${project_name}-${app_env}.yml."

   local states=("blue" "green")

   for state in "${states[@]}"
   do
       yq -i '.services.'${project_name}'-'${state}'.environment = []' docker-compose-${project_name}-${app_env}.yml
       yq -i '.services.'${project_name}'-'${state}'.environment += "SERVICE_NAME='${state}'"' docker-compose-${project_name}-${app_env}.yml

       for ((i=1; i<=$(echo ${docker_compose_environment} | yq eval 'length'); i++))
        do
           yq -i '.services.'${project_name}'-'${state}'.environment += "'$(echo ${docker_compose_environment} | yq -r 'to_entries | .['$((i-1))'].key')'='$(echo ${docker_compose_environment} | yq -r 'to_entries | .['$((i-1))'].value')'"' docker-compose-${project_name}-${app_env}.yml
        done
   done

}

apply_docker_compose_volumes_onto_app_real_yaml(){

   check_yq_installed

   echo "[NOTICE] DOCKER_COMPOSE_REAL_SELECTIVE_VOLUMES on .env is now being applied to docker-compose-${project_name}-real.yml."

   local states=("blue" "green")

   for state in "${states[@]}"
   do
       #yq -i '.services.'${project_name}'-'${state}'.volumes = []' ./docker-compose-${project_name}-real.yml

      for volume in "${docker_compose_real_selective_volumes[@]}"
      do
          yq -i '.services.'${project_name}'-'${state}'.volumes += '${volume}'' ./docker-compose-${project_name}-real.yml
      done
   done

}

apply_docker_compose_volumes_onto_app_nginx_yaml(){

   check_yq_installed

   echo "[NOTICE] DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES on .env is now being applied to docker-compose-${project_name}-nginx.yml."

    for volume in "${docker_compose_nginx_selective_volumes[@]}"
    do
        yq -i '.services.'${project_name}'-'nginx'.volumes += '${volume}'' ./docker-compose-${project_name}-nginx.yml
    done

}



make_docker_build_arg_strings(){

   check_yq_installed

   echo "[NOTICE] make_docker_build_arg_strings for the 'docker build command'." >&2

   local re=""

   for ((i=1; i<=$(echo ${docker_build_args} | yq eval 'length'); i++))
   do
       re="${re} --build-arg $(echo ${docker_build_args} | yq -r 'to_entries | .['$((i-1))'].key')=$(echo ${docker_build_args} | yq -r 'to_entries | .['$((i-1))'].value')"
   done

   echo ${re}
   return
}

create_nginx_ctmpl(){

    if [[ ${protocol} = 'http' ]]; then

    echo "[NOTICE] NGINX template (.docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl) is not being created."

    cat > .docker/nginx/ctmpl/http/nginx.conf.ctmpl <<EOF
server {
     listen ###EXPOSE_PORT### default_server;
     server_name localhost;

     client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;

     location / {
         add_header Pragma no-cache;
         add_header Cache-Control no-cache;
         {{ with \$key_value := keyOrDefault "###CONSUL_KEY###" "blue" }}
             {{ if or (eq \$key_value "blue") (eq \$key_value "green") }}
                 proxy_pass http://###PROJECT_NAME###-{{ \$key_value }}:###APP_PORT###;
             {{ else }}
                 proxy_pass http://###PROJECT_NAME###-blue:###APP_PORT###;
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

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/http/nginx.conf.ctmpl <<EOF

server {
     listen $i default_server;
     server_name localhost;

     client_max_body_size ###NGINX_CLIENT_MAX_BODY_SIZE###;

     location / {
         add_header Pragma no-cache;
         add_header Cache-Control no-cache;
         {{ with \$key_value := keyOrDefault "###CONSUL_KEY###" "blue" }}
             {{ if or (eq \$key_value "blue") (eq \$key_value "green") }}
                 proxy_pass http://###PROJECT_NAME###-{{ \$key_value }}:$i;
             {{ else }}
                 proxy_pass http://###PROJECT_NAME###-blue:$i;
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

    listen ###EXPOSE_PORT### default_server ssl http2;
    server_name localhost;

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
                proxy_pass https://###PROJECT_NAME###-{{ \$key_value }}:###APP_PORT###;
            {{ else }}
                proxy_pass https://###PROJECT_NAME###-blue:###APP_PORT###;
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

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/https/nginx.conf.ctmpl <<EOF

server {
    listen $i default_server ssl http2;
    server_name localhost;

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
                proxy_pass https://###PROJECT_NAME###-{{ \$key_value }}:$i;
            {{ else }}
                proxy_pass https://###PROJECT_NAME###-blue:$i;
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

get_value_from_env(){

  if [ ! -f ".env" ]; then
      echo "[ERROR] .env file NOT found." >&2 && exit 1
  fi
  value=''
  re='^[[:space:]]*('${1}'[[:space:]]*=[[:space:]]*)(.+)[[:space:]]*$'

  while IFS= read -r line; do
     if [[ $line =~ $re ]]; then                       # match regex
        #declare -p BASH_REMATCH
        value=${BASH_REMATCH[2]}
     fi
                                      # print each line
  done < <(grep "" .env)  # To read the last line

  value=$(echo $value | sed -e 's/\r//g')

  if [[ -z ${value} ]]; then
    echo "[ERROR] ${1} NOT found on .env." >&2 && exit 1
  fi

  echo ${value} # return.
}

compare_two_envs(){
  original_keys=()
  standard_keys=()

  while IFS= read -r line1; do

          [[ "$line1" =~ ^[[:space:]]*# ]] && continue

          key=$(echo $line1 | sed -E 's/^([^=]+)=.*/\1/')
          original_keys+=(${key})
  done < <(grep "" "$1")

  while IFS= read -r line2; do

          [[ "$line2" =~ ^[[:space:]]*# ]] && continue

          key2=$(echo $line2 | sed -E 's/^([^=]+)=.*/\1/')
          standard_keys+=(${key2})
  done < <(grep "" "$2")

  #echo ${original_keys[@]}
  echo ${original_keys[@]} ${standard_keys[@]} | tr ' ' '\n' | sort | uniq -u

}

check_empty_env_values(){

  empty_keys=()

  while IFS= read -r line; do

      [[ "$line" =~ ^[[:space:]]*# ]] && continue

      key=$(echo $line | sed -E 's/^([^=]+)=.*/\1/')
      value=$(echo $line | sed -E 's/^[^=]+=(.*)/\1/')

      value="$(echo -e "${value}" | sed -e 's/^[[:space:]]*|[[:space:]]*$//')"

      if [[ ${value} == '' && ${key} != "CONTAINER_SSL_VOLUME_PATH" && ${key} != "ADDITIONAL_PORTS" ]]; then
         empty_keys+=(${key})
      fi

  done < <(grep "" "$1")

  echo ${empty_keys[@]}

}

check_env_integrity(){

    diff=$(compare_two_envs .env .env.example.${app_env})
    if [[ ${diff} != "" ]]; then
      echo "[ERROR] The key values in the .env file do not match with .env.example.${app_env}, so the process cannot continue. Please update the .env file to match the requirements (Difference: ${diff})."
      exit 1
    fi

    empty_values=$(check_empty_env_values .env)
    if [[ ${empty_values} != "" ]]; then
      echo "[ERROR] The following values in the .env file are empty, so the process cannot proceed (Difference: ${empty_values})"
      exit 1
    fi
}

concat_safe_port() {
 if [[ -z ${app_port} || ${app_port} == '80' || ${app_port} == '443' ]]; then
    echo "${1}"
 else
    echo "${1}:${app_port}"
 fi
}


integer_hash_text(){
  echo $((0x$(sha1sum <<<"$1"|cut -c1-2)))
}

docker_login_with_params() {

  echo "[NOTICE] Login with the following account on to Gitlab Docker Registry. ( username : ${1}, password : $(integer_hash_text ${2}) (displayed encoded.) )"
  echo ${2} | docker login --username ${1} --password-stdin ${3}:5050 || (echo "[ERROR] Docker Registry Login failed to ${3}." && exit 1)

}

check_necessary_commands(){

  command -v git >/dev/null 2>&1 ||
  { echo >&2 "[ERROR] git NOT installed. Exiting...";
    exit 1
  }

  if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] docker is NOT installed. Exiting..."
    exit 1
  fi

  if ! docker-compose --version > /dev/null 2>&1; then
      echo "[ERROR] docker-compose is NOT installed. Exiting..."
      exit 1
  fi
}

sync_app_version_real() {
  if [[ ${app_env} == 'real' ]]; then
    app_version=$(cat appVersion.txt) || app_version=
    if [[ -z $app_version ]]; then
      app_version=$(git describe --exact-match --tags) || app_version=
    fi
    if [[ -z $app_version ]]; then
       echo "[ERROR] app_version NOT confirmed" && exit 1
    else
       sh -c "echo '${app_version}' > appVersion.txt"
    fi
  fi
}

check_command_in_container_or_fail(){
  # 컨테이너 이름 또는 ID
  CONTAINER_NAME=${1}

  # 확인하고 싶은 명령어
  COMMAND_TO_CHECK=${2}

  # 명령어 존재 여부 확인
  if docker exec $CONTAINER_NAME bash -c "command -v $COMMAND_TO_CHECK" &> /dev/null; then
      echo "[NOTICE] $COMMAND_TO_CHECK exists in $CONTAINER_NAME" >&2
     echo "true"
     return
  else
      echo "[ERROR] $COMMAND_TO_CHECK does not exist in $CONTAINER_NAME" >&2
      echo "false"
      return
  fi
}



# shellcheck disable=SC2120
check_availability_inside_container(){

  check_state=${1}

  if [[ -z ${check_state} ]]
    then
      echo "[ERROR] the 'state' NOT indicated on check_availability_inside_container "  >&2
      echo "false"
      return
  fi

  if [[ -z ${2} ]]
    then
      echo "[ERROR] there is no wait-for-it.sh timeout parameter."  >&2
      echo "false"
      return
  fi

  if [[ -z ${3} ]]
    then
      echo "[ERROR] there is no Health Check timeout parameter."  >&2
      echo "false"
      return
  fi



   if [[ $(check_command_in_container_or_fail ${project_name}-${check_state} "curl") != "true" ]]; then
         echo "false"
         return
   fi
    if [[ $(check_command_in_container_or_fail ${project_name}-${check_state} "bash") != "true" ]]; then
          echo "false"
          return
    fi

  
  echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] Copy wait-for-it.sh into ${project_name}-${check_state}:${project_location}/wait-for-it.sh."  >&2
  docker cp ./wait-for-it.sh ${project_name}-${check_state}:${project_location}/wait-for-it.sh || (echo "[ERROR] Failed in copying (HOST : ./wait-for-it.sh) to (CONTAINER : ${project_location}/wait-for-it.sh)" >&2 &&  echo "false" && return)



  echo "[NOTICE] ${project_name}-${check_state} Check if the web server is responding by making a request inside the node-express-boilerplate-green container. If library folders such as node_modules (Node.js), vendor (PHP) folders are NOT yet installed, the execution time of the ENTRYSCRIPT of your Dockerfile may be longer than usual (timeout: ${2} seconds)"  >&2
  sleep 10

  # 1) APP is ON

  container_load_timeout=${2}

  echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] In the ${project_name}-${check_state}  Container, conduct the Connection Check (localhost:${app_port} --timeout=${2}). (If this is delayed, run ' docker logs -f ${project_name}-${check_state} ' to check the status."   >&2
  echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] Current status (inside Container) : \n $(docker logs ${project_name}-${check_state})"   >&2
  local wait_for_it_re=$(docker exec -w ${project_location} ${project_name}-${check_state} ./wait-for-it.sh localhost:${app_port} --timeout=${2}) || (echo "[ERROR] Failed in running (CONTAINER : ${project_location}/wait-for-it.sh)" >&2 &&  echo "false" && return)
  if [[ $? != 0 ]]; then
      echo "[ERROR] Failed in getting the correct return from wait-for-it.sh. (${wait_for_it_re})" >&2
      echo "false"
      return
  else
      # 2) APP's health check
      echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] In the ${project_name}-${check_state}  Container, conduct the Health Check."  >&2
      sleep 1

      local interval_sec=5

      local total_cnt=$((${container_load_timeout}/${interval_sec}))

      if [[ $((container_load_timeout%interval_sec)) != 0 ]]; then
        total_cnt=$((${total_cnt}+1))
      fi

      for (( retry_count = 1; retry_count <= ${total_cnt}; retry_count++ ))
      do
        echo "[NOTICE] ${retry_count} round health check (curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path})... (timeout : ${3} sec)"  >&2
        response=$(docker exec ${project_name}-${check_state} sh -c "curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path} --connect-timeout ${3}")

        down_count=$(echo ${response} | egrep -i ${bad_app_health_check_pattern} | wc -l)
        up_count=$(echo ${response} | egrep -i ${good_app_health_check_pattern} | wc -l)

        if [[ ${down_count} -ge 1 || ${up_count} -lt 1 ]]
        then

            echo "[WARNING] Unable to determine the response of the health check or the status is not UP. (*Response : ${response}), (${project_name}-${check_state}, *Log (print max 25 lines) : $(docker logs --tail 25 ${project_name}-${check_state})"  >&2

        else
             echo "[NOTICE] Internal health check of the application succeeded. (*Response: ${response})"  >&2
             break
        fi

        if [[ ${retry_count} -eq ${total_cnt} ]]
        then
          echo "[FAILURE] Health check failed in the end. (*Response:  ${response})" >&2
          echo "false"
          return
        fi

        echo "[NOTICE] ${retry_count}/${total_cnt} round Health Check failure. Retrying in ${interval_sec} secs..."  >&2
        for (( i = 1; i <= ${interval_sec}; i++ ));do echo -n "$i." >&2 && sleep 1; done
        echo "\n"  >&2

      done

     echo "true"
     return
 fi
}


check_availability_inside_container_speed_mode(){

  if [[ -z ${1} ]]
    then
      echo "[ERROR] [Blue OR Green Alive Check : Currently ${check_state}] the 'state' NOT indicated on check_availability_inside_container "  >&2
      echo "false"
      return
  fi

  if [[ -z ${2} ]]
    then
      echo "[ERROR] [Blue OR Green Alive Check : Currently ${check_state}] there is no wait-for-it.sh timeout parameter."  >&2
      echo "false"
      return
  fi

  if [[ -z ${3} ]]
    then
      echo "[ERROR] [Blue OR Green Alive Check : Currently ${check_state}] there is no Health Check timeout parameter."  >&2
      echo "false"
      return
  fi

  check_state=${1}

  echo "[NOTICE] [Blue OR Green Alive Check : Currently checking ${check_state}] Copy wait-for-it.sh into ${project_name}-${check_state}:${project_location}/wait-for-it.sh."  >&2
  docker cp ./wait-for-it.sh ${project_name}-${check_state}:${project_location}/wait-for-it.sh


  #echo "[NOTICE] ${project_name}-${check_state} Check if the web server is responding by making a request inside the node-express-boilerplate-green container. If library folders such as node_modules (Node.js), vendor (PHP) folders are NOT yet installed, the execution time of the ENTRYSCRIPT of your Dockerfile may be longer than usual (timeout: ${2} seconds)"  >&2
  #sleep 3

  # 1) APP is ON

  container_load_timeout=${2}

  echo "[NOTICE] [Blue OR Green Alive Check : Currently checking ${check_state}] In the ${project_name}-${check_state}  Container, conduct the Connection Check (localhost:${app_port} --timeout=${2}). (If this is delayed, run ' docker logs -f ${project_name}-${check_state} ' to check the status."   >&2
  echo "[NOTICE] [Blue OR Green Alive Check : Currently checking ${check_state}] Current status (inside Container) : \n $(docker logs ${project_name}-${check_state})"   >&2
  local wait_for_it_re=$(docker exec -w ${project_location} ${project_name}-${check_state} ./wait-for-it.sh localhost:${app_port} --timeout=${2}) || echo "[WARNING] Failed in Connection Check (running wait_for_it.sh). But, this function is for checking which container is running. we don't exit."   >&2
  if [[ $? != 0 ]]; then
      #echo "[ERROR] Failure in wait-for-it.sh. (${wait_for_it_re})" >&2
      echo "false"
      return
  else
      # 2) APP's health check
      echo "[NOTICE] [Blue OR Green Alive Check : Currently ${check_state}] In the ${project_name}-${check_state}  Container, conduct the Health Check."  >&2
      sleep 1

      local interval_sec=5

      local total_cnt=$((${container_load_timeout}/${interval_sec}))

      if [[ $((container_load_timeout%interval_sec)) != 0 ]]; then
        total_cnt=$((${total_cnt}+1))
      fi

      for (( retry_count = 1; retry_count <= ${total_cnt}; retry_count++ ))
      do
        echo "[NOTICE] [Blue OR Green Alive Check : Currently ${check_state}] ${retry_count} round health check (curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path})... (timeout : ${3} sec)"  >&2
        response=$(docker exec ${project_name}-${check_state} sh -c "curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path} --connect-timeout ${3}") || echo "[WARNING] [Blue OR Green Alive Check : Currently ${check_state}] Failed in Health Check. But, this function is for checking which container is running. we don't exit."   >&2

        down_count=$(echo ${response} | egrep -i ${bad_app_health_check_pattern} | wc -l)
        up_count=$(echo ${response} | egrep -i ${good_app_health_check_pattern} | wc -l)

        if [[ ${down_count} -ge 1 || ${up_count} -lt 1 ]]
        then

            echo ""  >&2

        else
             echo ""  >&2
             break
        fi

        if [[ ${retry_count} -eq ${total_cnt} ]]
        then
          echo "false"
          return
        fi

        #echo "[NOTICE] ${retry_count}/${total_cnt} round Health Check failure. Retrying in ${interval_sec} secs..."  >&2
        for (( i = 1; i <= ${interval_sec}; i++ ));do echo -n "$i." >&2 && sleep 1; done
        echo "\n"  >&2

      done

     echo "true"
     return
 fi
}
