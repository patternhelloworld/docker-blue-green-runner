#!/bin/bash
java -jar -Djava.security.egd -Xdebug -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -Dspring.profiles.active=local -jar /app.jar
