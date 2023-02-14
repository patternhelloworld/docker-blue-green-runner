#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
echo "[NOTICE] WIN 운영체제에 따른 스크립트들의 CRLF 오류를 방지하기 위해, CRLF->LF 치환 중..."
bash prevent-crlf.sh

set -e

source ./util.sh

cache_global_vars

consul_key_value_store=$1
state=$2
new_state=$3

echo "[NOTICE] ${state} 로 CONSUL 에 저장합니다."
docker exec ${project_name}-nginx curl -X PUT -d ${state} ${consul_key_value_store} > /dev/null

echo "Stop the ${new_state} container"
docker-compose -f docker-compose-app-${app_env}.yml stop ${project_name}-${new_state}

exit 1
