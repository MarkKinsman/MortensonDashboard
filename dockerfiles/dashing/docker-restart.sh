#!/bin/bash

cd /home/ec2-user/MortensonDashboard

git pull origin dev

cd dockerfiles/dashing

# docker build -t markkinsman/dashing .

docker rm -f field_dashboard

local_DIR="/home/ec2-user/MortensonDashboard/dockerfiles/dashing/"

docker run -d -p 80:3030 \
    --name field_dashboard \
    -e GEMS=rest-client \
    -v="$local_DIR"widgets:/widgets \
    -v="$local_DIR"config:/config \
    -v="$local_DIR"public:/public \
    -v="$local_DIR"jobs:/jobs \
    -v="$local_DIR"dashboards:/dashboards \
    markkinsman/dashing

echo -e "\nDone!\n"
