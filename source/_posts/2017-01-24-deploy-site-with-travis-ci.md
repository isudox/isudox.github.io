---
title: Travis CI 持续部署静态站方案
date: 2017-01-24 22:07:42
tags:
  - CI
categories:
  - Coding
---


这两天在想 GitHub Page 部署的最佳实践。本站之前的部署方案，是通过在 VPS 上创建 Git 仓库后，再把生成的静态文件同时 Push 到 GitHub Page 和 VPS 的 Git 仓库。其中，VPS 上的 Git 仓库会设置 hook，使得有新的 Commit 被 Push 上来后，自动把 Nginx 下的站点目录进行 Pull 更新。这种方案只是一开始的设置比较麻烦，之后就能一劳永逸，但我觉得还可以再抢救下。

<!-- more -->

## 初步方案
既然核心目标都是一键部署，为什么不利用持续集成，那就用 [Travis CI](https://travis-ci.org/) 吧，和 GitHub 无缝结合。

先来梳理下整个部署思路：

1. 源码文件 Push 到 GitHub Page `source` 分支;
2. Travis-CI 在 GitHub Page `source` 分支更新后，自动构建生成站点文件；
3. Travis-CI 将站点文件推送到 GtiHub Page `master` 分支，同时推送到 VPS；


也就是说，整个部署过程只需要将写好源码文件 Push 到 GitHub 相应分支，后面的操作全部交给 Travis-CI 处理。

## 具体操作

### Travis 关联 GitHub

首先要让 Travis 监听 GitHub 的更新，打开 Travis，选择要监听的 GitHub 仓库，选中后记得勾选 "Build only if .travis.yml is present" 和 "Build pushes" 两个选项。

Travis 要有更改 GitHub 仓库的权限，因此还要到 GitHub 那为 Travis 设置权限 key。打开上面所关联的 GitHub 仓库的 Settings，在 Deploy keys 选项中，为 Travis 添加 SSH key。

```bash
# 生成 ssh key 私钥公钥对，无需 passphrase
ssh-keygen -t rsa -C "your_email@example.com"
```

然后讲 SSH 公钥 `id_rsa.pub` 粘贴到 Deploy key 中，如下图示——

![deploy-key](https://o70e8d1kb.qnssl.com/deploy-key.png)

接下来就是将 SSH 私钥赋给 Travis，参考下面的操作：

```shell
travis encrypt-file ~/.ssh/id_rsa --add
```

Travis 命令行工具会根据私钥自动匹配到对应的 GitHub 仓库，控制台会得到类似如下回显——

> Detected repository as isudox/isudox.github.io, is this correct? |yes|
> encrypting /home/sudoz/.ssh/id_rsa for isudox/isudox.github.io
> storing result as id_rsa.enc
> storing secure env variables for decryption
> Make sure to add id_rsa.enc to the git repository.
> Make sure **not** to add /home/sudoz/.ssh/id_rsa to the git repository.
> Commit all changes to your .travis.yml.

对 Travis 添加私钥后，就能在 Travis 网站上看到新增的环境变量配置，如下图示——

![travis-environment-variables](https://o70e8d1kb.qnssl.com/travis-env-var.png)

上面的操作会对私钥再次加密，并在当前路径下生成加密文件 `id_rsa.enc`，同时在当前路径下的 `.travis.yml` 配置中添加一条解密命令——

```shell
openssl aes-256-cbc -K $encrypted_xxx_key -iv $encrypted_xxx_iv -in .travis/id_rsa.enc -out ~/.ssh/id_rsa -d
```

然后对加密文件解密，存放在 `~/.ssh/` 下，并配置 `~/.ssh/config` 指定要使用的私钥文件，这些操作和普通的 SSH 操作是一致的，很易懂。

```shell
# Set the permission of the key
chmod 600 ~/.ssh/id_rsa
# Start SSH agent
eval $(ssh-agent)
# Add the private key to the system
ssh-add ~/.ssh/id_rsa
```

下面是 `~/.ssh/config` 的参考——

```txt
Host github.com
  HostName github.com
  User git
  StrictHostKeyChecking no
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
```

Push 到 GitHub 前还得对 Git 的全局参数进行配置，例如 username 和 email 信息——

```shell
# Set Git config
git config --global user.name 'sudoz'
git config --global user.email 'me@isudox.com'
```

剩下的工作就都是 Hexo 的操作了，安装依赖，构建静态文件，部署静态站点——

```shell
# Install Hexo
npm install hexo-cli -g
npm install

hexo generate
hexo deploy
```

### travis.yml 配置

```yml
language: node_js

node_js:
  - '6'

sudo: false

cache:
  apt: true
  directories:
    - node_modules

addons:
  ssh_known_hosts: github.com

script:
  - npm run build

deploy:
  provider: script
  script: .travis/deploy.sh
  skip_cleanup: true
  on:
    branch: source
```

Travis deploy script 参考如下——

```shell
#!/bin/bash

# Decrypt the private key
openssl aes-256-cbc -K $encrypted_xxx_key -iv $encrypted_xxx_iv -in .travis/id_rsa.enc -out ~/.ssh/id_rsa -d
# Set the permission of the key
chmod 600 ~/.ssh/id_rsa
# Start SSH agent
eval $(ssh-agent)
# Add the private key to the system
ssh-add ~/.ssh/id_rsa
# Copy SSH config
cp .travis/ssh_config ~/.ssh/config
# Set Git config
git config --global user.name 'sudoz'
git config --global user.email 'me@isudox.com'
# Clone the repository
git clone --branch master git@github.com:isudox/isudox.github.io.git .deploy_git
# Deploy to GitHub
npm run deploy
```

> 需要注意，上面的 deploy.sh 需要有执行权限，`chmod +x deploy.sh`

踩了好几个坑，足足 Push 了 7 次才调试成功

![](https://o70e8d1kb.qnssl.com/travis-build-success.png)