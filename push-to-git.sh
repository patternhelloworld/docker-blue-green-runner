#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -e

git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh

_main() {

  cache_global_vars

  local state_for_push=${state}

  git_image_push_to_host=$(get_value_from_env "GIT_IMAGE_PUSH_TO_HOST")
  git_image_push_to_pathname=$(get_value_from_env "GIT_IMAGE_PUSH_TO_PATHNAME")
  git_token_image_push_to_username=$(get_value_from_env "GIT_TOKEN_IMAGE_PUSH_TO_USERNAME")
  git_token_image_push_to_password=$(get_value_from_env "GIT_TOKEN_IMAGE_PUSH_TO_PASSWORD")


  echo "[NOTICE] Attempt to log in to the Registry."
  docker_login_with_params ${git_token_image_push_to_username} ${git_token_image_push_to_password} ${git_image_push_to_host}

  echo "[NOTICE] Prepare current versions of the App and Nginx and push them."

  echo "[DEBUG] Run : docker tag ${project_name}:${state_for_push} ${git_image_push_to_host}/${git_image_push_to_pathname}"
  docker tag ${project_name}:${state_for_push} ${git_image_push_to_host}/${git_image_push_to_pathname}/app
  echo "[DEBUG] Run : docker push ${git_image_push_to_host}/${git_image_push_to_pathname}"
  docker push ${git_image_push_to_host}/${git_image_push_to_pathname}

  echo "[DEBUG] Run : docker tag ${project_name}-nginx:latest ${git_image_push_to_host}/${git_image_push_to_pathname}/nginx"
  docker tag ${project_name}-nginx:latest ${git_image_push_to_host}/${git_image_push_to_pathname}/nginx
  echo "[DEBUG] Run : docker push ${git_image_push_to_host}/${git_image_push_to_pathname}/nginx}"
  docker push ${git_image_push_to_host}/${git_image_push_to_pathname}/nginx

}

_main