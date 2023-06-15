# Docker-Blue-Green-Runner

> Zero-downtime Nginx Blue-Green deployment on a service layer

To deploy web projects must be [simple](https://github.com/Andrew-Kang-G/docker-blue-green-runner).

## Introduction

With your project and its only Dockerfile (docker-compose.yml in the 'samples' folder is ignored), Docker-Blue-Green-Runner handles the rest of the Continuous Deployment (CD) process. Nginx allows your project to be deployed without experiencing any downtime.

![img.png](/documents/images/img.png)


Let me continually explain how to use Docker-Blue-Green-Runner with the following samples.

|         | Local (Development) | Real (Production) |
|---------|---------------------|-------------------|
| Node.js | O                   | not yet           |
| PHP     | O                   | not yet           |
| Java    | not yet             | not yet           |

In case you are using WSL2 on Win, I strongly recommend cloning the project into the WSL area (``\\wsl$\Ubuntu\home``) instead of ``C:\``.

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

A Node.js sample project (https://github.com/Andrew-Kang-G/laravel-crud-boilerplate) that comes with an MIT License and serves as an example for demonstrating how to use Docker-Blue-Green-Runner.

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

# If the script above fails, set NGINX_RESTART to be true on .env. and..
bash run.sh

# Ways to check logs
docker logs -f ${project_name}-nginx   # e.g. node-express-boilerplate-nginx
# Ways to check Nginx error logs
docker exec -it ${project_name}-nginx bash # now you're in the container. Check '/var/log/error.log'
```

## Structure
```shell
In run.sh

_main() {

  check_necessary_commands

  cache_global_vars
  local safe_old_state=${state}

  check_env_integrity

  # These are all about passing variables from the .env to the docker-compose-app-local.yml
  apply_env_service_name_onto_app_yaml
  apply_ports_onto_nginx_yaml
  apply_docker_compose_environment_onto_app_yaml
  make_docker_build_arg_strings

  create_nginx_ctmpl

  backup_app_to_previous_images
  backup_nginx_to_previous_images

  if [[ ${app_env} == 'local' ]]; then

      give_host_group_id_full_permissions
  else

      create_host_folders_if_not_exists
  fi

  #docker system prune -f
  if [[ ${docker_layer_corruption_recovery} == true ]]; then
    terminate_whole_system
  fi


  load_app_docker_image


  load_consul_docker_image


  load_nginx_docker_image

  if [[ ${app_env} == 'real' ]]; then
    inject_env_real
    sleep 2
  fi

  load_all_containers

  ./activate.sh ${new_state} ${state} ${new_upstream} ${consul_key_value_store}


  re=$(check_availability_out_of_container | tail -n 1);
  if [[ ${re} != 'true' ]]; then
    echo "[ERROR] Failed to call app_url outside container. Consider running bash rollback.sh. (result value : ${re})" && exit 1
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
