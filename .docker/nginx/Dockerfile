FROM nginx:1.25.4

RUN apt-get update -qqy && apt-get -qqy --force-yes install curl runit wget unzip vim logrotate && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG DISABLE_CACHE
ARG protocol
ARG shared_volume_group_id
ARG shared_volume_group_name

RUN if getent group $shared_volume_group_id ; then \
        usermod -aG $shared_volume_group_id nginx; \
    else \
        groupadd -g $shared_volume_group_id $shared_volume_group_name && usermod -aG $shared_volume_group_name nginx; \
    fi

COPY ./.docker/nginx/template/entrypoint.sh /
COPY ./.docker/nginx/template/nginx.service /etc/service/nginx/run/

COPY ./.docker/nginx/template/nginx.conf.main /etc/nginx/nginx.conf
COPY ./.docker/nginx/template/conf.d /conf.d
COPY ./.docker/nginx/template/logrotate/nginx /etc/logrotate.d/nginx

RUN chmod +x /etc/service/nginx/run
RUN sed -i -e 's/\r$//' /etc/service/nginx/run/nginx.service
RUN rm /etc/nginx/conf.d/default.conf

# If you want to use self-purchased SSL certificates, place the certificates in the ./.docker/ssl/ directory (refer to the file names in the nginx configuration). In the .env file, set USE_COMMERCIAL_SSL to true.
COPY ./.docker/ssl/ /etc/nginx/ssl/

#CMD ["/usr/bin/runsvdir", "/etc/service"]
ENTRYPOINT bash /entrypoint.sh