# Docker-Blue-Green-Runner

> Deploy your web project regardless of languages, without downtime, without load-balance

To deploy web projects must be [simple](https://github.com/Andrew-Kang-G/docker-blue-green-runner).

## Introduction

With your project with only Dockerfile, Docker-Blue-Green-Runner is in charge of the rest of CD (Continuous Deployment).
Nginx enables your project to be deployed without downtime.

![img.png](/documents/images/img.png)

## How to Start with Node sample.

I brought a Node.js sample project ( https://github.com/hagopj13/node-express-boilerplate ) which has been getting many stars,
with MIT License to show how to use Docker-Blue-Green-Runner.

```shell
# First, as the sample project requires mongodb, run it separately.
cd samples/node-express-boilerplate
docker-compose up -d mongodb
```

```shell
cd ../../
# [NOTE] At first, as "node_modules" is NOT installed in the sample project, the Health Check stage takes longer.
bash run.sh
```

## Environment Variables
```shell
# If this is set to be true, NGINX will be restarted, hence, it has a short downtime. Use this when NGINX has errors or when it is a first-time deployment.
NGINX_RESTART=false
CONSUL_RESTART=false
```