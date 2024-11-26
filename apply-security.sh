#!/bin/bash
set -eu

source use-common.sh

check_bash_version
check_gnu_grep_installed
check_gnu_sed_installed
check_yq_installed
check_git_docker_compose_commands_exist

cache_global_vars

set_safe_filemode_on_app() {
    for volume in "${docker_compose_selective_volumes[@]}"; do
        local local_path="${volume%%:*}"
        local_path=$(echo $local_path | sed 's/\s*\[\s*\"\s*//g')

        echo "[NOTICE] Executing chmod -R 770 for $local_path"
        sudo chmod -R 770 "$local_path"

        echo "[NOTICE] Executing chown -R 0:${shared_volume_group_id} for $local_path"
        sudo chown -R 0:${shared_volume_group_id} "$local_path"

        if [ $? -eq 0 ]; then
            echo "[NOTICE] Permissions changed successfully for $local_path"
        else
            echo "[NOTICE] Failed to change permissions for $local_path"
        fi
    done
}

echo "[NOTICE] Executing chmod 750 *.sh"
sudo chmod 750 *.sh || echo "[WARN] Running chmod 750 *.sh failed."

echo "[NOTICE] Executing chmod 770 *.yml"
sudo chmod 770 *.yml || echo "[WARN] Running chmod 770 *.yml failed."

echo "[NOTICE] Executing chmod 740 .env.*"
sudo chmod 740 .env.* || echo "[WARN] Running chmod 740 .env.* failed."

echo "[NOTICE] Executing chmod 740 .env"
sudo chmod 740 .env || echo "[WARN] Running chmod 740 .env failed."

echo "[NOTICE] Executing chmod -R 750 bin"
sudo chmod -R 750 bin || echo "[WARN] Running chmod 750 for the bin folder failed."

echo "[NOTICE] Executing chmod 770 .gitignore"
sudo chmod 770 .gitignore || echo "[WARN] Running chmod 770 .gitignore failed."

echo "[NOTICE] Executing chmod -R 770 .docker/"
sudo chmod -R 770 .docker/ || echo "[WARN] Running chmod -R 770 .docker/ failed."

if [[ "$(uname)" != "Darwin" ]]; then
    echo "[NOTICE] Executing chown -R 0:${shared_volume_group_id} .docker/"
    sudo chown -R 0:${shared_volume_group_id} .docker/ || echo "[WARN] Running chgrp ${shared_volume_group_id} .docker/ failed."
else
    echo "[NOTICE] Skipping chown command on Darwin (macOS) platform. See the README."
fi

if [[ "$(uname)" != "Darwin" ]]; then
    echo "[NOTICE] Executing chown -R 0:${shared_volume_group_id} bin/"
    sudo chown -R 0:${shared_volume_group_id} bin/ || echo "[WARN] Running chgrp ${shared_volume_group_id} bin/ failed."
else
    echo "[NOTICE] Skipping chown command on Darwin (macOS) platform. See the README."
fi

if [[ "$(uname)" != "Darwin" ]]; then
    echo "[NOTICE] Executing set_safe_filemode_on_app"
    set_safe_filemode_on_app
else
    echo "[NOTICE] Skipping chown command on Darwin (macOS) platform. See the README."
fi

echo "[NOTICE] Executing chmod -R 770 ${host_root_location}"
sudo chmod -R 770 ${host_root_location} || echo "[WARN] Running chmod 770 for your App project failed."