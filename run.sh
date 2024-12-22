#!/bin/bash
# set -e: This option tells the script to exit immediately if any command returns a non-zero status (i.e., if a command fails). This prevents the script from continuing execution when an error occurs, making it easier to catch issues early.
# set -u: This option causes the script to throw an error and stop if it tries to use an undefined variable. This helps catch typos or missing variable definitions that could lead to unexpected behavior.
set -eu

source use-common.sh

display_checkpoint_message "Checking versions for supporting libraries...(1%)"

check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_yq_installed
check_git_docker_compose_commands_exist


sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
sudo bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 1

source ./use-app.sh
source ./use-nginx.sh


# Back-up priority : new > blue or green > latest
backup_app_to_previous_images(){
  # App
  echo "[NOTICE] Docker tag 'previous' 'previous2'"
  docker tag ${project_name}:previous ${project_name}:previous2 || echo "[NOTICE] the 'previous' image does NOT exist."

  if [[ $(docker images -q ${project_name}:new 2> /dev/null) != '' ]]
  then

      echo "[NOTICE] Docker tag 'new' 'previous'"
      docker tag ${project_name}:new ${project_name}:previous && return  || echo "[NOTICE] There is no 'new' tag image to backup the app."
  fi

  echo "[NOTICE] Since there is no 'new' tag image for the app, depending on 'cache_all_states' previously run in the 'cache_global_vars' stage, we will back ${state} up."
  docker tag ${project_name}:${state} ${project_name}:previous && return || echo "[NOTICE] No ${state} tagged image."

  echo "[NOTICE] Since there is no ${state} images, we will attempt to back up the latest image as previous"
  docker tag ${project_name}:latest ${project_name}:previous || echo "[NOTICE] No 'latest' tagged image."

}

backup_nginx_to_previous_images(){
  # NGINX
  echo "[NOTICE] Before creating the 'previous' tagged image of Nginx, if there is an existing 'previous' tagged image, we will proceed with backing it up as the 'previous2' tagged image."
  docker tag ${project_name}-nginx:previous ${project_name}-nginx:previous2 || echo "[NOTICE] No 'previous' tagged image."

  if [[ $(docker images -q ${project_name}-nginx:new 2> /dev/null) != '' ]]
  then

    echo "[NOTICE] Docker tag 'new' 'previous' (NGINX)"
    docker tag ${project_name}-nginx:new ${project_name}-nginx:previous && return || echo "[NOTICE] No Nginx 'new' tagged image."

  fi

  echo "[NOTICE] Since there is no existing Nginx 'new' image, we will attempt to back up the latest image as 'previous'."
  docker tag ${project_name}-nginx:latest ${project_name}-nginx:previous || echo "[NOTICE] No Nginx 'latest' tagged image."

}

terminate_whole_system(){
  if [[ ${docker_layer_corruption_recovery} == true ]]; then
    docker rmi -f ${project_name}-nginx:latest
    docker rmi -f ${project_name}-nginx:new
    docker rmi -f ${project_name}-nginx:previous
    docker rmi -f ${project_name}-nginx:previous2

    docker rmi -f ${project_name}:latest
    docker rmi -f ${project_name}:new
    docker rmi -f ${project_name}:previous
    docker rmi -f ${project_name}:previous2
    docker rmi -f ${project_name}:blue
    docker rmi -f ${project_name}:green

    docker-compose -f docker-${orchestration_type}-${project_name}.yml down || echo "[NOTICE] docker-${orchestration_type}-${project_name}.yml down failure"
    docker-compose -f docker-${orchestration_type}-${project_name}.yml down || echo "[NOTICE] docker-${orchestration_type}-${project_name}.yml down failure"
    docker-compose -f docker-orchestration-${project_name}-nginx.yml down || echo "[NOTICE] docker-orchestration-${project_name}-nginx.yml down failure"

    docker network rm dbgr-net || echo "[NOTICE] dbgr-net has already been removed."

    docker system prune -f
  fi
}


load_all_containers(){
  # app, nginx
  # In the past, restarting Nginx before App caused error messages like "upstream not found" in the Nginx configuration file. This seems to have caused a 502 error on the socket side.

  echo "[NOTICE] Creating dbgr-net network..."
  if [[ ${orchestration_type} != 'stack' ]]; then
   docker network create dbgr-net || echo "[NOTICE] DBGR Network has already been created. You can ignore this message."
  else
      docker network create --driver overlay dbgr-net || echo "[NOTICE] DBGR Network has already been created. You can ignore this message."
  fi

  # Therefore, it is safer to restart the containers in the order of App -> Nginx.

  echo "[NOTICE] Run the app as a ${new_state} container. (As long as NGINX_RESTART is set to 'false', this won't stop the running container since this is a BLUE-GREEN deployment.)"
  app_down_and_up


  echo "[NOTICE] Check the integrity inside the '${project_name}-${new_state} container'."
  re=$(check_availability_inside_container ${new_state} 120 5 | tail -n 1) || exit 1;

  if [[ ${re} != 'true' ]]; then
    echo "[ERROR] Failed in running the ${new_state} container. Run ' docker logs -f ${project_name}-${new_state} (compose), docker service ps ${project_name}-${new_state}_${project_name}-${new_state} (stack) ' to check errors (Return : ${re})" && exit 1
  fi


  if [[ ${nginx_restart} == 'true' ]]; then
      check_nginx_templates_integrity
      nginx_down_and_up
  else
      echo "[NOTICE] As NGINX_RESTART in .env is NOT 'true' (NGINX_RESTART : ${nginx_restart}), there will be NO downtime, which becomes 'zero-downtime'."
  fi

  check_edge_routing_containers_loaded || (echo "[ERROR] Failed in loading necessary supporting containers." && exit 1)

}


backup_to_new_images(){

    echo "[NOTICE] docker tag latest new"
    docker tag ${project_name}:latest ${project_name}:new || echo "[NOTICE] the ${project_name}:latest image does NOT exist."
    echo "[NOTICE] docker tag latest new (NGINX)"
    docker tag ${project_name}-nginx:latest ${project_name}-nginx:new || echo "[NOTICE] ${project_name}-nginx:latest does NOT exist."
}


_main() {

  display_checkpoint_message "Initializing mandatory variables... (2%)"

  cache_global_vars
  # The 'cache_all_states' in 'cache_global_vars' function decides which state should be deployed. If this is called later at a point in this script, states could differ.
  local initially_cached_old_state=${state}
  check_env_integrity

  display_checkpoint_message "Deployment target between Blue and Green has been decided... (3%)"
  display_planned_transition "$initially_cached_old_state" "$new_state"
  sleep 2

  if [[ "${git_image_load_from}" == "build" && -n "${project_git_sha}" && -n "${docker_build_sha_insert_git_root}" ]]; then
      commit_message=$(get_commit_message "$project_git_sha" "$docker_build_sha_insert_git_root")
      display_checkpoint_message "Will build this GIT version: $project_git_sha : $commit_message"
      sleep 1
  fi

  ## App
  display_checkpoint_message "Setting up the app configuration 'yml' for orchestration type: ${orchestration_type}... (6%)"
  initiate_docker_compose_file
  apply_env_service_name_onto_app_yaml
  apply_docker_compose_environment_onto_app_yaml
  apply_docker_compose_volumes_onto_app_yaml
  if [[ ${skip_building_app_image} != 'true' ]]; then
    backup_app_to_previous_images
  fi


  ## Nginx
  if [[ ${nginx_restart} == 'true' ]]; then

    display_checkpoint_message "Since 'nginx_restart' is set to 'true', configuring the Nginx 'yml' for orchestration type: ${orchestration_type}... (7%)"

    initiate_nginx_docker_compose_file
    apply_env_service_name_onto_nginx_yaml
    apply_ports_onto_nginx_yaml
    apply_docker_compose_volumes_onto_app_nginx_yaml

    save_nginx_prepared_template_from_origin
    save_nginx_logrotate_template_from_origin
    save_nginx_main_template_from_origin

    backup_nginx_to_previous_images
  fi


  display_checkpoint_message "Performing additional steps before building images... (10%)"

  # Set 'Shared Volume Group'
  # Detect the platform (Linux or Mac)
  if [[ "$(uname)" == "Darwin" ]]; then
      echo "[NOTICE] Running on Mac. Skipping 'add_host_users_to_host_group' as dscl is used for user and group management."
  else
    local add_host_users_to_shared_volume_group_re=$(add_host_users_to_host_group ${shared_volume_group_id} ${shared_volume_group_name} ${uids_belonging_to_shared_volume_group_id} | tail -n 1) || echo "[WARNING] Running 'add_host_users_to_shared_volume_group' failed.";
    if [[ ${add_host_users_to_shared_volume_group_re} = 'false' ]]; then
      echo "[WARNING] Running 'add_host_users_to_host_group'(SHARED) failed."
    fi
  fi

  # Etc.
  if [[ ${docker_layer_corruption_recovery} == 'true' ]]; then
    terminate_whole_system
  fi



  if [[ ${skip_building_app_image} != 'true' ]]; then
      display_checkpoint_message "Building Docker image for the app... ('skip_building_app_image' is set to false) (12%)"
      load_app_docker_image
  fi

  if [[ ${nginx_restart} == 'true' ]]; then
      display_checkpoint_message "Building Docker image for Nginx... ('nginx_restart' is set to true) (16%)"
      load_nginx_docker_image
  fi


  if [[ ${only_building_app_image} == 'true' ]]; then
    echo "[NOTICE] Successfully built the App image : ${new_state}" && exit 0
  fi


  local cached_new_state=${new_state}
  cache_all_states
  if [[ ${cached_new_state} != "${new_state}" ]]; then
    (echo "[ERROR] Just checked all states shortly after the Docker Images had been done built. The state the App was supposed to be deployed as has been changed. (Original : ${cached_new_state}, New : ${new_state}). For the safety, we exit..." && exit 1)
  fi

  # docker-compose up the App, Nginx & * Internal Integrity Check for the App
  display_checkpoint_message "Starting docker-compose for App and Nginx, followed by an internal integrity check for the app... (40%)"
  load_all_containers


  display_checkpoint_message "Reached the transition point... (65%)"
  display_immediate_transition ${state} ${new_state}
  ./nginx-blue-green-activate.sh ${new_state} ${state} ${new_upstream}

  # [E] External Integrity Check, if fails, 'emergency-nginx-down-and-up.sh' will be run.
  display_checkpoint_message "Performing external integrity check. If it fails, 'emergency-nginx-down-and-up.sh' will be executed... (87%)"
  re=$(check_availability_out_of_container | tail -n 1);
  if [[ ${re} != 'true' ]]; then

    display_checkpoint_message "[WARNING] ! ${new_state}'s availability issue found. Now we are going to run 'emergency-nginx-down-and-up.sh' immediately."
    bash emergency-nginx-down-and-up.sh

    re=$(check_availability_out_of_container | tail -n 1);
    if [[ ${re} != 'true' ]]; then
      echo "[ERROR] Failed to call app_url on .env outside the container. Consider running bash rollback.sh OR check your !firewall. (result value : ${re})" && exit 1
    fi

  fi


  # [F] Finalizing the process : from this point on, regarded as "success".
  display_checkpoint_message "Finalizing the process. From this point, the deployment will be regarded as successful. (99%)"
  if [[ ${skip_building_app_image} != 'true' ]]; then
    backup_to_new_images
  fi

  echo "[DEBUG] state : ${state}, new_state : ${new_state}, initially_cached_old_state : ${initially_cached_old_state}"

  echo "[NOTICE] For safety, finally check Nginx pointing before stopping the previous container (${initially_cached_old_state})."

  local nginx_pointing
  nginx_pointing=$(get_nginx_pointing "$project_name")

  if [[ ${nginx_pointing} != ${initially_cached_old_state} ]]; then

    if [[ ${orchestration_type} != 'stack' ]]; then
      docker-compose -f docker-${orchestration_type}-${project_name}.yml stop ${project_name}-${initially_cached_old_state}
      echo "[NOTICE] The previous (${initially_cached_old_state}) container (initially_cached_old_state) has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
    else
       docker stack rm ${project_name}-${initially_cached_old_state}
       echo "[NOTICE] The previous (${initially_cached_old_state}) service (initially_cached_old_state) has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
    fi

    display_checkpoint_message "CURRENT APP_URL: ${app_url}."
    display_checkpoint_message "If this is your first time running the script, execute 'bash apply-security.sh' once."
    display_checkpoint_message "Run 'bash check-current-states.sh' to check the deployment status and Git SHA at any time."

    print_git_sha_and_message "${project_name}-${new_state}" "$docker_build_sha_insert_git_root"

    echo "[NOTICE] Delete <none>:<none> images."
    docker rmi $(docker images -f "dangling=true" -q) || echo "[NOTICE] Any images in use will not be deleted."

  else
    echo "[NOTICE] The previous (${initially_cached_old_state}) container (initially_cached_old_state) has NOT been stopped because the current Nginx Pointing is ${nginx_pointing}."
  fi

}

_main
