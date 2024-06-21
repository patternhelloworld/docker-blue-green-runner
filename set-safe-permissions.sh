#!/bin/bash
sudo sed -i -e "s/\r$//g" $(basename $0) || sed -i -e "s/\r$//g" $(basename $0)
sudo chmod 770 *
sudo chmod 770 .env.*
sudo chmod 770 tests/*
sudo chmod -R 770 .docker/nginx
# This is temporary. You should set your SSLs to be such as 644 or 640 on your SSL folder.
sudo chmod -R 770 .docker/ssl
