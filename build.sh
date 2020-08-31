#!/bin/bash

WORKSPACE=$(cd "$(dirname "$0")";pwd)

REPO=git@github.com:piupuer

cd $WORKSPACE

if [ ! -d "$WORKSPACE/gin-web" ]; then
  echo 'start clone gin-web...'
  git clone $REPO/gin-web
else
  echo 'start update gin-web...'
  cd $WORKSPACE/gin-web
  git pull
fi

cd $WORKSPACE

if [ ! -d "$WORKSPACE/gin-web-vue" ]; then
  echo 'start clone gin-web-vue...'
  git clone $REPO/gin-web-vue
else
  echo 'start update gin-web-vue...'
  cd $WORKSPACE/gin-web-vue
  git pull
fi

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
