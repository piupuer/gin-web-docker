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

  stop $1
  pull $1
  build $1
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

function start() {
  check $1

  echo "$CMD up -d $1"
  sh -c "$CMD up -d $1"
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
    echo "please set container_name" && exit 1
    return
  fi
  if [[ "$1" =~ "$WEB_NAME-prod" || "$1" =~ "$WEB_NAME-stage" ]]; then
    export WEB_IMAGE=$(cat tpl/app/web_image)
    environment WEB_IMAGE WEB_HOME
    environment WEB_PORT WEB_PPROF_PORT WEB_INTERNAL_PORT WEB_INTERNAL_PPROF_PORT MACHINE_ID
    environment WEB_REDIS_URI WEB_MYSQL_URI
    export WEB_MYSQL_URI=$(echo ${WEB_MYSQL_URI} | sed 's/&/\\&/g')
    cat tpl/app/web.yml |
      sed "s#\${WEB_IMAGE}#${WEB_IMAGE}#g" |
      sed "s#\${WEB_HOME}#${WEB_HOME}#g" |
      sed "s/\${MACHINE_ID}/${MACHINE_ID}/g" |
      sed "s/\${WEB_CONTAINER_NAME}/$1/g" |
      sed "s/\${WEB_TAG}/${WEB_TAG}/g" |
      sed "s/\${WEB_PORT}/${WEB_PORT}/g" |
      sed "s/\${WEB_PPROF_PORT}/${WEB_PPROF_PORT}/g" |
      sed "s/\${WEB_INTERNAL_PORT}/${WEB_INTERNAL_PORT}/g" |
      sed "s/\${WEB_INTERNAL_PPROF_PORT}/${WEB_INTERNAL_PPROF_PORT}/g" |
      sed "s#\${WEB_REDIS_URI}#${WEB_REDIS_URI}#g" |
      sed "s#\${WEB_MYSQL_URI}#${WEB_MYSQL_URI}#g" >run/$1-tmp.yml
    cat run/$1-tmp.yml | sed 's/\\\&/\&/g' >run/$1.yml
    rm run/$1-tmp.yml
    export WEB_MYSQL_URI=$(echo ${WEB_MYSQL_URI} | sed 's/\\&/\&/g')
  elif [[ "$1" =~ "$UI_NAME-prod" || "$1" =~ "$UI_NAME-stage" ]]; then
    export UI_IMAGE=$(cat tpl/app/ui_image)
    environment UI_IMAGE
    environment UI_PORT UI_INTERNAL_PORT
    environment WEB_HOST WEB_PORT NGINX_UPSTREAM
    cat tpl/app/ui.yml |
      sed "s/\${UI_CONTAINER_NAME}/$1/g" |
      sed "s#\${UI_IMAGE}#${UI_IMAGE}#g" |
      sed "s/\${UI_PORT}/${UI_PORT}/g" |
      sed "s/\${UI_INTERNAL_PORT}/${UI_INTERNAL_PORT}/g" >run/$1.yml
    cat tpl/app/nginx/nginx.conf |
      sed "s/\${WEB_HOST}/${WEB_HOST}/g" |
      sed "s/\${WEB_PORT}/${WEB_PORT}/g" |
      sed "s/\${UI_INTERNAL_PORT}/${UI_INTERNAL_PORT}/g" |
      sed "s/\${NGINX_UPSTREAM}/${NGINX_UPSTREAM}/g" >run/nginx-conf/$1-nginx.conf
  elif [[ "$1" =~ "redis-master-sentinel" ]]; then
    environment REDIS_PORT REDIS_PASS REDIS_MASTER_SENTINEL_PORT REDIS_MASTER_NAME REDIS_MASTER_IP LOCAL_IP
    environment REDIS_MASTER_SENTINEL_CONTAINER_NAME REDIS_IMAGE
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
    environment REDIS_MASTER_CONTAINER_NAME REDIS_IMAGE
    cat tpl/redis/redis-master.conf |
      sed "s/\${REDIS_PORT}/${REDIS_PORT}/g" |
      sed "s/\${REDIS_PASS}/${REDIS_PASS}/g" >run/redis-conf/$1.conf
    cat tpl/redis/redis-master.yml |
      sed "s/\${REDIS_PORT}/${REDIS_PORT}/g" |
      sed "s/\${REDIS_MASTER_CONTAINER_NAME}/${REDIS_MASTER_CONTAINER_NAME}/g" >run/$1.yml
  elif [[ "$1" =~ "redis-slave-sentinel" ]]; then
    environment REDIS_PORT REDIS_PASS REDIS_SLAVE_SENTINEL_PORT REDIS_MASTER_NAME REDIS_MASTER_IP LOCAL_IP
    environment REDIS_SLAVE_SENTINEL_CONTAINER_NAME REDIS_IMAGE
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
    environment REDIS_SLAVE_CONTAINER_NAME REDIS_IMAGE
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
    echo "missing env $msg" && exit 1
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
    echo "master port already in use: $(expr $REDIS_PORT)(u can change by export REDIS_PORT=xxx)"
    exit
  fi
  m1=$(port $(expr $REDIS_PORT + 1))
  if [ $m1 -eq 1 ]; then
    echo "master sentinel port already in use: $(expr $REDIS_PORT + 1)(u can change by export REDIS_PORT=xxx)"
    exit
  fi
  export REDIS_MASTER_SENTINEL_PORT=$(expr $REDIS_PORT + 1)
  echo "Initializing master node: $REDIS_MASTER_CONTAINER_NAME"
  run $REDIS_MASTER_CONTAINER_NAME
  echo "Initializing master sentinel node: $REDIS_MASTER_CONTAINER_NAME"
  run $REDIS_MASTER_SENTINEL_CONTAINER_NAME
}

function redisSlave() {
  environment REDIS_MASTER_IP LOCAL_IP
  defaultRedisEnv
  s=$(port $(expr $REDIS_SLAVE_PORT))
  if [ $s -eq 1 ]; then
    echo "slave port already in use: $(expr $REDIS_SLAVE_PORT)(u can change by export REDIS_SLAVE_PORT=xxx)"
    exit
  fi
  s1=$(port $(expr $REDIS_SLAVE_PORT + 1))
  if [ $s1 -eq 1 ]; then
    echo "slave sentinel port already in use: $(expr $REDIS_SLAVE_PORT + 1)(u can change by export REDIS_SLAVE_PORT=xxx)"
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
  echo "Initializing slave node: $REDIS_SLAVE_CONTAINER_NAME"
  run $REDIS_SLAVE_CONTAINER_NAME
  export REDIS_SLAVE_SENTINEL_CONTAINER_NAME=$REDIS_SLAVE_SENTINEL_CONTAINER_NAME
  echo "Initializing slave sentinel node: $REDIS_SLAVE_SENTINEL_CONTAINER_NAME"
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
    echo 'redis port minimum is 1024'
    exit
  fi
  start=$REDIS_PORT
  for ((index = 0; index < $1; index++)); do
    item=$(expr $start + $index)
    if [ $index -eq 0 ]; then
      m=$(port $(expr $item))
      if [ $m -eq 1 ]; then
        echo "master port already in use: $(expr $item)(u can change by export REDIS_PORT=xxx)"
        exit
      fi
      m2=$(port $(expr $item + $1))
      if [ $m2 -eq 1 ]; then
        echo "master sentinel port already in use: $(expr $item)(u can change by export REDIS_PORT=xxx)"
        exit
      fi
    else
      s=$(port $(expr $item))
      if [ $s -eq 1 ]; then
        echo "The $index slave port is already in use: $(expr $item)(u can change by export REDIS_PORT=xxx)"
        exit
      fi
      s2=$(port $(expr $item + $1))
      if [ $s2 -eq 1 ]; then
        echo "The $index slave sentinel port is already in use: $(expr $item)(u can change by export REDIS_PORT=xxx)"
        exit
      fi
    fi
  done
  for ((index = 0; index < $1; index++)); do
    item=$(expr $start + $index)
    if [ $index -eq 0 ]; then
      export REDIS_PORT=$(expr $item)
      export REDIS_MASTER_SENTINEL_PORT=$(expr $item + $1)
      echo "Initializing master node: $REDIS_MASTER_CONTAINER_NAME"
      run $REDIS_MASTER_CONTAINER_NAME
      echo "Initializing master sentinel node: $REDIS_MASTER_CONTAINER_NAME"
      run $REDIS_MASTER_SENTINEL_CONTAINER_NAME
    else
      export REDIS_SLAVE_PORT=$(expr $item)
      export REDIS_SLAVE_SENTINEL_PORT=$(expr $item + $1)
      export REDIS_SLAVE_CONTAINER_NAME="redis-slave$index"
      echo "Initializing $index slave node: $REDIS_SLAVE_CONTAINER_NAME"
      run $REDIS_SLAVE_CONTAINER_NAME
      export REDIS_SLAVE_SENTINEL_CONTAINER_NAME="redis-slave-sentinel$index"
      echo "Initializing $index slave sentinel node: $REDIS_SLAVE_SENTINEL_CONTAINER_NAME"
      run $REDIS_SLAVE_SENTINEL_CONTAINER_NAME
    fi
  done
}

function fast() {
  if [ "$1" == "web" ]; then
    runFastWeb $2
  elif [ "$1" == "ui" ]; then
    runFastUi $2
  else
    WEB_TMP_PORT=$WEB_PORT
    runFastWeb $1
    export WEB_PORT=$WEB_TMP_PORT
    runFastUi $1
  fi
}

function runFastWeb() {
  environment WEB_NAME
  if [ "$WEB_HOME" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      WEB_HOME="/app/$WEB_NAME-stage"
    else
      WEB_HOME="/app/$WEB_NAME-prod"
    fi
  fi
  if [ "$WEB_CONTAINER_NAME" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      WEB_CONTAINER_NAME="$WEB_NAME-stage"
    else
      WEB_CONTAINER_NAME="$WEB_NAME-prod"
    fi
  fi
  if [ "$WEB_PORT" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      WEB_PORT=9090
    else
      WEB_PORT=8080
    fi
  fi
  if [ "$WEB_PPROF_PORT" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      WEB_PPROF_PORT=9005
    else
      WEB_PPROF_PORT=8005
    fi
  fi
  if [ "$WEB_INTERNAL_PORT" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      WEB_INTERNAL_PORT=9090
    else
      WEB_INTERNAL_PORT=8080
    fi
  fi
  if [ "$WEB_INTERNAL_PPROF_PORT" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      WEB_INTERNAL_PPROF_PORT=9005
    else
      WEB_INTERNAL_PPROF_PORT=8005
    fi
  fi
  export WEB_HOME=$WEB_HOME
  export WEB_PORT=$WEB_PORT
  export WEB_PPROF_PORT=$WEB_PPROF_PORT
  export WEB_INTERNAL_PORT=$WEB_INTERNAL_PORT
  export WEB_INTERNAL_PPROF_PORT=$WEB_INTERNAL_PPROF_PORT
  if [ $WEB_PORT -lt 1024 ]; then
    echo 'web port minimum is 1024'
    exit
  fi
  start1=$WEB_PORT
  start2=$WEB_PPROF_PORT
  for ((index = 0; index < $1; index++)); do
    item1=$(expr $start1 + $index)
    item2=$(expr $start2 + $index)
    s1=$(port $(expr $item1))
    if [ $s1 -eq 1 ]; then
      echo "The $(expr $index + 1) web port already in use: $(expr $item1)(u can change by export WEB_PORT=xxx)"
      exit
    fi
    s2=$(port $(expr $item2))
    if [ $s2 -eq 1 ]; then
      echo "The $(expr $index + 1) web pporf port already in use: $(expr $item1)(u can change by export WEB_PPROF_PORT=xxx)"
      exit
    fi
  done
  for ((index = 0; index < $1; index++)); do
    item1=$(expr $start1 + $index)
    item2=$(expr $start2 + $index)
    export MACHINE_ID=$index
    export WEB_PORT=$item1
    export WEB_PPROF_PORT=$item2
    export WEB_INTERNAL_PORT=$item1
    export WEB_INTERNAL_PPROF_PORT=$item2
    export WEB_CONTAINER_TMP_NAME=$WEB_CONTAINER_NAME
    export WEB_CONTAINER_NAME="$WEB_CONTAINER_NAME$(expr $index + 1)"
    echo "Initializing $(expr $index + 1) web container: $WEB_CONTAINER_NAME"
    run $WEB_CONTAINER_NAME
    export WEB_CONTAINER_NAME=$WEB_CONTAINER_TMP_NAME
  done
}

function runFastUi() {
  environment UI_NAME
  if [ "$UI_CONTAINER_NAME" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      UI_CONTAINER_NAME="$UI_NAME-stage"
    else
      UI_CONTAINER_NAME="$UI_NAME-prod"
    fi
  fi
  if [ "$NGINX_UPSTREAM" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      NGINX_UPSTREAM=stage-api
    else
      NGINX_UPSTREAM=api
    fi
  fi
  if [ "$UI_PORT" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      UI_PORT=9080
    else
      UI_PORT=8070
    fi
  fi
  if [ "$UI_INTERNAL_PORT" == "" ]; then
    if [ "$RUN_MODE" == "stage" ]; then
      UI_INTERNAL_PORT=9080
    else
      UI_INTERNAL_PORT=8070
    fi
  fi
  export UI_PORT=$UI_PORT
  export UI_INTERNAL_PORT=$UI_INTERNAL_PORT
  export NGINX_UPSTREAM=$NGINX_UPSTREAM
  if [ $UI_PORT -lt 1024 ]; then
    echo 'ui port minimum is 1024'
    exit
  fi
  start3=$UI_PORT
  start4=$UI_INTERNAL_PORT
  start5=$WEB_PORT
  for ((index = 0; index < $1; index++)); do
    item3=$(expr $start3 + $index)
    s3=$(port $(expr $item3))
    if [ $s3 -eq 1 ]; then
      echo "The $(expr $index + 1) ui port already in use: $(expr $item3)(u can change by export UI_PORT=xxx)"
      exit
    fi
  done
  for ((index = 0; index < $1; index++)); do
    item3=$(expr $start3 + $index)
    item4=$(expr $start4 + $index)
    item5=$(expr $start5 + $index)
    export MACHINE_ID=$index
    export UI_PORT=$item3
    export UI_INTERNAL_PORT=$item4
    export WEB_PORT=$item5
    export UI_CONTAINER_TMP_NAME=$UI_CONTAINER_NAME
    export UI_CONTAINER_NAME="$UI_CONTAINER_NAME$(expr $index + 1)"
    echo "Initializing $(expr $index + 1) ui container: $UI_CONTAINER_NAME"
    run $UI_CONTAINER_NAME
    export UI_CONTAINER_NAME=$UI_CONTAINER_TMP_NAME
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
    echo "machine id $1 is illegal (0~9)" && exit 1
  fi
}

function help() {
  echo "
  env:
  COMPOSE_HTTP_TIMEOUT       -- compose timeout(default 60s)
  RUN_MODE                   -- run mode: prod/stage(default prod)
  ./control.sh usage:
  pull container_name        -- update docker image
  build container_name       -- build docker image
  start container_name       -- start container
  stop container_name        -- stop container
  restart container_name     -- restart container
  run container_name         -- auto rerun container(stop=>pull=>build=>start)
  top container_name         -- show container status
  tail container_name        -- show container logs
  id number                  -- set machine id(0<=number<=9)
  sentinel count             -- start redis sentinel(recommended count is set to 3)
  loki                       -- auto start loki
  fast count                 -- auto start count copies web and ui
  fast web count             -- auto start count copies web
  fast ui count              -- auto start count copies ui
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
  fast $2 $3
elif [ "$1" == "id" ]; then
  id $2
else
  help
fi
