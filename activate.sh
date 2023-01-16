#!/usr/bin/env bash
set -eu
sudo sed -i -e "s/\r$//g" $(basename $0)

source ./util.sh

cache_global_vars

new_state=$1
old_state=$2
new_upstream=$3
key_value_store=$4

echo "[NOTICE] new_state : ${new_state}, old_state : ${old_state}, new_upstream : ${new_upstream}, key_value_store : ${key_value_store}"
was_state=$(docker exec ${project_name}-nginx curl ${key_value_store}?raw)
echo "[NOTICE] CONSUL (${key_value_store}) 이 현재 바라보고 있는 컨테이너 : ${was_state}"

# ${pid_was} != '-' 의 의미는 Nginx 가 완전히 띄어졌을 때 CONSUL 에 BLUE-GREEN 변경 작업을 진행한다는 의미이다.
echo "[NOTICE] Nginx 가 완전히 띄어졌는 지 확인합니다."
for retry_count in {1..5}; do
  pid_was=$(docker exec ${project_name}-nginx pidof nginx 2>/dev/null || echo '-')

  if [[ ${pid_was} != '-' ]]; then
    echo "[NOTICE] 정상적으로 띄어졌습니다."
    break
  else
    echo "[NOTICE] 정상적으로 띄어지지 않아서 재시도 합니다. (pid_was : ${pid_was})"

  fi

  if [[ ${retry_count} -eq 4 ]]; then
    echo "[ERROR] Nginx 가 완전히 띄어졌는 지 확인 재시도에 실패하여 기존의 상태를 유지하고 스크립트를 종료 합니다."
    exit 1
  fi

  echo "[NOTICE] 3초에 한번씩 총 4회 재시도... (${retry_count} 회 재시도 중...)"
  sleep 3
done

echo "[NOTICE] ${new_state} 의 CONSUL 활성화를 진행합니다. (old Nginx pids: ${pid_was})"
echo "[NOTICE] ${new_state} 를 CONSUL 에 저장합니다."
docker exec ${project_name}-nginx curl -X PUT -d ${new_state} ${key_value_store} >/dev/null

sleep 1

echo "[NOTICE] NGINX 의 PID 를 확인 하였습니다. 이제 NGINX 설정 파일에 CONSUL 이 ${new_upstream} 스트링으로 교체하였는지 확인합니다."
count=0
while [ 1 ]; do
  lines=$(docker exec ${project_name}-nginx nginx -T | grep ${new_state} | wc -l | xargs)
  if [[ ${lines} == '0' ]]; then
    count=$((count + 1))
    if [[ ${count} -eq 10 ]]; then
      echo "[WARNING] NGINX 설정 파일에 ${new_upstream} 스트링 없기 때문에, CONSUL 을 ${old_state} 로 돌려 놓습니다. (이미 ${old_state} 겠지만 확실하게 위해 다시 저장해 줍니다.)"
        ./reset.sh ${key_value_store} ${old_state} ${new_state}
      exit 1
    fi
    echo 'Wait for the new configuration'
    sleep 3
  else
    echo 'The new configuration was loaded'
    break
  fi
done
