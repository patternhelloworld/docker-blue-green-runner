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

# To load
cache_global_vars

# Eventually, it will be activated as 'state_a' in ./activate.sh, and unless specifically specified parameters as below,
# Nginx should be reconfigured with the existing state.
state_a=${state}
state_b=${state}
if [[ ! -z ${1:-} ]] && ([[ ${1} == "blue" ]] || [[ ${1} == "green" ]]); then
    echo "[DEBUG] state_a : ${1}"
    state_a=${1}
fi

if [[ ${protocol} = 'https' ]]; then
  state_a_upstream=$(concat_safe_port "https://${project_name}-${state_a}")
else
  state_a_upstream=$(concat_safe_port "http://${project_name}-${state_a}")
fi

nginx_restart(){

   echo "[NOTICE] Re-Run NGINX as a container."
   PROJECT_NAME=${project_name} docker-compose -f docker-compose-nginx.yml up -d ${project_name}-nginx || echo "[ERROR] Critical - ${project_name}-nginx UP failure"

   ./activate.sh ${state_a} ${state_b} ${state_a_upstream} ${consul_key_value_store}
}

nginx_restart