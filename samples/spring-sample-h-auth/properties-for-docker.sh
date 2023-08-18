#!/usr/bin/env bash
sed -i -e "s/\r$//g" $(basename $0)
git config apply.whitespace nowarn
git config core.filemode false

echo "[WARN] 이 명령어로 인해 application-local.properties 의 DB 설정 IP가 변경됩니다. ** WIN 개발 시에는 원래대로 localhost 로 변경하십시오."
sed -i -Ee "s/(mysql:\/\/)[^:]+/\1${1}/" ./src/main/resources/application-local.properties
sed -i -e "s/\r$//g" ./src/main/resources/application-local.properties