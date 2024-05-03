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
#usermod -aG root www-data

protocol=$(echo $(printenv APP_URL) | awk -F[/:] '{print $1}')
if [[ ${protocol} = 'https' ]]; then
  
  use_commercial_ssl=$(echo $(printenv USE_COMMERCIAL_SSL))
  commercial_ssl_name=$(echo $(printenv COMMERCIAL_SSL_NAME))

  echo "[DEBUG] USE_COMMERCIAL_SSL : ${use_commercial_ssl} , COMMERCIAL_SSL_NAME : ${commercial_ssl_name}"

  apache2SslRoot="/etc/apache2/ssl"
  apache2Crt="/etc/apache2/ssl/${commercial_ssl_name}.crt"
  apache2Key="/etc/apache2/ssl/${commercial_ssl_name}.key"

  if [[ ${use_commercial_ssl} == false ]] && [[ ! -f ${apache2Crt} || ! -f ${apache2Key} || ! -s ${apache2Crt} || ! -s ${apache2Key} ]]; then

      echo "[NOTICE] Create a ssl certificate for the offline network."

      if [[ ! -d ${apache2SslRoot} ]]; then
          mkdir ${apache2SslRoot}
      fi
      if [[ -f ${apache2Crt} ]]; then
          rm ${apache2Crt}
      fi

      if [[ -f ${apache2Key} ]]; then
          rm ${apache2Key}
      fi

      openssl req -subj '/CN=localhost' -x509 -newkey rsa:4096 -nodes -keyout ${apache2Key} -out ${apache2Crt} -days 365

  fi

  chown -R www-data:${shared_volume_group_id} /etc/apache2/ssl
  chmod 640 /etc/apache2/ssl/${commercial_ssl_name}.key
  chmod 644 /etc/apache2/ssl/${commercial_ssl_name}.crt

  if [[ ${use_commercial_ssl} == 'true' ]] ; then
    sed -i -e 's/#SSLCertificateChainFile/SSLCertificateChainFile/' /etc/apache2/sites-available/ssl-substr
  fi
  sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/g" /etc/apache2/sites-available/ssl-substr

  sed -i -e '/###SSL-IF-REQUIRED###/{r /etc/apache2/sites-available/ssl-substr' -e 'd}' /etc/apache2/sites-available/default.conf

  # In case of a 80 port...
  #sed -i -e 's/VirtualHost \*:80/VirtualHost \*:443/' /etc/apache2/sites-available/default.conf
fi

\cp /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.bak

echo "[NOTICE] The error log file path for php-fpm is set to /var/log/php-fpm-error.log."
sed -i -E -z 's/(^\[global\][\n\r\t\s]*)/\1error_log = \/var\/log\/php-fpm-error.log\n/' /usr/local/etc/php-fpm.d/zz-docker.conf


echo "[NOTICE] Checking php-fpm configuration. (In case of an error, you can restore it using the command: \cp -f /usr/local/etc/php-fpm.d/zz-docker.bak /usr/local/etc/php-fpm.d/zz-docker.conf.)"
php-fpm -tt
php-fpm -D

service apache2 start

chown -R www-data:${shared_volume_group_id} storage/logs

protocol=$(echo $(printenv APP_URL) | awk -F[/:] '{print $1}')
use_commercial_ssl=$(echo $(printenv "USE_COMMERCIAL_SSL"))

if [[ ${protocol} == 'https' && ${use_commercial_ssl} == 'true' ]]; then
  commercial_ssl_name=$(echo $(printenv "COMMERCIAL_SSL_NAME"))
  sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/" /laravel-echo-server/${protocol}/laravel-echo-server.json || echo "[WARNING] laravel-echo-server ###COMMERCIAL_SSL_NAME### 치환 실패"
fi