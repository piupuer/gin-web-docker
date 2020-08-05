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
# 先关闭正在运行的项目
docker-compose down
# 无缓存重新构建镜像
docker-compose build --no-cache
# 后台启动项目
docker-compose up -d
