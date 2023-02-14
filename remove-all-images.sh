#!/bin/bash
sudo sed -i -e 's/\r$//' *.sh
echo "[NOTICE] WIN 운영체제에 따른 스크립트들의 CRLF 오류를 방지하기 위해, CRLF->LF 치환 중... (만약 이래도 개행 오류 발생 시 readme 참조)"
sudo sed -i -e 's/\r$//' *.sh
sudo bash prevent-crlf.sh

sleep 3
source ./util.sh

cache_global_vars

set -e

echo "[NOTICE] 해당 프로젝트와 관련 된 이미지를 모두 삭제 합니다. 해당 아이템들이 없을 경우 오류 메시지가 뜰 수 있기에 오류 메시지들은 무시해도 됩니다."

docker rmi -f ${project_name}-nginx:latest
docker rmi -f ${project_name}-nginx:new
docker rmi -f ${project_name}-nginx:previous

docker rmi -f ${project_name}:latest
docker rmi -f ${project_name}:new
docker rmi -f ${project_name}:previous
docker rmi -f ${project_name}:blue
docker rmi -f ${project_name}:green