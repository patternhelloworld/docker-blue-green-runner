#!/bin/bash
if [[ ${1} = 'https' ]]; then

  mv /etc/nginx/ssl/${commercial_ssl_name}.crt /etc/nginx/ssl/${commercial_ssl_name}.chained.crt

  nginxSslRoot="/etc/nginx/ssl"
  nginxCrt="/etc/nginx/ssl/${ssl_name}.chained.crt"
  nginxKey="/etc/nginx/ssl/${ssl_name}.key"

  if [[ ! -f ${nginxCrt} || ! -f ${nginxKey} || ! -s ${nginxCrt} || ! -s ${nginxKey} ]]; then

      echo "[NOTICE] 구입한 상업용 인증서가 없으므로 임의로 폐쇄망 용 SSL 인증서를 생성합니다."

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
  chmod 640 ${nginxKey}
  chmod 644 ${nginxCrt}


  app_url=$(printenv APP_URL)
  app_host=$(echo ${app_url} | awk -F[/:] '{print $4}')

  escaped_app_url=$(echo ${app_url} | sed 's/\//\\\//g')

  sed -i -e "s/###APP_URL###/${escaped_app_url}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "###APP_URL### 치환 실패" && exit 1)
  sleep 1
  sed -i -e "s/###APP_HOST###/${app_host}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "###APP_HOST### 치환 실패" && exit 1)

fi