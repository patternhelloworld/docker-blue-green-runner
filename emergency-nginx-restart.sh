#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -eu

sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 3
source ./util.sh


cache_global_vars

state_a=${state}
state_b=${state}
if [[ ! -z ${1:-} ]] && ([[ ${1} == "blue" ]] || [[ ${1} == "green" ]]); then
    echo "[DEBUG] state_b : ${1}"
    state_b=${1}
fi

nginx_restart(){

   echo "[NOTICE] Re-Run NGINX as a container."
   PROJECT_NAME=${project_name} docker-compose -f docker-compose-nginx.yml up -d ${project_name}-nginx || echo "[ERROR] Critical - ${project_name}-nginx UP failure"

   ./activate.sh ${state_a} ${state_b} ${new_upstream} ${consul_key_value_store}
}

nginx_restart