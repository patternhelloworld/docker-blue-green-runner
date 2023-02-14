#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
sed -i -e 's/\r$//' *.sh
sed -i -e 's/\r$//' .env .env.example.local .env.example.real || echo "[NOTICE] CRLF 개행 검사를 하였습니다. 존재하지 않는 파일들은 문제가 없습니다."
#find ./.docker/sh -type f -exec sed -i -e 's/\r$//' {} \;
#find ./.docker/nginx -type f -exec sed -i -e 's/\r$//' {} \;
