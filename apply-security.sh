#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh

cache_global_vars

set -e

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
sudo chmod 770 .gitignore || echo "[WARN] Running chmod 770 .gitignore failed."
sudo chmod -R 770 .docker/ || echo "[WARN] Running chmod -R 770 .docker/ failed."
sudo chown -R 0:${shared_volume_group_id} .docker/ || echo "[WARN] Running chgrp ${shared_volume_group_id} .docker/ failed."
set_safe_filemode_on_app
