---
title: Docker 部署 GitLab
tags:
  - Dev
categories:
  - DevOps
date: 2016-08-01 17:15:08
---


前几天给自己的域名添加了子域名 git，用来访问自己搭建的 [GitLab](https://about.gitlab.com/)。顺便实践了一把 Docker 的应用部署。

<!-- more -->

GitLab 的外部依赖很多，有 Nginx、Rails、Postgres、Redis、MySQL、unicorn、Go 等。如果单独安装各个依赖，一大堆的配置会让人抓狂。如果用官网提供的 omni 集成包，除非是全新的服务器，否则很大可能就导致依赖的重复安装，比如进程里有多个 Nginx、MySQL，很容易把服务器环境弄得很乱。像 GitLab 这样的程序，其实很适合用 Docker 来部署，一则和实机环境隔离开，另外运行性能相当好。

### 安装 Docker 环境

#### 安装配置

惯例，以 Debian 8 为参考，把 Docker 官方维护的 deb 包添加到系统的 APT 源内，创建文件 `/etc/apt/sources.list.d/docker.list`：

```
deb https://apt.dockerproject.org/repo debian-jessie main
```

更新源，安装 `docker-engine` 包，执行 `ps -ef | grep docker` 查看 Docker 的进程，

```
root      2885     1  0 09:40 ?        00:00:10 /usr/bin/dockerd --raw-logs
root      2897  2885  0 09:40 ?        00:00:00 docker-containerd -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --shim docker-containerd-shim --metrics-interval=0 --start-timeout 2m --state-dir /var/run/docker/libcontainerd/containerd --runtime docker-runc
sudoz    21053  6463  0 14:54 pts/0    00:00:00 grep --color=auto --exclude-dir=.bzr --exclude-dir=CVS --exclude-dir=.git --exclude-dir=.hg --exclude-dir=.svn docker
```

可以看到，Docker 的守护进程以 root 用户运行，通过绑定 Unix socket 而非 TCP 端口号来转发数据，通常 Unix socket 所属用户是 root，所以在执行 `docker [command]` 时需要加上 `sudo`。如果非 root 用户需要 docker 命令的执行权限，可以把用户加进 docker 用户组，这样 docker 守护进程在启动时，把 Unix socket 读写权限赋予给 docker 用户组，从而使得非 root 用户获得 docker 执行权限。很简单，

```bash
sudo groupadd docker
sudo sudo usermod -aG docker $(whoami)
sudo service docker restart
```

#### 基础操作

```bash
docker search [image]
```

在 Docker Hub 上搜索相关的镜像，并返回镜像的状态和信息；

```bash
docker pull [image]
```

从 Docker Hub 上下载指定的镜像，注意此时并没有运行 Docker 容器，仅仅只是下载；

```bash
docker run [image]
```

在容器内运行已下载的指定镜像，如果镜像未下载完成，会先执行下载；

```bash
docker ps [-l, -a]
```

类似系统的 ps 命令，查看当前正在运行的 Docker 容器，-l 参数是显示最近运行的容器，-a 参数显示全部的容器；

```bash
docker stop/start/restart [container]
```

容器有唯一的 ID，可以通过上述命令停止/启动/重启指定容器；

```bash
docker rm [container]
```

删除指定的容器；

```bash
docker images
```

查看全部已下载的 Docker 镜像；

```bash
docker rmi [image]
```

删除指定的 Docker 镜像；

目前为止，这些命令已经够用了。还有一些命令的参数没有展开，用到的时候再具体解释。


### Docker 运行 GitLab

Docker Hub 上维护的 GitLab 镜像有好几个，我没有选官方维护的镜像，而是 [sameersbn/gitlab](https://hub.docker.com/r/sameersbn/gitlab/) 镜像，这个镜像相比官方的更灵活。

安装很简单，参考上面给出的 Docker 命令，先下载镜像。

```bash
docker pull sameersbn/gitlab:8.10.2
```

Docker 提供了一个快速运行的工具 [docker-compose](https://docs.docker.com/compose/)，docker-compose 可以将配置文件里的 docker 命令和参数解释出来并运行，镜像的作者提供了可供参考的配置文件 [docker-compose.yml](https://raw.githubusercontent.com/sameersbn/docker-gitlab/master/docker-compose.yml)。从文件里可以看到，该 GitLab 镜像依赖了 Postgres 和 Redis，这些在镜像里没有包含，可以连接外部已经存在的服务，或者另起容器去运行这些依赖服务。

或者手动去运行容器，不通过 docker-compose。
首先，运行 Postgres 容器：

```bash
docker run --name gitlab-postgresql -d \
    --env 'DB_NAME=gitlabhq_production' \
    --env 'DB_USER=gitlab' --env 'DB_PASS=your_password' \
    --env 'DB_EXTENSION=pg_trgm' \
    --volume /srv/docker/gitlab/postgresql:/var/lib/postgresql \
    sameersbn/postgresql:9.4-24
```

然后，运行 Redis 容器：

```bash
docker run --name gitlab-redis -d \
    --volume /srv/docker/gitlab/redis:/var/lib/redis \
    sameersbn/redis:latest
```

最后，运行 GitLab 容器：

```bash
docker run --name gitlab -d \
    --link gitlab-postgresql:postgresql --link gitlab-redis:redisio \
    --publish 10022:22 --publish 10080:80 \
    --env 'GITLAB_PORT=10080' --env 'GITLAB_SSH_PORT=10022' \
    --env 'GITLAB_SECRETS_DB_KEY_BASE=long-and-random-alpha-numeric-string' \
    --volume /srv/docker/gitlab/gitlab:/home/git/data \
    sameersbn/gitlab:8.10.2
```

上面的命令涉及几个参数，分别解释下：
- `--name` 参数设置容器的名称，该名称必须唯一；
- `-d` 参数使容器在后台运行；
- `--volume` 参数设置容器挂载的磁盘目录（和宿主机共享）；
- `--env` 参数设置容器的环境变量；
- `link` 参数指定容器需要连接的其他容器；
- `publish` 参数指定容器的外部端口号和内部端口号；

对比手动运行的命令参数和配置文件的参数，两者是一致的。

Docker 容器挂载的共享目录在容器删除时并不会一并被删除，这里需要留意，如果 `/srv/gitlab` 里的文件不需要的话，可以手动删除，以免再次运行容器时发生前后配置差异的冲突。

GitLab 容器运行起来后，通过 `docker logs -f [container]` 来查看运行时日志，运行正常的话，就能访问 http://localhost:10080 看到 GitLab 了。当然这只是在本地运行，如果要部署到服务器上，还需要再做些工作。我的目标是通过 git 子域名访问 Docker 容器内的 GitLab，同时支持 HTTPS 访问。

### Nginx 反代 Docker 容器

要实现上面的目标，需要用到 Nginx 的反向代理，用 Nginx 作为负载的前端，将访问请求代理到 Docker 容器的外部端口上，从访问者的角度上看，就好像直接通过域名访问到 GitLab 一样。

#### 开启 GitLab SSL 支持

Docker GitLab 的 `--publish` 参数设置了 10080:80 的端口号，这表明容器内部的 80 端口映射到宿主机的 10080 端口上，因此访问 Docker 容器的外部端口来访问容器内的应用。

如果是通过上述方式访问 GitLab，那么 SSL 的配置是在 Docker 内部完成，这里不做说明了，我的想法是通过外部负载，比如 Nginx，转发请求到 Docker 容器的端口上。

首先得为 GitLab 的域名准备好 SSL 证书，这个在上一篇水文中已经写了。设置 Docker 容器的环境变量 `GITLAB_HTTPS=true`，使得 GitLab 支持 HTTPS，将环境变量 `GITLAB_PORT` 改为 443，把环境变量 `GITLAB_HOST` 设置为和 SSL 证书相匹配的域名，这样 GitLab 容器的运行命令变成如下：

```bash
docker run --name gitlab -d \
    --publish 10022:22 --publish 10080:80 \
    --env 'GITLAB_SSH_PORT=10022' --env 'GITLAB_PORT=443' \
    --env 'GITLAB_HTTPS=true' --env 'GITLAB_HOST=git.isudox.com' \
    --volume /srv/docker/gitlab/gitlab:/home/git/data \
    sameersbn/gitlab:8.10.2
```

#### 反向代理到 Docker

GitLab 容器正常启动后，还需要 Nginx 把请求反向代理到容器上。如果只是把 HTTP 的请求反代到 GitLab 并不麻烦，但需要同时把 HTTP 重定向 HTTPS。且看下面的 Nginx 配置：

```conf
upstream gitlab {
    server 45.33.47.109:10080 fail_timeout=0;
}

server {
    listen 80;
    server_name git.isudox.com;
    server_tokens off;

    access_log off;

    root /dev/null;

    client_max_body_size 0;

    location / {
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_redirect off;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_pass http://gitlab;
    }
}

server {
    listen 443 ssl;
    server_name git.isudox.com;
    server_tokens off;

    root /dev/null;
    client_max_body_size 0;

    ssl on;
    ssl_certificate /path-to-your-crt;
    ssl_certificate_key /path-to-your-key;
    ssl_verify_client off;

    ssl_ciphers
    "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 5m;

    location / {
        gzip off;

        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_redirect off;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_pass http://gitlab;
    }
}
```

测试下 HTTP 到 HTTPS 的重定向，

```bash
curl -H "X-Forwarded-Proto: https" http://45.33.47.109:10080/user/sign_in
<html><body>You are being <a href="https://45.33.47.109:10080/users/sign_in">redirected</a>.</body></html>
```

验收下最终的成果，[GitLab](http://git.isudox.com)

最后，贴上我的 `docker-composer.yml` 配置，仅作备忘。

```yml
version: '2'

services:
  redis:
    restart: always
    image: sameersbn/redis:latest
    command:
    - --loglevel warning
    volumes:
    - /srv/docker/gitlab/redis:/var/lib/redis:Z

  postgresql:
    restart: always
    image: sameersbn/postgresql:9.4-24
    volumes:
    - /srv/docker/gitlab/postgresql:/var/lib/postgresql:Z
    environment:
    - DB_USER=gitlab
    - DB_PASS=helloworld
    - DB_NAME=gitlabhq_production
    - DB_EXTENSION=pg_trgm

  gitlab:
    restart: always
    image: sameersbn/gitlab:8.10.3
    depends_on:
    - redis
    - postgresql
    ports:
    - "10080:80"
    - "10022:22"
    volumes:
    - /srv/docker/gitlab/gitlab:/home/git/data:Z
    environment:
    - DEBUG=false

    - DB_ADAPTER=postgresql
    - DB_HOST=postgresql
    - DB_PORT=5432
    - DB_USER=gitlab
    - DB_PASS=helloworld
    - DB_NAME=gitlabhq_production

    - REDIS_HOST=redis
    - REDIS_PORT=6379

    - TZ=Asia/Shanghai
    - GITLAB_TIMEZONE=Beijing

    - GITLAB_HTTPS=true
    - SSL_SELF_SIGNED=false

    - GITLAB_HOST=git.isudox.com
    - GITLAB_PORT=443
    - GITLAB_SSH_PORT=10022
    - GITLAB_RELATIVE_URL_ROOT=
    - GITLAB_SECRETS_DB_KEY_BASE=qwertyuiopasdfghjklzxcvbnm

    - GITLAB_ROOT_PASSWORD=
    - GITLAB_ROOT_EMAIL=

    - GITLAB_NOTIFY_ON_BROKEN_BUILDS=true
    - GITLAB_NOTIFY_PUSHER=false

    - GITLAB_EMAIL=hi@gmail.com
    - GITLAB_EMAIL_DISPLAY_NAME=GitLab
    - GITLAB_EMAIL_REPLY_TO=hi@gmail.com
    - GITLAB_EMAIL_ENABLED=true

    - GITLAB_BACKUP_SCHEDULE=daily
    - GITLAB_BACKUP_TIME=05:00

    - SMTP_ENABLED=enable
    - SMTP_DOMAIN=www.gmail.com
    - SMTP_HOST=smtp.gmail.com
    - SMTP_PORT=587
    - SMTP_USER=hi@gmail.com
    - SMTP_PASS=helloworld
    - SMTP_STARTTLS=true
    - SMTP_AUTHENTICATION=login

    - IMAP_ENABLED=false
    - IMAP_HOST=imap.gmail.com
    - IMAP_PORT=993
    - IMAP_USER=hi@gmail.com
    - IMAP_PASS=helloworld
    - IMAP_SSL=true
    - IMAP_STARTTLS=false
```