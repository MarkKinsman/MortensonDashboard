#!/bin/bash
set -o nounset
set -o errexit

WORKDIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

cd "${WORKDIR}"/../../
#git pull origin dev
#git checkout dev

cd "${WORKDIR}"

  # if an arguement was passed check if it is a container, if not ask if user wants to create one
  if [[ $# -ne 0 && ! $(docker ps -a | grep -i $1) ]];
  then
      read -p "The container can not be found, would you like to create a new container? (y/n) "
      if ! [[ $REPLY =~ ^[Yy]$ ]];
        then
        exit 0
      fi
      NAME=$1
      echo -e "Enter a port: \c"
      read PORT
  # if no argument was passed, let user choose from list
  else
    PS3='Choose a container: '
    lines=($(docker ps -a | grep 'dashing' | awk --re-interval 'BEGIN{FS="  *"}{ print $(NF-1) }'))
    select container in "${lines[@]}"
    do
      NAME=$container
      PORT=$(docker port $NAME 3030/tcp | awk --re-interval 'BEGIN{FS=":"}{print $2}')
      break
    done
  fi

  # if previous container with same name exists, delete it and build new
  if [[ -n $(docker ps -a | grep -i $NAME | awk '{ print $1 }') ]];
  then
      echo -e "\nDeleting previous container named: field_dashboard"
      docker ps -a | grep -i $NAME | awk '{print $1}' | xargs docker rm -f
  fi

echo -e "\nBuilding new field_dashboard containter"
docker build -t markkinsman/dashing .

docker run -d -p $PORT:3030 \
    --name $NAME \
    -e GEMS="rest-client" \
    -v="$WORKDIR"/widgets:/widgets \
    -v="$WORKDIR"/config:/config \
    -v="$WORKDIR"/public:/public \
    -v="$WORKDIR"/jobs:/jobs \
    -v="$WORKDIR"/dashboards:/dashboards \
    markkinsman/dashing

docker ps

echo -e "\nDone!\n"
