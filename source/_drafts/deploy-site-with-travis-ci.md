---
title: Travis-CI 持续部署静态站方案
tags:
  - CI
---

这两天在想 GitHub Page 部署的最佳实践。本站之前的部署方案，是通过在 VPS 上创建 Git 仓库后，再把生成的静态文件同时 Push 到 GitHub Page 和 VPS 的 Git 仓库。其中，VPS 上的 Git 仓库会设置 hook，使得有新的 Commit 被 Push 上来后，自动把 Nginx 下的站点目录进行 Pull 更新。这种方案只是一开始的设置比较麻烦，之后就能一劳永逸，但我觉得还可以再抢救下。

<!-- more -->

## 初步方案
既然核心目标都是一键部署，为什么不利用持续集成，那就用 Travis-CI 吧，和 GitHub 无缝结合。

先来梳理下整个部署思路：

1. 源码文件 Push 到 GitHub Page `source` 分支;
2. Travis-CI 在 GitHub Page `source` 分支更新后，自动构建生成站点文件；
3. Travis-CI 将站点文件推送到 GtiHub Page `master` 分支，同时推送到 VPS；


也就是说，整个部署过程只需要将写好源码文件 Push 到 GitHub 相应分支，后面的操作全部交给 Travis-CI 处理。

## 具体实现

Travis-CI 和 GitHub 的关联就不说了，傻瓜化图形操作，记得打开“Build only if .travis.yml is present”选项。

```yml
language: node_js

sudo: false

cache:
  apt: true
  directories:
    - node_modules

node_js:
  - '6'
  - '7'

branches:
  only:
    - source

before_install:
- openssl aes-256-cbc -K $encrypted_xxxxxxxxxxxx_key -iv $encrypted_xxxxxxxxxxxx_iv -in .travis/id_rsa.enc -out ~/.ssh/id_rsa -d
- chmod 600 ~/.ssh/id_rsa
- eval $(ssh-agent)
- ssh-add ~/.ssh/id_rsa
- cp .travis/ssh_config ~/.ssh/config
- git config --global user.name 'sudoz'
- git config --global user.email me@isudox.com

install:
- npm install hexo-cli -g
- npm install
script:
- rm db.json && hexo clean && hexo g -d
```