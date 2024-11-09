#!/bin/bash
set -eu

source ./validator.sh
source ./use-states.sh


display_checkpoint_message() {
    local message=$1
    printf "\033[1;34m[CHECKPOINT] %s\033[0m\n" "$message"  # Display message in bold blue
}

# Function to display a transition message between states in a Blue-Green deployment
display_planned_transition() {
    local current_state=$1
    local target_state=$2

    # Clear the screen and set text to bold blue
    echo -e "\033[1;34m"  # Bold blue text

    echo "─────────────────────────────"
    echo "  Current State (${current_state})"
    echo "─────────────────────────────"
    echo "              |"
    echo "  >> Transition planned <<"
    echo "              v"
    echo "─────────────────────────────"
    echo "  Target State (${target_state})"
    echo "─────────────────────────────"
    echo -e "\033[0m"  # Reset text style
}

display_immediate_transition() {
    local current_state=$1
    local target_state=$2

    # Display the state transition diagram with a bold blue message
    echo -e "\033[1;34m"  # Bold blue text

    echo "─────────────────────────────"
    echo "  Current State (${current_state})"
    echo "─────────────────────────────"
    echo "              |"
    echo "  >> Immediate Transition <<"
    echo "              v"
    echo "─────────────────────────────"
    echo "  Target State (${target_state})"
    echo "─────────────────────────────"
    echo -e "\033[0m"  # Reset text style
    echo -e "\033[1;32m"  # Bold green text for emphasis
    echo ">>> Transition to ${target_state} is now being executed <<<"
    echo -e "\033[0m"  # Reset text style
}


to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

set_expose_and_app_port(){

  if [[ -z ${1} ]]
    then
      echo "[ERROR] The 'project_port' has not been passed. Terminate the entire process to prevent potential errors." && exit 1
  fi

  if echo "${1}" | grep -Eq '^\[[0-9]+,[0-9]+\]$'; then
      expose_port=$(echo "$project_port" | bin/yq e '.[0]' -)
      app_port=$(echo "$project_port" | bin/yq e '.[1]' -)
  else
      expose_port="$project_port"
      app_port="$project_port"
  fi
}

cache_non_dependent_global_vars() {

  check_git_docker_compose_commands_exist

  HOST_IP=$(get_value_from_env "HOST_IP")

  host_root_location=$(get_value_from_env "HOST_ROOT_LOCATION")
  docker_file_location=$(get_value_from_env "DOCKER_FILE_LOCATION")

  project_name=$(get_value_from_env "PROJECT_NAME")
  project_location=$(get_value_from_env "PROJECT_LOCATION")
  project_port=$(echo "$(get_value_from_env "PROJECT_PORT")" | tr -d '[:space:]')
  if ! echo "$project_port" | grep -Eq '^\[[0-9]+,[0-9]+\]$|^[0-9]+$'; then
    echo "[ERROR] project_port on .env is a wrong type. (ex. [30000,3000] or 8888 formats are available)" && exit 1
  fi

  app_url=$(get_value_from_env "APP_URL")
  protocol=$(echo ${app_url} | awk -F[/:] '{print $1}')
  port_extracted_from_app_url=$(echo "$app_url" | awk -F':' '{print $NF}')

  set_expose_and_app_port ${project_port}
  echo "[DEBUG] app_port : ${app_port}, expose_port : ${expose_port}"

  if [ "$port_extracted_from_app_url" != "$expose_port" ]; then
     echo "[ERROR] The extracted port ($port_extracted_from_app_url) for APP_URL and PROJECT_PORT ($expose_port) must be the same." && exit 1
  fi

  additional_ports=(`echo $(get_value_from_env "ADDITIONAL_PORTS") | cut -d ","  --output-delimiter=" " -f 1-`)
  echo "[DEBUG] ADDITIONAL_PORTS : ${additional_ports[@]}"

  docker_compose_environment=$(get_value_from_env "DOCKER_COMPOSE_ENVIRONMENT")
  docker_build_args=$(get_value_from_env "DOCKER_BUILD_ARGS")

  consul_key_value_store=$(get_value_from_env "CONSUL_KEY_VALUE_STORE")
  consul_key=$(echo ${consul_key_value_store} | cut -d "/" -f6)\\/$(echo ${consul_key_value_store} | cut -d "/" -f7)

  app_health_check_path=$(get_value_from_env "APP_HEALTH_CHECK_PATH")
  bad_app_health_check_pattern=$(get_value_from_env "BAD_APP_HEALTH_CHECK_PATTERN")
  good_app_health_check_pattern=$(get_value_from_env "GOOD_APP_HEALTH_CHECK_PATTERN")

  app_env=$(get_value_from_env "APP_ENV")
  if [[ ! (${app_env} == 'real' || ${app_env} == 'local') ]]; then
     echo "[ERROR] app_env is only local or real." && exit 1
  fi

  docker_file_name="Dockerfile.${app_env}"

  if [ -f "${docker_file_location}/${docker_file_name}" ]; then
      docker_file_name="Dockerfile.${app_env}"
  else
      if [ -f "${docker_file_location}/Dockerfile" ]; then
        docker_file_name="Dockerfile"
      else
         echo "[ERROR] Couldn't find any of 'Dockerfile.${app_env} and Dockerfile' in ${docker_file_location}" && exit 1
      fi
  fi

  if [[ ${app_env} == 'real' ]]; then
    docker_compose_real_selective_volumes=$(get_value_from_env "DOCKER_COMPOSE_REAL_SELECTIVE_VOLUMES")
  fi

  docker_compose_nginx_selective_volumes=$(get_value_from_env "DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES")
  docker_compose_host_volume_check=$(get_value_from_env "DOCKER_COMPOSE_HOST_VOLUME_CHECK")

  docker_layer_corruption_recovery=$(get_value_from_env "DOCKER_LAYER_CORRUPTION_RECOVERY")


  if [[ ${protocol} = 'https' ]]; then
    use_commercial_ssl=$(get_value_from_env "USE_COMMERCIAL_SSL")
    commercial_ssl_name=$(get_value_from_env "COMMERCIAL_SSL_NAME")
  fi


  nginx_restart=$(get_value_from_env "NGINX_RESTART")
  consul_restart=$(get_value_from_env "CONSUL_RESTART")
  if [[ ${consul_restart} == 'true' && ${nginx_restart} == 'false' ]]; then
      echo "[ERROR] On .env, consul_restart=true but nginx_restart=false. That does NOT make sense, as Nginx depends on Consul." && exit 1
  fi
  use_my_own_app_yml=$(get_value_from_env "USE_MY_OWN_APP_YML")

  skip_building_app_image=$(get_value_from_env "SKIP_BUILDING_APP_IMAGE")

  if [[ ${docker_layer_corruption_recovery} == 'true' && ${skip_building_app_image} == 'true' ]]; then
      echo "[ERROR] On .env, docker_layer_corruption_recovery=true and skip_building_app_image=true as well. That does NOT make sense, as 'docker_layer_corruption_recovery=true' removes all images first." && exit 1
  fi

  orchestration_type=$(get_value_from_env "ORCHESTRATION_TYPE")
  only_building_app_image=$(get_value_from_env "ONLY_BUILDING_APP_IMAGE")


  docker_build_memory_usage=$(get_value_from_env "DOCKER_BUILD_MEMORY_USAGE")

  nginx_client_max_body_size=$(get_value_from_env "NGINX_CLIENT_MAX_BODY_SIZE")

  use_nginx_restricted_location=$(get_value_from_env "USE_NGINX_RESTRICTED_LOCATION")
  nginx_restricted_location=$(get_value_from_env "NGINX_RESTRICTED_LOCATION")

  nginx_restricted_location=$(get_value_from_env "NGINX_RESTRICTED_LOCATION")
  redirect_https_to_http=$(get_value_from_env "REDIRECT_HTTPS_TO_HTTP")

   app_https_protocol=${protocol};
   if [[ ${redirect_https_to_http} = 'true' && ${protocol} = 'https' ]]; then
      app_https_protocol="http"
   fi

  if [[ ${use_nginx_restricted_location} = 'true' ]]; then
    local passwd_file_path="./.docker/nginx/custom-files/.htpasswd";
    if [ ! -f "$passwd_file_path" ]; then
        echo "[ERROR] couldn't find '${passwd_file_path}' file for 'USE_NGINX_RESTRICTED_LOCATION=true'. See the README if you would like to use USE_NGINX_RESTRICTED_LOCATION."
        exit 1
    fi
  fi

  shared_volume_group_id=$(get_value_from_env "SHARED_VOLUME_GROUP_ID")
  uids_belonging_to_shared_volume_group_id=$(get_value_from_env "UIDS_BELONGING_TO_SHARED_VOLUME_GROUP_ID")
  shared_volume_group_name=$(get_value_from_env "SHARED_VOLUME_GROUP_NAME")

  nginx_logrotate_file_size=$(get_value_from_env "NGINX_LOGROTATE_FILE_SIZE")
  if [[ $(validate_file_size "$nginx_logrotate_file_size") == "false" ]]; then
    echo "[WARNING] NGINX_LOGROTATE_FILE_SIZE in .env has an incorrect format. (value: $nginx_logrotate_file_size, correct examples: 10K, 1M, 100K, etc. Expected behavior: Logrotate won't work). However, this is NOT a serious issue. We will continue the process."
  fi
  nginx_logrotate_file_number=$(get_value_from_env "NGINX_LOGROTATE_FILE_NUMBER")
  if [[ $(validate_number "$nginx_logrotate_file_number") == "false" ]]; then
    echo "[WARNING] NGINX_LOGROTATE_FILE_NUMBER in .env has an incorrect format. (value: $nginx_logrotate_file_number, correct examples: 5,10,101..., etc. Expected behavior: Logrotate won't work). However, this is NOT a serious issue. We will continue the process."
  fi
  use_my_own_nginx_origin=$(get_value_from_env "USE_MY_OWN_NGINX_ORIGIN")

}

cache_global_vars() {

  cache_non_dependent_global_vars

  host_root_uid=$(id -u)
  host_root_gid=$(id -g)

  CUR_TIME=$(date +%s)

  if [[ ${protocol} = 'https' ]]; then
    blue_upstream=$(concat_safe_port "https://${project_name}-blue")
    green_upstream=$(concat_safe_port "https://${project_name}-green")
  else
    blue_upstream=$(concat_safe_port "http://${project_name}-blue")
    green_upstream=$(concat_safe_port "http://${project_name}-green")
  fi

  cache_all_states


  # In real env, for Jenkins & customer servers
  git_image_load_from=$(get_value_from_env "GIT_IMAGE_LOAD_FROM")
  git_image_load_from_host=$(get_value_from_env "GIT_IMAGE_LOAD_FROM_HOST")
  git_image_load_from_pathname=$(get_value_from_env "GIT_IMAGE_LOAD_FROM_PATHNAME")

  git_token_image_load_from_username=$(get_value_from_env "GIT_TOKEN_IMAGE_LOAD_FROM_USERNAME")
  git_token_image_load_from_password=$(get_value_from_env "GIT_TOKEN_IMAGE_LOAD_FROM_PASSWORD")
  git_image_version=$(get_value_from_env "GIT_IMAGE_VERSION")

  app_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-app:${git_image_version}"
  nginx_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-nginx:${git_image_version}"
  consul_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-consul:${git_image_version}"
  registrator_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-registrator:${git_image_version}"



  if [[ $(docker exec consul echo 'yes' 2> /dev/null) == '' ]]
  then
      echo '[NOTICE] Since the Consul container is not running, we consider it as consul_restart=true and start from loading the image again. (The .env file will not be changed.)'
      consul_restart=true

      # Since there is no Dockerfile, unlike the 'load_nginx_docker_image' and 'load_app_docker_image' functions, there is no 'build' command.
  fi
  if [[ $(docker exec ${project_name}-nginx echo 'yes' 2> /dev/null) == '' ]]
  then
      echo "[NOTICE] Since the '${project_name}-nginx:latest' container is not running, we consider it as 'nginx_restart=true' and start from building again."
      nginx_restart=true
  fi

}

check_yq_installed(){
    required_version="4.35.1"
    yq_path="bin/yq"

    # Function to download yq
    download_yq() {
        echo "[NOTICE] Downloading bin/yq version $required_version..." >&2

        # Detect OS and architecture
        ARCH=$(uname -m)
        OS=$(uname | tr '[:upper:]' '[:lower:]')

        # Determine the correct bin/yq binary based on architecture
        case "$OS-$ARCH" in
            linux-x86_64)
                YQ_BINARY="yq_linux_amd64"
                ;;
            linux-aarch64)
                YQ_BINARY="yq_linux_arm64"
                ;;
            linux-armv7l | linux-armhf)
                YQ_BINARY="yq_linux_arm"
                ;;
            linux-i386 | linux-i686)
                YQ_BINARY="yq_linux_386"
                ;;
            darwin-x86_64)
                YQ_BINARY="yq_darwin_amd64"
                ;;
            darwin-arm64)
                YQ_BINARY="yq_darwin_arm64"
                ;;
            *)
                echo >&2 "[ERROR] Unsupported OS or architecture: $OS-$ARCH"
                exit 1
                ;;
        esac

        DOWNLOAD_URL="https://github.com/mikefarah/yq/releases/download/v$required_version/$YQ_BINARY"

        # Download yq
        curl -L "$DOWNLOAD_URL" -o "$yq_path"
        chmod +x "$yq_path"
        echo "[NOTICE] bin/yq version $required_version from $DOWNLOAD_URL has been downloaded to $yq_path." >&2
    }

    # Check if bin/yq is installed in the bin directory
    if [ ! -f "$yq_path" ]; then
        echo "[WARNING] bin/yq is not found in $yq_path. Downloading..." >&2
        download_yq
    else
        # Check if installed bin/yq version is the required version
        installed_version=$("$yq_path" --version | grep -oP 'version v\K[0-9.]+')
        if [ "$installed_version" != "$required_version" ]; then
            echo "[WARNING] bin/yq version is $installed_version, which is not the required version $required_version." >&2
            download_yq
        else
            echo "[NOTICE] bin/yq version $required_version is already installed in $yq_path." >&2
        fi
    fi
}


check_gnu_grep_installed() {
    # Check if grep is installed
    if ! command -v grep >/dev/null 2>&1; then
        echo >&2 "[ERROR] grep is NOT installed. Please install GNU grep."
        exit 1
    fi

    # Check if the installed grep supports -P option (GNU grep)
    if ! grep -P '' <<< '' >/dev/null 2>&1; then
        echo >&2 "[WARNING] The installed grep does not support the '-P' option."
        echo >&2 "[INFO] This is likely because the installed grep is not GNU grep."
        echo >&2 "Please install GNU grep using Homebrew:"
        exit 1
    else
        echo "[INFO] GNU grep is installed and ready to use with the '-P' option."
    fi
}


check_gnu_sed_installed() {
    # Check if sed is installed
    if ! command -v sed >/dev/null 2>&1; then
        echo >&2 "[ERROR] sed is NOT installed. Please install GNU sed."
        exit 1
    fi

    # Try to check sed version to confirm if it's GNU sed
    if sed --version >/dev/null 2>&1; then
        if sed --version | grep -q "GNU"; then
            echo "[INFO] GNU sed is installed and ready to use."
        else
            echo >&2 "[WARNING] The installed sed is not GNU sed."
            echo >&2 "It seems you're using a different version of sed, which behaves differently."
            exit 1
        fi
    else
        # If --version option is not supported, assume it's not GNU sed
        echo >&2 "[WARNING] sed does not support the --version parameter."
        echo >&2 "It seems you're using BSD sed or another non-GNU version."
        exit 1
    fi
}

check_bash_version() {
    # Check if bash is installed
    if ! command -v bash >/dev/null 2>&1; then
        echo >&2 "[ERROR] Bash is NOT installed. Please install GNU bash."
        exit 1
    fi

    # Get the current bash version
    current_version=$(bash --version | head -n 1 | grep -oP '\d+\.\d+\.\d+')

    # Define the required minimum version (4.4.0)
    required_version="4.4.0"

    # Function to compare version numbers
    version_compare() {
        # Split version numbers by .
        IFS='.' read -r -a current <<< "$1"
        IFS='.' read -r -a required <<< "$2"

        # Compare major, minor, and patch versions
        for i in 0 1 2; do
            if [[ ${current[i]:-0} -lt ${required[i]:-0} ]]; then
                return 1
            elif [[ ${current[i]:-0} -gt ${required[i]:-0} ]]; then
                return 0
            fi
        done
        return 0
    }

    # Compare current and required version
    if ! version_compare "$current_version" "$required_version"; then
        echo >&2 "[ERROR] Bash version is $current_version. Please upgrade to GNU Bash $required_version or higher."
        echo >&2 "You can install the latest version of bash using Homebrew:"
        echo >&2 "  brew install bash"
        echo >&2 "After installation, set the new bash as your default shell:"
        echo >&2 "  sudo chsh -s /usr/local/bin/bash"
        exit 1
    else
        echo "[INFO] GNU Bash version $current_version is installed and ready to use."
    fi
}

check_git_docker_compose_commands_exist(){

  command -v git >/dev/null 2>&1 ||
  { echo >&2 "[ERROR] git NOT installed. Exiting...";
    exit 1
  }

  if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] docker is NOT run. Exiting..."
    exit 1
  fi

  if ! docker-compose --version > /dev/null 2>&1; then
      echo "[ERROR] docker-compose is NOT installed. Exiting..."
      exit 1
  fi
}

get_value_from_env(){

  if [ ! -f ".env" ]; then
      echo "[ERROR] .env file NOT found." >&2 && exit 1
  fi
  value=''
  re='^[[:space:]]*('${1}'[[:space:]]*=[[:space:]]*)(.+)[[:space:]]*$'

  while IFS= read -r line; do
     if [[ $line =~ $re ]]; then                       # match regex
        #declare -p BASH_REMATCH
        value=${BASH_REMATCH[2]}
     fi
                                      # print each line
  done < <(grep "" .env)  # To read the last line

  value=$(echo $value | sed -e 's/\r//g')

  if [[ -z ${value} ]]; then
    echo "[WARNING] ${value} for the key ${1} is empty .env." >&2
  fi

  echo ${value} # return.
}

compare_two_envs(){
  original_keys=()
  standard_keys=()

  while IFS= read -r line1; do

          [[ "$line1" =~ ^[[:space:]]*# ]] && continue

          key=$(echo $line1 | sed -E 's/^([^=]+)=.*/\1/')
          original_keys+=(${key})
  done < <(grep "" "$1")

  while IFS= read -r line2; do

          [[ "$line2" =~ ^[[:space:]]*# ]] && continue

          key2=$(echo $line2 | sed -E 's/^([^=]+)=.*/\1/')
          standard_keys+=(${key2})
  done < <(grep "" "$2")

  #echo ${original_keys[@]}
  echo ${original_keys[@]} ${standard_keys[@]} | tr ' ' '\n' | sort | uniq -u

}

check_empty_env_values(){

  empty_keys=()

  while IFS= read -r line; do

      [[ "$line" =~ ^[[:space:]]*# ]] && continue

      key=$(echo $line | sed -E 's/^([^=]+)=.*/\1/')
      value=$(echo $line | sed -E 's/^[^=]+=(.*)/\1/')

      value="$(echo -e "${value}" | sed -e 's/^[[:space:]]*|[[:space:]]*$//')"

      if [[ ${value} == '' && ${key} != "CONTAINER_SSL_VOLUME_PATH" && ${key} != "ADDITIONAL_PORTS" && ${key} != "UIDS_BELONGING_TO_SHARED_VOLUME_GROUP_ID" ]]; then
         empty_keys+=(${key})
      fi

  done < <(grep "" "$1")

  echo ${empty_keys[@]}

}

check_env_integrity(){

    diff=$(compare_two_envs .env .env.example.${app_env})
    if [[ ${diff} != "" ]]; then
      echo "[ERROR] The key values in the .env file do not match with .env.example.${app_env}, so the process cannot continue. Please update the .env file to match the requirements (Difference: ${diff})."
      exit 1
    fi

    empty_values=$(check_empty_env_values .env)
    if [[ ${empty_values} != "" ]]; then
      echo "[ERROR] The following values in the .env file are empty, so the process cannot proceed (Difference: ${empty_values})"
      exit 1
    fi
}

concat_safe_port() {
 if [[ -z ${app_port} || ${app_port} == '80' || ${app_port} == '443' ]]; then
    echo "${1}"
 else
    echo "${1}:${app_port}"
 fi
}


check_command_in_container_or_fail(){
  # 컨테이너 이름 또는 ID
  CONTAINER_NAME=${1}

  # 확인하고 싶은 명령어
  COMMAND_TO_CHECK=${2}

  # 명령어 존재 여부 확인
  if docker exec $CONTAINER_NAME bash -c "command -v $COMMAND_TO_CHECK" &> /dev/null; then
      echo "[NOTICE] $COMMAND_TO_CHECK exists in $CONTAINER_NAME" >&2
     echo "true"
     return
  else
      echo "[ERROR] $COMMAND_TO_CHECK does not exist in $CONTAINER_NAME" >&2
      echo "false"
      return
  fi
}




check_one_container_loaded(){

  if [ "$(docker ps -q -f name=^${1})" ]; then
      echo "[NOTICE] Supporting container ( ${1} ) running checked."
    else
      echo "[ERROR] Supporting container ( ${1} ) running not found. But, this does NOT stop the current deployment, according to the Nginx Contingency Plan."
    fi
}

check_one_edge_routing_container_loaded(){
  if [ "$(docker ps -q -f name=^${1})" ]; then
      echo "[NOTICE] Supporting container ( ${1} ) running checked."
  else
      echo "[ERROR] Supporting container ( ${1} ) running not found. As it is a necessary container, we will now exit the deployment process for safety." && exit 1
  fi
}

check_common_containers_loaded(){
  all_container_names=("consul" "registrator")
  for name in "${all_container_names[@]}"; do
    check_one_container_loaded ${name}
  done
}

check_edge_routing_containers_loaded() {
  all_container_names=("${project_name}-nginx")

  for name in "${all_container_names[@]}"; do
    check_one_edge_routing_container_loaded "${name}"
  done
}


# GIT_IMAGE_LOAD_FROM=registry
integer_hash_text(){
  echo $((0x$(sha1sum <<<"$1"|cut -c1-2)))
}
docker_login_with_params() {

  echo "[NOTICE] Login with the following account on to Gitlab Docker Registry. ( username : ${1}, password : $(integer_hash_text ${2}) (displayed encoded.) )"
  echo ${2} | docker login --username ${1} --password-stdin ${3} || (echo "[ERROR] Docker Registry Login failed to ${3}." && exit 1)

}

# experimental
set_network_driver_for_orchestration_type(){

  local network_name="consul"
  local swarm_network_driver="overlay"
  local local_network_driver="local"
  # 네트워크 존재 여부 확인
  network_id=$(docker network ls --filter "name=^${network_name}$" --format "{{.ID}}")
  if [ -z "$network_id" ]; then
    echo "[NOTICE] Network name (${network_name}) does not exist."

    if [[ ${orchestration_type} != 'stack' ]]; then
      docker network create consul || echo "[NOTICE] Consul Network (Local) has already been created. You can ignore this message."
    else
      docker network create --driver ${swarm_network_driver} --attachable consul || echo "[NOTICE] Consul Network (Swarm) has already been created. You can ignore this message."
    fi
  else
    network_driver=$(docker network inspect $network_id --format "{{.Driver}}")
    if [ "$network_driver" == "$swarm_network_driver" ]; then
        if [[ ${orchestration_type} == 'stack' ]]; then
         echo "[NOTICE] $swarm_network_driver is appropriately set for $swarm_network_driver"
          exit 0
        else
          echo "[NOTICE] $swarm_network_driver is not appropriate for ${orchestration_type}"
          bash emergency-consul-down-and-up;
        fi
    elif [ "$network_driver" == "$local_network_driver" ]; then
        if [[ ${orchestration_type} == 'stack' ]]; then
              echo "[NOTICE] $swarm_network_driver is not appropriate for ${orchestration_type}"
              bash emergency-consul-down-and-up;
          else
              echo "[NOTICE] $swarm_network_driver is appropriately set for $local_network_driver"
              exit 0
         fi
    else
        echo "[ERROR] an serious error for set_network_driver_for_orchestration_type. (network_driver : ${network_driver})" && echo 1
    fi
  fi

}

add_host_users_to_host_group() {

    local gid=${1}
    local gname=${2}
    local uids=${3:-}


    echo "[DEBUG] add_host_users_to_host_group - gid : ${gid}, uids : ${uids}, gname : ${gname}"

    # Check if ${module_name}_GROUP_ID value is valid
    if [ -z "$gid" ]; then
        echo "[ERROR] ${module_name}_VOLUME_GROUP_ID value is not provided." >&2
        echo "false"
        return
    fi

    # Retrieve group name
    local final_gname=$(getent group "$gid" | cut -d: -f1)

    # Check if the group exists
    if [ -z "$final_gname" ]; then
        # If the group doesn't exist, create a new one
        echo "[NOTICE] Creating group with GID $gid..." >&2
        sudo groupadd -g "$gid" "${gname}"
        if [ $? -eq 0 ]; then
            echo "[NOTICE] Group '$(to_lower "${module_name}")_group' with GID $gid created successfully." >&2
            final_gname="${gname}"
        else
            echo "[ERROR] Failed to create group." >&2
            echo "false"
            return
        fi
    else
        echo "[NOTICE] Group with GID $gid already exists: $final_gname" >&2
    fi

    # Split comma-separated user IDs into an array and remove whitespace
    IFS=',' read -r -a uid_array <<< "$uids"

    # Iterate over each user ID in the array and add them to the group
    for uid in "${uid_array[@]}"; do
        # Remove surrounding whitespace from user ID
        local uid_clean=$(echo "$uid" | xargs)
        # Convert UID to username if necessary
        local username=$(getent passwd "$uid_clean" | cut -d: -f1)

        if [ -z "$username" ]; then
            echo "[WARNING] No user with UID $uid_clean exists." >&2
            continue
        fi
        # Add user to the group
        sudo usermod -a -G "$final_gname" "$username"
        if [ $? -eq 0 ]; then
            echo "[NOTICE] User $username added to group $final_gname successfully on your host." >&2
        else
            echo "[NOTICE] Failed to add user $username to group $final_gname on your host." >&2
        fi
    done

    echo "true"
    return
}

check_git_status() {

    status=$(git status --porcelain)

    if [ -n "$status" ]; then
        echo "true"
    else
        echo "false"
    fi

}

stop_and_remove_container() {
    # Assign container name passed as an argument
    local container_name="$1"

    # Check if the container is running or exists
    if [ "$(docker ps -a -q -f name=${container_name})" ]; then
        echo "[NOTICE] Stopping and removing container: ${container_name}"
        docker stop "${container_name}" || echo "[ERROR] Failed to stop container: ${container_name}"
        docker rm "${container_name}" || echo "[ERROR] Failed to remove container: ${container_name}"
    else
        echo "[NOTICE] Container ${container_name} does not exist."
    fi
}