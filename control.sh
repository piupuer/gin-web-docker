#!/bin/bash

WORKSPACE=$(
  cd "$(dirname "$0")"
  pwd
)

export COMPOSE_HTTP_TIMEOUT=30

mkdir -p run/redis-conf
mkdir -p run/nginx-conf
mkdir -p run/loki-conf

function run() {
  check $1

  # 停止
  stop $1
  # 拉取
  pull $1
  # 构建
  build $1
  # 创建
  create $1
  # 启动
  start $1
}

function pull() {
  check $1

  echo "$CMD pull $1"
  sh -c "$CMD pull $1"
}

function build() {
  check $1

  echo "$CMD build $1"
  sh -c "$CMD build $1"
}

function create() {
  check $1

  echo "$CMD create $1"
  sh -c "$CMD create $1"
}

function start() {
  check $1

  echo "$CMD start $1"
  sh -c "$CMD start $1"
}

function up() {
  check $1

  echo "$CMD up -d"
  sh -c "$CMD up -d"
}

function stop() {
  check $1

  echo "$CMD stop $1"
  sh -c "$CMD stop $1"
}

function top() {
  echo "$CMD top $1"
  sh -c "$CMD top $1"
}

function tail() {
  echo "$CMD logs -f --tail=50 $1"
  sh -c "$CMD logs -f --tail=50 $1"
}

function restart() {
  stop $1
  start $1
}

function check() {
  if [ "$1" == "" ]; then
    echo "请指定容器名" && exit 1
    return
  fi
  if [[ "$1" =~ "gin-web-prod" ]]; then
    export WEB_TAG=$(cat tpl/app/web_tag)
    environment WEB_TAG WEB_PORT WEB_PPROF_PORT MACHINE_ID
    environment WEB_REDIS_URI WEB_MYSQL_HOST WEB_MYSQL_PORT WEB_MYSQL_PASSWORD
    cat tpl/app/web.yml |
      sed "s/\${MACHINE_ID}/${MACHINE_ID}/g" |
      sed "s/\${WEB_CONTAINER_NAME}/$1/g" |
      sed "s/\${WEB_TAG}/${WEB_TAG}/g" |
      sed "s/\${WEB_PORT}/${WEB_PORT}/g" |
      sed "s/\${WEB_PPROF_PORT}/${WEB_PPROF_PORT}/g" |
      sed "s#\${WEB_REDIS_URI}#${WEB_REDIS_URI}#g" |
      sed "s/\${WEB_MYSQL_HOST}/${WEB_MYSQL_HOST}/g" |
      sed "s/\${WEB_MYSQL_PORT}/${WEB_MYSQL_PORT}/g" |
      sed "s/\${WEB_MYSQL_PASSWORD}/${WEB_MYSQL_PASSWORD}/g" >run/$1.yml
  elif [[ "$1" =~ "gin-web-stage" ]]; then
    export WEB_STAGE_TAG=$(cat tpl/app/web_tag)
    environment WEB_STAGE_TAG WEB_PORT WEB_PPROF_PORT MACHINE_ID
    environment WEB_REDIS_URI WEB_MYSQL_HOST WEB_MYSQL_PORT
    cat tpl/app/web-stage.yml |
      sed "s/\${MACHINE_ID}/${MACHINE_ID}/g" |
      sed "s/\${WEB_CONTAINER_NAME}/$1/g" |
      sed "s/\${WEB_STAGE_TAG}/${WEB_STAGE_TAG}/g" |
      sed "s/\${WEB_PORT}/${WEB_PORT}/g" |
      sed "s/\${WEB_PPROF_PORT}/${WEB_PPROF_PORT}/g" |
      sed "s#\${WEB_REDIS_URI}#${WEB_REDIS_URI}#g" |
      sed "s/\${WEB_MYSQL_HOST}/${WEB_MYSQL_HOST}/g" |
      sed "s/\${WEB_MYSQL_PORT}/${WEB_MYSQL_PORT}/g" |
      sed "s/\${WEB_MYSQL_PASSWORD}/${WEB_MYSQL_PASSWORD}/g" >run/$1.yml
  elif [[ "$1" =~ "gin-web-vue-prod" ]]; then
    export UI_TAG=$(cat tpl/app/ui_tag)
    environment UI_TAG UI_PORT
    environment WEB_HOST WEB_PORT
    cat tpl/app/ui.yml |
      sed "s/\${UI_CONTAINER_NAME}/$1/g" |
      sed "s/\${UI_TAG}/${UI_TAG}/g" |
      sed "s/\${UI_PORT}/${UI_PORT}/g" >run/$1.yml
    cat tpl/app/nginx/nginx.conf |
      sed "s/\${WEB_HOST}/${WEB_HOST}/g" |
      sed "s/\${WEB_PORT}/${WEB_PORT}/g" >run/nginx-conf/$1-nginx.conf
  elif [[ "$1" =~ "gin-web-vue-stage" ]]; then
    export UI_STAGE_TAG=$(cat tpl/app/ui_tag)
    environment UI_STAGE_TAG UI_PORT
    environment WEB_HOST WEB_PORT
    cat tpl/app/ui-stage.yml |
      sed "s/\${UI_CONTAINER_NAME}/$1/g" |
      sed "s/\${UI_TAG}/${UI_TAG}/g" |
      sed "s/\${UI_PORT}/${UI_PORT}/g" >run/$1.yml
    cat tpl/app/nginx/nginx-stage.conf |
      sed "s/\${WEB_HOST}/${WEB_HOST}/g" |
      sed "s/\${WEB_PORT}/${WEB_PORT}/g" >run/nginx-conf/$1-nginx-stage.conf
  elif [[ "$1" =~ "redis-master-sentinel" ]]; then
    environment REDIS_PORT REDIS_PASS REDIS_MASTER_SENTINEL_PORT REDIS_MASTER_NAME REDIS_MASTER_IP LOCAL_IP
    environment REDIS_MASTER_SENTINEL_CONTAINER_NAME
    cat tpl/redis/redis-sentinel.conf |
      sed "s/\${REDIS_PORT}/${REDIS_PORT}/g" |
      sed "s/\${REDIS_PASS}/${REDIS_PASS}/g" |
      sed "s/\${REDIS_SENTINEL_PORT}/${REDIS_MASTER_SENTINEL_PORT}/g" |
      sed "s/\${REDIS_MASTER_NAME}/${REDIS_MASTER_NAME}/g" |
      sed "s/\${REDIS_MASTER_IP}/${REDIS_MASTER_IP}/g" |
      sed "s/\${LOCAL_IP}/${LOCAL_IP}/g" >run/redis-conf/$1.conf
    cat tpl/redis/redis-sentinel.yml |
      sed "s/\${REDIS_SENTINEL_PORT}/${REDIS_MASTER_SENTINEL_PORT}/g" |
      sed "s/\${REDIS_SENTINEL_CONTAINER_NAME}/${REDIS_MASTER_SENTINEL_CONTAINER_NAME}/g" >run/$1.yml
  elif [[ "$1" =~ "redis-master" ]]; then
    environment REDIS_PORT REDIS_PASS
    environment REDIS_MASTER_CONTAINER_NAME
    cat tpl/redis/redis-master.conf |
      sed "s/\${REDIS_PORT}/${REDIS_PORT}/g" |
      sed "s/\${REDIS_PASS}/${REDIS_PASS}/g" >run/redis-conf/$1.conf
    cat tpl/redis/redis-master.yml |
      sed "s/\${REDIS_PORT}/${REDIS_PORT}/g" |
      sed "s/\${REDIS_MASTER_CONTAINER_NAME}/${REDIS_MASTER_CONTAINER_NAME}/g" >run/$1.yml
  elif [[ "$1" =~ "redis-slave-sentinel" ]]; then
    environment REDIS_PORT REDIS_PASS REDIS_SLAVE_SENTINEL_PORT REDIS_MASTER_NAME REDIS_MASTER_IP LOCAL_IP
    environment REDIS_SLAVE_SENTINEL_CONTAINER_NAME
    cat tpl/redis/redis-sentinel.conf |
      sed "s/\${REDIS_PORT}/${REDIS_PORT}/g" |
      sed "s/\${REDIS_PASS}/${REDIS_PASS}/g" |
      sed "s/\${REDIS_SENTINEL_PORT}/${REDIS_SLAVE_SENTINEL_PORT}/g" |
      sed "s/\${REDIS_MASTER_NAME}/${REDIS_MASTER_NAME}/g" |
      sed "s/\${REDIS_MASTER_IP}/${REDIS_MASTER_IP}/g" |
      sed "s/\${LOCAL_IP}/${LOCAL_IP}/g" >run/redis-conf/$1.conf
    cat tpl/redis/redis-sentinel.yml |
      sed "s/\${REDIS_SENTINEL_PORT}/${REDIS_SLAVE_SENTINEL_PORT}/g" |
      sed "s/\${REDIS_SENTINEL_CONTAINER_NAME}/${REDIS_SLAVE_SENTINEL_CONTAINER_NAME}/g" >run/$1.yml
  elif [[ "$1" =~ "redis-slave" ]]; then
    environment REDIS_PORT REDIS_PASS REDIS_SLAVE_PORT REDIS_MASTER_IP LOCAL_IP
    environment REDIS_SLAVE_CONTAINER_NAME
    cat tpl/redis/redis-slave.conf |
      sed "s/\${REDIS_SLAVE_PORT}/${REDIS_SLAVE_PORT}/g" |
      sed "s/\${REDIS_MASTER_IP}/${REDIS_MASTER_IP}/g" |
      sed "s/\${REDIS_PORT}/${REDIS_PORT}/g" |
      sed "s/\${REDIS_PASS}/${REDIS_PASS}/g" |
      sed "s/\${LOCAL_IP}/${LOCAL_IP}/g" >run/redis-conf/$1.conf
    cat tpl/redis/redis-slave.yml |
      sed "s/\${REDIS_SLAVE_PORT}/${REDIS_SLAVE_PORT}/g" |
      sed "s/\${REDIS_SLAVE_CONTAINER_NAME}/${REDIS_SLAVE_CONTAINER_NAME}/g" >run/$1.yml
  elif [[ "$1" =~ "loki" ]]; then
    environment LOCAL_IP DOCKER_BIP
    environment LOKI_PORT LOKI_FRONTEND_PORT LOKI_FRONTEND_PORT LOKI_GATEWAY_PORT LOKI_PROMTAIL_PORT LOKI_GRAFANA_PORT LOKI_MEMBER_PORT
    cat tpl/loki/loki.yml |
      sed "s/\${LOKI_PORT}/${LOKI_PORT}/g" |
      sed "s/\${LOKI_FRONTEND_PORT}/${LOKI_FRONTEND_PORT}/g" |
      sed "s/\${LOKI_FRONTEND_PORT}/${LOKI_FRONTEND_PORT}/g" |
      sed "s/\${LOKI_GATEWAY_PORT}/${LOKI_GATEWAY_PORT}/g" |
      sed "s/\${LOKI_PROMTAIL_PORT}/${LOKI_PROMTAIL_PORT}/g" |
      sed "s/\${LOKI_GRAFANA_PORT}/${LOKI_GRAFANA_PORT}/g" |
      sed "s/\${LOKI_MEMBER_PORT}/${LOKI_MEMBER_PORT}/g" >run/$1.yml
    cat tpl/loki/conf/boltdb-shipper.yml |
      sed "s/\${LOKI_PORT}/${LOKI_PORT}/g" |
      sed "s/\${LOKI_MEMBER_PORT}/${LOKI_MEMBER_PORT}/g" >run/loki-conf/boltdb-shipper.yml
    cat tpl/loki/conf/promtail.yml |
      sed "s/\${LOKI_PROMTAIL_PORT}/${LOKI_PROMTAIL_PORT}/g" |
      sed "s/\${LOKI_GATEWAY_PORT}/${LOKI_GATEWAY_PORT}/g" >run/loki-conf/promtail.yml
    cat tpl/loki/conf/gateway.conf |
      sed "s/\${LOKI_PORT}/${LOKI_PORT}/g" |
      sed "s/\${LOKI_GATEWAY_PORT}/${LOKI_GATEWAY_PORT}/g" >run/loki-conf/gateway.conf
    cat tpl/loki/conf/gateway.conf |
      sed "s/\${LOKI_PORT}/${LOKI_PORT}/g" |
      sed "s/\${LOKI_GATEWAY_PORT}/${LOKI_GATEWAY_PORT}/g" >run/loki-conf/gateway.conf
    cat tpl/loki/conf/daemon.json |
      sed "s/\${LOCAL_IP}/${LOCAL_IP}/g" |
      sed "s/\${LOKI_PORT}/${LOKI_PORT}/g" |
      sed "s#\${DOCKER_BIP}#${DOCKER_BIP}#g" >/etc/docker/daemon.json
    cp tpl/sources.list run/sources.list
    systemctl daemon-reload
    systemctl restart docker
  fi
  CMD="docker-compose -f $WORKSPACE/run/$1.yml"
}

function environment() {
  for arg in $*; do
    val=""
    for i in $(env); do
      key=$(echo $i | awk -F"=" '{print $1}')
      if [ "$key" == "$arg" ]; then
        val=$(echo $i | awk -F"=" '{print $2}')
        break
      fi
    done
    if [ "$val" == "" ]; then
      msg="$msg $arg"
    fi
  done
  if [ ! "$msg" == "" ]; then
    echo "缺少环境变量$msg" && exit 1
    return
  fi
}

function sentinel() {
  if [ "$1" == "" ]; then
    genRedisEnv 3
  elif [ "$1" == "master" ]; then
    redisMaster
  elif [ "$1" == "slave" ]; then
    redisSlave
  else
    genRedisEnv $1
  fi
}

function redisMaster() {
  environment REDIS_MASTER_IP LOCAL_IP
  defaultRedisEnv
  m=$(port $(expr $REDIS_PORT))
  if [ $m -eq 1 ]; then
    echo "master节点端口被占用: $(expr $REDIS_PORT)(可通过export REDIS_PORT=xxx修改)"
    exit
  fi
  m1=$(port $(expr $REDIS_PORT + 1))
  if [ $m1 -eq 1 ]; then
    echo "master sentinel节点端口被占用: $(expr $REDIS_PORT + 1)(可通过export REDIS_PORT=xxx修改)"
    exit
  fi
  export REDIS_MASTER_SENTINEL_PORT=$(expr $REDIS_PORT + 1)
  echo "正在初始化master节点: $REDIS_MASTER_CONTAINER_NAME"
  run $REDIS_MASTER_CONTAINER_NAME
  echo "正在初始化master sentinel节点: $REDIS_MASTER_CONTAINER_NAME"
  run $REDIS_MASTER_SENTINEL_CONTAINER_NAME
}

function redisSlave() {
  environment REDIS_MASTER_IP LOCAL_IP
  defaultRedisEnv
  s=$(port $(expr $REDIS_SLAVE_PORT))
  if [ $s -eq 1 ]; then
    echo "slave节点端口被占用: $(expr $REDIS_SLAVE_PORT)(可通过export REDIS_SLAVE_PORT=xxx修改)"
    exit
  fi
  s1=$(port $(expr $REDIS_SLAVE_PORT + 1))
  if [ $s1 -eq 1 ]; then
    echo "slave sentinel节点端口被占用: $(expr $REDIS_SLAVE_PORT + 1)(可通过export REDIS_SLAVE_PORT=xxx修改)"
    exit
  fi

  export REDIS_SLAVE_SENTINEL_PORT=$(expr $REDIS_SLAVE_PORT + 1)
  if [ "$REDIS_SLAVE_CONTAINER_NAME" == "" ]; then
    REDIS_SLAVE_CONTAINER_NAME="redis-slave"
  fi
  if [ "$REDIS_SLAVE_SENTINEL_CONTAINER_NAME" == "" ]; then
    REDIS_SLAVE_SENTINEL_CONTAINER_NAME="redis-slave-sentinel"
  fi
  export REDIS_SLAVE_CONTAINER_NAME=$REDIS_SLAVE_CONTAINER_NAME
  echo "正在初始化slave节点: $REDIS_SLAVE_CONTAINER_NAME"
  run $REDIS_SLAVE_CONTAINER_NAME
  export REDIS_SLAVE_SENTINEL_CONTAINER_NAME=$REDIS_SLAVE_SENTINEL_CONTAINER_NAME
  echo "正在初始化slave sentinel节点: $REDIS_SLAVE_SENTINEL_CONTAINER_NAME"
  run $REDIS_SLAVE_SENTINEL_CONTAINER_NAME
}

function defaultRedisEnv() {
  if [ "$REDIS_PORT" == "" ]; then
    REDIS_PORT=6379
  fi
  if [ "$REDIS_SLAVE_PORT" == "" ]; then
    REDIS_SLAVE_PORT=6279
  fi
  if [ "$REDIS_PASS" == "" ]; then
    REDIS_PASS=123456
  fi
  if [ "$REDIS_MASTER_NAME" == "" ]; then
    REDIS_MASTER_NAME=prod
  fi
  if [ "$REDIS_MASTER_CONTAINER_NAME" == "" ]; then
    REDIS_MASTER_CONTAINER_NAME=redis-master
  fi
  if [ "$REDIS_MASTER_SENTINEL_CONTAINER_NAME" == "" ]; then
    REDIS_MASTER_SENTINEL_CONTAINER_NAME=redis-master-sentinel
  fi
  export REDIS_PORT=$REDIS_PORT
  export REDIS_SLAVE_PORT=$REDIS_SLAVE_PORT
  export REDIS_PASS=$REDIS_PASS
  export REDIS_MASTER_NAME=$REDIS_MASTER_NAME
  export REDIS_MASTER_CONTAINER_NAME=$REDIS_MASTER_CONTAINER_NAME
  export REDIS_MASTER_SENTINEL_CONTAINER_NAME=$REDIS_MASTER_SENTINEL_CONTAINER_NAME
}

function genRedisEnv() {
  environment REDIS_MASTER_IP LOCAL_IP
  defaultRedisEnv
  if [ $REDIS_PORT -lt 1024 ]; then
    echo 'redis端口>1023'
    exit
  fi
  start=$REDIS_PORT
  for ((index = 0; index < $1; index++)); do
    item=$(expr $start + $index)
    if [ $index -eq 0 ]; then
      m=$(port $(expr $item))
      if [ $m -eq 1 ]; then
        echo "master节点端口被占用: $(expr $item)(可通过export REDIS_PORT=xxx修改)"
        exit
      fi
      m2=$(port $(expr $item + $1))
      if [ $m2 -eq 1 ]; then
        echo "master sentinel节点端口被占用: $(expr $item)(可通过export REDIS_PORT=xxx修改)"
        exit
      fi
    else
      s=$(port $(expr $item))
      if [ $s -eq 1 ]; then
        echo "第 $index 个slave节点端口被占用: $(expr $item)(可通过export REDIS_PORT=xxx修改)"
        exit
      fi
      s2=$(port $(expr $item + $1))
      if [ $s2 -eq 1 ]; then
        echo "第 $index 个slave sentinel节点端口被占用: $(expr $item + $1)(可通过export REDIS_PORT=xxx修改)"
        exit
      fi
    fi
  done
  for ((index = 0; index < $1; index++)); do
    item=$(expr $start + $index)
    if [ $index -eq 0 ]; then
      export REDIS_PORT=$(expr $item)
      export REDIS_MASTER_SENTINEL_PORT=$(expr $item + $1)
      echo "正在初始化master节点: $REDIS_MASTER_CONTAINER_NAME"
      run $REDIS_MASTER_CONTAINER_NAME
      echo "正在初始化master sentinel节点: $REDIS_MASTER_CONTAINER_NAME"
      run $REDIS_MASTER_SENTINEL_CONTAINER_NAME
    else
      export REDIS_SLAVE_PORT=$(expr $item)
      export REDIS_SLAVE_SENTINEL_PORT=$(expr $item + $1)
      export REDIS_SLAVE_CONTAINER_NAME="redis-slave$index"
      echo "正在初始化第 $index 个slave节点: $REDIS_SLAVE_CONTAINER_NAME"
      run $REDIS_SLAVE_CONTAINER_NAME
      export REDIS_SLAVE_SENTINEL_CONTAINER_NAME="redis-slave-sentinel$index"
      echo "正在初始化第 $index 个slave sentinel节点: $REDIS_SLAVE_SENTINEL_CONTAINER_NAME"
      run $REDIS_SLAVE_SENTINEL_CONTAINER_NAME
    fi
  done
}

function fast() {
  if [ "$1" == "web" ]; then
    runFastWeb $1
  elif [ "$1" == "ui" ]; then
    runFastUi $1
  else
    runFastWeb $1
    runFastUi $1
  fi
}

function runFastWeb() {
  if [ "$WEB_PORT" == "" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      WEB_PORT=9090
    else
      WEB_PORT=8080
    fi
  fi
  if [ "$WEB_PPROF_PORT" == "" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      WEB_PPROF_PORT=9005
    else
      WEB_PPROF_PORT=8005
    fi
    if [ "$WEB_MYSQL_PASSWORD" == "" ]; then
      WEB_MYSQL_PASSWORD=root
    fi
  fi
  export WEB_PORT=$WEB_PORT
  export WEB_PPROF_PORT=$WEB_PPROF_PORT
  export WEB_MYSQL_PASSWORD=$WEB_MYSQL_PASSWORD
  if [ $WEB_PORT -lt 1024 ]; then
    echo 'web端口>1023'
    exit
  fi
  start1=$WEB_PORT
  start2=$WEB_PPROF_PORT
  for ((index = 0; index < $1; index++)); do
    item1=$(expr $start1 + $index)
    item2=$(expr $start2 + $index)
    s1=$(port $(expr $item1))
    if [ $s1 -eq 1 ]; then
      echo "第 $(expr $index + 1) 个web端口被占用: $(expr $item1)(可通过export WEB_PORT=xxx修改)"
      exit
    fi
    s2=$(port $(expr $item2))
    if [ $s2 -eq 1 ]; then
      echo "第 $(expr $index + 1) 个web pprof端口被占用: $(expr $item2)(可通过export WEB_PPROF_PORT=xxx修改)"
      exit
    fi
  done
  for ((index = 0; index < $1; index++)); do
    item1=$(expr $start1 + $index)
    item2=$(expr $start2 + $index)
    export MACHINE_ID=$index
    export WEB_PORT=$item1
    export WEB_PPROF_PORT=$item2
    export WEB_CONTAINER_NAME="gin-web-prod$(expr $index + 1)"
    echo "正在初始化第 $(expr $index + 1) 个web容器: $WEB_CONTAINER_NAME"
    run $WEB_CONTAINER_NAME
  done
}

function runFastUi() {
  if [ "$UI_PORT" == "" ]; then
    if [ "$GIN_WEB_MODE" == "staging" ]; then
      UI_PORT=9080
    else
      UI_PORT=8070
    fi
  fi
  export UI_PORT=$UI_PORT
  if [ $UI_PORT -lt 1024 ]; then
    echo 'ui端口>1023'
    exit
  fi
  start3=$UI_PORT
  for ((index = 0; index < $1; index++)); do
    item3=$(expr $start3 + $index)
    s1=$(port $(expr $item1))
    s3=$(port $(expr $item3))
    if [ $s3 -eq 1 ]; then
      echo "第 $(expr $index + 1) 个ui端口被占用: $(expr $item3)(可通过export UI_PORT=xxx修改)"
      exit
    fi
  done
  for ((index = 0; index < $1; index++)); do
    item3=$(expr $start3 + $index)
    export MACHINE_ID=$index
    export UI_PORT=$item3
    export UI_CONTAINER_NAME="gin-web-vue-prod$(expr $index + 1)"
    echo "正在初始化第 $(expr $index + 1) 个ui容器: $UI_CONTAINER_NAME"
    run $UI_CONTAINER_NAME
  done
}

function loki() {
  defaultLokiEnv $1
  up loki
}

function defaultLokiEnv() {
  if [ "$DOCKER_BIP" == "" ]; then
    DOCKER_BIP="172.15.0.1/16"
  fi
  if [ "$LOKI_PORT" == "" ]; then
    LOKI_PORT=3100
  fi
  if [ "$LOKI_FRONTEND_PORT" == "" ]; then
    LOKI_FRONTEND_PORT=3200
  fi
  if [ "$LOKI_GATEWAY_PORT" == "" ]; then
    LOKI_GATEWAY_PORT=3300
  fi
  if [ "$LOKI_PROMTAIL_PORT" == "" ]; then
    LOKI_PROMTAIL_PORT=3080
  fi
  if [ "$LOKI_GRAFANA_PORT" == "" ]; then
    LOKI_GRAFANA_PORT=3000
  fi
  if [ "$LOKI_MEMBER_PORT" == "" ]; then
    LOKI_MEMBER_PORT=7946
  fi
  export DOCKER_BIP=$DOCKER_BIP
  export LOKI_PORT=$LOKI_PORT
  export LOKI_FRONTEND_PORT=$LOKI_FRONTEND_PORT
  export LOKI_FRONTEND_PORT=$LOKI_FRONTEND_PORT
  export LOKI_GATEWAY_PORT=$LOKI_GATEWAY_PORT
  export LOKI_PROMTAIL_PORT=$LOKI_PROMTAIL_PORT
  export LOKI_GRAFANA_PORT=$LOKI_GRAFANA_PORT
  export LOKI_MEMBER_PORT=$LOKI_MEMBER_PORT
}

function port() {
  if [ "$SKIP_CHECK_PORT" != "" ]; then
    echo 0
  else
    l=$(which lsof)
    pid=$($l -i :$1 | grep -v "PID" | awk '{print $2}')
    if [ "$pid" != "" ]; then
      echo 1
    else
      echo 0
    fi
  fi
}

function id() {
  if [ "$1" -ge 0 ] && [ "$1" -le 9 ]; then
    cat tpl/machine.id |
      sed "s/\${MACHINE_ID}/$1/g" >machine.id
  else
    echo "机器编号$1不合法(0~9)" && exit 1
  fi
}

function help() {
  echo "
  ./control.sh环境变量:
  COMPOSE_HTTP_TIMEOUT compose连接超时时间: 默认60(秒)
  GIN_WEB_MODE 应用模式: production/staging, 默认production
  ./control.sh运行命令:
  注意: str可取值web(后端)/ui(前端)/container-name(容器名, 可自由设置)
  pull str 更新容器
  build str 构建容器
  start str 启动容器
  stop str 关闭容器
  restart str 重启容器
  run str 运行容器(关闭、更新、构建、启动)
  top str 查看容器状态
  tail str 查看容器日志
  id str 写入当前机器编号
  sentinel str 一键启动redis主从哨兵模式, str表示哨兵数, 默认3(一主两从)
  loki 一键启动loki
  fast str 一键启动前端后端, str表示副本数量, 默认1(一个后端一个前端, 如果大于1会自动拷贝副本)
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
elif [ "$1" == "sentinel" ]; then
  sentinel $2
elif [ "$1" == "loki" ]; then
  loki
elif [ "$1" == "fast" ]; then
  fast $2
elif [ "$1" == "id" ]; then
  id $2
else
  help
fi
