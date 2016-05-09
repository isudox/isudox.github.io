---
title: 搭建 Hexo 站点
date: 2015-09-03 00:19:38
tags: [Hexo,VPS,Git]
categories: [Coding]
---
进入9月了，开学季正拉开序幕，又是一个新的开始。对于刚结束学生生涯的我而言，这个开学季有长长的todo list，排在队首的就是在这里码字开垦。

Blog仿佛已是古董，在一众微博微信席卷的现下，多少有点像长势萎靡无人问津的路边草。那为什么还要做Blog？为什么不选用现成的空间、Blog提供商？为什么还是静态Blog，还要搭在VPS上？

需要有这么多为什么吗？因为好玩，这就够了。具体好玩的元素有很多，在下面的记录中会有所提及，更多的还需要自己去发现。

<!-- more -->

### Why

* 选择自己搭建独立 Blog 的理由很简单，既然是自己的东西，就不需要放在别人口袋里；
* 选择静态 Blog 是因为无需数据库，支持 Markdown，文本文件便于 Git 管理；

静态 Blog 程序尽管小众，也还是有不少选择的，按语言不同门派各异，也是一江湖。比如 Ruby 系 [Jekyll](http://jekyllrb.com)，Node.js 系 [Hexo](http://hexo.io)，Python 系 [Pelican](http://blog.getpelican.com)。

什么？竟然没有世界上最好的语言！好吧，[WordPress](http://wordpress.org) 正在冲你露大白牙……

Jekyll、Hexo 和 Pelican各有拥趸，各执一词。我不辩优劣，选 Hexo 只是因为对 JS 相对更了解一些罢了。如果对语言有信仰，那就闭上眼睛遵从信仰吧。

### How

Google 一下关键字H exo + Blog，或者直接查看 Hexo 官方[文档](http://hexo.io/docs)，都可以对 Hexo 的搭建过程有较为清晰的认知。我设想的方案是搭建一个由 GitHub 托管，并且能在 VPS 上实时部署发布的 Blog 程序，因此整体骨架就是 Hexo + GitHub + VPS。

### Let's Hexo

#### GitHub

网上已有的 Hexo 方案基本都是将 Hexo 生成的静态文件提交至 GitHub Pages，通过 GitHub Pages 实现 Blog 的撰写及更新。但有一不足，如果换一台电脑写，难道还要将 Hexo 源文件拷贝出来？对此我的建议很简单：在 GitHub 上的以 <username>.github.io仓库里建立两个分支：一是 master 分支，保存 Hexo 生成的静态文件；另一是 source 分支，保存 Hexo 的源文件。

#### VPS

我在 VPS 上测试过两种方案，其一为在 VPS 上也搭建 Hexo 环境，同时创建一个 Git 裸仓库作为私有 Git 服务器，本地提交 Hexo 的源文件，然后 VPS 生成 Hexo 静态文件并部署发布 Web 目录下；其二是创建的 Git 裸仓库提交 Hexo 生成文件，VPS 直接将其部署到 Web 目录下。前者徒增 VPS 的压力，后者使得 Git log 冗余，各有长短。两种方案我都测试通过，目前选用的方案二。
GitHub 提供 GitHub Pages 服务，原意是用来给开发者发布器在 GitHub 上项目的文档及说明，当然也可以作为开发者的个人站点使用。如果是创建`<username>.github.io` 仓库，GitHub 会将其 master 分支下的内容作为站点文件发布；如果是创建其他自定义名称的仓库，GitHub 将以 gh-page 分支作为站点文件。

创建新用户 git，在服务器上创建 git server 请参考 git [官方文档](https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server)
```bash
$ sudo adduser git
$ git init --bare <your_repo>.git
$ touch <your_repo>.git/hook/post-receive
$ chmod +x post-receive
$ cd <path_to_your_blog>
$ git clone <your_repo>.git
```

其中`post-receive`为 Git Hook，Git 通过该脚本实现本地提交改动后自动发布更新
```bash
#!/bin/bash -l

GIT_REPO=/home/git/isudox-hexo.git
GIT_TEMP=/home/git/repo/isudox-hexo
WWW_HEXO=/home/git/www/isudox-hexo

rm -rf ${GIT_TEMP}
git clone $GIT_REPO $GIT_TEMP
rm -rf ${WWW_HEXO}/*
cp -rf ${GIT_TEMP}/* ${WWW_HEXO}
```

原理很简单，VPS 上的 Git 仓库一旦接收到 `push`，便会触发 `post-receive` 脚本，进入 Blog 根目录，执行更新发布任务。

如果是方案一，`post-receive` 也是类似的操作，只是多了一步 `hexo generate` 生成静态文件的操作，因为提交到 Git 仓库的是 Hexo 源文件而不是生成文件。

#### Local

本地环境需要 Node.js 和 git，系统可以是 Win、Linux、Mac 任一，Node.js与Git 和这些操作系统都能友好相处。我的本地环境是Ubuntu 14.04，因此配置起来可谓轻松愉快——

安装Node.js、git
```bash
$ sudo apt-get install git nodejs
```

安装Hexo
```bash
$ sudo npm install -g hexo-cli
```

创建本地Git仓库并提交至远端master分支
```bash
echo # isudox.github.io >> README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin git@github.com:isudox/isudox.github.io.git
git push -u origin master
```

新建 Hexo 源文件分支 `source`
```bash
git branch source
git checkout source
```

在本地 Gitc 仓库下创建 Hexo
```bash
$ hexo init
$ npm install
$ npm install hexo-deployer-git --save
```

执行完上述命令后，属于你的 Hexo Blog 就已经诞生了，接下来可以修改配置文件 `_config.yml`，可以在 `themes/` 路径下添加主题，可以撰写新文章……总之，你拥有了 Hexo 的全部魔力。

因为本地的Hexo项目的提交涉及三处：
1. Github 仓库的 source 分支；
2. Github 仓库的 master 分支；
3. VPS 上的私有 Git 仓库 master 分支；

因此需要更改 `_config` 文件中 `deploy` 字段的属性
```
deploy:
    type: git
    repo:
        github: git@github.com:<username>/<username>.github.io.git,master
        vpsgit: git@vps_ip:<your_repo>.git,master
```

注意 `.yml` 的 `:` 后面必须跟一个空格，这是格式规定，否则配置无效。

提交 GitHub source 分支时，确人当前分支为 source，然后执行 `git push origin source`；
提交 GitHub master 分支和 VPS 私有 Git 库时，执行 `hexo deploy` 发布即可；

好了，回到本地的 Hexo 项目根目录下，再敲最后一行命令，让我们看看会发生什么
```bash
$ hexo generate --deploy
```

打开 `http://<username>.github.io` 或者你自己绑定的域名……

Duang    ^______^
