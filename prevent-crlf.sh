#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0) || sed -i -e "s/\r$//g" $(basename $0)

sudo sed -i -e 's/\r$//' *.sh

# Attempt to remove carriage return characters from the script itself with sudo; if that fails, try without sudo.
find . -name "*.sh" -exec sed -i -e 's/\r$//' {} \;

# Remove carriage return characters from all shell script files in the current directory.
find ./.docker/nginx -type f \( -name 'logrotate' -o -name 'nginx.service' -o -name 'entrypoint.sh' -o -name "*.origin" \) -exec sed -i -e 's/\r$//' {} \;

# Remove carriage return characters from specific configuration files.
find . -type f \( -name '.env' -o -name '.env.example.local' -o -name '.env.example.real' -o -name '.env.*' -o -name '*.yml' \) -exec sed -i -e 's/\r$//' {} \; || echo "[NOTICE] Performed CRLF line ending inspection. There are no issues with the non-existent files."