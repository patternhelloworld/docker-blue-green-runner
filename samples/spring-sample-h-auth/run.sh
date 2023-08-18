#!/usr/bin/env bash
sed -i -e "s/\r$//g" $(basename $0)
git config apply.whitespace nowarn
git config core.filemode false

get_value_from_env(){
  value=''
  re='^[[:space:]]*('${1}'[[:space:]]*=[[:space:]]*)(.+)[[:space:]]*$'

  while IFS= read -r line; do
     if [[ $line =~ $re ]]; then                       # match regex
        #declare -p BASH_REMATCH
        value=${BASH_REMATCH[2]}
     fi
                                      # print each line
  done < <(grep "" .env)  # To read the last line

  value=$(echo $value | sed -e 's/\r//g')

  if [[ -z ${value} ]]; then
    echo "[ERROR] ${1} NOT found on .env." >&2 && exit 1
  fi

  echo ${value} # return.
}

cache_global_vars() {
  APP_ENV=$(get_value_from_env "APP_ENV")
  PROJECT_ROOT_IN_CONTAINER=$(get_value_from_env "PROJECT_ROOT_IN_CONTAINER")
  CONTAINER_TO_DB_HOSTNAME=$(get_value_from_env "CONTAINER_TO_DB_HOSTNAME")
}

cache_global_vars

#if [[ ! -d ../../files ]]; then
 # mkdir ../../files
 # echo "[NOTICE] 상위 폴더의 상위 폴더 그 아래 files ('../../files') 디렉토리를 생성하였습니다. (컨테이너와 호스트의 공유 폴더)"
#fi
if [[ ${APP_ENV} == 'local' ]]; then
  bash properties-for-docker.sh ${CONTAINER_TO_DB_HOSTNAME} || exit 1
fi
docker-compose build || exit 1
docker-compose down
docker-compose up -d app

