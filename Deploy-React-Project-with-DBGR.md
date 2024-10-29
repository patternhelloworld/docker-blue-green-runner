# Deploy React Project for Production

## The Goal
- External -> Docker-Blue-Green-Runner (443 port) -> Your App (8360 port)
- For a perfectly static React app, your application should include NGINX, which requires more setup compared to something like Spring Boot, which can be run directly from the command line, or use Next.js.

## Locate projects
- Clone the project https://github.com/patternhelloworld/docker-blue-green-runner at  to ``/var/projects/docker-blue-green-runner`` (the path is not important; adjust as per your setup).
- Clone your application to ``/var/projects/your-app`` (the path is not important; adjust as per your setup).

## Runner-side work
### Create a .env file in the Runner's Root Directory
- ```dotenv
    HOST_IP=host.docker.internal
    APP_ENV=real
    
    # It is recommended to enter your formal URL or IP, such as https://test.com, for the 'check_availability_out_of_container' test in the 'run.sh' script.
    # Both https://your-app.com:443 and https://localhost:443 are valid
    APP_URL=https://localhost:443
    
    USE_COMMERCIAL_SSL=false
    # Your domain name is recommended. The files 'your-app.com.key', 'your-app.com.crt', and 'your-app.com.chained.crt' should be in place.
    COMMERCIAL_SSL_NAME=your-app.com
    
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
    
    PROJECT_NAME=your-app
    ## [IMPORTANT] Ensure it matches 'PROJECT_ROOT_IN_CONTAINER' below.
    PROJECT_LOCATION=/app
    PROJECT_PORT=[443,8360]
    # Example (8093,8094,11000...)
    ADDITIONAL_PORTS=
    
    CONSUL_KEY_VALUE_STORE=http://consul:8500/v1/kv/deploy/your-app
    
    # If you locate your project on ../ (upper folder)
    HOST_ROOT_LOCATION=/var/projects/your-app
    # If you locate your project's Dockerfile ../ (upper folder)
    DOCKER_FILE_LOCATION=/var/projects/your-app
    
    # This is for integrating health checkers such as "https://www.baeldung.com/spring-boot-actuators"
    APP_HEALTH_CHECK_PATH=login
    BAD_APP_HEALTH_CHECK_PATTERN=xxxxxxx
    GOOD_APP_HEALTH_CHECK_PATTERN=Head
    
    
    # This is for environment variables for docker-compose-app-${app_env}.
    DOCKER_COMPOSE_ENVIRONMENT={"TZ":"Asia/Seoul"}
    # This goes with "docker build ... in the 'run.sh' script file", and the command always contain "HOST_IP" and "APP_ENV" above.
    # docker exec -it CONTAINER_NAME cat /var/log/env_build_args.log
    # The name "PROJECT_ROOT_IN_CONTAINER" is simply a convention used with your Dockerfile. You can change it if desired.
    DOCKER_BUILD_ARGS={"PROJECT_ROOT_IN_CONTAINER":"/app"}
    # In the case of "REAL," the project is not synchronized in its entirety. The source codes that are required for only production are injected.
    # For SSL, the host folder is recommended to be './.docker/ssl' to be synchronized with 'docker-compose-nginx-original.yml'
    # [IMPORTANT] Run mkdir -p /var/projects/files/your-app/logs on your host machine
    DOCKER_COMPOSE_REAL_SELECTIVE_VOLUMES=["/var/projects/your-app/.docker/nginx/app.conf.ctmpl:/etc/nginx-template/app.conf.ctmpl","/var/projects/files/your-app/logs:/var/log/nginx"]
    # [IMPORTANT] Run mkdir -p /var/projects/files/nginx/logs on your host machine
    DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES=["/var/projects/files/nginx/logs:/var/log/nginx"]
    
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
    
    # You can change the values below. These settings for security related to ``set-safe-permissions.sh`` at the root of Docker-Blue-Green-Runner. 
    SHARED_VOLUME_GROUP_ID=1559
    SHARED_VOLUME_GROUP_NAME=mba-shared-volume-group
    UIDS_BELONGING_TO_SHARED_VOLUME_GROUP_ID=1000,1001
    
    USE_MY_OWN_NGINX_ORIGIN=false
  ```
### Locate your commercial SSLs in the folder ``docker-blue-green-runner/.docker/ssl``. See the comments in the ``.env`` above.  

## Your App-Side work

### Dockerfile
- At ``/var/projects/your-app``, write the following.
- The ARG below PROJECT_ROOT_IN_CONTAINER is passed from the above during the building process.
```Dockerfile
FROM node:18.20.4-slim AS build

ARG PROJECT_ROOT_IN_CONTAINER

RUN mkdir -p $PROJECT_ROOT_IN_CONTAINER
COPY . $PROJECT_ROOT_IN_CONTAINER
WORKDIR $PROJECT_ROOT_IN_CONTAINER
RUN export NODE_OPTIONS="--max-old-space-size=2048"
RUN whereis npm && alias npm='node --max_old_space_size=2048 /usr/local/bin/npm'
RUN export NODE_OPTIONS="--max-old-space-size=2048"
RUN if [ -d $PROJECT_ROOT_IN_CONTAINER/node_modules ]; then echo "[NOTICE] The node_modules folder exists. Skipping 'npm install'... "; else npm install --legacy-peer-deps; fi
RUN npm cache clean --force
RUN npm run build:prod

FROM nginx:stable

RUN apt-get update -qqy && apt-get -qqy --force-yes install curl runit wget unzip vim && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG PROJECT_ROOT_IN_CONTAINER

COPY --chown=nginx --from=build $PROJECT_ROOT_IN_CONTAINER/dist/ $PROJECT_ROOT_IN_CONTAINER

USER root
WORKDIR $PROJECT_ROOT_IN_CONTAINER

COPY ./.docker/ssl /etc/nginx/ssl

COPY ./.docker/entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

ENTRYPOINT bash /entrypoint.sh
```
### Dependent Files for the Dockerfile
  - Folders & Files
    - your-app/
      - .docker/
          - entrypoint.sh
          - nginx/
              - app.conf.ctmpl
   - entrypoint.sh
     - ```shell
       #!/bin/bash
        # synced the paths at DOCKER_COMPOSE_REAL_SELECTIVE_VOLUMES in .env
        cat /etc/nginx-template/app.conf.ctmpl > /etc/nginx/conf.d/default.conf
        /usr/sbin/nginx -t && exec /usr/sbin/nginx -g "daemon off;"
       ```
   - app.conf.ctmpl
      - ```nginx
        server {
        listen 8360;
        server_name localhost; 
        
            # Root directory
            root /app; 
            index index.html
            # Access and Error logs
            access_log /var/log/nginx/access.log;
            error_log /var/log/nginx/error.log;
        
            # Gzip compression for performance improvement
            gzip on;
            gzip_comp_level 5;
            gzip_min_length 256;
            gzip_proxied any;
            gzip_vary on;
        
            gzip_types
                application/javascript
                application/json
                application/xml
                text/css
                text/plain;
        
            # Cache settings for static files for better performance
            location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
                expires 30d;
                add_header Cache-Control "public, no-transform";
            }
        
            location / {
              try_files $uri $uri/ /index.html?$query_string;
            }
        }

        ``` 
## Run
- Execute ``sudo bash run.sh`` after each ``git pull`` on your project for production updates.