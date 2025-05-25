#!/bin/bash
if [ -z "$1" ]; then
    echo "[INSIDE APP CONTAINER][ERROR] No project root path parameter found for the 'run-app.sh'"
    exit 1
fi
if [ -z "$2" ]; then
    echo "[INSIDE APP CONTAINER][ERROR] No file root path parameter found for the 'run-app.sh'"
    exit 1
fi
if [ -z "$3" ]; then
    echo "[INSIDE APP CONTAINER][ERROR] No Xms parameter found for the 'run-app.sh'"
    exit 1
fi
if [ -z "$4" ]; then
    echo "[INSIDE APP CONTAINER][ERROR] No Xmx parameter found for the 'run-app.sh'"
    exit 1
fi

echo "[INSIDE APP CONTAINER][NOTICE] Starting Spring Boot App with graceful shutdown..."

# graceful shutdown handler
term_handler() {
  echo "[INSIDE APP CONTAINER][NOTICE] Caught SIGTERM, forwarding to Java process (PID $pid)..."
  if [ "$pid" -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143
}

trap 'term_handler' SIGTERM

echo "[INSIDE APP CONTAINER][NOTICE] Run : java -Xms${3}m -Xmx${4}m -XX:+PrintGCDetails -Xloggc:${2}/logs/auth-gc.log -Dspring.config.location=file:${1}/src/main/resources/application.properties -Dlogging.config=file:${1}/src/main/resources/logback-spring.xml -jar /app.jar > ${2}/logs/auth-start.log 2>&1 &"
java -Xms${3}m -Xmx${4}m -XX:+PrintGCDetails -Xloggc:${2}/auth-gc.log -Dspring.config.location=file:${1}/src/main/resources/application.properties  -jar /app.jar > ${2}/auth-start.log 2>&1 &
pid=$!

# foreground wait
wait "$pid"