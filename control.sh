#!/bin/bash -x

WORKSPACE=$(
  cd "$(dirname "$0")"
  pwd
)

function run() {
  # 空字符默认后端和前端
  if [ "$1" == "" ]; then
    run web && run ui
    return
  fi

  # 停止
  stop $1
  # 拉取
  pull $1
  # 构建
  build $1
  # 启动
  start $1
}

function pull() {
  # 空字符默认后端和前端
  if [ "$1" == "" ]; then
    pull web && pull ui
    return
  fi
  
  if [ "$1" == "loki" ]; then
    docker-compose -f docker-compose.loki.yml pull
  elif [ "$1" == "minio" ]; then
    docker-compose -f docker-compose.minio.yml pull
  elif [ "$1" == "db" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml pull
    else
      docker-compose -f docker-compose.db.yml logs pull
    fi
  elif [ "$1" == "web" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml pull
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml pull
    fi
  elif [ "$1" == "ui" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml pull
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml pull
    fi
  else
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml pull $1
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml pull $1
    fi
  fi
}

function build() {
  # 空字符默认后端和前端
  if [ "$1" == "" ]; then
    build web && build ui
    return
  fi
  
  if [ "$1" == "loki" ]; then
    docker-compose -f docker-compose.loki.yml build
  elif [ "$1" == "minio" ]; then
    docker-compose -f docker-compose.minio.yml build
  elif [ "$1" == "db" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml build
    else
      docker-compose -f docker-compose.db.yml build
    fi
  elif [ "$1" == "web" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml build
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml build
    fi
  elif [ "$1" == "ui" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml build
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml build
    fi
  else
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml build $1
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml build $1
    fi
  fi
}

function start() {
  # 空字符默认后端和前端
  if [ "$1" == "" ]; then
    start web && start ui
    return
  fi
  
  if [ "$1" == "loki" ]; then
    docker-compose -f docker-compose.loki.yml up -d
  elif [ "$1" == "minio" ]; then
    docker-compose -f docker-compose.minio.yml up -d
  elif [ "$1" == "db" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml up -d
    else
      docker-compose -f docker-compose.db.yml up -d
    fi
  elif [ "$1" == "web" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml up -d
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml up -d
    fi
  elif [ "$1" == "ui" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml up -d
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml up -d
    fi
  else
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml up -d $1
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml up -d $1
    fi
  fi
}

function stop() {
  # 空字符默认后端和前端
  if [ "$1" == "" ]; then
    stop web && stop ui
    return
  fi
  
  if [ "$1" == "loki" ]; then
    docker-compose -f docker-compose.loki.yml down
  elif [ "$1" == "minio" ]; then
    docker-compose -f docker-compose.minio.yml down
  elif [ "$1" == "db" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml down
    else
      docker-compose -f docker-compose.db.yml down
    fi
  elif [ "$1" == "web" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml down
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml down
    fi
  elif [ "$1" == "ui" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml down
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml down
    fi
  else
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml stop $1
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml stop $1
    fi
  fi
}

function top() {
  if [ "$1" == "" ]; then
    echo "请指定容器名" && exit 1
    return
  fi
  
  if [ "$1" == "loki" ]; then
    docker-compose -f docker-compose.loki.yml top
  elif [ "$1" == "minio" ]; then
    docker-compose -f docker-compose.minio.yml top
  elif [ "$1" == "db" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml top
    else
      docker-compose -f docker-compose.db.yml logs top
    fi
  elif [ "$1" == "web" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml top
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml top
    fi
  elif [ "$1" == "ui" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml top
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml top
    fi
  else
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml top $1
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml top $1
    fi
  fi
}

function tail() {
  if [ "$1" == "" ]; then
    echo "请指定容器名" && exit 1
    return
  fi
  
  if [ "$1" == "loki" ]; then
    docker-compose -f docker-compose.loki.yml logs -f --tail=50
  elif [ "$1" == "minio" ]; then
    docker-compose -f docker-compose.minio.yml logs -f --tail=50
  elif [ "$1" == "db" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml logs -f --tail=50
    else
      docker-compose -f docker-compose.db.yml logs -f --tail=50
    fi
  elif [ "$1" == "web" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml logs -f --tail=50
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml logs -f --tail=50
    fi
  elif [ "$1" == "ui" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml logs -f --tail=50
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml logs -f --tail=50
    fi
  else
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      docker-compose -f docker-compose.db.stage.yml -f docker-compose.web.stage.yml -f docker-compose.ui.stage.yml logs -f --tail=50 $1
    else
      docker-compose -f docker-compose.db.yml -f docker-compose.web.yml -f docker-compose.ui.yml logs -f --tail=50 $1
    fi
  fi
}

function restart() {
  stop $1
  start $1
}

function init() {
  restart loki && restart minio && restart db
}

function help() {
  echo "
  ./control.sh环境变量:
  COMPOSE_HTTP_TIMEOUT compose连接超时时间: 默认60(秒)
  GIN_WEB_MODE 应用模式: production/staging, 默认production
  ./control.sh运行命令:
  注意: str可取值loki(日志)/minio(对象存储)/db(数据库)/web(后端)/ui(前端)/container-name(容器名, 可自由设置)
  pull str 更新容器
  build str 构建容器
  start str 启动容器
  stop str 关闭容器
  restart str 重启容器
  run str 运行容器(关闭、更新、构建、启动)
  top str 查看容器状态
  tail str 查看容器日志
  init 初始化(将会自动开启loki、minio、db)
  "
}

cd $WORKSPACE
if [ "$1" == "pull" ]; then
  pull $2
elif [ "$1" == "run" ]; then
  run $2
elif [ "$1" == "start" ]; then
  start $2
elif [ "$1" == "stop" ]; then
  stop $2
elif [ "$1" == "restart" ]; then
  restart $2
elif [ "$1" == "build" ]; then
  build $2
elif [ "$1" == "top" ]; then
  top $2
elif [ "$1" == "tail" ]; then
  tail $2
elif [ "$1" == "init" ]; then
  init $2
else
  help
fi
