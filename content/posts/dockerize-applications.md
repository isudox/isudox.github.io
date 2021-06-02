---
title: Docker 容器化应用
date: 2017-01-16 13:30:31
tags:
  - Dev
categories:
  - Coding
---

最近看了一篇[博文](http://www.kkblog.me/notes/%E4%BD%BF%E7%94%A8Docker%E6%9E%84%E5%BB%BA%E9%AB%98%E6%95%88Web%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83)，大受启发，也想着手尝试把自己 VPS 上的应用容器化，一方面尝试下新的开发方式，另一方面也便于应用迁移。

<!-- more -->

## Dockerfile

Docker 通过 `dockerfile` 配置来把应用构建成镜像，`dockerfile` 是一个包含了配置和创建应用的全部命令的文本。Docker 官网上有对 `dockerfile` 的详细[说明文档](https://docs.docker.com/engine/reference/builder/)

看了文档后，对其使用有大致的了解，对不是太复杂的应用的容器化，已经能实践了，下面对 `dockerfile` 的编写和使用简单总结下。

### 编写 dockerfile

#### FROM

`FROM` 指令会设置要构建的镜像所依赖的基础镜像，比如应用是运行在 Ubuntu 系统上，那么就用 FROM 指定依赖镜像为 Ubuntu，`FROM` 必须是第一条非注释指令。

```dockerfile
FROM <image>
# tag 可选
FROM <image>:<tag>
```

#### MAINTAINER

该指令设置镜像的作者信息。

```dockerfile
MAINTAINER <name>
```

#### RUN

`RUN` 会运行其指定的命令，一个 `RUN` 运行一条命令，单条命令可以通过 `\` 反斜杠换行。`RUN` 支持两种格式：
   - `RUN <cmd>`：shell 格式，直接运行一条完整的 shell 命令，默认使用 `/bin/sh -c` 执行该 shell 命令；
   - `RUN ["executable", "param1", "param2"]`： exec 格式，第一个参数是可执行文件，后面跟参数；
参考下面的例子：

```dockerfile
RUN /bin/bash -c 'source $HOME/.bashrc; echo $HOME'
RUN ["/bin/bash", "-c", "echo hello"]
```

#### CMD

`CMD` 也是执行命令的指令，和 `RUN` 的区别在于，`RUN` 发生在镜像构建过程中，`CMD` 发生在容器启动时。`dockerfile` 中只能存在一条有效的 `CMD` 指令，如果编写了多条，则只有最后一条生效。

`CMD` 最主要的作用是给容器提供默认的配置，它支持 3 种格式：
  - `CMD ["executable","param1","param2"]`：exex 格式，推荐；
  - `CMD ["param1","param2"]`：提供给 ENTRYPOINT 脚本的参数；
  - `CMD command param1 param2`：shell 格式；

参考示例：

```dockerfile
FROM ubuntu
# shell 格式
CMD echo "This is a test." | wc -
# exec 格式
CMD ["/usr/bin/wc","--help"]
```

#### ENTRYPOINT

`ENTRYPOINT` 指令是在容器启动时执行的命令或脚本，一般是对容器进行设置。它支持两种格式：
  - `ENTRYPOINT ["executable", "param1", "param2"]`：exec 格式，推荐；
  - `ENTRYPOINT command param1 param2`：shell 格式；

```dockerfile
docker run -i -t --rm -p 80:80 nginx
```

例如上面的 nginx 容器启动命令，docker run <image> -d 会将参数 `-d` 传递给 entry point，如果是在 `CMD` 中已经被设置的参数，则会被覆盖掉。启动时，如果要覆盖 `ENTRYPOINT`，可以通过 `--entrypoint` 标识设置新的 `ENTRYPOINT`。

只有最后一条 `ENTRYPOINT` 指令才会生效。

#### EXPOSE

`EXPOSE` 指令设置容器运行时监听的端口号。`EXPOSE` 并不能直接使容器内端口被主机访问，如果要实现主机访问容器端口，必须通过 `-p` 标识来指定可访问的容器端口。

```dockerfile
EXPOSE <port> [<port>...]

# 映射一个端口
EXPOSE port1
# 相应的运行容器使用的命令
docker run -p port1 image

# 映射多个端口
EXPOSE port1 port2 port3
# 相应的运行容器使用的命令
docker run -p port1 -p port2 -p port3 image

# 还可以指定需要映射到宿主机器上的某个端口号  
docker run -p host_port1:port1 -p host_port2:port2 -p host_port3:port3 image
```

#### ENV

`ENV` 指令会设置键值对环境变量，它有两种格式：
  - `ENV <key> <value>`：一次设置单个环境变量；
  - `ENV <key>=<value> ...`：一次设置多个环境变量，以空格作为不同环境变量之间的分隔；

环境变量设置后，无论是在容器镜像构建时，还是在容器启动运行时，都能引用到。另外，在容器运行时，如果需要额外指定环境变量，可以通过 `run --env <key>=<value>` 设置。

#### ADD

`ADD` 指令把源地址的文件、文件夹复制到目的地址，支持通配符。`ADD` 有两种格式：
  - `ADD <src>... <dest>`
  - `ADD ["<src>",... "<dest>"]`：当路径中存在空格时，需要采用这种格式；

<dest> 是绝对路径，或者基于 `WORKDIR` 的相对路径，例如：

```dockerfile
ADD test relativeDir/          # adds "test" to `WORKDIR`/relativeDir/
ADD test /absoluteDir/         # adds "test" to /absoluteDir/
```

#### WORKDIR

`WORKDIR` 设置工作目录，类似 shell 的 `cd`，使 `RUN` `CMD` `ENCRYPT` `COPY` `ADD` 指令在该工作目录下执行。在 `dockerfile` 中，`WORKDIR` 可以多次指定，如果设置的是一个相对路径，则是相对于前一个 `WORKDIR` 设置的路径，比如：

```dockerfile
WORKDIR /a
WORKDIR b
WORKDIR c
RUN pwd
```

得到的结果应该是 `/a/b/c`。

#### COPY

`COPY` 和 `ADD` 功能上基本相同，不同之处在于，`ADD` 支持从远程拉取文件复制到 <dest>，支持自动解压 `tar` 包并删除。

#### VOLUME

`VOLUME` 指令创建一个挂载点，使得容器内的该挂载点具有持久数据的功能，换句话说，就是容器和主机之间的共享目录，当关闭容器后，共享目录仍会保留。参考示例：

```dockerfile
FROM ubuntu
RUN mkdir /myvol
RUN echo "hello world" > /myvol/greeting
VOLUME /myvol
# 多个挂载点
# VOLUME ["<mountpoint1>, <mountpoint2>"]
```

`myvol` 成为容器在主机里的挂载点。容器的挂载点还可以提供给其他容器使用，只需通过 `-volumes-from` 标识指定要使用的容器挂载点即可。

```dockerfile
docker run -t -i -rm -volumes-from container1 image2 bash
```

其中，container1 为第一个容器的 ID， image2 为第二个容器运行镜像的名称。

#### USER

`USER` 指令设置容器运行时和执行 `RUN` `CMD` `ENTRYPOINT` 的用户或 UID，默认为 root 用户。

#### ARG

`ARG` 指令规定了用户在通过 `docker build --build-arg <varname>=<value>` 构建镜像时允许传递的变量 varname。如果用户传递了 dockerfile 中未定义的变量，构建会报 “One or more build-args were not consumed, failing build.” 的错误信息。

`ARG` 也可以设置默认变量值，当设置了默认值后，用户如果在构建时没有传相应变量，则使用默认值，构建正常进行。

```dockerfile
ARG <name>[=<default value>]
```

还有一个注意点，当 `ARG` 和 `ENV` 同时设置了一个变量时，`ENV` 的设置会覆盖 `ARG`。

### dockerfile 完整示例

官网给了几个完整的 `dockerfile` 示例，例如 Firefox over VNC：

```dockerfile
# Firefox over VNC
#
# VERSION               0.3

FROM ubuntu

# Install vnc, xvfb in order to create a 'fake' display and firefox
RUN apt-get update && apt-get install -y x11vnc xvfb firefox
RUN mkdir ~/.vnc
# Setup a password
RUN x11vnc -storepasswd 1234 ~/.vnc/passwd
# Autostart firefox (might not be the best way, but it does the trick)
RUN bash -c 'echo "firefox" >> /.bashrc'

EXPOSE 5900
CMD    ["x11vnc", "-forever", "-usepw", "-create"]
```

## 容器化应用实践

### shadowsocks-libev

[shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev) 的容器化相对比较简单，对上面的指令初步了解后，再参考别人已有的镜像，实践编写 dockerfile 不算麻烦。

我的 VPS 是 Debian 系统，`FROM` 可以设为 debian，不过还是选了非常了流行的小镜像 [alpine](https://alpinelinux.org/)。然后根据 shadowsocks-libev README 编写安装的命令。

shadowsocks-libev 的源码编译安装过程如下：

```shell
# Debian / Ubuntu
sudo apt-get install --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev asciidoc xmlto zlib1g-dev
./autogen.sh && ./configure && make
sudo make install
```

如果采用 Alpine 作为基础镜像的话，个别命令要改动，`apt-get install` 要替换成 `apk add`。用 `RUN` 指令完成源码的编译安装。

```dockerfile
ENV DEP asciidoc autoconf build-base curl libtool linux-headers openssl-dev pcre-dev tar xmlto

RUN set -ex && \
    apk add --no-cache --virtual .build-deps $DEP && \
    curl -sSL $URL | tar xz && \
    cd $DIR && \
        ./configure --disable-documentation && \
        make install && \
        cd .. && \
    apk del .build-deps && \
    rm -rf $DIR
```

参考 shadowsocks 的启动参数，编写 `CMD` 或 `ENTRYPOINT` 指令：

```dockerfile
CMD ss-server -s $ADDR \
              -p $PORT \
              -k ${PASSWORD:-$(hostname)} \
              -m $METHOD \
              -t $TIMEOUT \
              --fast-open \
              -d $DNS \
              -u
```

本地构建成功后，就可以推送镜像到 Docker Hub 分享给他人，或者把 Dockerfile 上传到 GitHub，通过 Docker Hub 关联 GitHub 实现自动构建。完整的 Dockerfile 已上传到 GitHub 仓库，并结合 Docker Hub 实现自动构建镜像：
  - GitHub [仓库地址](https://github.com/isudox/dockerfile/tree/master/shadowsocks-libev)
  - Docker Hub [镜像地址](https://hub.docker.com/r/sudoz/shadowsocks-libev/)

Docker Hub 上有镜像后，以后再安装 shadowsocks 只需要一条命令就能完成安装和配置：

```shell
docker run -d -e METHOD=aes-256-cfb -e PASSWORD=123456 -p 8388:8388 --restart always sudoz/shadowsocks-libev
```

一劳永逸！

### docker-compose

如果每次启动 Docker 镜像都要手敲一大段命令来给容器配置参数的话，还是不够简洁优雅，docker-compose 就解决了这个问题，直接把配置写成文本，由 docker-compose 来读取配置文件 `docker-compose.yml` 并启动容器，真正做到一次编写，到处运行。

```yml
shadowsocks:
  image: sudoz/shadowsocks-libev
  ports:
    - "8388:8388"
  environment:
    - METHOD=aes-256-cfb
    - PASSWORD=123456
  restart: always
```

配置很明白，对应了 `docker run` 启动容器时的参数配置，现在只需要一行简单的命令来启动容器：

```shell
docker-compose up -d
```

*************************************************

参考资料：
  - [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
  - [Docker 镜像创建](http://zone.gaospot.com/2016/05/11/Docker%E9%95%9C%E5%83%8F%E5%88%9B%E5%BB%BA/)