FROM nginx:latest

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

# If you want to use self-purchased SSL certificates, place the certificates in the ./.docker/ssl/ directory (refer to the file names in the nginx configuration). In the .env file, set USE_COMMERCIAL_SSL to true.
COPY ./.docker/ssl/ /etc/nginx/ssl/

#CMD ["/usr/bin/runsvdir", "/etc/service"]
ENTRYPOINT bash /entrypoint.sh