#!/bin/bash
set -o nounset
set -o errexit

WORKDIR=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

cd "${WORKDIR}"/../../
git pull origin dev
git checkout dev

cd "${WORKDIR}"

# if previous container with same name exists, delete it and build new
if [[ -n $(sudo docker ps -a | grep -i "field_dashboard" | awk '{print $1}') ]];
then
    echo -e "\nDeleting previous container named: field_dashboard"
    sudo docker ps -a | grep -i "field_dashboard" | awk '{print $1}' | xargs docker rm -f
fi

echo -e "\nBuilding new field_dashboard containter"
sudo docker build -t markkinsman/dashing .

sudo docker run -d -p 80:3030 \
    --name field_dashboard \
    -e GEMS="rest-client" \
    -v="$WORKDIR"/widgets:/widgets \
    -v="$WORKDIR"/config:/config \
    -v="$WORKDIR"/public:/public \
    -v="$WORKDIR"/jobs:/jobs \
    -v="$WORKDIR"/dashboards:/dashboards \
    markkinsman/dashing

sudo docker ps

echo -e "\nDone!\n"
