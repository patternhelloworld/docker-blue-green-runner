#!/bin/bash
rootPath="$(printenv PROJECT_LOCATION)"
shared_volume_group_id="$(printenv SHARED_VOLUME_GROUP_ID)"
echo "[DEBUG] PROJECT_LOCATION : ${rootPath}"
echo "[DEBUG] SHARED_VOLUME_GROUP_ID : ${shared_volume_group_id}"

cd ${rootPath} || exit 1

chown -R www-data:${shared_volume_group_id} storage bootstrap/cache public

php artisan key:generate

if [[ ! -f ${rootPath}"/storage/oauth-private.key" || ! -f ${rootPath}"/storage/oauth-public.key" ]]
then
    php artisan passport:keys
fi

chown www-data:${shared_volume_group_id} storage/oauth-*.key

#composer dump-autoload
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Symbolic link /etc/apache2/sites-available -> /etc/apache2/sites-enabled
a2ensite default

service apache2 stop

# Use the same group between www-data and root
#usermod -aG www-data root

\cp /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.bak

echo "[NOTICE] The error log file path for php-fpm is set to /var/log/php-fpm-error.log."
sed -i -E -z 's/(^\[global\][\n\r\t\s]*)/\1error_log = \/var\/log\/php-fpm-error.log\n/' /usr/local/etc/php-fpm.d/zz-docker.conf


echo "[NOTICE] Checking php-fpm configuration. (In case of an error, you can restore it using the command: \cp -f /usr/local/etc/php-fpm.d/zz-docker.bak /usr/local/etc/php-fpm.d/zz-docker.conf.)"
php-fpm -tt
php-fpm -D

service apache2 start

chown -R www-data:${shared_volume_group_id} storage/logs