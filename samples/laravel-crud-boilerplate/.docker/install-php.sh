#!/bin/sh

apk add bzip2 file re2c freetds freetype icu libintl libldap libjpeg libmcrypt libpng libpq libwebp libzip nodejs npm

TMP="autoconf \
    bzip2-dev \
    freetds-dev \
    freetype-dev \
    g++ \
    gcc \
    gettext-dev \
    icu-dev \
    jpeg-dev \
    libmcrypt-dev \
    libpng-dev \
    libwebp-dev \
    libxml2-dev \
    libzip-dev \
    make \
    openldap-dev \
    postgresql-dev"

apk add $TMP

# Configure extensions
docker-php-ext-configure gd --with-jpeg-dir=usr/ --with-freetype-dir=usr/ --with-webp-dir=usr/
docker-php-ext-configure ldap --with-libdir=lib/
docker-php-ext-configure pdo_dblib --with-libdir=lib/

docker-php-ext-install \
    bz2 \
    exif \
    gd \
    gettext \
    intl \
    ldap \
    pdo_dblib \
    pdo_pgsql \
    xmlrpc \
    zip \
    mysqli \
    pdo_mysql

# Install Xdebug
# ${HOST_IP} : mac : docker.for.mac.localhost / win : host.docker.internal
pecl install xdebug-3.0.2
  echo "" >> /var/log/xdebug.log && chmod 777 /var/log/xdebug.log && echo -e "xdebug.log_level=1 \n xdebug.log=/var/log/xdebug.log \n zend_extension = xdebug.so \n xdebug.idekey=PHPSTORM \n xdebug.discover_client_host=0 \n xdebug.default_enable = 1 \n xdebug.remote_handler = "dbgp" \n xdebug.remote_port=9002 \n xdebug.client_host=${HOST_IP} \n xdebug.client_port=9002 \n xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini

# Install composer
cd /tmp && php -r "readfile('https://getcomposer.org/installer');" | php && \
	mv composer.phar /usr/bin/composer && \
	chmod +x /usr/bin/composer

apk del $TMP

# Install PHPUnit
curl -sSL -o /usr/bin/phpunit https://phar.phpunit.de/phpunit.phar && chmod +x /usr/bin/phpunit

# Set timezone
#RUN echo Asia/Karachi > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata
