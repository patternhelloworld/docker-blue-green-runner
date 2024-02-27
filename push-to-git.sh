#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -e

git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh

_main() {

  cache_global_vars

  local state_for_push=${state}


  echo "[NOTICE] Attempt to log in to the Registry."
  docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} ${git_image_load_from_host}

  echo "[NOTICE] Prepare current versions of the App,Nginx,Consul and Registrator and push them."

  echo "[DEBUG] Run : ${app_image_name_in_registry}"
  docker tag ${project_name}:${state_for_push} ${app_image_name_in_registry}
  echo "[DEBUG] Run : docker push ${git_image_load_from_host}/${git_image_load_from_pathname}"
  docker push ${app_image_name_in_registry}

  echo "[DEBUG] Run : ${nginx_image_name_in_registry}"
  docker tag ${project_name}-nginx:latest ${nginx_image_name_in_registry}
  echo "[DEBUG] Run : ${nginx_image_name_in_registry}"
  docker push ${nginx_image_name_in_registry}

  echo "[DEBUG] Run : ${consul_image_name_in_registry}"
  docker tag hashicorp/consul:1.14.11 ${consul_image_name_in_registry}
  echo "[DEBUG] Run : ${consul_image_name_in_registry}"
  docker push ${consul_image_name_in_registry}

  echo "[DEBUG] Run : ${registrator_image_name_in_registry}"
  docker tag gliderlabs/registrator:v7 ${registrator_image_name_in_registry}
  echo "[DEBUG] Run : ${registrator_image_name_in_registry}"
  docker push ${registrator_image_name_in_registry}

}

_main