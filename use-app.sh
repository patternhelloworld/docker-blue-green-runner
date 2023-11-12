#!/bin/bash
set -eu

git config apply.whitespace nowarn
git config core.filemode false


initiate_docker_compose_file(){

    if [[ ${use_my_own_app_yml} == true ]]; then
      if [[ ${orchestration_type} == 'stack' ]]; then
         echo "[NOTICE] As USE_MY_OWN_APP_YML is set 'true', we will use your customized 'docker-${orchestration_type}-${project_name}-${app_env}-original-${new_state}-ready.yml'"
         cp -f docker-${orchestration_type}-${project_name}-${app_env}-original-${new_state}-ready.yml docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to copy docker-${orchestration_type}-${project_name}-${app_env}-original-ready.yml" && exit 1)
         echo "[DEBUG] successfully copied docker-${orchestration_type}-${project_name}-${app_env}-original-${new_state}-ready.yml"
      else
         echo "[NOTICE] As USE_MY_OWN_APP_YML is set 'true', we will use your customized 'docker-${orchestration_type}-${project_name}-${app_env}-original-ready.yml'"
         cp -f docker-${orchestration_type}-${project_name}-${app_env}-original-ready.yml docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to copy docker-${orchestration_type}-${project_name}-${app_env}-original-ready.yml" && exit 1)
         echo "[DEBUG] successfully copied docker-${orchestration_type}-${project_name}-${app_env}-original-ready.yml"
      fi
    else
      if [[ ${orchestration_type} == 'stack' ]]; then
         cp -f docker-${orchestration_type}-app-${app_env}-original-${new_state}.yml docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to copy docker-${orchestration_type}-app-${app_env}-original.yml" && exit 1)
      else
        cp -f docker-${orchestration_type}-app-${app_env}-original.yml docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to copy docker-${orchestration_type}-app-${app_env}-original.yml" && exit 1)
      fi
      echo "[DEBUG] successfully copied docker-${orchestration_type}-app-${app_env}-original.yml"
    fi


    sleep 1
}

apply_env_service_name_onto_app_yaml(){

  check_yq_installed

  if [[ ${orchestration_type} == 'stack' ]]; then
      yq -i "with(.services; with_entries(select(.key ==\"*-${new_state}\") | .key |= \"${project_name}-${new_state}\"))" docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to apply the green service name in the app YAML as ${project_name}." && exit 1)
     # yq eval '(.services.[] | select(.image == "${PROJECT_NAME}:blue")).image |= \"${project_name}-blue\"' -i docker-${orchestration_type}-${project_name}-blue.yml  || (echo "[ERROR] Failed to apply image : ${project_name}-blue in the app YAML." && exit 1)
      yq -i "(.services.\"${project_name}-${new_state}\").image = \"${project_name}:${new_state}\"" -i docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to apply image : ${project_name}-${new_state} in the app YAML." && exit 1)
  else
      echo "[NOTICE] PROJECT_NAME on .env is now being applied to docker-${orchestration_type}-${project_name}-${app_env}.yml."
      yq -i "with(.services; with_entries(select(.key ==\"*-blue\") | .key |= \"${project_name}-blue\"))" docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to apply the blue service name in the app YAML as ${project_name}." && exit 1)
      sleep 2
      yq -i "with(.services; with_entries(select(.key ==\"*-green\") | .key |= \"${project_name}-green\"))" docker-${orchestration_type}-${project_name}-${app_env}.yml || (echo "[ERROR] Failed to apply the green service name in the app YAML as ${project_name}." && exit 1)
  fi

}

apply_docker_compose_environment_onto_app_yaml(){

   check_yq_installed

   echo "[NOTICE] DOCKER_COMPOSE_ENVIRONMENT on .env is now being applied to docker-${orchestration_type}-${project_name}-${app_env}.yml."

   if [[ ${orchestration_type} == 'stack' ]]; then
    local states=("${new_state}")
   else
    local states=("blue" "green")
   fi

   for state in "${states[@]}"
   do
       yq -i '.services.'${project_name}'-'${state}'.environment = []' docker-${orchestration_type}-${project_name}-${app_env}.yml
       yq -i '.services.'${project_name}'-'${state}'.environment += "SERVICE_NAME='${state}'"' docker-${orchestration_type}-${project_name}-${app_env}.yml

       for ((i=1; i<=$(echo ${docker_compose_environment} | yq eval 'length'); i++))
        do
           yq -i '.services.'${project_name}'-'${state}'.environment += "'$(echo ${docker_compose_environment} | yq -r 'to_entries | .['$((i-1))'].key')'='$(echo ${docker_compose_environment} | yq -r 'to_entries | .['$((i-1))'].value')'"' docker-${orchestration_type}-${project_name}-${app_env}.yml
        done
   done

}

apply_docker_compose_volumes_onto_app_real_yaml(){

   check_yq_installed

   echo "[NOTICE] DOCKER_COMPOSE_REAL_SELECTIVE_VOLUMES on .env is now being applied to docker-${orchestration_type}-${project_name}-real.yml."

   if [[ ${orchestration_type} == 'stack' ]]; then
    local states=("${new_state}")
   else
    local states=("blue" "green")
   fi

   for state in "${states[@]}"
   do
       #yq -i '.services.'${project_name}'-'${state}'.volumes = []' ./docker-${orchestration_type}-${project_name}-real.yml

      for volume in "${docker_compose_real_selective_volumes[@]}"
      do
          yq -i '.services.'${project_name}'-'${state}'.volumes += '${volume}'' ./docker-${orchestration_type}-${project_name}-real.yml
      done
   done

}

make_docker_build_arg_strings(){

   check_yq_installed

   echo "[NOTICE] make_docker_build_arg_strings for the 'docker build command'." >&2

   local re=""

   for ((i=1; i<=$(echo ${docker_build_args} | yq eval 'length'); i++))
   do
       re="${re} --build-arg $(echo ${docker_build_args} | yq -r 'to_entries | .['$((i-1))'].key')=$(echo ${docker_build_args} | yq -r 'to_entries | .['$((i-1))'].value')"
   done

   echo ${re}
   return
}

# Image name: ${project_name} (utilizing 4 tags for Blue-Green deployment: ${project_name}:latest, ${project_name}:previous, ${project_name}:blue, ${project_name}:green)
load_app_docker_image() {

  if [ ${git_image_load_from} = "registry" ]; then

    echo "[NOTICE] Attempt to log in to the Registry."
    docker_login_with_params ${git_token_image_load_from_username} ${git_token_image_load_from_password} ${git_image_load_from_hostname}:5050/${git_image_load_from_pathname}

    echo "[NOTICE] Pull the app image stored in the Registry."
    docker pull ${load_from_registry_image_with_env}-app-${app_version}|| exit 1
    docker tag ${load_from_registry_image_with_env}-app-${app_version} ${project_name}:latest || exit 1
    docker rmi -f ${load_from_registry_image_with_env}-app-${app_version}|| exit 1
  else


    echo "[NOTICE] Build the image with ${docker_file_location}/${docker_file_name} (using cache)"
    local env_build_args=$(make_docker_build_arg_strings)
    echo "[NOTICE] DOCKER_BUILD_ARGS on the .env : ${env_build_args}"

    if [[ ${docker_layer_corruption_recovery} == true ]]; then
       echo "[NOTICE] Docker Build Command : docker build --no-cache --tag ${project_name}:latest --build-arg server="${app_env}" ${env_build_args} -f ${docker_file_name} -m ${docker_build_memory_usage} ."
       cd ${docker_file_location} && docker build --no-cache --tag ${project_name}:latest --build-arg server="${app_env}" ${env_build_args} -f ${docker_file_name} -m ${docker_build_memory_usage} . || exit 1
       cd -
    else
       echo "[NOTICE] Docker Build Command : docker build --build-arg DISABLE_CACHE=${CUR_TIME} --tag ${project_name}:latest --build-arg server="${app_env}" --build-arg HOST_IP="${HOST_IP}" ${env_build_args} -f ${docker_file_name} -m ${docker_build_memory_usage} ."
       cd ${docker_file_location} && docker build --build-arg DISABLE_CACHE=${CUR_TIME} --tag ${project_name}:latest --build-arg server="${app_env}" --build-arg HOST_IP="${HOST_IP}" ${env_build_args} -f ${docker_file_name} -m ${docker_build_memory_usage} . || exit 1
       cd -
    fi

  fi

  if [[ $(docker images -q ${project_name}:previous 2> /dev/null) == '' ]]
  then
     docker tag ${project_name}:latest ${project_name}:previous
  fi

  docker tag ${project_name}:latest ${project_name}:blue
  docker tag ${project_name}:latest ${project_name}:green
}

app_down_and_up(){

    if [[ ${orchestration_type} == 'stack' ]]; then
      echo "[NOTICE] Down & Up '${project_name}-${new_state} stack'."
      docker stack rm ${project_name}-${new_state} || echo "[NOTICE] The ${project_name}-${new_state} stack has been removed, if exists."
      docker stack deploy --compose-file docker-${orchestration_type}-${project_name}-${app_env}.yml ${project_name}-${new_state} || (echo "[ERROR] Service ${new_state} UP failure, however that does NOT affect the current deployment, as this is Blue-Green Deployment. (command : docker stack deploy --compose-file docker-${orchestration_type}-${project_name}-${app_env}.yml ${project_name})" && exit 1)

      # [TO DO] docker stack takes a long time to be up. it needs to use a good logic instead of sleep.
      sleep 20

    else
      echo "[NOTICE] Down & Up '${project_name}-${new_state} container'."
      docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml stop ${project_name}-${new_state} || echo "[NOTICE] The previous ${new_state} Container has been stopped, if exists."
      docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml rm -f ${project_name}-${new_state} || echo "[NOTICE] The previous ${new_state} Container has been removed, if exists."
      docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml up -d ${project_name}-${new_state} || (echo "[ERROR] App ${new_state} UP failure, however that does NOT affect the current deployment, as this is Blue-Green Deployment." && exit 1)
      echo "[NOTICE] '${project_name}-${new_state} container' : successfully UP."
    fi

}




# shellcheck disable=SC2120
check_availability_inside_container(){

  echo "[DEBUG] check_availability_inside_container"  >&2

  check_state=${1}

  if [[ -z ${check_state} ]]
    then
      echo "[ERROR] the 'state' NOT indicated on check_availability_inside_container "  >&2
      echo "false"
      return
  fi

  if [[ -z ${2} ]]
    then
      echo "[ERROR] there is no wait-for-it.sh timeout parameter."  >&2
      echo "false"
      return
  fi

  if [[ -z ${3} ]]
    then
      echo "[ERROR] there is no Health Check timeout parameter."  >&2
      echo "false"
      return
  fi

  local container_name=
  if [[ ${orchestration_type} == 'stack' ]]; then

    container_name=$(docker ps -q --filter "name=^${project_name}-${check_state}" | shuf -n 1);

    if [[ -z ${container_name} ]]; then
      echo "[ERROR] Any container is NOT checked in the ${project_name}-${check_state}_${project_name}-${check_state} service. (container name : ${container_name}, command : docker ps -q --filter "name=^${project_name}-${check_state}" | shuf -n 1)"  >&2 && echo "false" && return
    fi

  else
    container_name=${project_name}-${check_state}
  fi

  if [[ $(check_command_in_container_or_fail ${container_name} "curl") != "true" ]]; then
         echo "false"
         return
  fi

  if [[ $(check_command_in_container_or_fail ${container_name} "bash") != "true" ]]; then
          echo "false"
          return
  fi


  echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] Copy wait-for-it.sh into ${container_name}:${project_location}/wait-for-it.sh."  >&2
  docker cp ./wait-for-it.sh ${container_name}:${project_location}/wait-for-it.sh || (echo "[ERROR] Failed in copying (HOST : ./wait-for-it.sh) to (CONTAINER : ${project_location}/wait-for-it.sh)" >&2 &&  echo "false" && return)


  echo "[NOTICE] Check if the web server is responding by making a request inside the container (Name : ${container_name}). If library folders such as node_modules (Node.js), vendor (PHP) folders are NOT yet installed, the execution time of the ENTRYSCRIPT of your Dockerfile may be longer than usual (timeout: ${2} seconds)"  >&2


  # 1) APP is ON

  container_load_timeout=${2}

  echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] In the ${container_name}  Container, conduct the Connection Check (localhost:${app_port} --timeout=${2}). (If this is delayed, run ' docker logs -f ${container_name} (compose), docker service ps ${project_name}-${check_state}_${project_name}-${check_state} (stack) ' to check the status."   >&2
  echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] Current status (inside Container) : \n $(docker logs ${container_name})"   >&2
  local wait_for_it_re=$(docker exec -w ${project_location} ${container_name} ./wait-for-it.sh localhost:${app_port} --timeout=${2}) || (echo "[ERROR] Failed in running (CONTAINER : ${project_location}/wait-for-it.sh)" >&2 &&  echo "false" && return)
  if [[ $? != 0 ]]; then
      echo "[ERROR] Failed in getting the correct return from wait-for-it.sh. (${wait_for_it_re})" >&2
      echo "false"
      return
  else
      # 2) APP's health check
      echo "[NOTICE] [Internal Integrity Check : will deploy ${check_state}] In the ${container_name}  Container, conduct the Health Check."  >&2
      sleep 1

      local interval_sec=5

      local total_cnt=$((${container_load_timeout}/${interval_sec}))

      if [[ $((container_load_timeout%interval_sec)) != 0 ]]; then
        total_cnt=$((${total_cnt}+1))
      fi

      for (( retry_count = 1; retry_count <= ${total_cnt}; retry_count++ ))
      do
        echo "[NOTICE] ${retry_count} round health check (curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path})... (timeout : ${3} sec)"  >&2
        response=$(docker exec ${container_name} sh -c "curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path} --connect-timeout ${3}")

        down_count=$(echo ${response} | egrep -i ${bad_app_health_check_pattern} | wc -l)
        up_count=$(echo ${response} | egrep -i ${good_app_health_check_pattern} | wc -l)

        if [[ ${down_count} -ge 1 || ${up_count} -lt 1 ]]
        then

            echo "[WARNING] Unable to determine the response of the health check or the status is not UP. (*Response : ${response}), (${container_name}, *Log (print max 25 lines) : $(docker logs --tail 25 ${container_name})"  >&2

        else
             echo "[NOTICE] Internal health check of the application succeeded. (*Response: ${response})"  >&2
             break
        fi

        if [[ ${retry_count} -eq ${total_cnt} ]]
        then
          echo "[FAILURE] Health check failed in the end. (*Response:  ${response})" >&2
          echo "false"
          return
        fi

        echo "[NOTICE] ${retry_count}/${total_cnt} round Health Check failure. Retrying in ${interval_sec} secs..."  >&2
        for (( i = 1; i <= ${interval_sec}; i++ ));do echo -n "$i." >&2 && sleep 1; done
        echo "\n"  >&2

      done

     echo "true"
     return
 fi
}

check_availability_inside_container_speed_mode(){

  echo "[DEBUG] check_availability_inside_container_speed_mode"  >&2


  check_state=${1}

  if [[ -z ${1} ]]
    then
      echo "[ERROR] [Blue OR Green Alive Check : Currently ${check_state}] the 'state' NOT indicated on check_availability_inside_container "  >&2
      echo "false"
      return
  fi

  if [[ -z ${2} ]]
    then
      echo "[ERROR] [Blue OR Green Alive Check : Currently ${check_state}] there is no wait-for-it.sh timeout parameter."  >&2
      echo "false"
      return
  fi

  if [[ -z ${3} ]]
    then
      echo "[ERROR] [Blue OR Green Alive Check : Currently ${check_state}] there is no Health Check timeout parameter."  >&2
      echo "false"
      return
  fi

  local container_name=
  if [[ ${orchestration_type} == 'stack' ]]; then
    container_name=$(docker ps -q --filter "name=^${project_name}-${check_state}" | shuf -n 1);

    if [[ -z ${container_name} ]]; then
      echo "[ERROR] Any container is NOT checked in the ${project_name}-${check_state}_${project_name}-${check_state} service."  >&2 && echo "false" && return
    fi
  else
    container_name=${project_name}-${check_state}
  fi


  echo "[NOTICE] [Blue OR Green Alive Check : Currently checking ${check_state}] Copy wait-for-it.sh into ${container_name}:${project_location}/wait-for-it.sh."  >&2
  docker cp ./wait-for-it.sh ${container_name}:${project_location}/wait-for-it.sh


  #echo "[NOTICE] ${container_name} Check if the web server is responding by making a request inside the node-express-boilerplate-green container. If library folders such as node_modules (Node.js), vendor (PHP) folders are NOT yet installed, the execution time of the ENTRYSCRIPT of your Dockerfile may be longer than usual (timeout: ${2} seconds)"  >&2
  #sleep 3

  # 1) APP is ON

  container_load_timeout=${2}

  echo "[NOTICE] [Blue OR Green Alive Check : Currently checking ${check_state}] In the ${container_name}  Container, conduct the Connection Check (localhost:${app_port} --timeout=${2}). (If this is delayed, run ' docker logs -f ${container_name} (compose), docker service ps ${project_name}-${check_state}_${project_name}-${check_state} (stack) ' to check the status."   >&2
  echo "[NOTICE] [Blue OR Green Alive Check : Currently checking ${check_state}] Current status (inside Container) : \n $(docker logs ${container_name})"   >&2
  local wait_for_it_re=$(docker exec -w ${project_location} ${container_name} ./wait-for-it.sh localhost:${app_port} --timeout=${2}) || echo "[WARNING] Failed in Connection Check (running wait_for_it.sh). But, this function is for checking which container is running. we don't exit."   >&2
  if [[ $? != 0 ]]; then
      #echo "[ERROR] Failure in wait-for-it.sh. (${wait_for_it_re})" >&2
      echo "false"
      return
  else
      # 2) APP's health check
      echo "[NOTICE] [Blue OR Green Alive Check : Currently ${check_state}] In the ${container_name}  Container, conduct the Health Check."  >&2
      sleep 1

      local interval_sec=5

      local total_cnt=$((${container_load_timeout}/${interval_sec}))

      if [[ $((container_load_timeout%interval_sec)) != 0 ]]; then
        total_cnt=$((${total_cnt}+1))
      fi

      for (( retry_count = 1; retry_count <= ${total_cnt}; retry_count++ ))
      do
        echo "[NOTICE] [Blue OR Green Alive Check : Currently ${check_state}] ${retry_count} round health check (curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path})... (timeout : ${3} sec)"  >&2
        response=$(docker exec ${container_name} sh -c "curl -s -k ${protocol}://$(concat_safe_port localhost)/${app_health_check_path} --connect-timeout ${3}") || echo "[WARNING] [Blue OR Green Alive Check : Currently ${check_state}] Failed in Health Check. But, this function is for checking which container is running. we don't exit."   >&2

        down_count=$(echo ${response} | egrep -i ${bad_app_health_check_pattern} | wc -l)
        up_count=$(echo ${response} | egrep -i ${good_app_health_check_pattern} | wc -l)

        if [[ ${down_count} -ge 1 || ${up_count} -lt 1 ]]
        then

            echo ""  >&2

        else
             echo ""  >&2
             break
        fi

        if [[ ${retry_count} -eq ${total_cnt} ]]
        then
          echo "false"
          return
        fi

        #echo "[NOTICE] ${retry_count}/${total_cnt} round Health Check failure. Retrying in ${interval_sec} secs..."  >&2
        for (( i = 1; i <= ${interval_sec}; i++ ));do echo -n "$i." >&2 && sleep 1; done
        echo "\n"  >&2

      done

     echo "true"
     return
 fi
}

check_availability_out_of_container(){

  echo "[NOTICE] Check the http status code from the outside of the container. by calling '${app_url}/${app_health_check_path}'"  >&2

 sleep 1

  for retry_count in {1..6}
  do
    status=$(curl ${app_url}/${app_health_check_path} -o /dev/null -k -Isw '%{http_code}' --connect-timeout 10)
    available_status_cnt=$(echo ${status} | egrep -i '^2[0-9]+|3[0-9]+$' | wc -l)

    if [[ ${available_status_cnt} -lt 1 ]]; then

      echo "Bad HTTP response in the ${new_state} app: ${status}"  >&2

      if [[ ${retry_count} -eq 5 ]]
      then
         echo "[ERROR] Health Check Failed. (If you are not accessing an external domain (=closed network setting environment), you need to check if APP_URL is the value retrieved by ifconfig on the Ubuntu host. Access to the ip output by the WIN ipconfig command may fail. Or you need to check the network firewall."  >&2
         echo "false"
         return
      fi

    else
      echo "[NOTICE] Success. (Status (2xx, 3xx) : ${status})"  >&2
      break
    fi

    echo "[NOTICE] Retry once every 3 seconds for a total of 8 times..."  >&2
    sleep 3
  done

  echo 'true'
  return

}