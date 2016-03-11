---
title: Git一般实践
date: 2016-03-10 18:01:32
tags: Git
categories: Coding
---

之前一个人玩开发时，用Git做版本管理很舒心愉快，因为从来不会有冲突，Git操作来操作去就是`git pull`、`git commit`、`git push`的三件套。严格意义上讲，绝大多数时候我只是把Git当成了个人代码存储而不是协作开发的版本管理工具。Git还有很多强大的功能并没有在个人小型开发中使用到，而在JD的工作中，实际上遇到了不少在使用Git协作开发时的问题。正好组长让我总结其间的问题和最佳实践，就把这些实践经验记录在本文中。另，Git本来就是一个命令工具集，所以我就以类Unix系统下的命令行操作为基准，各个平台下的Git GUI工具花样百出，操作也不统一，就一并略过了。

> 其实很多问题都是在你并不了解规律的情况下产生的，不仅仅是写代码用Git

### 常用操作

#### 创建Git仓库
创建Git仓库有几种不同的情况：

创建空的Git仓库，很简单，一条命令
```bash
git init repo-name
```
该目录就是一个Git本地仓库了，目录下会有一个隐藏文件夹`.git/`，看看它的目录结构
```bash
tree .git
.git
├── branches
├── COMMIT_EDITMSG
├── config
├── description
├── FETCH_HEAD
├── HEAD
├── hooks
├── index
├── info
│   └── exclude
├── logs
│   ├── HEAD
│   └── refs
│       ├── heads
│       │   ├── master
│       │   └── source
│       └── remotes
│           └── origin
│               ├── HEAD
│               ├── master
│               └── source
├── objects
│   ├── 18
│   │   └── f66c7ed1e9d6dadb9aa71836fdf58d5217fd26
│   ├── info
│   └── pack
│       ├── pack-137f36f2b48c9ee4fb17518f99ec9b9f842fcd81.idx
│       ├── pack-137f36f2b48c9ee4fb17518f99ec9b9f842fcd81.pack
├── packed-refs
├── refs
│   ├── heads
│   │   ├── master
│   │   └── source
│   ├── remotes
│   │   └── origin
│   │       ├── HEAD
│   │       ├── master
│   │       └── source
│   └── tags
└── smartgit.config
```
上面是我这个静态博客Git仓库下`.git/`目录结构。其中几个主要子目录和文件的基本作用如下——
* `COMMIT_EDITMSG`: 该文件存放最新的commit message；
* `config`: 该文件保存Git的配置；
* `description`: Git仓库的描述信息；
* `index`: Git本地暂存区，是二进制文件；
* `HEAD`: 该文件为Git仓库当前分支的引用；
* `hooks`: 该目录存放Git脚本钩子，用以触发Git自动执行某些操作，例如本人博客的Git钩子就自定义了文件更新后自动部署的操作；
* `info`: 存放Git仓库信息；
* `logs`: 存放Git log的信息；
* `objects`: 存放所有Git Object，每次提交Git都会生成一个Git Object，其SHA1值的前2位是文件夹名称，后38位是Object名；
* `refs`: 包含heads、remotes、tags三个子目录，分别存储当前head指针指向的commit，服务器端远程仓库的header指针及分支、Git tags标签；

创建空的Git仓库是最常用的操作，还有比较常用操作的是把已有的工程加入Git
```bash
cd existing-dir
git init
git add .
git commit -m 'first commit'
```

还有一种情况并不多见，就是创建裸仓库，有别于`git init`
```bash
git init --bare
```
Git仓库其实就是Git仓库下的`.git`目录，存储上面提到的那些子目录和文件，记录该Git仓库的所有记录。Git裸仓库一般用在远程服务器上的仓库初始化。

#### 添加到远程仓库
在本地创建Git仓库后，还需要推到远程仓库上，比如大名鼎鼎的GitHub，或者私有的Git服务器如GitLab。首先在服务器上新建远程仓库，取到Git远程仓库地址，然后就可以把本地仓库推到远程。
```bash
git remote add <origin remote repo URL>
git push origin master
```

#### 提交改动
当对Git仓库文件进行增删改操作后，需要把有必要提交的改动commit到本地，再push到远程仓库。想查看本地仓库有哪些改动可以执行`git status`命令。确认后执行`git add <filename or .>`把文件改动提交到Git仓库的__暂存区__，此时再通过`git status`就能看到提示信息与之前的变化。但暂存区顾名思义只是暂存改动，并未提交到本地仓库，因此还需要`git commit -m 'blabla'`将改动提交到本地仓库。这样就把改动提交上去了，至于是否需要再提交到远程仓库，视需要而定，`git push origin <branch-name>`就是提交到上面绑定的远程仓库。

#### 回滚/撤销
