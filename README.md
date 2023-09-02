# Docker-Blue-Green-Runner

> Zero-downtime Nginx Blue-Green deployment on a service layer with Consul

To deploy web projects must be [simple](https://github.com/Andrew-Kang-G/docker-blue-green-runner).

## Introduction

With your project and its only Dockerfile (docker-compose.yml in the 'samples' folder is ignored), Docker-Blue-Green-Runner handles the rest of the Continuous Deployment (CD) process with Consul. Nginx allows your project to be deployed without experiencing any downtime.

![img.png](/documents/images/img.png )


![img2.png](/documents/images/img2.png)


Let me continually explain how to use Docker-Blue-Green-Runner with the following samples.

|         | Local (Development) | Real (Production) |
|---------|---------------------|-------------------|
| Node.js | O                   | not yet           |
| PHP     | O                   | O                 |
| Java    | O                   | not yet           |

## Requirements

- Mainly tested on WSL2, Docker (24.0), Docker-Compose (2.18)

- In case you are using WSL2 on Win, I recommend cloning the project into the WSL area (``\\wsl$\Ubuntu\home``) instead of ``C:\``.

- No Container in Container
  - >Do not use Docker-Blue-Green-Runner in containers such as CircleCI. These builders operate within their own container environments, making it difficult for Docker-Blue-Green-Runner to utilize volumes. This issue is highlighted in [CircleCI discussion on 'docker-in-docker-not-mounting-volumes'](https://discuss.circleci.com/t/docker-in-docker-not-mounting-volumes/14037/3)
  - Dockerized Jenkins as well

- The image or Dockerfile in your app must contain "bash" & "curl" 

## How to Start with a Node Sample (Local, PORT: 3000).

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
bash run.sh
```

## How to Start with a PHP Sample (Local, PORT: 8080).

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
# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
# [NOTE] Initially, since the sample project does not have the "vendor" installed, the Health Check stage may take longer.
bash run.sh
```
and test with the Postman samples (./samples/laravel-crud-boilerplate/reference/postman) and debug with the following instruction ( https://github.com/Andrew-Kang-G/laravel-crud-boilerplate#debugging ).

## How to Start with a PHP Sample (Real, PORT: 8080).

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
# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
# [NOTE] Initially, since the sample project does not have the "vendor" installed, the Health Check stage may take longer.
bash run.sh
```
and test with the Postman samples (./samples/laravel-crud-boilerplate/reference/postman) and debug with the following instruction ( https://github.com/Andrew-Kang-G/laravel-crud-boilerplate#debugging ).

## How to Start with a Java Sample (Local, PORT: 8200).
```shell
# First, as the sample project requires MySQL8, run it separately.
# You can use your own MySQL8 Docker or just clone "https://github.com/Andrew-Kang-G/docker-my-sql-replica"
# and then, run ./sample/spring-sample-h-auth/.mysql/schema_all.sql
# Second, In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' for 'application-local.properties' to your host IP in the ./samples/spring-sample-h-auth/src/main/resources/application-local.properties
```

```shell
# In the ROOT folder,
cp -f .env.java.local .env
# In case you use a Mac, you are not available with 'host.docker.internal', so change 'host.docker.internal' to your host IP in the ./.env file.
bash run.sh
```


## Consul
`` http://localhost:8500 ``

## Environment Variables
```shell
# If this is set to be true, that means running 'stop-all-containers.sh & remove-all-images.sh'
# Why? In case you get your project renamed or moved to another folder, docker may NOT work properly.  
DOCKER_LAYER_CORRUPTION_RECOVERY=false

# If this is set to true, Nginx will be restarted, resulting in a short downtime. This option should be used when Nginx encounters errors or during the initial deployment.
NGINX_RESTART=false
CONSUL_RESTART=false

# The value must be json or yaml type, which is injected into docker-compose-app-${app_env}.yml
DOCKER_COMPOSE_ENVIRONMENT={"MONGODB_URL":"mongodb://host.docker.internal:27017/node-boilerplate","NODE_ENV":"development"}
```
## Emergency
1) Nginx (like when Nginx is NOT booted OR 502 error...)
```shell
bash emergency-nginx-restart.sh
# In case you need to manually set the Nginx to point to 'blue' or 'green'
bash emergency-nginx-restart.sh blue
## OR
bash emergency-nginx-restart.sh green

# If the script above fails, set NGINX_RESTART to be true on .env. and..
bash run.sh

# This fully restarts the whole system.
bash stop-all-containers.sh && bash run.sh

# Ways to check logs
docker logs -f ${project_name}-nginx   # e.g. node-express-boilerplate-nginx
# Ways to check Nginx error logs
docker exec -it ${project_name}-nginx bash # now you're in the container. Check '/var/log/error.log'
```

## Structure
```shell
In run.sh

_main() {

  # Check necessary commands such as git, docker and docker-compose
  check_necessary_commands
  
  # Load the environment variables on .env and container-state-related variables
  cache_global_vars
  # Once you run 'cache_global_vars' at different stages, the values of the container-state-related variables can differ.
  # The container with 'safe_old_state' will be killed after 'new_state' is successfully deployed.
  local safe_old_state=${state}

  check_env_integrity

  # These are all about passing variables from the .env to the docker-compose-app-local.yml
  initiate_docker_compose
  apply_env_service_name_onto_app_yaml
  apply_ports_onto_nginx_yaml
  apply_docker_compose_environment_onto_app_yaml

  # Refer to .env.*.real
  if [[ ${app_env} == 'real' ]]; then
    apply_docker_compose_volumes_onto_app_real_yaml
  fi


  create_nginx_ctmpl

  backup_app_to_previous_images
  backup_nginx_to_previous_images

  if [[ ${app_env} == 'local' ]]; then

      give_host_group_id_full_permissions
  #else

     # create_host_folders_if_not_exists
  fi

  #docker system prune -f
  if [[ ${docker_layer_corruption_recovery} == true ]]; then
    terminate_whole_system
  fi


  load_app_docker_image


  load_consul_docker_image


  load_nginx_docker_image

  # Run 'docker-compose up' for 'App', 'Consul (Service Mesh)' and 'Nginx' and
  # Check if the App is properly working from the inside of the App's container using 'wait-for-it.sh ( https://github.com/vishnubob/wait-for-it )' and conducting a health check with settings defined on .env.
  load_all_containers

  ./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}

  re=$(check_availability_out_of_container | tail -n 1);
  if [[ ${re} != 'true' ]]; then
    echo "[WARNING] a ${new_state}'s availabilty issue found. Now we are going to run 'emergency-nginx-restart.sh' immediately."
    bash emergency-nginx-restart.sh

    re=$(check_availability_out_of_container | tail -n 1);
    if [[ ${re} != 'true' ]]; then
      echo "[ERROR] Failed to call app_url outside container. Consider running bash rollback.sh. (result value : ${re})" && exit 1
    fi
  fi

  ## From this point on, regarded as "success"

  backup_to_new_images

  echo "[DEBUG] state : ${state}, new_state : ${new_state}, safe_old_state : ${safe_old_state}"
  echo "[NOTICE] The previous (${safe_old_state}) container (safe_old_state) exits because the deployment was successful. (If NGINX_RESTART=true or CONSUL_RESTART=true, existing containers have already been terminated in the load_all_containers function.)"
  docker-compose -f docker-compose-app-${app_env}.yml stop ${project_name}-${safe_old_state}

  echo "[NOTICE] Delete <none>:<none> images."
  docker rmi $(docker images -f "dangling=true" -q) || echo "[NOTICE] If any images are in use, they will not be deleted."
}

```

## Advanced

- Docker-Blue-Green-Runner uses your App's only '```Dockerfile.local``` or ```Dockerfile.real```', not ```docker-compose.yml```.
- You can set 'DOCKER_COMPOSE_ENVIRONMENT' on .env to change environments when your container is up.
- **In case you need more to set, correct the file ```docker-compose-app-${app_env}-original.yml``` directly.**
