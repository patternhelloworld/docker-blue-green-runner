# Docker-Blue-Green-Runner

> Simple Zero-Downtime Blue-Green Deployment Starting from your Dockerfiles

To deploy web projects must be [simple and safe](https://github.com/Andrew-Kang-G/docker-blue-green-runner#emergency).

- Use ``the latest Release version`` OR at least ``tagged versions`` for your production, NOT the latest version of the 'main' branch.
You can directly create pull requests for the 'main' branch.

## Table of Contents
- [Features](#Features)
- [Requirements](#Requirements)
- [Quick Start with Samples](#Quick-Start-with-Samples)
- [Usage](#usage)
- [Structure](#Structure)
- [Gitlab Container Registry](#Gitlab-Container-Registry)
- [Extra Information](#Extra-Information)

---

## Features

- Pure Docker (No Need for Binary Installation Files and Complex Configurations)
  - On Linux, you only need to have ``docker, docker-compose`` and some helping libraries such as ``git, curl, bash, yq`` installed.
  
- With your project and its sole Dockerfile, Docker-Blue-Green-Runner manages the remainder of the Continuous Deployment (CD) process with Consul. Nginx enables your project to be deployed without any downtime.
  - ![consists-of.png](/documents/images/consists-of.png )
  - By building your project from Dockerfiles, you can fully build your project and achieve zero-downtime blue-green deployments simply by executing `run.sh`. 

- Suitable for Single-Machine Deployments
  - While Kubernetes excels in multi-machine environments with the support of Layer 7 (L7) technologies (I would definitely use Kubernetes in that case), this approach is ideal for scenarios with lower traffic where only one or two machines are available.
  - For deployments involving more machines, traditional Layer 4 (L4) load-balancer using servers could be utilized.


Let me continually explain how to use Docker-Blue-Green-Runner with the following samples.

|         | Local (Development) | Real (Production) |
|---------|---------------------|-------------------|
| Node.js | O                   | not yet           |
| PHP     | O                   | O                 |
| Java    | O                   | O                 |

## Requirements

- Mainly tested on WIN10 WSL2 & Ubuntu 22.04.3 LTS, Docker (24.0), Docker-Compose (2.18)
  - If this module operates well on WSL2, then there should be no issues using it on an Ubuntu Linux server considering the instability of WSL2.
  - If you are using WSL2, which has the CRLF issue, you should run ```bash prevent-crlf.sh``` twice, and then run the .sh file you need.
  - The error message is `` $'\r': command not found``
- In case you are using WSL2 on Win, I recommend cloning the project into the WSL area (``\\wsl$\Ubuntu\home``) instead of ``C:\``.
- In summary, Linux is way better than WSL2.
- No Container in Container
  - >Do not use Docker-Blue-Green-Runner in containers such as CircleCI. These builders operate within their own container environments, making it difficult for Docker-Blue-Green-Runner to utilize volumes. This issue is highlighted in [CircleCI discussion on 'docker-in-docker-not-mounting-volumes'](https://discuss.circleci.com/t/docker-in-docker-not-mounting-volumes/14037/3)
  - Dockerized Jenkins as well

- The image or Dockerfile in your app must contain "bash" & "curl" commands, which are shown in ``./samples/spring-sample-h-auth`` folder as an example.
- Do NOT build or run 'local' & 'real' at the same time (There's no reason to do so, but just in case... They have the same name of the image and container)
- You can achieve your goal by running ```bash run.sh```, but when coming across any permission issue run ```sudo bash run.sh```
- I have located the sample folders included in this project; however, I recommend locating your projects in external folders and using absolute paths at all times.


## Quick Start with Samples

### How to Start with a Node Sample (Local).
- Check the port number 13000 available before getting this started.

A Node.js sample project (https://github.com/hagopj13/node-express-boilerplate) that has been receiving a lot of stars, comes with an MIT License and serves as an example for demonstrating how to use Docker-Blue-Green-Runner.

```shell
# First, as the sample project requires Mongodb, run it separately.
cd samples/node-express-boilerplate
docker-compose build
docker-compose up -d mongodb
# Second, In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' for 'MONGODB_URL' to your host IP in the ./samples/node-express-boilerplate/.env

```

```shell
# Go back to the ROOT
cd ../../
cp -f .env.node.local .env
# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
# [NOTE] Initially, since the sample project does not have the "node_modules" installed, the Health Check stage may take longer.
sudo bash run.sh
```


### How to Start with a PHP Sample (Real, HTTPS self-signed SSL)
- Check the port number 8080 available before getting this started.

Differences between ``./samples/laravel-crud-boilerplate/Dockerfile.local`` and ``./samples/laravel-crud-boilerplate/Dockerfile.real``

1) Staging build : (Local - no, Real - yes to reduce the size of the image)
2) Volume for the whole project : (Local - yes, Real - no. copy the whole project only one time)
3) SSL : (Local - not required, Real - yes, you can. as long as you set APP_URL on .env starting with 'https')

A PHP sample project (https://github.com/Andrew-Kang-G/laravel-crud-boilerplate) that comes with an MIT License and serves as an example for demonstrating how to use Docker-Blue-Green-Runner.

```shell
# First, as the sample project requires MariaDB, run it separately.
cd samples/laravel-crud-boilerplate
docker-compose build
docker-compose up -d 
# Second, In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' for 'HOST_IP' to your host IP in the ./samples/laravel-crud-boilerplate/.env
```

```shell
# Go back to the root
cd ../../
cp -f .env.php.real .env
# For WIN WSL2, \r on shell scripts can cause issues.
sed -i -e 's/\r$//' samples/laravel-crud-boilerplate/.docker/sh/update/real/run.sh
# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
# [NOTE] Initially, since the sample project does not have the "vendor" installed, the Health Check stage may take longer.
sudo bash run.sh
```
Open https://localhost:8080 (NO http. see .env. if you'd like http, change APP_URL) in your browser, and test with the Postman samples (./samples/laravel-crud-boilerplate/reference/postman) and debug with the following instruction ( https://github.com/Andrew-Kang-G/laravel-crud-boilerplate#debugging ).

### How to Start with a PHP Sample (Local).
- Check the port number 8080 available before getting this started.

A PHP sample project (https://github.com/Andrew-Kang-G/laravel-crud-boilerplate) that comes with an MIT License and serves as an example for demonstrating how to use Docker-Blue-Green-Runner.

```shell
# First, as the sample project requires MariaDB, run it separately.
cd samples/laravel-crud-boilerplate
docker-compose build
docker-compose up -d 
# Second, In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' for 'HOST_IP' to your host IP in the ./samples/laravel-crud-boilerplate/.env
```

```shell
# Go back to the root
cd ../../
cp -f .env.php.local .env
# For WIN WSL2, \r on shell scripts can cause issues.
sed -i -e 's/\r$//' samples/laravel-crud-boilerplate/.docker/sh/update/real/local.sh
# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
# [NOTE] Initially, since the sample project does not have the "vendor" installed, the Health Check stage may take longer.
sudo bash run.sh
```
and test with the Postman samples (./samples/laravel-crud-boilerplate/reference/postman) and debug with the following instruction ( https://github.com/Andrew-Kang-G/laravel-crud-boilerplate#debugging ).


### How to Start with a Java Spring-Boot Sample (Local).
- Check the port number 8200 available before getting this started.

```shell
# First, as the sample project requires MySQL8, run it separately.
# You can use your own MySQL8 Docker or just clone "https://github.com/Andrew-Kang-G/docker-my-sql-replica"
# and then, run ./sample/spring-sample-h-auth/.mysql/schema_all.sql
# Second, In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' for 'application-local.properties' to your host IP in the ./samples/spring-sample-h-auth/src/main/resources/application-local.properties
```

```shell
# In the ROOT folder,
cp -f .env.java.local .env # or cp -f .env.java.real .env
# For WIN WSL2, \r on shell scripts can cause issues.
 sed -i -e 's/\r$//' samples/spring-sample-h-auth/.docker/entrypoint/local.sh
# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
sudo bash run.sh
```


### How to Start with a Java Spring-Boot Sample (Real, HTTPS commercial SSL).
```shell
# First, as the sample project requires MySQL8, run it separately.
# You can use your own MySQL8 Docker or just clone "https://github.com/Andrew-Kang-G/docker-my-sql-replica"
# and then, run ./sample/spring-sample-h-auth/.mysql/schema_all.sql
# Second, In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' for 'application-local.properties' to your host IP in the ./samples/spring-sample-h-auth/src/main/resources/application-local.properties
# Third, you must have SSLs purchased on Domain & SSL selling sites such as Godaddy and etc. 
```

```shell
# Read comments carefully on ``.env.java.real.commercial.ssl.sample``, and you should be aware of where to put 'application.properties', 'logback-spring.xml', 'yourdomin.com.jks'
# In the ROOT folder,
cp -f .env.java.real.commercial.ssl.sample .env

# For WIN WSL2, \r on shell scripts can cause issues.
sed -i -e 's/\r$//' samples/spring-sample-h-auth/.docker/entrypoint/run-app.sh

# Make sure to set the path of 'server.ssl.key-store' on application.properties same to be PROJECT_ROOT_IN_CONTAINER on .env. 
cp -f samples/spring-sample-h-auth/src/main/resources/application.properties.commerical.ssl samples/spring-sample-h-auth/src/main/resources/application.properties

# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
sudo bash run.sh
```
- Focus on ``` 1) .env.java.real.commercial.ssl.sample, 2) samples/spring-sample-h-auth/Dockerfile.real, which is pointing to samples/spring-sample-h-auth/.docker/entrypoint/run-app.sh, 3) samples/spring-sample-h-auth/src/main/resources/application.properties&logback.xml```
- In case ``APP_ENV`` on ``.env`` is 'real', the Runner points to ``Dockerfile.real`` in priority, and if it does NOT exist, the Runner points to ``Dockerfile``.


## Usage

### Upgrade
- When you use any upgraded version of 'docker-blue-green-runner', set ```NGINX_RESTART=true``` on your .env,
- Otherwise, your server will load the previously built Nginx Image and can cause errors.
- then, just one time, run
```shell
git pull origin main
# set NGINX_RESTART=true on your .env, after that,
sudo bash run.sh
```
- However, as you are aware, ```NGINX_RESTART=true``` causes a short downtime. **Make sure ```NGINX_RESTART=false``` at all times**.


### Terms
For all echo messages or properties .env, the following terms indicate...
- BUILD (=LOAD IMAGE) : ```docker build```
- UP (=LOAD CONTAINER) : ```docker-compose up```
- DOWN : ```docker-compose down```
- RESTART : Parse related-files if exists, and then run ```docker build & docker-compose down & docker-compose up ```
  - ex) NGINX_RESTART on .env means docker build & down & up for NGINX
- safe : set a new state(=blue or green) without halting the running server safely. (=zero-downtime)

### Log Levels
- ``DEBUG``: Simply indicates that a specific function has been executed or a certain part of the source code has been run.
- ``NOTICE``, ``WARN``: Just for your information.
- ``ERROR``: Although the current deployment has not been halted, there is a clear error.
- ``EMERGENCY``: A level of risk that halts the current deployment.

### Information on Environment Variables
```shell
# If this is set to be true, that means running 'stop-all-containers.sh & remove-all-images.sh'
# Why? In case you get your project renamed or moved to another folder, docker may NOT work properly.  
DOCKER_LAYER_CORRUPTION_RECOVERY=false

# If this is set to true, Nginx will be restarted, resulting in a short downtime. This option should be used when Nginx encounters errors or during the initial deployment.
NGINX_RESTART=false
CONSUL_RESTART=false

# The value must be json or yaml type, which is injected into docker-compose-app-${app_env}.yml
DOCKER_COMPOSE_ENVIRONMENT={"MONGODB_URL":"mongodb://host.docker.internal:27017/node-boilerplate","NODE_ENV":"development"}

If you set this to 'true', you won't need to configure SSL for your app. For instance, in a Spring Boot project, you won't have to create a ".jks" file. However, in rare situations, such as when it's crucial to secure all communication lines with SSL or when converting HTTPS to HTTP causes 'curl' errors, you might need to set it to 'false'.If you set this to 'true', you don't need to set SSL on your App like for example, for a Spring Boot project, you won't need to create the ".jks" file. However, in rare cases, such as ensuring all communication lines are SSL-protected, or when HTTPS to HTTP causes 'curl' errors, you might need to set it to 'false'.
# 1) true : [Request]--> https (external network) -->Nginx--> http (internal network) --> App
# 2) false :[Request]--> https (external network) -->Nginx--> httpS (internal network) --> App
REDIRECT_HTTPS_TO_HTTP=true
```

### Check states
```shell
bash check-current-states.sh

# an output sample below
# [DEBUG] ! Setting which (Blue OR Green) to deploy the App as... (Final Check) : blue_score : 80, green_score : 0, state : blue, new_state : green, state_for_emergency : blue, new_upstream : https://laravel_crud_boilerplate-green:8080.
# The higher the score a state receives, the more likely it is to be the currently running state. So the updated App should be deployed as the non-occupied state(=new_state).
# For the emergency script, there is another safer priority added over the results of scores. So, the 'state_for_emergency' is basically the same as the 'state' but can differ.

# Only to get the result,
bash check-current-states.sh | grep -o '[^_]state : [^,]*,'
```

### Emergency
- Nginx (like when Nginx is NOT booted OR 502 error...)
```shell
# Automatically set the safe state & down and up Nginx
bash emergency-nginx-down-and-up.sh

# In case you need to manually set the Nginx to point to 'blue' or 'green'
bash emergency-nginx-down-and-up.sh blue
## OR
bash emergency-nginx-down-and-up.sh green

# If the script above fails, recreate & reset all about Nginx settings.
bash emergency-nginx-restart.sh

# If the script above fails, set *NGINX_RESTART to be true on .env. and..
sudo bash run.sh

# This fully restarts the whole system.
bash stop-all-containers.sh && bash remove-all-images.sh && bash run.sh

# Ways to check logs
docker logs -f ${project_name}-nginx   # e.g. node-express-boilerplate-nginx
# Ways to check Nginx error logs
docker exec -it ${project_name}-nginx bash # now you're in the container. Check '/var/log/error.log'
```
- Rollback your App to the previous App
```shell
# Roll-back only your App to the previous image.
bash ./rollback.sh

# The Nginx Container is roll-backed as well.
bash ./rollback.sh 1
```
- Critical Error on the Consul Network
  - This can happen when...
    - The server machine has been restarted, and affects the Consul network
    - When you change the ```ORCHESTRATION_TYPE``` on the .env, the two use different network scopes.
```shell
bash emergency-consul-down-and-up.sh
```

### Running & Stopping Multiple Projects
- Store your .env as ```.env.ready.*``` (for me, like ```.env.ready.client```, ```.env.ready.server```)
- When deploying ```.env.ready.client```, simply run ```cp -f .env.ready.client .env```
- ```bash run.sh```
- If you wish to terminate the project, which should be on your .env, run ```bash stop-all-containers.sh```
- If you wish to remove the project's images, which should be on your .env, run ```bash remove-all-images.sh```

### Consul
`` http://localhost:8500 ``
- Need to set a firewall for the 8500 port referring to ``./docker-compose-consul.yml``.

### USE_NGINX_RESTRICTION on .env
- https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication
- Create .htpasswd on ./.docker/nginx/custom-files if you would like use the settings. This is useful when you apply security to API Doc Modules such as Spring-Rest-Docs.

## Advanced
- Customizing ```docker-compose.yml```
  - Docker-Blue-Green-Runner uses your App's only ```Dockerfile```, NOT ```docker-compose```.
  - You can set 'DOCKER_COMPOSE_ENVIRONMENT' on .env to change environments when your container is up.
  - **However, in case you need more to set, follow this step.**
    - ```cp -f docker-compose-app-${app_env}-original.yml docker-compose-${project_name}-${app_env}-original-ready.yml```
    - Add variables you would like to ```docker-compose-${project_name}-${app_env}-original-ready.yml```
    - **For the properties of 'environment, volumes', use .env instead of setting them on the yml.**
    - Set ```USE_MY_OWN_APP_YML=true``` on .env
    - ```bash run.sh```

## Structure
```shell
  # [A] Get mandatory variables
  check_necessary_commands
  cache_global_vars
  # The 'cache_all_states' in 'cache_global_vars' function decides which state should be deployed. If this is called later at a point in this script, states could differ.
  local initially_cached_old_state=${state}
  check_env_integrity

  echo "[NOTICE] Finally, !! Deploy the App as !! ${new_state} !!, we will now deploy '${project_name}' in a way of 'Blue-Green'"

  # [B] Set mandatory files
  ## App
  initiate_docker_compose_file
  apply_env_service_name_onto_app_yaml
  apply_docker_compose_environment_onto_app_yaml
  if [[ ${app_env} == 'real' ]]; then
    apply_docker_compose_volumes_onto_app_real_yaml
  fi
  if [[ ${skip_building_app_image} != 'true' ]]; then
    backup_app_to_previous_images
  fi

  ## Nginx
  if [[ ${nginx_restart} == 'true' ]]; then
    initiate_nginx_docker_compose_file
    apply_ports_onto_nginx_yaml
    apply_docker_compose_volumes_onto_app_nginx_yaml
    create_nginx_ctmpl
    create_nginx_contingency_conf
    backup_nginx_to_previous_images
  fi


  if [[ ${app_env} == 'local' ]]; then
      give_host_group_id_full_permissions
  fi
  if [[ ${docker_layer_corruption_recovery} == 'true' ]]; then
    terminate_whole_system
  fi

  # [B] Build Docker images for the App, Nginx, Consul
  if [[ ${skip_building_app_image} != 'true' ]]; then
    load_app_docker_image
  fi
  if [ ${consul_restart} = "true" ]; then
    load_consul_docker_image
  fi
  if [ ${nginx_restart} = "true" ]; then
    load_nginx_docker_image
  fi

  if [[ ${only_building_app_image} == 'true' ]]; then
    echo "[NOTICE] Successfully built the App image : ${new_state}" && exit 0
  fi

  local cached_new_state=${new_state}
  cache_all_states
  if [[ ${cached_new_state} != "${new_state}" ]]; then
    (echo "[ERROR] Just checked all states shortly after the Docker Images had been done built. The state the App was supposed to be deployed as has been changed. (Original : ${cached_new_state}, New : ${new_state}). For the safety, we exit..." && exit 1)
  fi

  # Run 'docker-compose up' for 'App', 'Consul (Service Mesh)' and 'Nginx' and
  # Check if the App is properly working from the inside of the App's container using 'wait-for-it.sh ( https://github.com/vishnubob/wait-for-it )' and conducting a health check with settings defined on .env.
  ```
- Integrity Check is conducted at this point.
  - **Internal Integrity Check** ( in the function 'load_all_containers')
    - Internal Connection Check
      - Use the open-source ./wait-for-it.sh
    - Internal Health Check
      - Use your App's health check URL (Check, on .env, HEALTH_CHECK related variables)
  - **External Integrity Check**  ( in the function 'check_availability_out_of_container')
    - External HttpStatus Check

```shell

# [C] docker-compose up the App, Nginx, Consul & * Internal Integrity Check for the App
load_all_containers

# [D] Set Consul
./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}

# [E] External Integrity Check, if fails, 'emergency-nginx-down-and-up.sh' will be run.
re=$(check_availability_out_of_container | tail -n 1);
if [[ ${re} != 'true' ]]; then
echo "[WARNING] ! ${new_state}'s availability issue found. Now we are going to run 'emergency-nginx-down-and-up.sh' immediately."
bash emergency-nginx-down-and-up.sh

re=$(check_availability_out_of_container | tail -n 1);
if [[ ${re} != 'true' ]]; then
  echo "[ERROR] Failed to call app_url on .env outside the container. Consider running bash rollback.sh. (result value : ${re})" && exit 1
fi
fi


# [F] Finalizing the process : from this point on, regarded as "success".
if [[ ${skip_building_app_image} != 'true' ]]; then
backup_to_new_images
fi

echo "[DEBUG] state : ${state}, new_state : ${new_state}, initially_cached_old_state : ${initially_cached_old_state}"

echo "[NOTICE] For safety, finally check Consul pointing before stopping the previous container (${initially_cached_old_state})."
local consul_pointing=$(docker exec ${project_name}-nginx curl ${consul_key_value_store}?raw 2>/dev/null || echo "failed")
if [[ ${consul_pointing} != ${initially_cached_old_state} ]]; then
if [[ ${orchestration_type} != 'stack' ]]; then
  docker-compose -f docker-${orchestration_type}-${project_name}-${app_env}.yml stop ${project_name}-${initially_cached_old_state}
  echo "[NOTICE] The previous (${initially_cached_old_state}) container (initially_cached_old_state) has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
else
   docker stack rm ${project_name}-${initially_cached_old_state}
   echo "[NOTICE] The previous (${initially_cached_old_state}) service (initially_cached_old_state) has been stopped because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
fi
else
echo "[NOTICE] The previous (${initially_cached_old_state}) container (initially_cached_old_state) has NOT been stopped because the current Consul Pointing is ${consul_pointing}."
fi

echo "[NOTICE] Delete <none>:<none> images."
docker rmi $(docker images -f "dangling=true" -q) || echo "[NOTICE] Any images in use will not be deleted."

echo "[NOTICE] APP_URL : ${app_url}"
```

## Gitlab Container Registry

On .env, let me explain this.

- CASE 1. DOWNLOAD IMAGE
  ```shell
  GIT_IMAGE_LOAD_FROM=build
  GIT_IMAGE_LOAD_FROM_HOST=mysite.com:5050
  GIT_IMAGE_LOAD_FROM_PATHNAME=my-group/my-project-name/what/you/want
  GIT_TOKEN_IMAGE_LOAD_FROM_USERNAME=aaa
  GIT_TOKEN_IMAGE_LOAD_FROM_PASSWORD=12345
  GIT_IMAGE_VERSION=1.0.0
  ```
  - ``GIT_IMAGE_LOAD_FROM`` is 'build', ``docker-blue-green-runner`` builds your ``Dockerfile``, while it is 'registry', the runner downloads ``app, nginx, consul, registrator`` from such as the example code on ``util.sh``.
    ```shell
    app_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-app:${git_image_version}"
    nginx_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-nginx:${git_image_version}"
    consul_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-consul:${git_image_version}"
    registrator_image_name_in_registry="${git_image_load_from_host}/${git_image_load_from_pathname}-registrator:${git_image_version}"
    ``` 
- CASE 2. PUSH IMAGE
  - In case you run the command ``push-to-git.sh``, ``docker-blue-green-runner`` pushes one of ``Blue or Green`` images which is currently running to the address above of the Gitlab Container Registry.
  - This case is not related to ``GIT_IMAGE_LOAD_FROM``.
- REFERENCE
  - You can easily create your own Gitlab Docker with https://github.com/Andrew-Kang-G/docker-gitlab-ce-runner
  - ``GIT_TOKEN_IMAGE_LOAD_FROM_USERNAME, PASSWORD`` are registered on 'Project Access Tokens'.
  - ``docker login failed to verify certificate: x509: certificate signed by unknown authority`` Error
    - The error "failed to verify certificate: x509: certificate signed by unknown authority" typically occurs when the Docker client is unable to trust the SSL certificate presented by the Docker registry (in this case, your GitLab Docker registry).
    - Solution
      - Place your CA's root certificate (.crt file) in /usr/local/share/ca-certificates/ and run sudo update-ca-certificates.

## Extra Information

### Test
```shell
# Tests should be conducted in the folder
cd tests/spring-sample-h-auth
sudo bash run-and-kill-jar-and-state-is-restarting-or-running.sh
```

### Concurrent Running for this App
- Running ```sudo bash *.sh``` concurrently for the **same** project at the same time, is NOT safe.
- Running ```sudo bash *.sh``` concurrently for **different** projects at the same time, is safe.

### Docker Swarm

- 'ORCHESTRATION_TYPE=stack' is currently experimental, keep 'ORCHESTRATION_TYPE=compose' as it is in the production stage.
  - However, you would test the docker swarm, run the command. It is currently tested for the Java sample.
    - ```shell
        docker swarm init
        sudo bash run.sh
      ``` 
---