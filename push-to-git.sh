#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -e

git config apply.whitespace nowarn
git config core.filemode false

source use-common.sh

_main() {

  cache_global_vars

  local state_for_push=${state}

  echo "[IMPORTANT][NOTICE] we will push the image of !!'${state}'!! currently running to the Gitlab Container Registry."

  echo "[NOTICE] Log in to the Gitlab Container Registry."
  docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} ${git_image_load_from_host}

  echo "[NOTICE] Prepare current versions of the App,Nginx,Consul and Registrator and push them."

  echo "[DEBUG] Run : docker tag ${project_name}:${state_for_push} ${app_image_name_in_registry}"
  docker tag ${project_name}:${state_for_push} ${app_image_name_in_registry} || exit 1
  echo "[DEBUG] Run : docker push ${app_image_name_in_registry}"
  docker push ${app_image_name_in_registry}  || exit 1
  echo "[DEBUG] Run : docker rmi -f ${app_image_name_in_registry}"
  docker rmi ${app_image_name_in_registry}  || exit 1

  echo "[DEBUG] Run : docker tag ${project_name}-nginx:latest ${nginx_image_name_in_registry}"
  docker tag ${project_name}-nginx:latest ${nginx_image_name_in_registry}  || exit 1
  echo "[DEBUG] Run : docker push ${nginx_image_name_in_registry}"
  docker push ${nginx_image_name_in_registry}  || exit 1
  echo "[DEBUG] Run : docker rmi -f ${nginx_image_name_in_registry}"
  docker rmi ${nginx_image_name_in_registry}  || exit 1
  


  echo "[DEBUG] Run : docker tag hashicorp/consul:1.14.11 ${consul_image_name_in_registry}}"
  docker tag hashicorp/consul:1.14.11 ${consul_image_name_in_registry}  || exit 1
  echo "[DEBUG] Run : docker push ${consul_image_name_in_registry}"
  docker push ${consul_image_name_in_registry}  || exit 1
  echo "[DEBUG] Run : docker rmi -f ${consul_image_name_in_registry}"
  docker rmi ${consul_image_name_in_registry}  || exit 1

  echo "[DEBUG] Run : docker tag gliderlabs/registrator:v7 ${registrator_image_name_in_registry}"
  docker tag gliderlabs/registrator:v7 ${registrator_image_name_in_registry}  || exit 1
  echo "[DEBUG] Run : docker push ${registrator_image_name_in_registry}"
  docker push ${registrator_image_name_in_registry}  || exit 1
  echo "[DEBUG] Run : docker rmi -f ${registrator_image_name_in_registry}"
  docker rmi ${registrator_image_name_in_registry}  || exit 1

}

_main