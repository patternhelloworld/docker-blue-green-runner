#!/usr/bin/env bash
sudo sed -i -e "s/\r$//g" $(basename $0)
echo "[NOTICE] To prevent CRLF errors in scripts based on the Windows operating system, currently performing CRLF to LF conversion."
bash prevent-crlf.sh

set -e

sudo chmod 750 *.sh || echo "[WARN] Running chmod 750 *.sh failed."
sudo chmod 770 *.yml || echo "[WARN] Running chmod 770 *.yml failed."
sudo chmod 740 .env.* || echo "[WARN] Running chmod 740 .env.* failed."
sudo chmod 740 .env || echo "[WARN] Running chmod 740 .env failed."
sudo chmod 770 .gitignore || echo "[WARN] Running chmod 770 .gitignore failed."
sudo chmod -R 770 .docker/ || echo "[WARN] Running chmod -R 770 .docker/ failed."
