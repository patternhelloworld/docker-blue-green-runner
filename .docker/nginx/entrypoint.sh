#!/bin/bash

set_expose_and_app_port(){

  if [[ -z ${1} ]]
    then
      echo "[INSIDE_NGINX_CONTAINER][ERROR] The 'project_port' has not been passed. Terminate the entire process to prevent potential errors." && exit 1
  fi

  if echo "${1}" | grep -Eq '^\[[0-9]+,[0-9]+\]$'; then
      IFS=',' read -ra values <<< "${project_port//[^0-9,]}"
      expose_port=${values[0]}
      app_port=${values[1]}
  else
      expose_port="$project_port"
      app_port="$project_port"
  fi
}

project_name=$(printenv PROJECT_NAME)
project_port=$(printenv PROJECT_PORT)

if ! echo "$project_port" | grep -Eq '^\[[0-9]+,[0-9]+\]$|^[0-9]+$'; then
  echo "[INSIDE_NGINX_CONTAINER][ERROR] project_port on .env is a wrong type. (ex. [30000,3000] or 8888 formats are available). Correct .env, and re-run ./run.sh." && exit 1
fi
set_expose_and_app_port ${project_port}

echo "[INSIDE_NGINX_CONTAINER][DEBUG] expose_port : ${expose_port} , app_port : ${app_port}"

app_url=$(printenv APP_URL)
protocol=$(echo ${app_url} | awk -F[/:] '{print $1}')
consul_key=$(echo $(printenv CONSUL_KEY_VALUE_STORE) | cut -d "/" -f6)\\/$(echo $(printenv CONSUL_KEY_VALUE_STORE) | cut -d "/" -f7)
nginx_client_max_body_size=$(printenv NGINX_CLIENT_MAX_BODY_SIZE)

echo "[DEBUG] protocol : ${protocol} , consul_key : ${consul_key}, nginx_client_max_body_size : ${nginx_client_max_body_size}"

echo "[INSIDE_NGINX_CONTAINER][NOTICE] In case the original file './docker/nginx/logrotate' has CRLF. That causes errors to Logrotate. So replacing CRLF to LF"
sed -i -e 's/\r$//' /etc/logrotate.d/nginx || echo "[INSIDE_NGINX_CONTAINER][NOTICE] Failed in replacing CRLF to LF, but it is a minor error, we continue the process."

echo "[INSIDE_NGINX_CONTAINER][NOTICE] Give safe permissions to '/var/log/nginx'."
chown -R www-data /var/log/nginx


#echo "[NOTICE] Start Logrotate for logging Nginx (Access, Error) logs"
#echo "59 23 * * * /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontab

if [[ ! -d /etc/consul-templates ]]; then
    echo "[INSIDE_NGINX_CONTAINER][NOTICE] As the directory name '/etc/consul-templates' does NOT exist, it has been created."
    mkdir /etc/consul-templates
fi

echo "[INSIDE_NGINX_CONTAINER][NOTICE] Locate the template file for ${protocol}."
sleep 3
cp -f /ctmpl/${protocol}/nginx.conf.ctmpl /etc/consul-templates

sed -i -e "s/###EXPOSE_PORT###/${expose_port}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "expose_port (${expose_port}) replacement failure." && exit 1)
sed -i -e "s/###APP_PORT###/${app_port}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "app_port (${app_port}) replacement failure." && exit 1)

sed -i -e "s/###PROJECT_NAME###/${project_name}/g" /etc/consul-templates/nginx.conf.ctmpl || (echo "project_name (${project_name}) replacement failure." && exit 1)
sed -i -e "s/###CONSUL_KEY###/${consul_key}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "consul_key (${consul_key}) replacement failure." && exit 1)
sed -i -e "s/###NGINX_CLIENT_MAX_BODY_SIZE###/${nginx_client_max_body_size}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "nginx_client_max_body_size (${nginx_client_max_body_size}) replacement failure." && exit 1)

if [[ ${protocol} = 'https' ]]; then

    use_commercial_ssl=$(printenv USE_COMMERCIAL_SSL)
    commercial_ssl_name=$(printenv COMMERCIAL_SSL_NAME)

    echo "[DEBUG] USE_COMMERCIAL_SSL : ${use_commercial_ssl} , COMMERCIAL_SSL_NAME : ${commercial_ssl_name}"

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

    chown -R root:www-data /etc/nginx/ssl
    chmod 640 /etc/nginx/ssl/${commercial_ssl_name}.key
    chmod 644 /etc/nginx/ssl/${commercial_ssl_name}.chained.crt
    chmod 644 /etc/nginx/ssl/${commercial_ssl_name}.crt

    app_host=$(echo ${app_url} | awk -F[/:] '{print $4}')
    echo "[INSIDE_NGINX_CONTAINER][DEBUG] app_host : ${app_host}"

    #escaped_app_url=$(echo ${app_url} | sed 's/\//\\\//g')
    #echo "[DEBUG] escaped_app_url : ${escaped_app_url}"

    #sed -i -e "s/###APP_URL###/${escaped_app_url}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "APP_URL on .env failed to be applied." && exit 1)
    # sleep 1
    #sed -i -e "s/###APP_HOST###/${app_host}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "APP_HOST on .env failed to be applied." && exit 1)
    #sleep 1
    sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "commercial_ssl_name (${commercial_ssl_name}) on .env failed to be applied." && exit 1)
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
echo "[INSIDE_NGINX_CONTAINER][NOTICE] Applying the Nginx template..."
bash /etc/service/consul-template/run/consul-template.service
echo "[INSIDE_NGINX_CONTAINER][NOTICE] Start the Nginx."
bash /etc/service/nginx/run/nginx.service
