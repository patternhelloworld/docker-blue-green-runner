#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -e
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."
# 리눅스 - 윈도우 개발 환경 충돌 방지
git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh

cache_global_vars

echo '[NOTICE] 롤백을 시작합니다. 현재의 state 를 확인합니다.'
blue_is_run=$(docker exec ${project_name}-blue echo 'yes' 2> /dev/null || echo 'no')

state='blue'
new_state='green'
new_upstream=${green_upstream}
if [[ ${blue_is_run} != 'yes' ]]
then
    state='green'
    new_state='blue'
    new_upstream=${blue_upstream}
fi

# 1) Nginx 롤백

if [ ${nginx_restart} = "true" ]; then
  echo "[NOTICE] 이전 (previous) Nginx 이미지를 latest 이미지로 변경"
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:latest || echo "[ERROR] ${project_name}-nginx:previous 이미지가 존재하는 지 확인해야 합니다."

  sleep 2

  echo "[NOTICE] Nginx latest 컨테이너를 띄웁니다"
  docker-compose -f docker-compose-nginx.yml up -d ${project_name}-nginx
fi

# 2) 앱 롤백

echo "[NOTICE] 이전 (previous) 앱 이미지를 ${new_state} 이미지로 변경하여 롤백"
docker tag ${project_name}:previous ${project_name}:${new_state} || echo "[ERROR] ${project_name}:previous 이미지가 존재하는 지 확인해야 합니다."

sleep 2

echo "[NOTICE] ${new_state} 컨테이너를 띄웁니다"
docker-compose -f docker-compose-app-${app_env}.yml up -d ${project_name}-${new_state}

# local 개발자 환경의 경우 vendor 폴더나 node_modules 가 없을 경우 재설치 과정을 콘솔에 띄우기 위함 (real 의 경우 이미 Dockerfile 의 ENTRYPOINT 를 통해 이미 뜨고 있거나 떠 있음)
if [[ ${app_env} == 'local' ]]; then
  sleep 5
  docker exec -it ${project_name}-${new_state}  bash -c 'bash '${project_location}'/'${project_name}'/.docker/sh/update/local/'${project_name}'.sh'
fi

echo "[NOTICE] ${new_state} 컨테이너가 다 띄어질 때 까지 기다립니다."
if [[ $(check_availability_inside_container ${new_state} 60 5 | tail -n 1) != 'true' ]]; then
  echo "[ERROR] 신규 앱 ${new_state} 컨테이너를 띄우는데 실패 하였습니다." && exit 1
fi

# Consul 과 연동하여 Blue-Green 세팅을 한다.
./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}

echo "[NOTICE] 기존 ${state} 컨테이너 종료"
docker-compose -f docker-compose-app-${app_env}.yml stop ${project_name}-${state}
