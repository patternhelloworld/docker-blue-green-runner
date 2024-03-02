#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -eu

cd ../../

sudo chmod a+x *.sh

echo "[NOTICE][1] Stopping all containers."
bash stop-all-containers.sh

echo "[NOTICE][2] Deleting all images."
bash stop-all-containers.sh # This seems to be a mistake; you might want to use a script that stops containers here instead.

echo "[NOTICE][3] Deleting all images."
bash remove-all-images.sh


echo "[NOTICE][4] Running DB of the PHP sample 'laravel-crud-boilerplate'."
cd samples/laravel-crud-boilerplate
pwd
docker-compose build
docker-compose up -d
cd ../../
pwd

echo "[NOTICE][5] Running the PHP sample 'laravel-crud-boilerplate'."
bash run.sh
