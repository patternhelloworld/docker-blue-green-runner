#!/bin/bash
set -eu

source use-common.sh
check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_git_docker_compose_commands_exist


cache_global_vars