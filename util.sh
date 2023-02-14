#!/bin/bash
set -eu

# 리눅스 - 윈도우 개발 환경 충돌 방지
git config apply.whitespace nowarn
git config core.filemode false


cache_all_states() {

  echo '[NOTICE] blue, green 중 어떤 컨테이너가 띄어져 있는 지 확인 합니다.'

  blue_is_run=$(docker exec ${project_name}-blue echo 'yes' 2>/dev/null || echo 'no')
  green_is_run=$(docker exec ${project_name}-green echo 'yes' 2>/dev/null || echo 'no')

  state='blue'
  new_state='green'
  new_upstream=${green_upstream}
  if [[ ${blue_is_run} != 'yes' ]]; then
    if [[ ${green_is_run} != 'yes' ]]; then
      echo "[WARNING] 현재 blue, green 어느 컨테이너도 띄어져 있지 않습니다. blue 로 배포 하겠습니다."
    fi
    state='green'
    new_state='blue'
    new_upstream=${blue_upstream}
  fi

  echo "[NOTICE] ${new_state} (${new_upstream}) 컨테이너를 띄울 예정 입니다. "
}

cache_global_vars() {

  host_root_location=$(get_value_from_env "HOST_ROOT_LOCATION")
  docker_file_location=$(get_value_from_env "DOCKER_FILE_LOCATION")

  project_name=$(get_value_from_env "PROJECT_NAME")
  project_location=$(get_value_from_env "PROJECT_LOCATION")
  project_port=$(get_value_from_env "PROJECT_PORT")
  additional_ports=(`echo $(get_value_from_env "ADDITIONAL_PORTS") | cut -d ","  --output-delimiter=" " -f 1-`)
  echo "[DEBUG] ADDITIONAL_PORTS : ${additional_ports[@]}"

  consul_key_value_store=$(get_value_from_env "CONSUL_KEY_VALUE_STORE")

  app_health_check_path=$(get_value_from_env "APP_HEALTH_CHECK_PATH")
  bad_app_health_check_pattern=$(get_value_from_env "BAD_APP_HEALTH_CHECK_PATTERN")
  good_app_health_check_pattern=$(get_value_from_env "GOOD_APP_HEALTH_CHECK_PATTERN")

  app_env=$(get_value_from_env "APP_ENV")
  if [[ ! (${app_env} == 'real' || ${app_env} == 'local') ]]; then
     echo "[ERROR] app_env 는 local 또는 real 값만 유효합니다." && exit 1
  fi

  if [[ ${app_env} == 'real' ]]; then
    host_shared_path=$(get_value_from_env "HOST_SHARED_PATH")
    host_system_log_path=$(get_value_from_env "HOST_SYSTEM_LOG_PATH")
    host_error_log_path=$(get_value_from_env "HOST_ERROR_LOG_PATH")
  fi

  docker_layer_corruption_recovery=$(get_value_from_env "DOCKER_LAYER_CORRUPTION_RECOVERY")
  app_url=$(get_value_from_env "APP_URL")
  protocol=$(echo ${app_url} | awk -F[/:] '{print $1}')

  if [[ ${protocol} = 'https' ]]; then
    use_commercial_ssl=$(get_value_from_env "USE_COMMERCIAL_SSL")
    commercial_ssl_name=$(get_value_from_env "COMMERCIAL_SSL_NAME")
    container_ssl_volume_path=$(get_value_from_env "CONTAINER_SSL_VOLUME_PATH")
  fi

  nginx_restart=$(get_value_from_env "NGINX_RESTART")
  consul_restart=$(get_value_from_env "CONSUL_RESTART")

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


  # 주로 real (Jenkins & 고객사 서버)에서 사용
  git_image_load_from=$(get_value_from_env "GIT_IMAGE_LOAD_FROM")
  git_image_load_from_hostname=$(get_value_from_env "GIT_IMAGE_LOAD_FROM_HOSTNAME")
  git_image_load_from_pathname=$(get_value_from_env "GIT_IMAGE_LOAD_FROM_PATHNAME")
  docker_image_env_concatenate=":"
  if [[ ${git_image_load_from} == 'registry' ]] && [[ ! -z ${git_image_load_from_hostname} ]] && [[ ! -z ${git_image_load_from_pathname} ]]; then
    load_from_registry_image_with_env="${git_image_load_from_hostname}:5050/$(echo ${git_image_load_from_pathname} | awk '{ print tolower($0); }')${docker_image_env_concatenate}${app_env}"
  fi
  git_token_image_load_from_username=$(get_value_from_env "GIT_TOKEN_IMAGE_LOAD_FROM_USERNAME")
  git_token_image_load_from_password=$(get_value_from_env "GIT_TOKEN_IMAGE_LOAD_FROM_PASSWORD")

  sync_app_version_real

}

apply_env_service_name_onto_app_yaml(){
  command -v yq >/dev/null 2>&1 ||
  { echo >&2 "[ERROR] yq가 설치되어 있지 않습니다. 설치를 진행합니다.";

    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod a+x /usr/local/bin/yq
  }
  echo "[NOTICE] docker-compose-app-${app_env}.yml 의 service 명에 .env 의 PROJECT_NAME 을 적용 합니다."
  yq -i "with(.services; with_entries(select(.key ==\"*-blue\") | .key |= \"${project_name}-blue\"))" docker-compose-app-${app_env}.yml || (echo "[ERROR] app yaml 의 blue service 명을 ${project_name} 으로 적용 하는데 실패 하였습니다." && exit 1)
  sleep 2
  yq -i "with(.services; with_entries(select(.key ==\"*-green\") | .key |= \"${project_name}-green\"))" docker-compose-app-${app_env}.yml || (echo "[ERROR] app yaml 의 green service 명을 ${project_name} 으로 적용 하는데 실패 하였습니다." && exit 1)

  yq -i "with(.services; with_entries(select(.key ==\"*-nginx\") | .key |= \"${project_name}-nginx\"))" docker-compose-nginx.yml || (echo "[ERROR] nginx yaml 의 service 명을 ${project_name} 으로 적용 하는데 실패 하였습니다." && exit 1)
}


apply_ports_onto_nginx_yaml(){
   echo "[NOTICE] docker-compose-nginx.yml 에 .env 의 PORTS 를 적용 합니다."
   yq -i '.services.rpa-bpo-dashboard-nginx.ports = []' docker-compose-nginx.yml
   yq -i '.services.rpa-bpo-dashboard-nginx.ports += "${PROJECT_PORT}:${PROJECT_PORT}"' docker-compose-nginx.yml

   for i in "${additional_ports[@]}"
   do
      [ -z "${i##*[!0-9]*}" ] && (echo "[ERROR] .env 의 잘못 된 Port Number 발견 : ${i}" && exit 1);
      yq -i '.services.rpa-bpo-dashboard-nginx.ports += "'$i:$i'"' docker-compose-nginx.yml
   done
}

create_nginx_ctmpl(){

    if [[ ${protocol} = 'http' ]]; then

    echo "[NOTICE] NGINX 탬플릿 (.docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl) 을 생성합니다."

    cat > .docker/nginx/ctmpl/http/nginx.conf.ctmpl <<EOF
server {
     listen ###PROJECT_PORT### default_server;
     server_name localhost;

     client_max_body_size 50M;

     location / {
         add_header Pragma no-cache;
         add_header Cache-Control no-cache;
         {{ with \$key_value := keyOrDefault "###CONSUL_KEY###" "blue" }}
             {{ if or (eq \$key_value "blue") (eq \$key_value "green") }}
                 proxy_pass http://###PROJECT_NAME###-{{ \$key_value }}:###PROJECT_PORT###;
             {{ else }}
                 proxy_pass http://###PROJECT_NAME###-blue:###PROJECT_PORT###;
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


     access_log /var/log/access.log;
     error_log /var/log/error.log;
}
EOF

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/http/nginx.conf.ctmpl <<EOF

server {
     listen $i default_server;
     server_name localhost;

     client_max_body_size 50M;

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

     access_log /var/log/access.log;
     error_log /var/log/error.log;
}
EOF
   done

   else

    echo "[NOTICE] NGINX 탬플릿 (.docker/nginx/ctmpl/${protocol}/nginx.conf.ctmpl) 을 생성합니다."

    cat > .docker/nginx/ctmpl/https/nginx.conf.ctmpl <<EOF
server {

    if (\$http_host != "###APP_HOST###") {
        return 301 ###APP_URL###\$request_uri;
    }

    listen ###PROJECT_PORT### default_server ssl http2;
    server_name localhost;

    client_max_body_size 50M;

    ssl on;
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
                proxy_pass https://###PROJECT_NAME###-{{ \$key_value }}:###PROJECT_PORT###;
            {{ else }}
                proxy_pass https://###PROJECT_NAME###-blue:###PROJECT_PORT###;
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


    access_log /var/log/access.log;
    error_log /var/log/error.log;
}
EOF

   for i in "${additional_ports[@]}"
   do
        cat >> .docker/nginx/ctmpl/https/nginx.conf.ctmpl <<EOF

server {
    listen $i default_server ssl http2;
    server_name localhost;

    client_max_body_size 50M;

    ssl on;
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


    access_log /var/log/access.log;
    error_log /var/log/error.log;
}
EOF
   done



   fi

}

get_value_from_env(){
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
    echo "[ERROR] .env 에서 ${1}에 해당하는 값을 찾을 수 없습니다." >&2 && exit 1
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
    # .env 유효성 검사
    # .env 파일이 .env.example.${app_env} 와 같은 key 값들을 가지고 있는 지 확인
    diff=$(compare_two_envs .env .env.example.${app_env})
    if [[ ${diff} != "" ]]; then
      echo "[ERROR] .env 파일의 key 값들이 .env.example.${app_env} 과 일치하지 않으므로 진행이 불가합니다. .env 파일을 기준에 맞게 수정하십시오. (차이 : ${diff})"
      exit 1
    fi
    # 비어 있는 value 값들을 확인
    empty_values=$(check_empty_env_values .env)
    if [[ ${empty_values} != "" ]]; then
      echo "[ERROR] .env 파일의 다음 값들이 비어 있어서 진행이 불가 합니다. (차이 : ${empty_values})"
      exit 1
    fi
}

concat_safe_port() {
 if [[ -z ${project_port} || ${project_port} == '80' || ${project_port} == '443' ]]; then
    echo "${1}"
 else
    echo "${1}:${project_port}"
 fi
}


integer_hash_text(){
  echo $((0x$(sha1sum <<<"$1"|cut -c1-2)))
}

docker_login_with_params() {

  echo "[NOTICE] 다음 계정 정보로 Gitlab 의 Docker Registry 로그인을 진행 합니다. ( username : ${1}, password : $(integer_hash_text ${2}) (암호화하여 보여집니다.) )"
  echo ${2} | docker login --username ${1} --password-stdin ${3}:5050 || (echo "[ERROR] Gitlab 의  ${3} 로의 Docker Registry 로그인에 실패 하였습니다. 상기 오류 메시지를 확인해주세요." && exit 1)

}

check_necessary_commands(){
  command -v git >/dev/null 2>&1 ||
  { echo >&2 "[ERROR] git 이 설치되어 있지 않습니다. 종료 합니다.";
    exit 1
  }

  if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] docker 가 실행 중이지 않습니다. 종료 합니다."
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
       echo "[ERROR] app_version 이 확인되지 않습니다." && exit 1
    else
       # HealthCheckController@showAppVersion 을 확인해 보면 appVersion 을 확인하는 두 가지 방식이 있다.
       bash -c "echo '${app_version}' > appVersion.txt"
    fi
  fi
}


# shellcheck disable=SC2120
check_availability_inside_container(){

  if [[ -z ${1} ]]
    then
      echo "[ERROR] check_availability_inside_container 의 대상 state 를 명시해야 합니다."  >&2
      echo "false"
      return
  fi

  if [[ -z ${2} ]]
    then
      echo "[ERROR] wait-for-it.sh timeout 파라매터가 없습니다."  >&2
      echo "false"
      return
  fi

  if [[ -z ${3} ]]
    then
      echo "[ERROR] Health Check timeout 파라매터가 없습니다."  >&2
      echo "false"
      return
  fi


  check_state=${1}

  echo "[NOTICE] ${project_name}-${check_state} 컨테이너 내부에서 웹 서버 를 호출하여 응답하는 지 확인 합니다. node_modules 또는 vendor 폴더가 없다면, ENTRYSCRIPT 실행 시간이 다소 길어 집니다. (timeout : ${2} 초)"  >&2
  sleep 10

  # 1) 앱이 띄어졌는지 기본 확인

  container_load_timeout=${2}

  local wait_for_it_re=$(docker exec -w ${project_location}/${project_name} ${project_name}-${check_state} ./wait-for-it.sh localhost:${project_port} --timeout=${2})
  if [[ $? != 0 ]]; then
      echo "[ERROR] wait-for-it.sh 호출에 실패 하였습니다. (${wait_for_it_re})" >&2
      echo "false"
      return
  else
      # 2) 앱 자체의 health check
      echo "[NOTICE] ${project_name}-${check_state} 컨테이너 내부에서 ${check_state} container 의 Health Check 를 진행합니다."  >&2
      sleep 1

      local interval_sec=5

      # timeout설정값으로 재시도 횟수를 맞추기 위해 로직 변경
      local total_cnt=$((${container_load_timeout}/${interval_sec}))

      # 0으로 나눠떨이지지 않을경우 재시도 횟수 1회 추가
      if [[ $((container_load_timeout%interval_sec)) != 0 ]]; then
        total_cnt=$((${total_cnt}+1))
      fi

      for (( retry_count = 1; retry_count <= ${total_cnt}; retry_count++ ))
      do
        echo "[NOTICE] ${retry_count}회 차 Health check 연결 시도... (timeout : ${3} 초)"  >&2
        response=$(docker exec ${project_name}-${check_state} bash -c "curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path} --connect-timeout ${3}")
        # 전체 status의 UP을 확인하는 regex
        down_count=$(echo ${response} | egrep -i ${bad_app_health_check_pattern} | wc -l)
        # 단순히 DOWN이 없다면으로 판별하기가 어려운 것이.. JSON response 가 아닌 Html 오류 화면(ex. Apache2 web server 502 오류)과 같은 것으로 화면 상에 아파치 오류가 뜰 수 있음.
        up_count=$(echo ${response} | egrep -i ${good_app_health_check_pattern} | wc -l)

        if [[ ${down_count} -ge 1 || ${up_count} -lt 1 ]]
        then # $down_count >= 1 ("DOWN" 문자열이 있는지 검증)

            echo "[WARNING] Health check의 응답을 알 수 없거나 혹은 status가 UP이 아닙니다. (response : ${response})"  >&2

        else
             echo "[NOTICE] 앱 내부 Health check 성공. (response : ${response})"  >&2
             break
        fi

        if [[ ${retry_count} -eq ${total_cnt} ]]
        then
          echo "[실패] Health check 최종 실패. (response : ${response})" >&2
          echo "false"
          return
        fi

        echo "[NOTICE] ${retry_count}/${total_cnt}회 차 Health check 연결 실패. ${interval_sec} 초 후 재시도..."  >&2
        for (( i = 1; i <= ${interval_sec}; i++ ));do echo -n "$i." >&2 && sleep 1; done
        echo "\n"  >&2

      done

     echo "true"
     return
 fi
}
