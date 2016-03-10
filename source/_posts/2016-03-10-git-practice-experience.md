---
title: Git实践经验
date: 2016-03-10 18:01:32
tags: Git
categories: Coding
---

之前一个人玩开发时，用Git做版本管理很舒心愉快，因为从来不会有冲突，Git操作来操作去就是`git pull`、`git commit`、`git push`的三件套。严格意义上讲，绝大多数时候我只是把Git当成了个人代码存储而不是协作开发的版本管理工具。Git还有很多强大的功能并没有在个人小型开发中使用到，而在JD的工作中，实际上遇到了不少在使用Git协作开发时的问题。正好组长让我总结其间的问题和最佳实践，就把这些实践经验记录在本文中。另，Git本来就是一个命令工具集，所以我就以类Unix系统下的命令行操作为基准，各个平台下的Git GUI工具花样百出，操作也不统一，就一并略过了。

> 其实很多问题都是在你并不了解规律的情况下产生的，不仅仅是写代码用Git

### 常用操作

#### 创建Git仓库
创建Git仓库有几种不同的情况：创建空的Git仓库，很简单，一条命令
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
│   ├── 47
│   │   └── b83379345f67ea80036dff7c8f01df3973cb6f
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
上面是本静态博客Git仓库的`.git/`目录结构。其中
// TODO: 明天再写……
