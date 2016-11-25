---
title: 初学 gRPC 和 Protobuf
tags:
  - RPC
categories:
  - Coding
---

> gRPC: A high performance, open-source universal RPC framework

[gRPC](http://www.grpc.io/) 是 Google 开发的开源 RPC 框架，跨语言、高性能、内置 HTTP/2 和移动设备的支持。使用二进制序列化协议 [Protocol Buffers](https://developers.google.com/protocol-buffers/) 定义服务、接口、参数。谷歌出品必属精品，虽然没有项目实战，但值得花时间学习。

<!-- more -->

### Protocol Buffers

Protocol buffers 也是由 Google 开发（后文简称 protobuf），是跨语言跨平台，扩展性非常好的数据序列化协议，像 XML，但更小更快更简单，以上都是 Google 说的。通过 Protobuf 定义好结构化数据后，就能通过它的编译器生成读写这些结构化数据的源代码。

#### 搭建编译环境

Protobuf 的运行时环境和编辑器的安装很简单，从 GitHub 下载源码包，进入源码目录，shell 下依次执行以下命令，安装完后，默认在 `/usr/local/` 下生成编译器的可执行文件 protoc。

```shell
$ ./autogen.sh
$ ./configure
$ make
$ make check
$ sudo make install
$ sudo ldconfig # refresh shared library cache.
$ protoc --version
libprotoc 3.1.0
```

测试下 Google 提供的示例，将其编译成 Java 的源码：

```shell
protoc --java_out=. person.proto
```

在当前目录下就生成了对应的源码文件 `Person.java`，Protobuf 的环境就算安装成功了。

#### Proto 语法

Protobuf 把数据结构定义在 `.proto` 文件里， Protobuf 的语法很简单，接近 C 语言。参考 Google 文档里的示例：

```proto
syntax = "proto3";

message Person {
  required string name = 1;
  required int32 id = 2;
  optional string email = 3;
}
```

第一行设置选用的 Protobuf 版本，支持 proto2 和 proto3。

![](https://o70e8d1kb.qnssl.com/protobug-scalar-value-types.png)

### gRPC

