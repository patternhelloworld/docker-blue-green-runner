#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -eu

echo "[NOTICE] WIN 운영체제에 따른 스크립트들의 CRLF 오류를 방지하기 위해, CRLF->LF 치환 중..."
bash prevent-crlf.sh
# 리눅스 - 윈도우 개발 환경 충돌 방지
git config apply.whitespace nowarn
git config core.filemode false

sleep 3
source ./util.sh


# 백업 우선 순위 : new > blue 또는 green 현재 띄어져 있는 컨테이너 > latest
backup_app_to_previous_images(){
  # 앱
  echo "[NOTICE] 앱의 previous 이미지를 생성하기 이전에, 기존의 previous 이미지가 있다면 previous2 로 백업을 진행합니다."
  docker tag ${project_name}:previous ${project_name}:previous2 || echo "[NOTICE] 기존의 previous 이미지가 존재하지 않습니다."

  if [[ $(docker images -q ${project_name}:new 2> /dev/null) != '' ]]
  then
      # new 이미지가 있을 경우
      echo "[NOTICE] 기존의 앱 new 이미지를 previous 로 백업 합니다."
      docker tag ${project_name}:new ${project_name}:previous && return  || echo "[NOTICE] 백업 할 앱 new 이미지가 존재하지 않습니다."
  fi

  # new 이미지가 없을 경우
  echo "[NOTICE] 앱의 new 이미지가 없어서, blue 또는 green 컨테이너를 확인하고 정상적으로 띄어져 있는 컨테이너의 이미지를 백업 이미지로 사용합니다."
  if [[ $(docker exec ${project_name}-blue printenv SERVICE_NAME 2> /dev/null) == 'blue' ]]
  then
      if [[ $(check_availability_inside_container 'blue' 20 5 | tail -n 1) == 'true' ]]; then
          echo "[NOTICE] 기존의 앱 blue 이미지를 previous 로 백업 합니다."
          docker tag ${project_name}:blue ${project_name}:previous && return || echo "[NOTICE] 백업 할 앱 blue 이미지가 존재하지 않습니다."
      fi
  fi

  if [[ $(docker exec ${project_name}-green printenv SERVICE_NAME 2> /dev/null) == 'green' ]]
  then
      if [[ $(check_availability_inside_container 'green' 20 5 | tail -n 1) == 'true' ]]; then
        echo "[NOTICE] 기존의 앱 green 이미지를 previous 로 백업 합니다."
        docker tag ${project_name}:green ${project_name}:previous && return || echo "[NOTICE] 백업 할 앱 green 이미지가 존재하지 않습니다."
      fi
  fi

  echo "[NOTICE] 기존의 앱 new, blue, green 이미지 모두 없어서, latest 이미지를 previous 로 백업 시도 합니다."
  docker tag ${project_name}:latest ${project_name}:previous || echo "[NOTICE] 백업 할 앱 latest 이미지도 존재하지 않습니다."

}

backup_nginx_to_previous_images(){
  # NGINX
  echo "[NOTICE] Nginx 의 previous 이미지를 생성하기 이전에, 기존의 previous 이미지가 있다면 previous2 로 백업을 진행합니다."
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:previous2 || echo "[NOTICE] 기존의 previous2 이미지가 존재하지 않습니다."

  if [[ $(docker images -q ${project_name}-nginx:new 2> /dev/null) != '' ]]
  then

    echo "[NOTICE] 기존의 Nginx new 이미지를 previous 로 백업 합니다."
    docker tag ${project_name}-nginx:new ${project_name}-nginx:previous && return || echo "[NOTICE] 백업 할 nginx new 이미지가 존재하지 않습니다."

  fi

  echo "[NOTICE] 기존의 Nginx new 이미지가 없어서, latest 이미지를 previous 로 백업 시도 합니다."
  docker tag ${project_name}-nginx:latest ${project_name}-nginx:previous || echo "[NOTICE] 백업 할 nginx latest 이미지도 존재하지 않습니다."

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

      # sudo bash run.sh 를 할 경우, root 권한으로 해당 폴더가 생성된다. bash run.sh 를 할 경우, 현재 로그인 된 사용자 권한으로 폴더가 생성된다.
      # 따라서, 여기에 sudo 를 명시할 경우 run.sh 가 설령 로그인 된 사용자 권한으로 실행되더라도, 폴더는 최종적으로 root 권한으로 생성된다.
      sudo mkdir -p $val

      echo "[NOTICE] The directory of '$val' has been created."

      chgrp -R ${host_root_gid} $val
      echo "[NOTICE] The directory of '$val' has been given the ${host_root_gid} group permission."
    fi
  done
}

give_root_folder_full_permissions(){
  echo "[NOTICE] IDE (PHPSTORM) 의 도커 내부 접근 권한을 용이하게 하기 위해, 로컬에서 777로 유지 합니다. 실서버(real) 에서는 보안 상 사용하지 마세요."
  sudo chmod -R 777 ../*
  # 기본적으로, 모든 volume 폴더에는 host 의 사용자 그룹 (root 사용자가 아닌 현재 사용자)을 권한을 준다. 그리고 Dockerfile 또는 ENTRYPOINT 에서 컨테이너 안에서 해당 폴더를 사용하는 App 의 권한 (www-data, redis 등)을 준다.
  # 왜냐하면, 개발 환경에서는 Volume 폴더를 IDE 등으로 수정할 수도 있어야 하므로, host 에 권한을 주고, 도커 안 각 폴더에는 각 라이브러리들이 접근할 수 있는 권한이 필요하다. (도커 안 권한은 ENTRYPOINT 스크립트에서 실행 된다.)
  sudo chgrp -R ${host_root_gid} ../*
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

    docker-compose -f docker-compose-app-local.yml down || echo "[NOTICE] docker-compose-app-local.yml down 에 실패 하였습니다."
    docker-compose -f docker-compose-app-real.yml down || echo "[NOTICE] docker-compose-app-real.yml down 에 실패 하였습니다."
    docker-compose -f docker-compose-consul.yml down || echo "[NOTICE] docker-compose-app-consul.yml down 에 실패 하였습니다."
    docker-compose -f docker-compose-nginx.yml down || echo "[NOTICE] docker-compose-app-nginx.yml down 에 실패 하였습니다."
    docker-compose down || echo "[NOTICE] docker-compose.yml down 에 실패 하였습니다."
    docker system prune -f
  fi
}


load_consul_docker_image(){

  if [[ $(docker exec consul echo 'yes' 2> /dev/null) == '' ]]
  then
      echo '[NOTICE] 컨테이너가 띄어져 있지 않으므로  consul_restart=true 로 간주하여 이미지 load 부터 다시 시작합니다. (.env 파일은 변경되지 않습니다.)'
      consul_restart=true

      # Dockerfile 이 없으므로 load_nginx_docker_image, load_app_docker_image 함수들과 다르게 build 명령어가 없다.
  fi

  if [ ${consul_restart} = "true" ]; then
    # Dockerfile 이 없으므로 load_nginx_docker_image, load_app_docker_image 함수들과 다르게 build 명령어가 없다.
  fi

}

# TO DO : 폐쇄망 모듈
load_nginx_docker_image(){

  if [[ $(docker exec ${project_name}-nginx echo 'yes' 2> /dev/null) == '' ]]
  then
      echo '[NOTICE] ${project_name}-nginx:latest 컨테이너가 띄어져 있지 않으므로 nginx_restart=true 로 간주하여 빌드부터 다시 시작합니다.'
      nginx_restart=true
  fi

  if [ ${nginx_restart} = "true" ]; then

      echo "[NOTICE] ${project_name}-nginx 이미지를 빌드 합니다. (캐시는 활용 합니다.)"
      docker build --build-arg DISABLE_CACHE=${CUR_TIME}  --build-arg protocol="${protocol}" --tag ${project_name}-nginx -f ./.docker/nginx/Dockerfile . || exit 1

  fi
}

# 이미지 명 : ${project_name} (태그 4가지를 활용하여 무중단 Blue-Green 배포 구현 - ${project_name}:latest, ${project_name}:previous, ${project_name}:blue, ${project_name}:green)
load_app_docker_image() {

  #  이미지 파일을 load 하지 않고 Dockerfile 을 활용하는 경우
  echo "[NOTICE] ${project_name} 이미지를 빌드 합니다. (캐시는 활용 합니다.)"
  if [[ ${docker_layer_corruption_recovery} == true ]]; then
    docker build --no-cache --tag ${project_name}:latest --build-arg server="${app_env}" -f ${docker_file_path_name} . || exit 1
  else
    docker build --build-arg DISABLE_CACHE=${CUR_TIME} --tag ${project_name}:latest --build-arg server="${app_env}" -f ${docker_file_path_name} . || exit 1
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
  echo "[NOTICE] 현재 프로젝트의 .env 를 사용하기 위해 'cp -f .env ./.docker/env/real/.env' 명령어 실행."
  sudo cp -f .env ./.docker/env/real/.env
}


nginx_restart(){

   echo "[NOTICE] NGINX 의 컨테이너와 네트워크를 종료합니다."

   # docker-compose -f docker-compose-app-${app_env}.yml down || echo "[DEBUG] A1"
   docker-compose -f docker-compose-nginx.yml down || echo "[DEBUG] N1"

   docker network rm ${project_name}_app || echo "[DEBUG] NA"

   echo "[NOTICE] NGINX 를 컨테이너로 띄웁니다."
   PROJECT_NAME=${project_name} docker-compose -f docker-compose-nginx.yml up -d ${project_name}-nginx || echo "[ERROR] 중요 오류 - ${project_name}-nginx 가 UP 되는데 실패 하였습니다."
}

consul_restart(){

    echo "[NOTICE] CONSUL 의 컨테이너와 네트워크를 종료합니다."

    #docker-compose -f docker-compose-app-${app_env}.yml down || echo "[DEBUG] C-A1"
    #docker-compose -f docker-compose-nginx.yml down || echo "[DEBUG] C-N1"
    docker-compose -f docker-compose-consul.yml down || echo "[DEBUG] C-1"

    docker network rm consul || echo "[DEBUG] CA"

    docker network create consul || echo "[NOTICE] network consul 이 미리 생성되어 있습니다. 해당 메시지는 무시하거나, 반드시 재시작 하고자 한다면 consul 을 공유하는 다른 프로젝트를 종료하십시오."

    echo "[NOTICE] CONSUL 을 컨테이너로 띄웁니다."
    docker-compose -p consul -f docker-compose-consul.yml up -d || echo "[NOTICE] 다른 consul 공유 프로젝트 들 (pineworks-hr, pinenote-rpa-bpo-auth-server)에 의해 consul 이 미리 생성되어 있을 수 있습니다. 해당 메시지는 무시하십시오."
    sleep 10
}

# 위에서 이미지들을 load 했으니, 해당 이미지들을 바탕으로 컨테이너 들을 load 한다.
load_all_containers(){

  # app -> consul -> nginx 식으로 재시작 (컨테이너 재시작을 의미)하는 것이 안전하다. 이전에는 nginx 를 app 보다 먼저 재시작 하였는데, 이 것이 nginx conf 쪽에 오류 메시지 (upstream not found)를 남겼었다. 이와 같은 이유로 소캣쪽에 502 오류가 발생한 것으로 보인다.
  # 엄밀히 app 의 경우 blue/green 배포 이므로 재시작이라고 볼 수는 없다. 현재 blue 로 배포 되어 있다면, green 으로 배포하고자 할 경우 green 대시보드가 완전히 시작한 후에,
  # nginx 를 green 방향으로 재시작 (배포 스크립트 상에서는 conf 파일이 green 방향으로 바뀜) 하는 것이 오류를 방지할 수 있을 것이다.
  # 이전의 nginx 를 app 보다 먼저 재시작 하는 스크립트는, blue 컨테이너를 끄고 nginx 를 재시작 하였는데, nginx 가 올라가면서 blue 도 green 도 없으므로 오류 (upstream not found)를 남겼다.
  # 그러나 비록 오류를 남기더라도, 로컬에서 간헐적으로 소캣이 502 오류가 떠서 재시작하는 불편과, 실서버에서는 nginx 를 재시작 안하므로 (재시작 하는 순간 무중단 배포가 아님) 불편을 크게 초래하지
  # 않은 것으로 보이나, 이와 같은 조치가 이러한 불편도 완전히 제거시킬 수 있는지는 시간을 두고 지켜볼 것이며, 해결된다면 인증서버와, 파인웍스에도 적용 할 예정이다.
  # ※ consul 이 안 뜬 상태에서도, nginx 는 혼란을 겪으므로 (다음과 같은 오류 발생 - [WARN] (view) kv.get(deploy/dashboard): Get http://consul:8500/v1/kv/deploy/dashboard?index=47423&stale=&wait=60000ms: dial tcp 172.26.0.4:8500: getsockopt: connection refused (retry attempt 1 after "250ms"))
  # nginx 는 다른 컨테이너들이 안전하게 다 뜨고나서 마지막에 뜨는 것이 안정성을 높일 것으로 보인다.

  echo "[NOTICE] 앱을 ${new_state} 컨테이너로 띄웁니다. (BLUE-GREEN 배포이기 때문에 기존 컨테이너를 종료하지 않습니다.)"

  docker network create consul || echo "[NOTICE] network consul 이 미리 생성되어 있습니다. 해당 메시지는 무시합니다."
  docker-compose -f docker-compose-app-${app_env}.yml up -d ${project_name}-${new_state} || echo "[ERROR] 중요 오류 - 앱이 ${new_state}로 UP 되는데 실패 하였습니다."


  # local 개발자 환경의 경우 vendor 폴더나 node_modules 가 없을 경우 재설치 과정을 콘솔에 띄우기 위함 (real 의 경우 이미 Dockerfile 의 ENTRYPOINT 를 통해 이미 뜨고 있거나 떠 있음)
  if [[ ${app_env} == 'local' ]]; then
     re=$(check_availability_inside_container ${new_state} 600 5 | tail -n 1) || exit 1;
  else
     re=$(check_availability_inside_container ${new_state} 120 5 | tail -n 1) || exit 1;
    #dynamic_timeout=5000
    #sleep 5
    #docker exec -it ${project_name}-${new_state}  bash -c 'bash '${project_location}'/'${project_name}'/.docker/sh/update/local/'${project_name}'.sh'
  fi

  if [[ ${re} != 'true' ]]; then
    echo "[ERROR] 신규 앱 ${new_state} 컨테이너를 띄우는데 실패 하였습니다. docker logs -f ${project_name}-${new_state} 명령어를 통해 오류를 확인하십시오. (결과 값 : ${re})" && exit 1
  fi

  if [[ ${consul_restart} == 'true' ]]; then

      consul_restart

  fi

  if [[ ${nginx_restart} == 'true' ]]; then

      nginx_restart

  fi

}

push_consul_docker_image_to_akuo(){

  docker tag gliderlabs/registrator ${1}-registrator-${app_version}
  echo "[NOTICE] ${1}-registrator-${app_version} 도커 이미지를 Docker Registry 에 push 합니다."
  docker push ${1}-registrator-${app_version}

  docker tag consul ${1}-consul-${app_version}
  echo "[NOTICE] ${1}-consul-${app_version} 도커 이미지를 Docker Registry 에 push 합니다."
  docker push ${1}-consul-${app_version}

}

push_nginx_docker_image_to_akuo(){

  docker tag ${project_name}-nginx:latest ${1}-nginx-${app_version}
  echo "[NOTICE] ${1}-nginx-${app_version} 도커 이미지를 Docker Registry 에 push 합니다."
  docker push ${1}-nginx-${app_version}

}

push_app_docker_image_to_akuo(){

  docker tag ${project_name}:latest ${1}-app-${app_version}
  echo "[NOTICE] ${1}-app-${app_version} 도커 이미지를 Docker Registry 에 push 합니다."
  docker push ${1}-app-${app_version}

}

check_availability_out_of_container(){

  echo "[NOTICE] 외부에서 호출하여 Status=200 인지 확인 합니다."  >&2
  sleep 1

  for retry_count in {1..6}
  do
    status=$(curl ${app_url} -o /dev/null -k -Isw '%{http_code}' --connect-timeout 10)
    if [[ ${status} != '200' ]]; then

      echo "Bad HTTP response in the ${new_state} app: ${status}"  >&2

      if [[ ${retry_count} -eq 5 ]]
      then
         echo "[ERROR] Health Check 실패. (외부 도메인 접근이 아니라면(=폐쇄망 세팅 환경), APP_URL 이 우분투 호스트에서 ifconfig 로 검색한 값인지 확인 필요. WIN ipconfig 명령어로 출력 된 ip는 접근 실패할 수 있다. 또는 네트워크 방화벽 확인 필요.)"  >&2
         echo "false"
         return
      fi

    else
      echo "[NOTICE] 외부 호출 테스트 성공."  >&2
      break
    fi

    echo "[NOTICE] 연결 실패. 3초에 한번씩 총 5회 재시도..."  >&2
    sleep 3
  done

  echo 'true'
  return

}

backup_to_new_images(){
    # 성공 시 현재 도커 이미지를 previous 로 하여 rollback 시 시용
    echo "[NOTICE] 성공한 앱 이미지를 new 태그로 백업 합니다."
    docker tag ${project_name}:latest ${project_name}:new || echo "[NOTICE] 백업 할 ${project_name}:latest 이미지가 존재하지 않습니다."
    echo "[NOTICE] 성공한 Nginx 이미지를 new 태그로 백업 합니다."
    docker tag ${project_name}-nginx:latest ${project_name}-nginx:new || echo "[NOTICE] 백업 할 ${project_name}-nginx:latest 이미지가 존재하지 않습니다."
}


_main() {

  check_necessary_commands

  cache_global_vars

  check_env_integrity

  backup_app_to_previous_images
  backup_nginx_to_previous_images

  # 필요한 폴더들의 생성과 권한 설정
  if [[ ${app_env} == 'local' ]]; then
      # 권한이 적합하지 않을 경우 앱이 작동하는 상황에서 오류 발생
      give_root_folder_full_permissions
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


  # Blue-Green 배포를 위한 state 설정
  cache_all_states

  if [[ ${app_env} == 'real' ]]; then
    inject_env_real
    sleep 2
  fi
  # 위에서 이미지들을 load 했으니, 해당 이미지들을 바탕으로 컨테이너 들을 load 한다.
  load_all_containers

  # Consul 과 연동하여 Blue-Green 세팅을 한다.
  ./activate.sh ${new_state} ${state} ${new_upstream} ${key_value_store}

  # 컨테이너 밖에서 app_url 을 호출하여 유효성을 확인한다.
  re=$(check_availability_out_of_container | tail -n 1);
  if [[ ${re} != 'true' ]]; then
    echo "[ERROR] 컨테이너 밖에서 app_url 을 호출하는데에 실패 하였습니다.  bash rollback.sh 실행을 고려 하십시오. (결과 값 : ${re})" && exit 1
  fi

  ## 여기까지 도달하면 성공으로 간주

  # 성공 시 현재 도커 이미지를 previous 로 하여 rollback 시 시용
  backup_to_new_images

  # 성공 시 이전 컨테이너 종료
  echo "[NOTICE] 배포에 성공 하였으므로 이전 (${state}) 컨테이너는 종료합니다. ( NGINX_RESTART=true 또는 CONSUL_RESTART=true 의 경우 기존 컨테이너가 load_all_containers 함수 에서 이미 종료 되었습니다. )"
  docker-compose -f docker-compose-app-${app_env}.yml stop ${project_name}-${state}

  echo "[NOTICE] <none>:<none> 이미지들을 삭제합니다."
  docker rmi $(docker images -f "dangling=true" -q) || echo "[NOTICE] 사용 중인 이미지가 있다면 삭제되지 않습니다."
}

_main