---
title: "MySQL Binlog 解析组件 open-replicator 原理介绍"
date: 2020-02-28T13:41:33+08:00
draft: true
---

[open-replicator](https://github.com/whitesock/open-replicator) 是一款高性能的 MySQL binlog 解析组件，通过 open-replicator 可以对 binlog 进行实时的解析、过滤、广播。业界常用的数据同步中间件 databus 就是基于 open-replicator 抓取 MySQL 的 binlog。

在探索 open-replicator 原理前，先思考一个问题，如果是自己来开发这个组件该怎么做。

open-replicator 的做法是参照 MySQL 主从复制的方式，像 slave 一样连接到 MySQL 实例，拉取 binlog 并解析，再通过回调进行处理。

MySQL 主从复制的过程：

- master 将数据变更写入 binlog；
- slave 将 master 的 binlog event 复制到 relay log；
- slave 重放 relay log 中的事件，把数据变更写入到 DB；

类似的，open-replicator 的执行过程是：
- 包装成 slave 连接到目标 MySQL，并发送 dump 请求；
- master 收到 dump 请求，发送 binlog 到 open-replicator；
- open-replicator 解析 binlog；

![](https://i.imgur.com/mtwr0cb.png)

