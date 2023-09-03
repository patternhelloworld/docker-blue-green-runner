#!/bin/bash
java -Xms1024m -Xmx2048m -XX:+PrintGCDetails -Xloggc:/var/www/files/auth-gc.log -Dspring.profiles.active=production -jar /app.jar