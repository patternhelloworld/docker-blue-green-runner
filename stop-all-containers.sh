#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0)
set -e
echo "[NOTICE] WIN 운영체제에 따른 스크립트들의 CRLF 오류를 방지하기 위해, CRLF->LF 치환 중... (만약 이래도 개행 오류 발생 시 readme 참조)"
# 리눅스 - 윈도우 개발 환경 충돌 방지
#git config apply.whitespace nowarn
#git config core.filemode false


echo "[NOTICE] 해당 프로젝트와 관련 된 컨테이너, 네트워크를 모두 삭제 합니다. 해당 아이템들이 없을 경우 오류 메시지가 뜰 수 있기에 오류 메시지들은 무시해도 됩니다."

docker-compose -f docker-compose-app-local.yml down || echo "[DEBUG] A-L"
docker-compose -f docker-compose-app-real.yml down || echo "[DEBUG] A-R"
docker-compose -f docker-compose-nginx.yml down || echo "[DEBUG] N"
docker-compose -f docker-compose-consul.yml down || echo "[DEBUG] C"

docker-compose down || echo "[DEBUG] G"
docker system prune -f
