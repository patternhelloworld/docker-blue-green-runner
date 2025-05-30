FROM php:7.4-fpm-buster as backend-build

RUN apt-get -qqy update && apt-get -qqy upgrade

RUN apt-get update && apt-get install -y --no-install-recommends \
        locales \
        apt-utils \
        git \
        g++ \
        libicu-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        libonig-dev \
        libxslt-dev \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        apache2 \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        opcache \
        intl \
        zip \
        calendar \
        dom \
        mbstring \
        gd \
        xsl \
    && pecl install apcu \
    && docker-php-ext-enable apcu


RUN curl -s https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

ARG DISABLE_CACHE

COPY ./ /var/www/app
WORKDIR /var/www/app
RUN composer install --prefer-dist --optimize-autoloader --no-interaction


FROM php:7.4-fpm-buster  as production

ARG server

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -qqy update && apt-get -qqy upgrade

RUN apt-get update && apt-get install -y --no-install-recommends \
        locales \
        apt-utils \
        git \
        g++ \
        libicu-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        libonig-dev \
        libxslt-dev \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        apache2 \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
        pdo \
        pdo_mysql \
        opcache \
        intl \
        zip \
        calendar \
        dom \
        mbstring \
        gd \
        xsl \
    && pecl install apcu \
    && docker-php-ext-enable apcu



RUN \cp /usr/local/etc/php/php.ini-production  /usr/local/etc/php/php.ini \
&& rm /etc/apache2/sites-available/000-default.conf \
&& rm /etc/apache2/sites-enabled/000-default.conf \
&& a2enmod proxy \
&& a2enmod proxy_http \
&& a2enmod proxy_wstunnel \
&& a2enmod ssl \
&& a2enmod proxy_fcgi \
&& a2enmod rewrite \
&& a2enmod headers \
&& usermod -u 1000 www-data && groupmod -g 1000 www-data

ARG shared_volume_group_id

RUN if getent group $shared_volume_group_id ; then \
        usermod -aG $shared_volume_group_id www-data; \
    else \
        groupadd -g $shared_volume_group_id shared-volume-group && usermod -aG shared-volume-group www-data; \
    fi


RUN sed -i -E "s/(post_max_size\s*=\s*)[^\n\r]+/\1100M/" /usr/local/etc/php/php.ini \
    && sed -i -E "s/(upload_max_filesize\s*=\s*)[^\n\r]+/\1100M/" /usr/local/etc/php/php.ini \
    && sed -i -E "s/(memory_limit\s*=\s*)[^\n\r]+/\11024M/" /usr/local/etc/php/php.ini

RUN curl -s https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

ARG DISABLE_CACHE


COPY --from=backend-build /var/www/app/ /var/www/app
WORKDIR /var/www/app

ARG SAMPLE
ENV SAMPLE=${SAMPLE}
ARG SAMPLE2
ENV SAMPLE2=${SAMPLE2}

RUN echo "${SAMPLE} ${SAMPLE2}" >> /var/log/env_build_args.log

WORKDIR /var/www/app


COPY ./.docker/etc/apache2/apache2.conf /etc/apache2/apache2.conf
COPY ./.docker/etc/apache2/sites-available/default.conf /etc/apache2/sites-available/default.conf

COPY ./.docker/etc/apache2/conf-enabled/security.conf /etc/apache2/conf-enabled/security.conf

COPY ./.docker/etc/sysctl.conf /etc/sysctl.conf

COPY ./.docker/etc/logrotate.d/* /etc/logrotate.d/

COPY ./.docker/oauth2-key/ /var/www/app/storage/

COPY ./.docker/sh/update/$server/run.sh /run.sh

WORKDIR /var/www/app
ENTRYPOINT bash /run.sh && /bin/bash








