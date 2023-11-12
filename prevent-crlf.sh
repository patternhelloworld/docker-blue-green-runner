#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0) || sed -i -e "s/\r$//g" $(basename $0)
sed -i -e 's/\r$//' *.sh
sed -i -e 's/\r$//' ./.docker/nginx/logrotate
sed -i -e 's/\r$//' ./.docker/nginx/nginx.service
sed -i -e 's/\r$//' ./.docker/nginx/entrypoint.sh
sed -i -e 's/\r$//' .env .env.example.local .env.example.real *.yml  || echo "[NOTICE] Performed CRLF line ending inspection. There are no issues with the non-existent files."
