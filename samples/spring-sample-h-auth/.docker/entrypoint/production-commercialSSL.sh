#!/bin/bash
if [ -z "$1" ]; then
    echo "[ERROR] No project root path parameter found for the 'production.sh'"
    exit 1
fi
if [ -z "$2" ]; then
    echo "[ERROR] No file root path parameter found for the 'production.sh'"
    exit 1
fi
if [ -z "$3" ]; then
    echo "[ERROR] No Xms parameter found for the 'production.sh'"
    exit 1
fi
if [ -z "$4" ]; then
    echo "[ERROR] No Xmx parameter found for the 'production.sh'"
    exit 1
fi
if [ -z "$5" ]; then
    echo "[ERROR] No resources type parameter found for the 'production.sh'"
    exit 1
fi
java -Xms${3}m -Xmx${4}m -XX:+PrintGCDetails -Xloggc:${2}/logs/auth-gc.log -Dspring.profiles.active=production -Dspring.config.location=file:${1}/src/main/resources/application.${5}.properties -Dlogging.config=file:${1}/src/main/resources/logback.${5}.xml -jar /app.jar > ${2}/logs/auth-start.log 2>&1 &
