#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -eu

sudo chmod a+x *.sh

echo "[NOTICE] Substituting CRLF with LF to prevent possible CRLF errors..."
bash prevent-crlf.sh
git config apply.whitespace nowarn
git config core.filemode false

sleep 3
source ./util.sh

# Load necessary things from util.sh
check_necessary_commands
cache_global_vars
check_env_integrity


network_name="consul"

container_ids=$(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' "$network_name" | awk '{print $1}')
for container_id in $container_ids; do
    echo "[NOTICE] Stopping containers for removing the Consul network : $container_id"
    docker stop "$container_id"
done

consul_down_and_up