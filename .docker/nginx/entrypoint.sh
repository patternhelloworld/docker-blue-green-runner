#!/bin/bash
project_name=$(printenv PROJECT_NAME)
project_port=$(printenv PROJECT_PORT)
app_url=$(printenv APP_URL)
protocol=$(echo ${app_url} | awk -F[/:] '{print $1}')
consul_key=$(echo $(printenv CONSUL_KEY_VALUE_STORE) | cut -d "/" -f6)\\/$(echo $(printenv CONSUL_KEY_VALUE_STORE) | cut -d "/" -f7)
nginx_client_max_body_size=$(printenv NGINX_CLIENT_MAX_BODY_SIZE)

echo "[NOTICE] In case the original file './docker/nginx/logrotate' has CRLF. That causes errors to Logrotate. So replacing CRLF to LF"
sed -i -e 's/\r$//' /etc/logrotate.d/nginx || echo "[NOTICE] Failed in replacing CRLF to LF, but it is a minor error, we continue the process."

echo "[NOTICE] Give safe permissions to '/var/log/nginx'."
chown -R www-data /var/log/nginx


#echo "[NOTICE] Start Logrotate for logging Nginx (Access, Error) logs"
#echo "59 23 * * * /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontab

if [[ ! -d /etc/consul-templates ]]; then
    echo "[NOTICE] As the directory name '/etc/consul-templates' does NOT exist, it has been created."
    mkdir /etc/consul-templates
fi

echo "[NOTICE] Locate the template file for ${protocol}."
sleep 3
mv /ctmpl/${protocol}/nginx.conf.ctmpl /etc/consul-templates

sed -i -e "s/###PROJECT_PORT###/${project_port}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "project_port (${project_port}) replacement failure." && exit 1)
sed -i -e "s/###PROJECT_NAME###/${project_name}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "project_name (${project_name}) replacement failure." && exit 1)
sed -i -e "s/###CONSUL_KEY###/${consul_key}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "consul_key (${consul_key}) replacement failure." && exit 1)
sed -i -e "s/###NGINX_CLIENT_MAX_BODY_SIZE###/${nginx_client_max_body_size}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "nginx_client_max_body_size (${nginx_client_max_body_size}) replacement failure." && exit 1)

if [[ ${protocol} = 'https' ]]; then

    use_commercial_ssl=$(printenv USE_COMMERCIAL_SSL)
    commercial_ssl_name=$(printenv COMMERCIAL_SSL_NAME)

    echo "[NOTICE] Start the job of relocating certificates."

    # Unlike Apache2, Nginx does not require a separate chained certificate.
    \cp /etc/nginx/ssl/${commercial_ssl_name}.crt /etc/nginx/ssl/${commercial_ssl_name}.chained.crt

    nginxSslRoot="/etc/nginx/ssl"
    nginxCrt="/etc/nginx/ssl/${commercial_ssl_name}.chained.crt"
    nginxKey="/etc/nginx/ssl/${commercial_ssl_name}.key"

    if [[ ${use_commercial_ssl} == false ]] && [[ ! -f ${nginxCrt} || ! -f ${nginxKey} || ! -s ${nginxCrt} || ! -s ${nginxKey} ]]; then

        echo "[NOTICE] Creating SSL certificates for closed network purposes."

        if [[ ! -d ${nginxSslRoot} ]]; then
            mkdir ${nginxSslRoot}
        fi
        if [[ -f ${nginxCrt} ]]; then
            rm ${nginxCrt}
        fi

        if [[ -f ${nginxKey} ]]; then
            rm ${nginxKey}
        fi

        openssl req -subj '/CN=localhost' -x509 -newkey rsa:4096 -nodes -keyout ${nginxKey} -out ${nginxCrt} -days 365

    fi

    chown -R root:www-data /etc/nginx/ssl
    chmod 640 /etc/nginx/ssl/${commercial_ssl_name}.key
    chmod 644 /etc/nginx/ssl/${commercial_ssl_name}.chained.crt


    app_host=$(echo ${app_url} | awk -F[/:] '{print $4}')

    escaped_app_url=$(echo ${app_url} | sed 's/\//\\\//g')

    sed -i -e "s/###APP_URL###/${escaped_app_url}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "APP_URL on .env failed to be applied." && exit 1)
    sleep 1
    sed -i -e "s/###APP_HOST###/${app_host}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "APP_HOST on .env failed to be applied." && exit 1)
    sleep 1
    sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "commercial_ssl_name (${commercial_ssl_name}) on .env failed to be applied." && exit 1)
fi


echo "[NOTICE] Start Nginx before applying the template"
service nginx start
echo "[NOTICE] Check if it has started successfully."
for retry_count in {1..5}; do
  pid_was=$(pidof nginx 2>/dev/null || echo '-')

  if [[ ${pid_was} != '-' ]]; then
    echo "[NOTICE] It has started normally."
    break
  else
    echo "[NOTICE] If it fails to start properly, we retry. (pid_was : ${pid_was})"
  fi

  if [[ ${retry_count} -eq 4 ]]; then
    echo "[ERROR] After unsuccessful retries to confirm if Nginx has fully started, we maintain the current state and exit the script."
    exit 1
  fi

  echo "[NOTICE] Retry four times with a three-second interval... (retrying ${retry_count} times...)"
  sleep 3
done
echo "[NOTICE] Applying the Nginx template..."
bash /etc/service/consul-template/run/consul-template.service
echo "[NOTICE] Start the Nginx."
bash /etc/service/nginx/run/nginx.service
