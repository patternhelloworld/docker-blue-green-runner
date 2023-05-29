FROM nginx:latest
# RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list



RUN apt-get update -qqy && apt-get -qqy --force-yes install curl runit wget unzip vim && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG DISABLE_CACHE
ARG protocol

RUN wget --no-check-certificate https://releases.hashicorp.com/consul-template/0.19.3/consul-template_0.19.3_linux_amd64.zip && \
    unzip -d /usr/local/bin consul-template_0.19.3_linux_amd64.zip && \
    rm -rf consul-template_0.19.3_linux_amd64.zip

COPY ./.docker/nginx/entrypoint.sh /
COPY ./.docker/nginx/nginx.service /etc/service/nginx/run/
COPY ./.docker/nginx/consul-template.service /etc/service/consul-template/run/
COPY ./.docker/nginx/ctmpl/ /ctmpl
RUN chmod +x /etc/service/nginx/run && chmod +x /etc/service/consul-template/run
RUN sed -i -e 's/\r$//' /etc/service/consul-template/run/consul-template.service
RUN sed -i -e 's/\r$//' /etc/service/nginx/run/nginx.service
RUN rm /etc/nginx/conf.d/default.conf

# 자체적으로 구매한 인증서를 사용할 경우 ./.docker/ssl/ 에 인증서들을 위치시키고 (파일명은 nginx 설정 값 참조) .env 에서 USE_COMMERCIAL_SSL 을 true 로 해야 함
COPY ./.docker/ssl/ /etc/nginx/ssl/

#CMD ["/usr/bin/runsvdir", "/etc/service"]
ENTRYPOINT bash /entrypoint.sh