---
title: Shadowsocks 项目学习笔记
date: 2018-09-17 15:33:54
tags:
---

本篇是对 shadowsocks 工程源码和相关网络协议的学习笔记。

<!-- more -->

# socks 5 协议

shadowsocks 是基于 socks 5 协议开发的加密代理工具。想要了解 shadowsocks 的工作原理，绕不开对 socks 5 协议的学习。socks 5 [RFC](https://www.ietf.org/rfc/rfc1928.txt) 文档篇幅不大，也不难，简单提炼下。

## socks 5 客户端

客户端在连接服务端时，会发送一个如下格式的数据包：

```
+----+----------+----------+
|VER | NMETHODS | METHODS  |
+----+----------+----------+
| 1  |    1     | 1 to 255 |
+----+----------+----------+
```

`VER` 字段表示 socks 协议版本号，所以 socks 5 固定是 `0x05`;
`METHODS` 字段表示要选用的方法，取值是 `0x00` ~ `0xff`；
`NMETHODS` 字段表示 `METHODS` 的长度，固定为 1 字节；


目前 socks 5 定义的 `METHODS` 有：

- X'00' NO AUTHENTICATION REQUIRED
- X'01' GSSAPI
- X'02' USERNAME/PASSWORD
- X'03' to X'7F' IANA ASSIGNED
- X'80' to X'FE' RESERVED FOR PRIVATE METHODS
- X'FF' NO ACCEPTABLE METHODS

服务端会在 `METHODS` 中选择方法，并发送方法消息到客户端：

```
+----+--------+
|VER | METHOD |
+----+--------+
| 1  |   1    |
+----+--------+
```

比如，已选择的方法是 `0xFF`，就意味着上述方法都不可接受，客户端必须要关闭连接。


当客户端发送的方法数据包被服务端接受后，就可以发送实际请求的数据包。socks 请求的格式如下：

```
+----+-----+-------+------+----------+----------+
|VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  | X'00' |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

- `VER`: 协议版本号，socks5 设置为 `0x05`；
- `CMD`: 
  - CONNECT 为 `0x01`；
  - BIND 为 `0x02`；
  - UDP ASSOCIATE 为 `0x03`；
- `RSV`: RESERVED 为 `0x00`；