# Docker-Blue-Green-Runner

> Deploy your web project regardless of languages, without downtime, without load-balance

To deploy web projects must be [simple](https://github.com/Andrew-Kang-G/docker-blue-green-runner).

## Introduction

With your project and its only Dockerfile (docker-compose.yml in the 'samples' folder is ignored), Docker-Blue-Green-Runner handles the rest of the Continuous Deployment (CD) process. Nginx allows your project to be deployed without experiencing any downtime.

![img.png](/documents/images/img.png)

## How to Start with a Node Sample.

A Node.js sample project (https://github.com/hagopj13/node-express-boilerplate) that has been receiving a lot of stars, comes with an MIT License and serves as an example for demonstrating how to use Docker-Blue-Green-Runner.

```shell
# First, as the sample project requires Mongodb, run it separately.
cd samples/node-express-boilerplate
docker-compose up -d mongodb
```

```shell
cd ../../
# [NOTE] Initially, since the sample project does not have the "node_modules" installed, the Health Check stage may take longer.
bash run.sh
```

## Environment Variables
```shell
# If this is set to be true, that means running 'stop-all-containers.sh & remove-all-images.sh'
# Why? In case you get your project renamed or moved to another folder, docker may NOT work properly.  
DOCKER_LAYER_CORRUPTION_RECOVERY=false

# If this is set to true, Nginx will be restarted, resulting in a short downtime. This option should be used when Nginx encounters errors or during the initial deployment.
NGINX_RESTART=false
CONSUL_RESTART=false

# The value must be json or yaml type, which is injected into docker-compose-app-${app_env}.yml
PROJECT_ENVIRONMENTS={"MONGODB_URL":"mongodb://host.docker.internal:27017/node-boilerplate","NODE_ENV":"development"}
```
