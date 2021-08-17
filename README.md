<h1 align="center">Gin Web Docker</h1>

<div align="center">
Docker Compose一键部署Gin Web, 解决构建部署烦恼
</div>

## 目录说明
```
# 注意: 
# 前后端项目指定了阿里云镜像, 如果在本地构建, 需要将前后端项目clone到根目录下
├── gin-web-docker # 部署构建根目录
│   ├── tpl # 模版文件目录
│   │    ├── app # 项目配置文件目录
│   │    └── redis # redis配置文件目录
│   ├── .gitignore # git忽略文件列表
│   ├── .dockerignore # docker忽略文件列表
│   └── README.md # 说明文档

```

## 快速开始

### shell脚本(支持unix内核系统)

```
git clone git@github.com:piupuer/gin-web-docker.git
cd gin-web-docker
chmod +x control.sh
# 1. 启动redis
# 一键启动redis哨兵模式(只需执行一次即可, 哨兵数按需修改)
# 主节点IP(如果是单机则填写ifconfig | grep inet打印的局域网IP, 例如我的是10.13.2.252)
export REDIS_MASTER_IP=10.13.2.252
# 从节点IP(如果是单机则填写ifconfig | grep inet打印的局域网IP, 例如我的是10.13.2.252)
export LOCAL_IP=10.13.2.252
# 起始端口(会自动分配各个节点对应端口)
export REDIS_PORT=6379
./control.sh sentinel 3

# 校验redis是否配置成功


# 2. 启动前后端 
# 指定远程镜像版本
echo xxx > tpl/app/web_tag
echo xxx > tpl/app/ui_tag
# 一键启动前端后端
# 起始端口(默认8080)
export WEB_PORT=7070
# redis哨兵模式连接地址(上面配置的redis对应sentinel所在端口)
export WEB_REDIS_SENTINEL_ADDRESSES=10.13.2.252:6182,10.13.2.252:6183,10.13.2.252:6184
# mysql连接地址
export WEB_MYSQL_HOST=10.13.2.252
export WEB_MYSQL_PORT=3306
export WEB_MYSQL_PASSWORD=root
# 后端项目IP(如果是单机则填写ifconfig | grep inet打印的局域网IP, 例如我的是10.13.2.252)
export WEB_HOST=10.13.2.252
# 启动
./control.sh fast 2


# 第二次需要重启时需要跳过端口校验
SKIP_CHECK_PORT=1
./control.sh fast 2
```

### nginx配置

请将docker-conf/nginx目录下的配置文件拷贝到nginx安装目录(Ubuntu是在/etc/nginx)

### 域名映射

由于nginx.conf中设置了域名piupuer-local.com(也可以改成你自己的域名), 需要修改hosts才能访问, 部署机器ip为192.168.1.105

```
sudo vim /etc/hosts

# 在/etc/hosts文件中添加一行
192.168.1.105 piupuer-local.com
```

> docker-compose运行成功后, 可在浏览器中输入: [http://piupuer-local.com:10001](http://piupuer-local.com:10001), 若不能访问请检查nginx/docker-compose配置是否正确


## Ubuntu 18.04安装docker
```shell
# docker
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install docker-ce

# docker-compose
curl -L https://github.com/docker/compose/releases/download/1.26.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```


## 互动交流

### QQ群：943724601

<img src="https://github.com/piupuer/gin-web/blob/contact/images/qq.jpeg?raw=true" width="256" alt="QQ群" />

## MIT License

    Copyright (c) 2020 piupuer
