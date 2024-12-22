#!/bin/bash

echo "[INSIDE_NGINX_CONTAINER][NOTICE] In case the original file './docker/nginx/logrotate' has CRLF. That causes errors to Logrotate. So replacing CRLF to LF"
sed -i -e 's/\r$//' /etc/logrotate.d/nginx || echo "[INSIDE_NGINX_CONTAINER][NOTICE] Failed in replacing CRLF to LF on '/etc/logrotate.d/nginx', but it is a minor error, we continue the process."

shared_volume_group_id=$(printenv SHARED_VOLUME_GROUP_ID)
if [[ -n ${shared_volume_group_id} ]]; then
  echo "[INSIDE_NGINX_CONTAINER][NOTICE] Give safe permissions to '/var/log/nginx'."
  chown -R root:${shared_volume_group_id} /var/log/nginx || echo "[INSIDE_NGINX_CONTAINER][NOTICE] Failed in running 'chown -R root:${shared_volume_group_id} /var/log/nginx', we continue the process."
  chmod -R 750 /var/log/nginx || echo "[INSIDE_NGINX_CONTAINER][NOTICE] Failed in running 'chmod -R 750 /var/log/nginx', but it is a minor error, we continue the process."
else
  echo "[INSIDE_NGINX_CONTAINER][WARNING] ${shared_volume_group_id} NOT found."
fi

echo "[INSIDE_NGINX_CONTAINER][NOTICE] Start Logrotate (every hour at minute 1) for logging Nginx (Access, Error) logs"
(crontab -l -u root; echo "1 * * * * /usr/sbin/logrotate /etc/logrotate.conf") | crontab || echo "[WARN] Registering Cron failed."
service cron restart || echo "[WARN] Restarting Cron failed."


# From this point on, the configuration of the NGINX consul-template begins.
if [[ ! -d /etc/consul-templates ]]; then
    echo "[INSIDE_NGINX_CONTAINER][NOTICE] As the directory name '/etc/consul-templates' does NOT exist, it has been created."
    mkdir /etc/consul-templates
fi

app_url=$(printenv APP_URL)
protocol=$(echo ${app_url} | awk -F[/:] '{print $1}')
echo "[INSIDE_NGINX_CONTAINER][NOTICE] Copy the prepared files for ${protocol} from '/ctmpl/${protocol}' to '/etc/consul-templates'."
sleep 2
cp -f /ctmpl/${protocol}/nginx.conf.prepared.blue /etc/consul-templates
cp -f /ctmpl/${protocol}/nginx.conf.prepared.green /etc/consul-templates

# SSL
if [[ ${protocol} = 'https' ]]; then

    use_commercial_ssl=$(printenv USE_COMMERCIAL_SSL)
    commercial_ssl_name=$(printenv COMMERCIAL_SSL_NAME)

    echo "[INSIDE_NGINX_CONTAINER][DEBUG] USE_COMMERCIAL_SSL : ${use_commercial_ssl} , COMMERCIAL_SSL_NAME : ${commercial_ssl_name}"

    nginxSslRoot="/etc/nginx/ssl"
    nginxCrt="/etc/nginx/ssl/${commercial_ssl_name}.crt"
    nginxChainedCrt="/etc/nginx/ssl/${commercial_ssl_name}.chained.crt"
    nginxKey="/etc/nginx/ssl/${commercial_ssl_name}.key"

    if [[ ${use_commercial_ssl} == false ]] && [[ ! -f ${nginxChainedCrt} || ! -f ${nginxCrt} || ! -f ${nginxKey} || ! -s ${nginxChainedCrt} || ! -s ${nginxCrt} || ! -s ${nginxKey} ]]; then

        echo "[INSIDE_NGINX_CONTAINER][NOTICE] Creating SSL certificates for closed network purposes."

        if [[ ! -d ${nginxSslRoot} ]]; then
            mkdir ${nginxSslRoot}
        fi

        if [[ -f ${nginxChainedCrt} ]]; then
            rm -f ${nginxChainedCrt}
        fi

        if [[ -f ${nginxCrt} ]]; then
            rm -f ${nginxCrt}
        fi

        if [[ -f ${nginxKey} ]]; then
            rm -f ${nginxKey}
        fi

        openssl req -subj '/CN=localhost' -x509 -newkey rsa:4096 -nodes -keyout ${nginxKey} -out ${nginxChainedCrt} -days 365

    fi

    echo "[INSIDE_NGINX_CONTAINER][NOTICE] For Apache2 containers, run cp -f /etc/nginx/ssl/${commercial_ssl_name}.chained.crt /etc/nginx/ssl/${commercial_ssl_name}.crt"
    cp -f /etc/nginx/ssl/${commercial_ssl_name}.chained.crt /etc/nginx/ssl/${commercial_ssl_name}.crt

    chown -R root:${shared_volume_group_id} /etc/nginx/ssl
    chmod 640 /etc/nginx/ssl/${commercial_ssl_name}.key
    chmod 644 /etc/nginx/ssl/${commercial_ssl_name}.chained.crt
    chmod 644 /etc/nginx/ssl/${commercial_ssl_name}.crt

    sed -i -e "s/!#{COMMERCIAL_SSL_NAME}/${commercial_ssl_name}/" /etc/consul-templates/nginx.conf.prepared.blue || (echo "commercial_ssl_name (${commercial_ssl_name}) on .env failed to be applied. (prepared blue)" && exit 1)
    sed -i -e "s/!#{COMMERCIAL_SSL_NAME}/${commercial_ssl_name}/" /etc/consul-templates/nginx.conf.prepared.green || (echo "commercial_ssl_name (${commercial_ssl_name}) on .env failed to be applied. (prepared green)" && exit 1)
fi


echo "[INSIDE_NGINX_CONTAINER][NOTICE] Start Nginx before applying the template"
service nginx start
echo "[INSIDE_NGINX_CONTAINER][NOTICE] Check if it has started successfully."
for retry_count in {1..5}; do
  pid_was=$(pidof nginx 2>/dev/null || echo '-')

  if [[ ${pid_was} != '-' ]]; then
    echo "[INSIDE_NGINX_CONTAINER][NOTICE] It has started normally."
    break
  else
    echo "[INSIDE_NGINX_CONTAINER][NOTICE] If it fails to start properly, we retry. (pid_was : ${pid_was})"
  fi

  if [[ ${retry_count} -eq 4 ]]; then
    echo "[INSIDE_NGINX_CONTAINER][ERROR] After unsuccessful retries to confirm if Nginx has fully started, we maintain the current state and exit the script."
    exit 1
  fi

  echo "[INSIDE_NGINX_CONTAINER][NOTICE] Retry four times with a three-second interval... (retrying ${retry_count} times...)"
  sleep 3
done

echo "[INSIDE_NGINX_CONTAINER][NOTICE] Start the Nginx."
bash /etc/service/nginx/run/nginx.service
