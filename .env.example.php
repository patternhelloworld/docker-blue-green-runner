# IMPORTANT - mac : docker.for.mac.localhost OR check IP. / win : host.docker.internal OR you can just type your host IP.
HOST_IP=host.docker.internal

# I recommend you should type your exposed formal URL or IP such as https://test.com for the test of 'check_availability_out_of_container' in the script 'run.sh'
APP_URL=https://localhost:8081

USE_COMMERCIAL_SSL=false
COMMERCIAL_SSL_NAME=yyy

DOCKER_LAYER_CORRUPTION_RECOVERY=false

NGINX_RESTART=false

# The method of acquiring Docker images:
# build (Used in developer's local environment or during Jenkins builds when a new image needs to be built, so this module is typically used)
# registry (Used on deployment servers where images are fetched from a repository, so this module is used)
# If you choose the "build" method, you don't need to input the values below since Dockerfile is used (no image is fetched from the Docker registry).
GIT_IMAGE_LOAD_FROM=build
GIT_IMAGE_LOAD_FROM_HOST=xxx
GIT_IMAGE_LOAD_FROM_PATHNAME=xxx
GIT_TOKEN_IMAGE_LOAD_FROM_USERNAME=xxx
GIT_TOKEN_IMAGE_LOAD_FROM_PASSWORD=xxx
GIT_IMAGE_VERSION=1.0.0

PROJECT_NAME=laravel_crud_boilerplate
PROJECT_LOCATION=/var/www/app
PROJECT_PORT=8081
# Example (8093,8094,11000...)
ADDITIONAL_PORTS=

# If you locate your project on ../ (upper folder)
HOST_ROOT_LOCATION=./samples/laravel-crud-boilerplate
# If you locate your project's Dockerfile ../ (upper folder)
DOCKER_FILE_LOCATION=./samples/laravel-crud-boilerplate

# This is for integrating health checkers such as "https://www.baeldung.com/spring-boot-actuators"
APP_HEALTH_CHECK_PATH=api/v1/health
BAD_APP_HEALTH_CHECK_PATTERN=DOWN
GOOD_APP_HEALTH_CHECK_PATTERN=UP


# This is for environment variables for docker-compose-app.
DOCKER_COMPOSE_ENVIRONMENT={"XDEBUG_CONFIG":"idekey=IDE_DEBUG","PHP_IDE_CONFIG":"serverName=laravel-crud-boilerplate"}
# This goes with "docker build ... in the 'run.sh' script file", and the command always contain "HOST_IP" and "APP_ENV" above.
# docker exec -it CONTAINER_NAME cat /var/log/env_build_args.log
DOCKER_BUILD_ARGS={"SAMPLE":"YAHOO","SAMPLE2":"YAHOO2","shared_volume_group_id":"1351","shared_volume_group_name":"laravel-shared-volume-group"}
DOCKER_BUILD_LABELS=["foo=happy","bar=sad"]
# EX. --platform linux/amd64
DOCKER_BUILD_ADDITIONAL_RAW_PARAMS=
# Your Git's commit SHA will be added as a label to DOCKER_BUILD_LABELS when your container is built.
DOCKER_BUILD_SHA_INSERT_GIT_ROOT=

# In the case of "REAL," the project is not synchronized in its entirety. The source codes that are required for only production are injected.
# For SSL, the host folder is recommended to be './.docker/ssl' to be synchronized with 'docker-orchestration-app-nginx-original.yml'
DOCKER_COMPOSE_SELECTIVE_VOLUMES=["./shared/app-error-logs:/var/www/app/storage/logs","./.docker/ssl:/etc/apache2/ssl"]
DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES=["./shared/nginx-error-logs:/var/log/nginx"]
DOCKER_COMPOSE_HOST_VOLUME_CHECK=false

NGINX_CLIENT_MAX_BODY_SIZE=50M

USE_MY_OWN_APP_YML=false

SKIP_BUILDING_APP_IMAGE=false

ORCHESTRATION_TYPE=compose

ONLY_BUILDING_APP_IMAGE=false

DOCKER_BUILD_MEMORY_USAGE=1G

USE_NGINX_RESTRICTED_LOCATION=false
# ex. /docs/api-app.html
NGINX_RESTRICTED_LOCATION=xxx

REDIRECT_HTTPS_TO_HTTP=false

NGINX_LOGROTATE_FILE_NUMBER=7
NGINX_LOGROTATE_FILE_SIZE=100K

SHARED_VOLUME_GROUP_ID=1351
SHARED_VOLUME_GROUP_NAME=laravel-shared-volume-group
UIDS_BELONGING_TO_SHARED_VOLUME_GROUP_ID=1000

USE_MY_OWN_NGINX_ORIGIN=false