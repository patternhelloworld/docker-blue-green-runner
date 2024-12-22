# Deploy React Project for Production

## The Goal
- External -> Docker-Blue-Green-Runner (443 port) -> Your App (8360 port)
- For a perfectly static React app, your application should include NGINX, which requires more setup compared to something like Spring Boot, which can be run directly from the command line, or you wouldn't love that, use Next.js.

## Locate projects
- Clone the project https://github.com/patternhelloworld/docker-blue-green-runner at  to ``/var/projects/docker-blue-green-runner`` (the path is not important; adjust as per your setup).
- Clone your application to ``/var/projects/your-app`` (the path is not important; adjust as per your setup).

## Runner-side work
### Create a .env file in the Runner's Root Directory
#### Points
- ``443`` indicated below
- ``DOCKER_BUILD_ARGS`` for your Dockerfile
- ``DOCKER_COMPOSE_SELECTIVE_VOLUMES`` for your Volumes.
- ``REDIRECT_HTTPS_TO_HTTP``
- .env file
- ```dotenv
    # Leave as it is
    HOST_IP=host.docker.internal
    
    # It is recommended to enter your formal URL or IP, such as https://test.com, for the 'check_availability_out_of_container' test in the 'run.sh' script.
    # Both https://your-app.com:443 and https://localhost:443 are valid
    # Docker-Blue-Runner recognizes if your App requires SSL in the Nginx router if this starts with 'https'.
    # This URL is used for the "External Integrity Check" process.
    APP_URL=https://localhost:443
    
    # APP_URL=http://localhost:<--!host-port-number!-->
    # PROJECT_PORT=<--!common-port-number!--> OR
    # PROJECT_PORT=[<--!host-port-number!-->,<--!internal-project-port-number!-->]
    PROJECT_PORT=[443,8360]
    # In case USE_COMMERCIAL_SSL is 'false', the Runner generates self-signed SSL certificates. However, you should set any name for ``COMMERCIAL_SSL_NAME``.
    # In case it is 'true', locate your commercial SSLs in the folder docker-blue-green-runner/.docker/ssl. See the comments in the .env above.
    USE_COMMERCIAL_SSL=true
    # Your domain name is recommended. The files 'your-app.com.key', 'your-app.com.crt', and 'your-app.com.chained.crt' should be in place.
    COMMERCIAL_SSL_NAME=your-app.com
    
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
    
    PROJECT_NAME=your-app
    ## [IMPORTANT] Ensure it matches 'PROJECT_ROOT_IN_CONTAINER' below.
    PROJECT_LOCATION=/app
    PROJECT_PORT=[443,8360]
    # Example (8093,8094,11000...)
    ADDITIONAL_PORTS=
    
    # If you locate your project on ../ (upper folder)
    HOST_ROOT_LOCATION=/var/projects/your-app
    # If you locate your project's Dockerfile ../ (upper folder)
    DOCKER_FILE_LOCATION=/var/projects/your-app
    
    # This is for integrating health checkers such as "https://www.baeldung.com/spring-boot-actuators"
    # This path is used for both internal and external health checks.
    # Note: Do not include a leading slash ("/") at the start of the path.
    # Example: "api/v1/health" (correct), "/api/v1/health" (incorrect)
    APP_HEALTH_CHECK_PATH=api/v1/health
    
    # The BAD & GOOD conditions are checked using an "AND" condition.
    # To ignore the "BAD_APP_HEALTH_CHECK_PATTERN", set it to a non-existing value (e.g., "###lsdladc").
    BAD_APP_HEALTH_CHECK_PATTERN=DOWN
    
    # Pattern required for a successful health check.
    GOOD_APP_HEALTH_CHECK_PATTERN=UP
    
    # The following trick is just for skipping the check.
    # APP_HEALTH_CHECK_PATH=login
    # BAD_APP_HEALTH_CHECK_PATTERN=xxxxxxx
    # GOOD_APP_HEALTH_CHECK_PATTERN=Head
    
    
    # This is for environment variables for docker-compose-app.
    DOCKER_COMPOSE_ENVIRONMENT={"TZ":"Asia/Seoul"}
    # [IMPORTANT] You can pass any variable to Step 2 of your Dockerfile using DOCKER_BUILD_ARGS, e.g., DOCKER_BUILD_ARGS={"PROJECT_ROOT_IN_CONTAINER":"/app"}."
    DOCKER_BUILD_ARGS={"PROJECT_ROOT_IN_CONTAINER":"/app"}
    # For SSL, the host folder is recommended to be './.docker/ssl' to be synchronized with 'docker-orchestration-app-nginx-original.yml'.
    # [IMPORTANT] Run mkdir -p /var/projects/files/your-app/logs on your host machine
    DOCKER_COMPOSE_SELECTIVE_VOLUMES=["/var/projects/your-app/.docker/nginx/app.conf.conf.d:/etc/nginx-template/app.conf.conf.d","/var/projects/files/your-app/logs:/var/log/nginx"]
    # [IMPORTANT] Run mkdir -p /var/projects/files/nginx/logs on your host machine
    DOCKER_COMPOSE_NGINX_SELECTIVE_VOLUMES=["/var/projects/files/nginx/logs:/var/log/nginx"]
    DOCKER_COMPOSE_HOST_VOLUME_CHECK=false
    
    NGINX_CLIENT_MAX_BODY_SIZE=50M
    
    USE_MY_OWN_APP_YML=false
    
    SKIP_BUILDING_APP_IMAGE=false
    
    # Docker-Swarm(stack) is currently a beta version. Use 'compose'.
    ORCHESTRATION_TYPE=compose
    
    ONLY_BUILDING_APP_IMAGE=false
    
    DOCKER_BUILD_MEMORY_USAGE=1G
    
    USE_NGINX_RESTRICTED_LOCATION=false
    # ex. /docs/api-app.html
    NGINX_RESTRICTED_LOCATION=xxx
    
    # If you set this to 'true', you won't need to configure SSL for your app. For instance, in a Spring Boot project, you won't have to create a ".jks" file. However, in rare situations, such as when it's crucial to secure all communication lines with SSL or when converting HTTPS to HTTP causes 'curl' errors, you might need to set it to 'false'.If you set this to 'true', you don't need to set SSL on your App like for example, for a Spring Boot project, you won't need to create the ".jks" file. However, in rare cases, such as ensuring all communication lines are SSL-protected, or when HTTPS to HTTP causes 'curl' errors, you might need to set it to 'false'.
    # 1) true : [Request]--> https (external network) -->Nginx--> http (internal network) --> App
    # 2) false :[Request]--> https (external network) -->Nginx--> httpS (internal network) --> App
    # !!! [IMPORTANT] As your App container below is Http, this should be set to 'true'.
    REDIRECT_HTTPS_TO_HTTP=true
    
    NGINX_LOGROTATE_FILE_NUMBER=7
    NGINX_LOGROTATE_FILE_SIZE=1M
    
    # You can change the values below. These settings for security related to ``apply-security.sh`` at the root of Docker-Blue-Green-Runner.
    SHARED_VOLUME_GROUP_ID=1559
    SHARED_VOLUME_GROUP_NAME=mba-shared-volume-group
    UIDS_BELONGING_TO_SHARED_VOLUME_GROUP_ID=1000,1001
    
    USE_MY_OWN_NGINX_ORIGIN=false
  ```
### Locate your commercial SSLs in the folder ``docker-blue-green-runner/.docker/ssl``. See the comments in the ``.env`` above.  
- For me, I have used GoDaddy, https://dearsikandarkhan.medium.com/ssl-godaddy-csr-create-on-mac-osx-4401c47fd94c .
## Your App-Side work

### Dockerfile
- At ``/var/projects/your-app``, write the following.
- The ARG below PROJECT_ROOT_IN_CONTAINER is passed from the above during the building process.

```Dockerfile
FROM node:18.20.4-slim AS build

ARG PROJECT_ROOT_IN_CONTAINER

RUN mkdir -p $PROJECT_ROOT_IN_CONTAINER
COPY .. $PROJECT_ROOT_IN_CONTAINER
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

COPY ../.docker/ssl /etc/nginx/ssl

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
              - app.conf.conf.d
   - entrypoint.sh
     - ```shell
       #!/bin/bash
        # synced the paths at DOCKER_COMPOSE_SELECTIVE_VOLUMES in .env
        cat /etc/nginx-template/app.conf.conf.d > /etc/nginx/conf.d/default.conf
        /usr/sbin/nginx -t && exec /usr/sbin/nginx -g "daemon off;"
       ```
   - app.conf.conf.d
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
- Check your firewall & Execute ``sudo bash run.sh`` after each ``git pull`` on your project for production updates.
