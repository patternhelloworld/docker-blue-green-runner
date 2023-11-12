#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -eu

cd ../../

sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

container=$(docker ps --format '{{.Names}}' | grep "spring-sample-h-auth-[bg]")
if [ -z "$container" ]; then
  echo "[NOTICE] There is NO spring-sample-h-auth container, now we will build it."
  cp -f .env.java.real .env
  sudo bash run.sh
else
  echo "[NOTICE] $container exists."
fi

sleep 3
source ./util.sh
source ./use-app.sh

cache_global_vars

consul_pointing=$(docker exec ${project_name}-nginx curl ${consul_key_value_store}?raw 2>/dev/null || echo "failed")
the_opposite_of_consul_pointing=''
if [[ ${consul_pointing} == 'blue' ]]; then
  the_opposite_of_consul_pointing='green'
else
  the_opposite_of_consul_pointing='blue'
fi

echo "[TEST][DEBUG] the_opposite_of_consul_pointing : ${the_opposite_of_consul_pointing}"

echo "[TEST][NOTICE] To make a Nginx error, get consul_pointing to the wrong(=NOT running) container"
bash emergency-nginx-down-and-up.sh ${the_opposite_of_consul_pointing} || echo ""
#echo "[TEST][NOTICE] Run 'emergency-nginx-down-and-up.sh'"
#bash emergency-nginx-down-and-up.sh

echo "[TEST][NOTICE] Run check_availability_out_of_container"
cache_global_vars
re=$(check_availability_out_of_container | tail -n 1);

if [[ ${re} != 'true' ]]; then
  echo "[TEST][NOTICE] : FAILURE"
else
  echo "[TEST][NOTICE] : SUCCESS"
fi