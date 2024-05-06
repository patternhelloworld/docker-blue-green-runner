#!/bin/bash
sed -i -e "s/\r$//g" $(basename $0)
set -e

git config apply.whitespace nowarn
git config core.filemode false

source ./util.sh

result=$(check_git_status)

if [ "$result" == "true" ]; then
    echo "[WARNING] There are arbitrary changes in the source code. Please check."
    git status
else
    echo "[NOTICE] [SUCCESS] No arbitrary changes detected in the source code."
fi