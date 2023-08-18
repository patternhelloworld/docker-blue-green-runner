#!/bin/bash

#
# [Spring boot Nginx 무중단 배포]
#
# 외부에서 접근 하는 PORT는 항상 PROJECT_PORT 이며, Nginx 리버스 프록시를 사용하여 두 개의 포트에 번갈아 가면서 배포하여, 서버의 무중단을 유지한다.
# 아래에서 사용되는 명령어 'service nginx reload' 는 서버 설정 변경 사항을 적용하는 강력한 기능이며 서버 무중단을 유지한다.

# 테스트

# 해당 스크립트 수정 시에는 Alpha 서버에서 다음과 같은 테스트를 반드시 진행한다.
# 두 개의 포트에 모두 서비스가 없는 경우, 1개의 포트에 서비스가 있는 경우, 두 개의 포트에 모두 서비스가 있는 경우, 아래 파라매터들에 인위적으로 오류 발생시킴.


# 결과

# 스크립트는 [성공], [실패], [긴급 오류]로 끝난다. [실패] 또는 [긴급 오류] 시 CloudWatch에서 확인 가능하다.

# [성공] - 성공
# [실패] - 신규 배포에는 실패하였고 기존의 배포에는 이상이 없을 확률이 매우 높다. CloudWatch 에는 오류로 표시되나 기존의 배포가 정상적으로 돌아가고 있다.
# [긴급 오류] - 지금 FIRST_REVERSE_PROXY_PORT 포트나 SECOND_REVERSE_PROXY_PORT 포트에 프로젝트가 올라와 있지 않은 상황 (실서버 다운) 이니 긴급히 인스턴스에 접근하여 수정해야 한다.


# 상수 (서버 설정과 연동되어 있으므로 절대 바꾸어서는 안된다)

# FIRST_REVERSE_PROXY_PORT와 SECOND_REVERSE_PROXY_PORT가 번갈아 가며 기록된다.
# 예) FIRST_REVERSE_PROXY_PORT로 배포 성공 시 FIRST_REVERSE_PROXY_PORT가 해당 파일에 기록 됨.
NGINX_SERVICE_FILE_PATH_NAME=/etc/nginx/conf.d/spring-sample-h-auth-service-url.inc

# Spring acutator에서 제공하는 서버 Health Check
# appplication.properties의 management.endpoints.web.base-path과 health 확인 주소가 일치하는 지 항상 확인
HEALTH_CHECK_URI=/healthStatus

PROJECT_PORT=8200

FIRST_REVERSE_PROXY_PORT=8086
SECOND_REVERSE_PROXY_PORT=8087

PRODUCTION_PATH=/var/www/server/spring-sample-h-auth
# pom.xml 과 반드시 같은 pattern 이어야 한다.
SERVER_IMAGE_NAME_PATTERN=spring-sample-h-auth-[0-9.]*-SNAPSHOT.jar


# 변수

CURRENT_PORT=
IDLE_PORT=

echo -e "# 1. 배포할 유효한 Port 번호를 지정합니다."

echo "> Application level check : 현재 구동중인 Port 를 'curl -k -s $(curl -Ls -o /dev/null -w %{url_effective} http://127.0.0.1:${PROJECT_PORT}/localPort)' 명령어를 통해 확인"

for retry_count in {1..4}
do
  response=$(curl -k -s $(curl -Ls -o /dev/null -w %{url_effective} http://127.0.0.1:${PROJECT_PORT}/localPort))
  # 모든 포트 값 유형 regex
  current_port_count=$(echo ${response} | egrep '^[\n\r\t\s]*[0-9]+[\n\r\t\s]*$' | wc -l)

  if [[ ${current_port_count} -ge 1 ]]
  then
      echo "> Port 값이 발견되었습니다. - ${response}"
      CURRENT_PORT=${response}

      break
  else
      echo "> Port 값이 아닌 response 입니다."
      echo "> ${response}"
  fi

  if [[ ${retry_count} -eq 3 ]]
  then
    echo "> Port 값이 발견되지 않았습니다."
    break
  fi

  echo "> 2초에 한번씩 총 3회 재시도..."
  sleep 2
done


if [[ ${CURRENT_PORT} == ${FIRST_REVERSE_PROXY_PORT} ]]
then
  IDLE_PORT=${SECOND_REVERSE_PROXY_PORT}
elif [[ ${CURRENT_PORT} == ${SECOND_REVERSE_PROXY_PORT} ]]
then
  IDLE_PORT=${FIRST_REVERSE_PROXY_PORT}
else

  echo "> Application level check 실패, 구동 중인 Port가 확인되지 않습니다."
  echo "> Unix level check : 현재 Port를 명령어 방식으로 확인 합니다."

    if ! lsof -t -i tcp:${FIRST_REVERSE_PROXY_PORT} && ! lsof -t -i tcp:${SECOND_REVERSE_PROXY_PORT} ; then

        echo "> 현재 두개의 Port 가 모두 미사용 중입니다. 현재 서버가 다운 상태일 수 있습니다."

        IDLE_PORT=${FIRST_REVERSE_PROXY_PORT}
        echo "> ${IDLE_PORT} 를 배포 예정 Port로 지정합니다."
        CURRENT_PORT=${SECOND_REVERSE_PROXY_PORT}
        echo "> ${CURRENT_PORT} 를 현재 Port (CURRENT_PORT)로 지정합니다."

    elif ! lsof -Pi :${FIRST_REVERSE_PROXY_PORT} -sTCP:LISTEN -t >/dev/null ; then

      IDLE_PORT=${FIRST_REVERSE_PROXY_PORT}
      echo "> ${IDLE_PORT} 를 배포 예정 Port로 지정합니다."

      if lsof -Pi :${SECOND_REVERSE_PROXY_PORT} -sTCP:LISTEN -t >/dev/null ; then
        CURRENT_PORT=${SECOND_REVERSE_PROXY_PORT}
        echo "> ${CURRENT_PORT} 를 현재 Port (CURRENT_PORT)로 지정합니다."
      fi

    elif ! lsof -Pi :${SECOND_REVERSE_PROXY_PORT} -sTCP:LISTEN -t >/dev/null ; then

      IDLE_PORT=${SECOND_REVERSE_PROXY_PORT}
      echo "> ${IDLE_PORT} 를 배포 예정 Port로 지정합니다."

      if lsof -Pi :${FIRST_REVERSE_PROXY_PORT} -sTCP:LISTEN -t >/dev/null ; then
        CURRENT_PORT=${FIRST_REVERSE_PROXY_PORT}
        echo "> ${CURRENT_PORT} 를 현재 Port (CURRENT_PORT)로 지정합니다."
      fi

    else

       echo "> Nginx setting level check : localPort 두 개 모두 프로세스 점유 중입니다. 어떤 것인지 특정할 수가 없어서, ${NGINX_SERVICE_FILE_PATH_NAME}을 참조합니다."

       if [[ "$(grep -c -E -w ${FIRST_REVERSE_PROXY_PORT} ${NGINX_SERVICE_FILE_PATH_NAME})" -ge 1 ]]; then

             CURRENT_PORT=${FIRST_REVERSE_PROXY_PORT}
             echo "> ${CURRENT_PORT} 를 현재 Port (CURRENT_PORT)로 지정합니다."
             IDLE_PORT=${SECOND_REVERSE_PROXY_PORT}
             echo "> ${IDLE_PORT} 를 배포 예정 Port로 지정합니다."

       elif [[ "$(grep -c -E -w ${SECOND_REVERSE_PROXY_PORT} ${NGINX_SERVICE_FILE_PATH_NAME})" -ge 1 ]]; then

             CURRENT_PORT=${SECOND_REVERSE_PROXY_PORT}
             echo "> ${CURRENT_PORT} 를 현재 Port (CURRENT_PORT)로 지정합니다."
             IDLE_PORT=${FIRST_REVERSE_PROXY_PORT}
             echo "> ${IDLE_PORT} 를 배포 예정 Port로 지정합니다."

       else

         echo "[실패] 현재 localPort가 두 개 띄어져 있습니다. ${NGINX_SERVICE_FILE_PATH_NAME} 에서 Port 확인 불가이며, 인스턴스 내부 확인 필요."
         exit 1

       fi

    fi

fi

echo "> 다음 Port로 배포가 진행됩니다. ( IDLE_PORT : ${IDLE_PORT} )"


echo -e "# 2. 배포할 대상 jar를 배포 디렉토리에 위치 시키고, 1. 에서 지정된 Port로 jar를 부팅 합니다."

echo "> 새롭게 배포하고자 하는 ${IDLE_PORT} Port 디렉토리를 초기화 합니다."
if [[ -d ${PRODUCTION_PATH}/target/${IDLE_PORT} ]]
then
    sudo rm -rf ${PRODUCTION_PATH}/target/${IDLE_PORT}
    echo "> ${IDLE_PORT} Port 디렉토리 삭제 성공"
elif [[ -f ${PRODUCTION_PATH}/target/${IDLE_PORT} ]]
then
    sudo rm ${PRODUCTION_PATH}/target/${IDLE_PORT}
    echo "> ${IDLE_PORT} Port 파일 삭제 성공"
else
    echo "> 기존의 다음 디렉토리가 존재하지 않습니다. 없어도 생성할 예정이므로 무방합니다. : rm ${PRODUCTION_PATH}/target/${IDLE_PORT}"
fi
sudo mkdir -vp ${PRODUCTION_PATH}/target/${IDLE_PORT}

if [[ -d ${PRODUCTION_PATH}/target/${IDLE_PORT} ]]
then
    echo "> ${PRODUCTION_PATH}/target/${IDLE_PORT} 디렉토리 생성 성공"
else
    echo "[실패] ${PRODUCTION_PATH}/target/${IDLE_PORT} 디렉토리 생성 실패"
    exit 1
fi

if lsof -Pi :${IDLE_PORT} -sTCP:LISTEN -t >/dev/null
then

    echo "> 배포 예정 Port에 프로세스가 발견되었습니다. (이 경우는 Port가 두 개 띄어져 있는 상태이며, CURRENT_PORT가 localPort인 상태)"

    echo "배포 예정 IDLE_PORT ${IDLE_PORT} 가 점유 중 이어서 이를 종료합니다."
    sudo kill -15 $(lsof -t -i tcp:${IDLE_PORT})
    sleep 10
fi


echo "> JAR를 메모리에 띄웁니다."

if compgen -G ${PRODUCTION_PATH}/target/${SERVER_IMAGE_NAME_PATTERN} > /dev/null;
then
    echo "> 배포할 JAR (${SERVER_IMAGE_NAME_PATTERN})가 ${PRODUCTION_PATH}/target 경로에 존재"
else
   echo "[실패] 배포할 JAR (${SERVER_IMAGE_NAME_PATTERN})가 ${PRODUCTION_PATH}/target 경로에 존재하지 않아 종료"
   exit 1
fi

sudo cp  ${PRODUCTION_PATH}/target/${SERVER_IMAGE_NAME_PATTERN} ${PRODUCTION_PATH}/target/${IDLE_PORT}/
sudo chmod +x ${PRODUCTION_PATH}/target/${IDLE_PORT}/${SERVER_IMAGE_NAME_PATTERN}

cd ${PRODUCTION_PATH}/target/${IDLE_PORT}


if compgen -G ${PRODUCTION_PATH}/target/${IDLE_PORT}/${SERVER_IMAGE_NAME_PATTERN} > /dev/null
then
    sudo nohup java -jar ${SERVER_IMAGE_NAME_PATTERN} --server.port=${IDLE_PORT} > /var/www/auth-start.log 2>&1 &
else
    echo "[실패] 배포할 JAR (${PRODUCTION_PATH}/target/${IDLE_PORT}/${SERVER_IMAGE_NAME_PATTERN})가 미존재하여 중단"
    exit 1
fi



echo -e "# 3. 배포할 대상 포트로 jar이 안전하게 떴는 지 확인합니다. (spring actuator health check)"

echo "> $IDLE_PORT 15초 후 Health check 시작"
echo "> curl -s http://127.0.0.1:${IDLE_PORT}/${HEALTH_CHECK_URI}"
sleep 15

for retry_count in {1..7}
do
  response=$(curl -s http://127.0.0.1:${IDLE_PORT}/${HEALTH_CHECK_URI})
  # 전체 status의 UP을 확인하는 regex
  up_count=$(echo ${response} | egrep -i '^[\n\r\t\s]*{[\n\r\t\s]*\"status\"[\n\r\t\s]*:[\n\r\t\s]*\"UP' | wc -l)

  if [[ ${up_count} -ge 1 ]]
  then # $up_count >= 1 ("UP" 문자열이 있는지 검증)
        echo "> Health check 성공."

      break
  else
      echo "> Health check의 응답을 알 수 없거나 혹은 status가 UP이 아닙니다."
      echo "> Health check: ${response}"
  fi

  if [[ ${retry_count} -eq 6 ]]
  then
    echo "[실패] Health check 실패. Nginx에 띄우지 않고 배포를 종료합니다. 기존 배포가 있다면 기존 배포에 영향을 끼치지는 않았습니다."
    exit 1
  fi

  echo "> Health check 연결 실패. 5초에 한번씩 총 6회 재시도..."
  sleep 5
done

echo -e "# 4. Nginx Reverse Proxy Port 전환을 시작합니다."

echo "> ${NGINX_SERVICE_FILE_PATH_NAME}에 전환할 Port ( ${IDLE_PORT} )를 Injection 합니다."

echo "set \$service_url http://127.0.0.1:${IDLE_PORT};" |sudo tee ${NGINX_SERVICE_FILE_PATH_NAME}

echo "> Nginx reload를 시도합니다."

output=$( sudo service nginx reload )

reload_code=$?

if [[ ${reload_code} -eq 0 ]]; then
  echo "Nginx reload 성공"
else
  echo "[실패 또는 긴급 오류] Nginx가 정상적인 상태가 아닙니다. Nginx의 오류를 확인해야 하고 조치를 취해야 합니다."
  exit 1
fi


echo -e "# 5. 7초 후에 Port 전환이 성공적으로 이루어졌는지 확인합니다."

sleep 7

echo "> 전환된 Port 확인"

for retry_count in {1..10}
do
  response=$(curl -k -s $(curl -Ls -o /dev/null -w %{url_effective} http://127.0.0.1:${PROJECT_PORT}/localPort))
  idle_port_count=$(echo ${response} | egrep '^[\n\r\t\s]*'${IDLE_PORT}'[\n\r\t\s]*$' | wc -l)

  if [[ ${idle_port_count} -ge 1 ]]
  then
       echo "> 성공. 전환된 포트가 목표 수정 포트와 일치"

      break
  else
      echo "> 전환된 포트가 ${IDLE_PORT}가 아닙니다."
      echo "> 서버 리턴 값 : ${response}"
  fi

  if [[ ${retry_count} -eq 9 ]]
  then
    echo "[실패] 목표 수정 포트로의 전환에 실패하였을 수 있습니다. 이는 상기 명령어 또는 Nginx 네트워크 설정에 문제가 있을 경우 발생할 수 있습니다. 또한 Nginx -t 로도 발견되지 않는 오류도 있을 수 있습니다."
    exit 1
  fi

  echo "> localPort 5초에 한번씩 총 9회 재시도..."
  sleep 5
done


echo -e "# 6. 7초 후 최종 process 유효성 검사 및 미사용 중인 Port를 확인하고 종료하여 메모리를 확보합니다."

sleep 7

if lsof -t -i tcp:${CURRENT_PORT};
then
    if lsof -t -i tcp:${IDLE_PORT};
    then

      if ps -ef | egrep ${SERVER_IMAGE_NAME_PATTERN}.+${CURRENT_PORT} && ps -ef | egrep ${SERVER_IMAGE_NAME_PATTERN}.+${IDLE_PORT};
      then
          echo "최종 process 유효성 검사를 통과하였습니다."

          echo "기존의 Port 를 점유하고 있는 process 를 종료합니다."
          sudo kill -15 $(lsof -t -i tcp:${CURRENT_PORT})

          echo "[성공] ${CURRENT_PORT}를 종료하고 ${IDLE_PORT}로 실행되었습니다."
      else
          echo "[실패] 최종 process 유효성 검사에 실패하였습니다. 서버 상태를 확인하십시오."
          exit 1
      fi
    else
      echo "[실패] 배포에 실패하였습니다. 기존 배포를 유지합니다."
      exit 1
    fi
else
    if lsof -t -i tcp:${IDLE_PORT};
    then

      if ps -ef | egrep ${SERVER_IMAGE_NAME_PATTERN}.+${IDLE_PORT};
      then
          echo "최종 process 유효성 검사를 통과하였습니다."
          echo "[성공] 종료할 Port가 없고, ${IDLE_PORT}로 실행되었습니다."
      else
          echo "[실패] 최종 process 유효성 검사에 실패하였습니다. 서버 상태를 확인하십시오."
          exit 1
      fi

    else
      echo "[긴급 오류] 실행 중인 포트가 없습니다. 즉시 재배포 하십시오."
      exit 1
    fi
fi