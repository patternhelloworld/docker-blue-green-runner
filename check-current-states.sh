#!/bin/bash
set -eu

source use-common.sh

check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_yq_installed
check_git_docker_compose_commands_exist

# Load global variables
cache_global_vars

# Define container name
container_name="${project_name}-${state}"

echo "[NOTICE] Project Name: ${project_name}"
display_emphasized_message "[NOTICE] Current State: ${state}"
display_emphasized_message "[NOTICE] Container Name: ${container_name}"


# Call the function
display_emphasized_message "$(print_git_sha_and_message "$container_name" "$docker_build_sha_insert_git_root")"

# echo "[NOTICE] All labels inside the Container $container_name"
# docker inspect -f '{{json .Config.Labels}}' "$container_name" 2>/dev/null | yq -P