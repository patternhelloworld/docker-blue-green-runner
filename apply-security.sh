#!/bin/bash
set -eu

source use-common.sh
check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_git_docker_compose_commands_exist

cache_global_vars

set_safe_filemode_on_app() {
    for volume in "${docker_compose_real_selective_volumes[@]}"; do
        local local_path="${volume%%:*}"
        local_path=$(echo $local_path | sed 's/\s*\[\s*\"\s*//g')

        echo "[NOTICE] Changing permissions for $local_path to 770"
        sudo chmod -R 770 "$local_path"

        echo "[NOTICE] Changing owner for $local_path to 'root:shared-volume-group'"
        sudo chown -R 0:${shared_volume_group_id} "$local_path"

        if [ $? -eq 0 ]; then
            echo "[NOTICE] Permissions changed successfully for $local_path"
        else
            echo "[NOTICE] Failed to change permissions for $local_path"
        fi
    done
}

sudo chmod 750 *.sh || echo "[WARN] Running chmod 750 *.sh failed."
sudo chmod 770 *.yml || echo "[WARN] Running chmod 770 *.yml failed."
sudo chmod 740 .env.* || echo "[WARN] Running chmod 740 .env.* failed."
sudo chmod 740 .env || echo "[WARN] Running chmod 740 .env failed."
sudo chmod -R 750 bin || echo "[WARN] Running chmod 750 for the bin folder"
sudo chmod 770 .gitignore || echo "[WARN] Running chmod 770 .gitignore failed."
sudo chmod -R 770 .docker/ || echo "[WARN] Running chmod -R 770 .docker/ failed."
# Check if the OS is not Darwin (macOS) before running the command
if [[ "$(uname)" != "Darwin" ]]; then
    sudo chown -R 0:${shared_volume_group_id} .docker/ || echo "[WARN] Running chgrp ${shared_volume_group_id} .docker/ failed."
else
    echo "[NOTICE] Skipping chown command on Darwin (macOS) platform. See the README."
fi

if [[ "$(uname)" != "Darwin" ]]; then
    sudo chown -R 0:${shared_volume_group_id} bin/ || echo "[WARN] Running chgrp ${shared_volume_group_id} bin/ failed."
else
    echo "[NOTICE] Skipping chown command on Darwin (macOS) platform. See the README."
fi


set_safe_filemode_on_app
