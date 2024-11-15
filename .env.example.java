# IMPORTANT - mac : docker.for.mac.localhost OR check IP. / win : host.docker.internal OR you can just type your host IP.
HOST_IP=host.docker.internal

APP_URL=http://localhost:18200

USE_COMMERCIAL_SSL=yyy
COMMERCIAL_SSL_NAME=yyy

DOCKER_LAYER_CORRUPTION_RECOVERY=false


NGINX_RESTART=false
CONSUL_RESTART=false

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

PROJECT_NAME=spring-sample-h-auth
PROJECT_LOCATION=/var/www/server/spring-sample-h-auth
PROJECT_PORT=[18200,8200]
# Example (8093,8094,11000...)
ADDITIONAL_PORTS=5005

CONSUL_KEY_VALUE_STORE=http://consul:8500/v1/kv/deploy/spring-sample-h-auth

# If you locate your project on ../ (upper folder)
HOST_ROOT_LOCATION=./samples/spring-sample-h-auth
# If you locate your project's Dockerfile ../ (upper folder)
DOCKER_FILE_LOCATION=./samples/spring-sample-h-auth

# This is for integrating health checkers such as "https://www.baeldung.com/spring-boot-actuators"
APP_HEALTH_CHECK_PATH=systemProfile
BAD_APP_HEALTH_CHECK_PATTERN=xxxxxxx
GOOD_APP_HEALTH_CHECK_PATTERN=production


# This is for environment variables for docker-compose-app.
DOCKER_COMPOSE_ENVIRONMENT={"TZ":"Asia/Seoul"}
# This goes with "docker build ... in the 'run.sh' script file", and the command always contain "HOST_IP" and "APP_ENV" above.
# docker exec -it CONTAINER_NAME cat /var/log/env_build_args.log
DOCKER_BUILD_ARGS={"DOCKER_BUILDKIT":"1","PROJECT_ROOT_IN_CONTAINER":"/var/www/server/spring-sample-h-auth","FILE_STORAGE_ROOT_IN_CONTAINER":"/var/www/files","APP_ENV":"production"}
DOCKER_BUILD_LABELS=["foo=happy","bar=sad"]
# For Mac like, EX.  DOCKER_BUILD_ADDITIONAL_RAW_PARAMS=--platform linux/amd64
DOCKER_BUILD_ADDITIONAL_RAW_PARAMS=--platform linux/amd64
DOCKER_BUILD_SHA_INSERT_GIT_ROOT=

DOCKER_COMPOSE_SELECTIVE_VOLUMES=["./samples/spring-sample-h-auth/logs:/var/www/files"]
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
NGINX_LOGROTATE_FILE_SIZE=1M

SHARED_VOLUME_GROUP_ID=1351
SHARED_VOLUME_GROUP_NAME=shared-volume-group
UIDS_BELONGING_TO_SHARED_VOLUME_GROUP_ID=

USE_MY_OWN_NGINX_ORIGIN=false