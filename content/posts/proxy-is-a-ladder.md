---
title: "动手搭建一个梯子"
date: 2019-12-13T10:14:44+08:00
draft: false
tags:
  - Networks
---

由于众所周知的原因，大陆的互联网在一定程度上受限的。这归功于北京某高校校长主导的防火墙项目，我们时不时会看到类似下面这种地图——

![Imgur](/images/SZyhwKa.png)

出现防火墙后，不断的有技术去突破这个封锁，双方都从彼此身上吸取教训，升级迭代，如果有兴趣去了解的话，其实是一段非常有趣的历史。但实事求是的说，校长还是放了一马，毕竟没有祭出杀手锏才使得技术手段有突破高墙的可能。

早期防火墙通过 DNS 劫持的方式，给客户端返回一个错误的 IP 来破坏客户端到目标域名的访问。在那个相对单纯的年代里，我们通常是用修改 hosts 的方式来固定访问正确的 IP。

后来防火墙使用了 IP 黑名单，阻止客户端到服务端的通讯，像 Google YouTube 就在这个名单里。所以这时候的技术思路就是通过不在该黑名单里的第三方服务器做代理中转，把我们所要访问的内容辗转搬运到客户端。这就是目前绝大多数梯子的实现原理。

下文会根据 shadowsocks 项目（以下简称 ss），来尝试说明如何造一把简单的梯子。

> 代理服务器的最终目的：不被检测出客户端的真实访问网站，且不被检测出代理服务器在提供代理服务。

首先基于上面的第一点，要让墙无法解析数据包里的内容，就是通过加密，比如 AES。而第二点，是决定一个代理服务器是否能藏匿起来，躲过墙的试探而不被封锁的关键。

限于能力和时间，在这篇文章里我只能对第一点做一些展开。要实现代理的整个数据流如下所示——

![Imgur](https://i.imgur.com/F2CD5p3.png)

类似 shadowsocks 这类的工具，会在本地客户端和远程代理服务器上分别部署自己的 client 和 server，用来加解密数据包。 就 ss 而言，它的核心就两个部分，分别是 ss-local 和 ss-server，对应上图的 local-proxy 和 remote-proxy。

本地客户端需要对请求进行加密，这是最基础的功能。ss-local 会在本地监听端口，本地发起的网络请求都会发送到这个端口进行加密处理，再转发到 ss-server 所在的代理服务器上。

远程服务端接收来自 ss-local 的请求，解密出原始请求信息，并转发到真实的目标服务器上，在接收到响应后会再次对响应做加密，转发给 ss-local，ss-local 再做一次解密，拿到真实的响应信息。

整个过程是非常标准清晰的对称加密的过程。

# Socks5 协议

> socks5 是 socks 协议的第 5 版。参考 [RPC 1928](https://tools.ietf.org/html/rfc1928)。

另一个核心是通信协议，ss 基于 socks5 协议，为什么选择 socks5 而不是 HTTPS，一个比较重要的原因是 socks5 同时支持 TCP 和 UDP，而 UDP 往往是 IM 和游戏数据通信所采用的协议。

根据 RFC 简单说明下 socks5 的协议——

1) client 向 server 发起握手请求，会先发送一个表明协议和方法的消息，格式如下：

```
+----+----------+----------+
|VER | NMETHODS | METHODS  |
+----+----------+----------+
| 1  |    1     | 1 to 255 |
+----+----------+----------+
```

- VER: 占 1 字节，表示 socks 协议版本，如果是 sock5 则该值为 X'05';

- NMETHODS: 占 1 字节，表示 METHODS 字段的长度；

- METHODS: 占 1 ～ 255 字节，表示客户端所支持的加密方法；

2) server 接收到 client 的连接请求后，会选择一个 method，返回给 client 一个 method-selection 消息，格式如下：

```
+----+--------+
|VER | METHOD |
+----+--------+
| 1  |   1    |
+----+--------+
```

同样的，VER 表示协议版本，METHOD 表示选定的方法，1 字节，各枚举值含义如下：

```
X'00' NO AUTHENTICATION REQUIRED
X'01' GSSAPI
X'02' USERNAME/PASSWORD
X'03' to X'7F' IANA ASSIGNED
X'80' to X'FE' RESERVED FOR PRIVATE METHODS
X'FF' NO ACCEPTABLE METHODS
```

在上面这个请求-响应过程，数据包可能类似下面的情况——

```
                    VER     NMETHODS    METHODS
client -> server:   X'05'   X'01'       X'00'
                    VER     METHOD
server -> client:   X'05'   X'00'
-----------------------------------------------
                    VER     NMETHODS    METHODS
client -> server:   X'05'   X'01'       X'00' X'02'
                    VER     METHOD
server -> client:   X'05'   X'00'
-----------------------------------------------
                    VER     NMETHODS    METHODS
client -> server:   X'05'   X'01'       X'02'
                    VER     METHOD
server -> client:   X'05'   X'FF'
```

3) 完成 method-dependent 的握手后，client 和 server 开始建立连接。client 再向 server 发起请求，格式如下：

```
+----+-----+-------+------+----------+----------+
|VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  | X'00' |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

各字段含义和枚举值为：

- VER protocol version: X'05'，协议版本号；

- CMD

    - CONNECT X'01'，建立 TCP 连接；

    - BIND X'02'，端口绑定；

    - UDP ASSOCIATE X'03'，建立 UDP 连接；

- RSV RESERVED，保留字 X'00'；

- ATYP address type of following address，地址类型

- IPv4 address: X'01'，IPv4；

- DOMAINNAME: X'03'，域名；

- IPv6 address: X'04'，IPv6；

- DST.ADDR desired destination address，目标地址（域名/IPv4/IPv6）；

- DST.PORT desired destination port in network octet order，目标端口；

上面关键的信息有 ATYP（目标地址类型）、DST.ADDR（目标地址）、DST.PORT（目标端口），通过这三个字段可以确定所要访问的目标。ss-server 在确定要访问的目标后，就会向目标发起请求。

4) server 收到上面的请求后，向 client 发送 reply 消息，reply 的结构如下：

```
+----+-----+-------+------+----------+----------+
|VER | REP |  RSV  | ATYP | BND.ADDR | BND.PORT |
+----+-----+-------+------+----------+----------+
| 1  |  1  | X'00' |  1   | Variable |    2     |
+----+-----+-------+------+----------+----------+
```

其中，

- REP 字段表示请求处理结果，X'00' 为成功；其他枚举值均为失败，比如 0X'01' 是 SOCKS server 失败，X'07' 是命令不支持；

- RSV 保留字必须是 X'00'；

这个阶段，client 和 server 之间的请求-响应可能是如下情形，以访问 127.0.0.1:8080 为例：

```
                    VER     CMD     RSV     ATYP    DST.ADDR                    DST.PORT
client -> server:   X'05'   X'01'   X'00'   X'01'   X'7F' X'00' X'00' X'01'     X'1F' X'90'
                    VER     REP     RSV     ATYP    BND.ADDR                    BND.PORT
server -> client:   X'05'   X'00'   X'00'   X'01'   X'00' X'00' X'00' X'00'     X'10' X'10'
```

# 加密

> 加密的目的是为了不让墙发现请求的具体信息，常用的有工业界广泛使用的 AES。

仅仅只是实现 socks5 做请求转发并不能突破墙的限制，因为它只完成了代理，还没有实现加密。类似 ss 这样具备梯子功能的代理，要完成下面的工作——

- 在本地有 ss-local（本地的 socks5 server）完成和 socks5 client 的通信，由 ss-local 对 client 的请求进行加密并转发；

- 在远端有 ss-server（服务器上的 socks5 server）接收来自 ss-local 的请求，按规则解密拿到原始请求信息，转发给真实目标后拿到响应，最后再进行加密返回给 ss-local；

所以 ss 的工作原理里，除了实现了 socks5 的通信外，最主要的工作就是对请求进行加密，从而躲过墙的检测，达到科学上网的目的。这里就需要用到上面提过的对称加密算法，比如 AES。

下面简单介绍下 AES 加密算法。

AES 是一种对称加密算法，它的加密过程涉及字节替代（SubBytes）、行移位（ShiftRows）、列混淆（MixColumns）和加轮密钥（AddRoundKey）。

- **字节替代**

字节替换是通过矩阵 S 把原字节转换为另一个字节。下图分别是矩阵 S 和逆矩阵 S<sup>-1</sup>：

![Imgur](https://i.imgur.com/5h2FroL.png)

16 x 16 的矩阵可以完成 8 比特的替换，其中高 4 位是行坐标，低 4 位是列坐标。比如输入 a=a7a6a5a4a3a2a1a0，输出值为 S[a7a6a5a4][a3a2a1a0]，S-1的变换也同理。

字节 00000000B 替换后的值为 (S[0][0])=63H，再通过 S-1 即可得到替换前的值 (S-1 [6][3])=00H。

- **行移位**

1) 正向列混淆

左乘一个混淆算子（N * N 常量矩阵），运算过程举例如下：

![Imgur](https://i.imgur.com/Neatfhd.png)

2) 逆向列混淆

![Imgur](https://i.imgur.com/AcXFyvd.png)

注意，正向列混淆和逆向列混淆的算子互逆，所以经过一次逆向列混淆后即可恢复原文。

![Imgur](https://i.imgur.com/NWzCnMy.png)

- **加轮密钥**

这个操作相对简单，其依据的原理是 X ⊕ X = 0，X ⊕ 0 = X。加密过程中，每轮的输入与轮子密钥异或一次；因此，解密时再异或上该轮的轮子密钥即可恢复。即：

```
encrypt: input ⊕ round_key = output, decrypt: output ⊕ round_key = input
（input ⊕ round_key ⊕ round_key = input ⊕ 0 = input）
```

# socks5 proxy 的简陋实现

这里没有用 AES 加密，二是最简单的码表映射。

按 socks 协议，本地的 socks server 的处理逻辑如下（远端的 socks server 类似，加解密顺序有区别）：

```python
def handle(self):
    # 初始化本地 socks server
    sock = self.connection
    sock.recv(262)
    # 返回给本地 socks 客户端 0x05 0x00，确定 socks 协议和连接方法
    sock.send("\x05\x00")
    # 再读 4 字节，分别是 VER CMD RSV ATYP 字段
    data = self.rfile.read(4)
    # 取 CMD 字段的值, X'01' 为建立 TCP 连接
    mode = ord(data[1])
    if mode != 1:
      logging.warn('cmd != 1, not tcp connection.')
      return
    # 取 ATYP 字段，确定地址类型
    atyp = ord(data[3])
    addr_to_send = data[3]
    if atyp == 1:
      # IPv4
      addr_ip = self.rfile.read(4)
      addr = socket.inet_ntoa(addr_ip)
      addr_to_send += addr_ip
      elif atyp == 3:
        # 域名
        addr_len = self.rfile.read(1)
        addr = self.rfile.read(ord(addr_len))
        addr_to_send += addr_len + addr
        else:
          logging.warn('atype not support')
          return
        addr_port = self.rfile.read(2)
        # 目标地址 = ATYP + 长度 + IP/域名 + 端口
        addr_to_send += addr_port
        port = struct.unpack('>H', addr_port)
        # 组装返回给 socks 客户端的 reply 消息
        reply = "\x05\x00\x00\x01"
        reply += socket.inet_aton('0.0.0.0') + struct.pack(">H", 2222)
        self.wfile.write(reply)

        remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        remote.connect((REMOTE_SERVER, REMOTE_PORT))
        self.send_encrypt(remote, addr_to_send)
        self.handle_tcp(sock, remote)
```

对数据包加解密的过程，简单的码表映射：

- `string.translate(encryped_table[, deleted_characters])` 对数据进行加密；

- `string.translate(decrypted_table[, deleted_characters])` 对数据进行解密；

参考下面的示例——

```python
encrypt_table = ''.join(utils.init_table(KEY))
decrypt_table = string.maketrans(encrypt_table, string.maketrans('', ''))

def handle_tcp(self, sock, remote):
    try:
        fds = [sock, remote]
        while True:
            # select 多路复用
            r_fd, w_fd, e_fd = select.select(fds, [], [])
            if sock in r_fd:
                # 当前 socket 可读
                data = sock.recv(4096)
                if len(data) <= 0:
                    break
                # 加密
                result = utils.send_data(remote, self.enc(data))
                if result < len(data):
                    raise Exception('failed to send all data')

            if remote in r_fd:
                # 远程 socket 刻度
                data = remote.recv(4096)
                if len(data) <= 0:
                    break
                # 对接收到的加密信息进行解密
                result = utils.send_data(sock, self.dec(data))
                if result < len(data):
                    raise Exception('failed to send all data')
    finally:
        sock.close()
        remote.close()

def enc(data):
    return data.translate(encrypt_tableo)

def dec(data):
    return data.translate(decrypt_table)
```
