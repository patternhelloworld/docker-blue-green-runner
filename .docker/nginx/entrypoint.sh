#!/bin/bash
project_name=$(printenv PROJECT_NAME)
project_port=$(printenv PROJECT_PORT)
app_url=$(printenv APP_URL)
protocol=$(echo ${app_url} | awk -F[/:] '{print $1}')
consul_key=$(echo $(printenv CONSUL_KEY_VALUE_STORE) | cut -d "/" -f6)\\/$(echo $(printenv CONSUL_KEY_VALUE_STORE) | cut -d "/" -f7)

if [[ ! -d /etc/consul-templates ]]; then
    echo "[NOTICE] /etc/consul-templates 디랙토리가 없어서 생성하였습니다."
    mkdir /etc/consul-templates
fi

echo "[NOTICE] ${protocol} 에 해당하는 템플릿 파일을 위치 시킵니다."
mv /ctmpl/${protocol}/nginx.conf.ctmpl /etc/consul-templates

sed -i -e "s/###PROJECT_PORT###/${project_port}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "project_port (${project_port}) 치환 실패" && exit 1)
sed -i -e "s/###PROJECT_NAME###/${project_name}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "project_name (${project_name}) 치환 실패" && exit 1)
sed -i -e "s/###CONSUL_KEY###/${consul_key}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "consul_key (${consul_key}) 치환 실패" && exit 1)

if [[ ${protocol} = 'https' ]]; then

    use_commercial_ssl=$(printenv USE_COMMERCIAL_SSL)
    commercial_ssl_name=$(printenv COMMERCIAL_SSL_NAME)

    echo "[NOTICE] 인증서를 위치시키는 작업을 시작합니다."

    # nginx 의 경우 apache2 와 다르게 별도로 chained 인증서가 필요하지 않다.
    \cp /etc/nginx/ssl/${commercial_ssl_name}.crt /etc/nginx/ssl/${commercial_ssl_name}.chained.crt

    nginxSslRoot="/etc/nginx/ssl"
    nginxCrt="/etc/nginx/ssl/${commercial_ssl_name}.chained.crt"
    nginxKey="/etc/nginx/ssl/${commercial_ssl_name}.key"

    if [[ ${use_commercial_ssl} == false ]] && [[ ! -f ${nginxCrt} || ! -f ${nginxKey} || ! -s ${nginxCrt} || ! -s ${nginxKey} ]]; then

        echo "[NOTICE] 폐쇄망 용 SSL 인증서를 생성합니다."

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

    sed -i -e "s/###APP_URL###/${escaped_app_url}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "###APP_URL### 치환 실패" && exit 1)
    sleep 1
    sed -i -e "s/###APP_HOST###/${app_host}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "###APP_HOST### 치환 실패" && exit 1)
    sleep 1
    sed -i -e "s/###COMMERCIAL_SSL_NAME###/${commercial_ssl_name}/" /etc/consul-templates/nginx.conf.ctmpl || (echo "commercial_ssl_name (${commercial_ssl_name}) 치환 실패" && exit 1)
fi


echo "[NOTICE] 템플릿 적용 전 Nginx 를 시작합니다."
service nginx start
echo "[NOTICE] Nginx 가 완전히 띄어졌는 지 확인합니다."
for retry_count in {1..5}; do
  pid_was=$(pidof nginx 2>/dev/null || echo '-')

  if [[ ${pid_was} != '-' ]]; then
    echo "[NOTICE] 정상적으로 띄어졌습니다."
    break
  else
    echo "[NOTICE] 정상적으로 띄어지지 않아서 재시도 합니다. (pid_was : ${pid_was})"
  fi

  if [[ ${retry_count} -eq 4 ]]; then
    echo "[ERROR] Nginx 가 완전히 띄어졌는 지 확인 재시도에 실패하여 기존의 상태를 유지하고 스크립트를 종료 합니다."
    exit 1
  fi

  echo "[NOTICE] 3초에 한번씩 총 4회 재시도... (${retry_count} 회 재시도 중...)"
  sleep 3
done
echo "[NOTICE] Nginx 템플릿을 적용합니다."
bash /etc/service/consul-template/run/consul-template.service
echo "[NOTICE] Nginx 를 기동합니다."
bash /etc/service/nginx/run/nginx.service