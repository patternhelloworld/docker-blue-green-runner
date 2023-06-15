#!/bin/bash
echo "[NOTICE] app_env 가 real 인 ENTRYPOINT 스크립트 (.docker/sh/update/real/$(printenv PROJECT_NAME).sh)를 실행합니다."

rootPath="$(printenv PROJECT_LOCATION)/$(printenv PROJECT_NAME)"
echo "[DEBUG] Root Path : ${rootPath}"

service supervisor stop

cd ${rootPath} || exit 1

# 세팅 값은 항상 .docker 가 기준이 된다.
cp -f /env/.env ${rootPath} || exit 1

chown -R redis /var/log/redis
sleep 3
redis-server --daemonize yes --protected-mode no
service redis-server restart

chown -R www-data:www-data storage bootstrap/cache shared public

php artisan key:generate

if [[ ! -f ${rootPath}"/storage/oauth-private.key" || ! -f ${rootPath}"/storage/oauth-public.key" ]]
then
    php artisan passport:keys
fi

chown www-data:www-data storage/oauth-*.key

#composer dump-autoload
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Symbolic link /etc/apache2/sites-available -> /etc/apache2/sites-enabled
a2ensite default

service apache2 stop

# 둘 다 Group 을 share
usermod -aG www-data root
usermod -aG root www-data


#echo "[NOTICE] .env 의 APP_URL 에 맞게 ServerName 을 세팅해 줍니다."
#sed -i -E "s/ServerName(.+)/ServerName $(echo $(printenv APP_URL) | awk -F[/:] '{print $4}')/" /etc/apache2/sites-available/pine.conf

protocol=$(echo $(printenv APP_URL) | awk -F[/:] '{print $1}')
if [[ ${protocol} = 'https' ]]; then
  
  use_commercial_ssl=$(echo $(printenv USE_COMMERCIAL_SSL))
  commercial_ssl_name=$(echo $(printenv COMMERCIAL_SSL_NAME))

  apache2SslRoot="/etc/apache2/ssl"
  apache2Crt="/etc/apache2/ssl/${commercial_ssl_name}.crt"
  apache2Key="/etc/apache2/ssl/${commercial_ssl_name}.key"

  if [[ ${use_commercial_ssl} == false ]] && [[ ! -f ${nginxCrt} || ! -f ${nginxKey} || ! -s ${nginxCrt} || ! -s ${nginxKey} ]]; then

      echo "[NOTICE] 폐쇄망 용 SSL 인증서를 생성합니다."

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

  chown -R www-data /etc/apache2/ssl
  chmod 640 /etc/apache2/ssl/${commercial_ssl_name}.key
  chmod 644 /etc/apache2/ssl/${commercial_ssl_name}.crt

  if [[ ${use_commercial_ssl} == 'true' ]] ; then
    sed -i -e 's/#SSLCertificateChainFile/SSLCertificateChainFile/' /etc/apache2/sites-available/ssl-substr
  fi
  sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/g" /etc/apache2/sites-available/ssl-substr

  sed -i -e '/###SSL-IF-REQUIRED###/{r /etc/apache2/sites-available/ssl-substr' -e 'd}' /etc/apache2/sites-available/default.conf
  sed -i -e 's/VirtualHost \*:80/VirtualHost \*:443/' /etc/apache2/sites-available/default.conf
fi

\cp /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.bak

echo "[NOTICE] php-fpm 의 오류 로그 파일 경로를 /var/log/php-fpm-error.log 로 설정 합니다."
sed -i -E -z 's/(^\[global\][\n\r\t\s]*)/\1error_log = \/var\/log\/php-fpm-error.log\n/' /usr/local/etc/php-fpm.d/zz-docker.conf

if [[ ! -z $(printenv PHP_FPM_ALLOCATED_GB_MEMORY) && $(printenv PHP_FPM_ALLOCATED_GB_MEMORY) > 1 ]]; then

  echo "[NOTICE] php-fpm 메모리를 .env 의 PHP_FPM_ALLOCATED_GB_MEMORY 값에 따라 재조정 합니다."
  echo "pm.max_children = $((10 * $(printenv PHP_FPM_ALLOCATED_GB_MEMORY)))" >> /usr/local/etc/php-fpm.d/zz-docker.conf
  echo "pm.start_servers = $((2 * $(printenv PHP_FPM_ALLOCATED_GB_MEMORY)))" >> /usr/local/etc/php-fpm.d/zz-docker.conf
  echo "pm.min_spare_servers = $((2 * $(printenv PHP_FPM_ALLOCATED_GB_MEMORY)))" >> /usr/local/etc/php-fpm.d/zz-docker.conf
  echo "pm.max_spare_servers = $((8 * $(printenv PHP_FPM_ALLOCATED_GB_MEMORY)))" >> /usr/local/etc/php-fpm.d/zz-docker.conf
  echo "pm.max_requests = $((42 * $(printenv PHP_FPM_ALLOCATED_GB_MEMORY)))" >> /usr/local/etc/php-fpm.d/zz-docker.conf

fi

echo "[NOTICE] php-fpm 설정을 확인 합니다. (오류 시, \cp /usr/local/etc/php-fpm.d/zz-docker.bak /usr/local/etc/php-fpm.d/zz-docker.conf 명령어로 복원 가능합니다.)"
php-fpm -tt
php-fpm -D

service apache2 start

echo "[NOTICE] 메뉴얼을 publish 합니다."
php artisan vendor:publish --tag=larecipe_assets --force || echo "[WARNING] 메뉴얼 생성에 실패 하였습니다."
sleep 2
echo "[NOTICE] 로그 파일의 권한을 (오류 : www-data, Laravel-Queue : root (supervisor 권한이 root 이므로), 웹 소캣 : root (supervisor 권한이 root 이므로) 로 유지 합니다."
chown -R www-data storage/logs
chown www-data storage/logs/laravel-worker*
chown root storage/logs/websocket-server*


echo "[NOTICE] supervisor 를 띄웁니다. (supervisor 의 경우 restart 명령어는 작동이 잘 안되고, stop 후 start 를 해주어야 합니다.)"
service supervisor stop
protocol=$(echo $(printenv APP_URL) | awk -F[/:] '{print $1}')
use_commercial_ssl=$(echo $(printenv "USE_COMMERCIAL_SSL"))

if [[ ${protocol} == 'https' && ${use_commercial_ssl} == 'true' ]]; then
  commercial_ssl_name=$(echo $(printenv "COMMERCIAL_SSL_NAME"))
  sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/" /laravel-echo-server/${protocol}/laravel-echo-server.json || echo "[WARNING] laravel-echo-server ###COMMERCIAL_SSL_NAME### 치환 실패"
fi

\cp /laravel-echo-server/${protocol}/laravel-echo-server.json /var/www/app
sleep 2
service supervisor start || echo "[ERROR] supervisor 를 띄우는데 실패 하였습니다."
sleep 5
chmod 777 laravel-echo-server.lock || echo "[ERROR] laravel-echo-server 를 띄우는데 실패 하였습니다."
supervisorctl restart all || echo "[ERROR] supervisorctl 를 재시작 하는 것에 실패 하였습니다."

echo "[NOTICE] crontab 을 시작합니다"
service cron start
crontab /etc/cron.d/cronjob