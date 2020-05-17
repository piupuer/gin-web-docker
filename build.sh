#!/bin/bash

WORKSPACE=$(cd $(dirname $0)/; pwd)

git clone git@github.com:piupuer/gin-web
git clone git@github.com:piupuer/gin-web-vue

cd $WORKSPACE/gin-web
chmod +x version.sh
./version.sh

cd $WORKSPACE/gin-web-vue
chmod +x version.sh
./version.sh

cd $WORKSPACE
docker-compose up
