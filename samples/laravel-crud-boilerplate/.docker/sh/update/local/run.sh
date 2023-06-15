#!/bin/bash

rootPath="$(printenv PROJECT_LOCATION)"
echo "[DEBUG] Root Path : ${rootPath}"

cd ${rootPath} || exit

if [[ ! -d ${rootPath}/vendor/laravel ]]
then
  composer install
fi

php artisan key:generate

if [[ ! -f ${rootPath}"/storage/oauth-private.key" || ! -f ${rootPath}"/storage/oauth-public.key" ]]
then
    php artisan passport:keys
fi


chown -R www-data storage bootstrap/cache shared

composer dump-autoload
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Symbolic link /etc/apache2/sites-available -> /etc/apache2/sites-enabled
a2ensite default

#echo "[NOTICE] .env 의 APP_URL 에 맞게 ServerName 을 세팅해 줍니다."
#sed -i -E "s/ServerName(.+)/ServerName $(echo $(printenv APP_URL) | awk -F[/:] '{print $4}')/" /etc/apache2/sites-available/default.conf

service apache2 stop

# 둘 다 Group 을 share
usermod -aG www-data root
usermod -aG root www-data

\cp /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.bak

sed -i -E -z 's/(^\[global\][\n\r\t\s]*)/\1error_log = \/var\/log\/php-fpm-error.log\n/' /usr/local/etc/php-fpm.d/zz-docker.conf

php-fpm -tt
php-fpm -D

service apache2 start

chown -R www-data storage/logs