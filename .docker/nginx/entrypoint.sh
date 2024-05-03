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

# Set base ENVs

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

# Handle Logging

echo "[INSIDE_NGINX_CONTAINER][NOTICE] In case the original file './docker/nginx/logrotate' has CRLF. That causes errors to Logrotate. So replacing CRLF to LF"
sed -i -e 's/\r$//' /etc/logrotate.d/nginx || echo "[INSIDE_NGINX_CONTAINER][NOTICE] Failed in replacing CRLF to LF on '/etc/logrotate.d/nginx', but it is a minor error, we continue the process."

shared_volume_group_id=$(printenv SHARED_VOLUME_GROUP_ID)
if [[ -n ${shared_volume_group_id} ]]; then
  echo "[INSIDE_NGINX_CONTAINER][NOTICE] Give safe permissions to '/var/log/nginx'."
  chown -R root:shared_volume_group_id /var/log/nginx || echo "[INSIDE_NGINX_CONTAINER][NOTICE] Failed in running 'chown -R root:nginx /var/log/nginx', we continue the process."
  chmod -R 770 /var/log/nginx || echo "[INSIDE_NGINX_CONTAINER][NOTICE] Failed in running 'chmod -R 660 /var/log/nginx', but it is a minor error, we continue the process."
else
  echo "[INSIDE_NGINX_CONTAINER][WARNING] ${shared_volume_group_id} NOT found."
fi

echo "[INSIDE_NGINX_CONTAINER][NOTICE] Start Logrotate (every hour at minute 1) for logging Nginx (Access, Error) logs"
nginx_logrotate_file_number=$(printenv NGINX_LOGROTATE_FILE_NUMBER)
nginx_logrotate_file_size=$(printenv NGINX_LOGROTATE_FILE_SIZE)
shared_volume_group_name=$(printenv SHARED_VOLUME_GROUP_NAME)

sed -i -e "s/###NGINX_LOGROTATE_FILE_NUMBER###/${nginx_logrotate_file_number}/" /etc/logrotate.d/nginx || (echo "nginx_logrotate_file_number (${nginx_logrotate_file_number}) replacement failure.")
sed -i -e "s/###NGINX_LOGROTATE_FILE_SIZE###/${nginx_logrotate_file_size}/" /etc/logrotate.d/nginx || (echo "nginx_logrotate_file_size (${nginx_logrotate_file_size}) replacement failure.")
sed -i -e "s/###SHARED_VOLUME_GROUP_NAME###/${shared_volume_group_name}/" /etc/logrotate.d/nginx || (echo "shared_volume_group_name (${shared_volume_group_name}) replacement failure.")

(crontab -l -u root; echo "1 * * * * /usr/sbin/logrotate /etc/logrotate.conf") | crontab || echo "[WARN] Registering Cron failed."
service cron restart || echo "[WARN] Restarting Cron failed."


# From this point on, the configuration of the NGINX consul-template begins.

if [[ ! -d /etc/consul-templates ]]; then
    echo "[INSIDE_NGINX_CONTAINER][NOTICE] As the directory name '/etc/consul-templates' does NOT exist, it has been created."
    mkdir /etc/consul-templates
fi

echo "[INSIDE_NGINX_CONTAINER][NOTICE] Locate the template file for ${protocol}."
sleep 3
cp -f /ctmpl/${protocol}/nginx.conf.ctmpl /etc/consul-templates
cp -f /ctmpl/${protocol}/nginx.conf.contingency /etc/consul-templates

sed -i -e "s/###EXPOSE_PORT###/${expose_port}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "expose_port (${expose_port}) replacement (ctmpl) failure." && exit 1)
sed -i -e "s/###EXPOSE_PORT###/${expose_port}/" /etc/consul-templates/nginx.conf.contingency || (echo "expose_port (${expose_port}) replacement (contingency) failure." && exit 1)

sed -i -e "s/###APP_PORT###/${app_port}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "app_port (${app_port}) replacement (ctmpl) failure." && exit 1)
sed -i -e "s/###APP_PORT###/${app_port}/" /etc/consul-templates/nginx.conf.contingency || (echo "app_port (${app_port}) replacement (contingency) failure." && exit 1)

sed -i -e "s/###PROJECT_NAME###/${project_name}/g" /etc/consul-templates/nginx.conf.ctmpl || (echo "project_name (${project_name}) replacement (ctmpl) failure." && exit 1)
sed -i -e "s/###PROJECT_NAME###/${project_name}/g" /etc/consul-templates/nginx.conf.contingency || (echo "project_name (${project_name}) replacement (contingency) failure." && exit 1)

sed -i -e "s/###CONSUL_KEY###/${consul_key}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "consul_key (${consul_key}) replacement (ctmpl) failure." && exit 1)
sed -i -e "s/###CONSUL_KEY###/${consul_key}/" /etc/consul-templates/nginx.conf.contingency || (echo "consul_key (${consul_key}) replacement (contingency) failure." && exit 1)

sed -i -e "s/###NGINX_CLIENT_MAX_BODY_SIZE###/${nginx_client_max_body_size}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "nginx_client_max_body_size (${nginx_client_max_body_size}) replacement (ctmpl) failure." && exit 1)
sed -i -e "s/###NGINX_CLIENT_MAX_BODY_SIZE###/${nginx_client_max_body_size}/" /etc/consul-templates/nginx.conf.contingency || (echo "nginx_client_max_body_size (${nginx_client_max_body_size}) replacement (contingency) failure." && exit 1)

use_nginx_restricted_location=$(printenv USE_NGINX_RESTRICTED_LOCATION)
nginx_restricted_location=$(printenv NGINX_RESTRICTED_LOCATION)

if [[ ${use_nginx_restricted_location} = 'true' ]]; then

  sed -i -e "/###USE_NGINX_RESTRICTED_LOCATION###/c \
      location ${nginx_restricted_location} { \
          add_header Pragma no-cache; \
          add_header Cache-Control no-cache; \
  \
                          auth_basic           \"Restricted\"; \
                          auth_basic_user_file /etc/nginx/custom-files/.htpasswd; \
  \
         {{ with \$key_value := keyOrDefault \"${consul_key}\" \"blue\" }} \
             {{ if or (eq \$key_value \"blue\") (eq \$key_value \"green\") }} \
                  proxy_pass ${protocol}://${project_name}-{{ \$key_value }}:${app_port}; \
           {{ else }} \
                  proxy_pass ${protocol}://${project_name}-blue:${app_port}; \
              {{ end }} \
          {{ end }}  \
          proxy_set_header Host \$http_host; \
          proxy_set_header X-Scheme \$scheme; \
          proxy_set_header X-Forwarded-Protocol \$scheme; \
          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; \
          proxy_set_header X-Real-IP \$remote_addr; \
          proxy_http_version 1.1; \
          proxy_read_timeout 300s; \
          proxy_connect_timeout 75s; \
      }" /etc/consul-templates/nginx.conf.ctmpl

  sed -i -e "/###USE_NGINX_RESTRICTED_LOCATION###/c \
      location ${nginx_restricted_location} { \
          add_header Pragma no-cache; \
          add_header Cache-Control no-cache; \
  \
                          auth_basic           \"Restricted\"; \
                          auth_basic_user_file /etc/nginx/custom-files/.htpasswd; \
  \
          proxy_pass ${protocol}://${project_name}-###APP_STATE###:${app_port}; \
          proxy_set_header Host \$http_host; \
          proxy_set_header X-Scheme \$scheme; \
          proxy_set_header X-Forwarded-Protocol \$scheme; \
          proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for; \
          proxy_set_header X-Real-IP \$remote_addr; \
          proxy_http_version 1.1; \
          proxy_read_timeout 300s; \
          proxy_connect_timeout 75s; \
      }" /etc/consul-templates/nginx.conf.contingency


else
  sed -i -e "s/###USE_NGINX_RESTRICTED_LOCATION###//" /etc/consul-templates/nginx.conf.ctmpl || (echo "use_nginx_restricted_location=false (${use_nginx_restricted_location}) replacement (ctmpl) failure." && exit 1)
  sed -i -e "s/###USE_NGINX_RESTRICTED_LOCATION###//" /etc/consul-templates/nginx.conf.contingency || (echo "use_nginx_restricted_location=false (${use_nginx_restricted_location}) replacement (contingency) failure." && exit 1)
fi

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

    chown -R root:nginx /etc/nginx/ssl
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
    sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "commercial_ssl_name (${commercial_ssl_name}) on .env failed to be applied. (ctmpl)" && exit 1)
    sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/" /etc/consul-templates/nginx.conf.contingency || (echo "commercial_ssl_name (${commercial_ssl_name}) on .env failed to be applied. (contingency)" && exit 1)
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
echo "[INSIDE_NGINX_CONTAINER][NOTICE] Creating 'nginx.conf.contingency.blue', 'nginx.conf.contingency.green' ..."
cp -f /etc/consul-templates/nginx.conf.contingency /etc/consul-templates/nginx.conf.contingency.blue || (echo "Failed in creating /etc/consul-templates/nginx.conf.contingency.blue" && exit 1)
sed -i -e "s/###APP_STATE###/blue/" /etc/consul-templates/nginx.conf.contingency.blue || (echo "Failed in creating /etc/consul-templates/nginx.conf.contingency.blue (2)" && exit 1)
cp -f /etc/consul-templates/nginx.conf.contingency /etc/consul-templates/nginx.conf.contingency.green || (echo "Failed in creating /etc/consul-templates/nginx.conf.contingency.green" && exit 1)
sed -i -e "s/###APP_STATE###/green/" /etc/consul-templates/nginx.conf.contingency.green || (echo "Failed in creating /etc/consul-templates/nginx.conf.contingency.green (2)" && exit 1)

echo "[INSIDE_NGINX_CONTAINER][NOTICE] Applying the Nginx template..."
bash /etc/service/consul-template/run/consul-template.service
echo "[INSIDE_NGINX_CONTAINER][NOTICE] Start the Nginx."
bash /etc/service/nginx/run/nginx.service
