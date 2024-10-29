#!/bin/bash
set -eu

source use-common.sh
check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_git_docker_compose_commands_exist

git config apply.whitespace nowarn
git config core.filemode false

result=$(check_git_status)

if [ "$result" == "true" ]; then
    echo "[WARNING] There are arbitrary changes in the source code. Please check."
    git status
else
    echo "[NOTICE] [SUCCESS] No arbitrary changes detected in the source code."
fi