#!/usr/bin/env bash
sed -i -e "s/\r$//g" $(basename $0)
git config apply.whitespace nowarn
git config core.filemode false

sed -i -Ee "s/(mysql:\/\/)[^:]+/\1${1}/" ./src/main/resources/application.properties
sed -i -e "s/\r$//g" ./src/main/resources/application.properties