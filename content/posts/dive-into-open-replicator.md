---
title: "MySQL Binlog 解析组件 open-replicator 原理介绍"
date: 2020-02-28T13:41:33+08:00
tags:
  - Database
---

[open-replicator](https://github.com/whitesock/open-replicator) 是一款高性能的 MySQL binlog 解析组件，通过 open-replicator 可以对 binlog 进行实时的解析、过滤、广播。业界常用的数据同步中间件 databus 就是基于 open-replicator 抓取 MySQL 的 binlog。

在探索 open-replicator 原理前，可以先思考一个问题，如果是自己来开发这个组件该怎么做。
open-replicator 的做法是参照 MySQL 主从复制的方式，像 slave 一样连接到 MySQL 实例，拉取 binlog 并解析，再通过回调进行处理。

MySQL 主从复制的过程：

- master 将数据变更写入 binlog；
- slave 将 master 的 binlog event 复制到 relay log；
- slave 重放 relay log 中的事件，把数据变更写入到 DB；

类似的，open-replicator 的执行过程是：
- 包装成 slave 连接到目标 MySQL，并发送 dump 请求；
- master 收到 dump 请求，返回 binlog 到 open-replicator；
- open-replicator 解析 binlog；

# 源码梳理

![类图](/images/open-replicator_class.svg)

参考上面的类图，open-replicator 的入口就是 `OpenReplicator` 类，其主要的成员属性有：

- `serverId`: 即 MySQL 配置中的 `server-id`，全局唯一；
- `transport`: 和目标 MySQL 建立的 socket 通信；
- `binlogParser`: binlog 的解析器，根据 eventType 适配对应的 parser；
- `binlogEventListener`: 委托 binlog 事件的监听处理；

初始化 `OpenReplicator` 的示例代码：

```java
final OpenReplicator or = new OpenReplicator();
or.setUser("nextop");
or.setPassword("nextop");
or.setHost("192.168.1.216");
or.setPort(3306);
or.setServerId(6789);
or.setBinlogPosition(120);
or.setBinlogFileName("mysql-bin.000003");
or.setBinlogEventListener(new BinlogEventListener() {
    public void onEvents(BinlogEventV4 event) {
        LOGGER.info("{}", event);
    }
});
or.start();
```

接下来了解下 `start()` 方法里都做了些哪些工作。

## 建立 socket 连接

首先是初始化 `Transport` 建立 socket 连接：

```java
if (this.transport == null)
    this.transport = getDefaultTransport();
this.transport.connect(this.host, this.port);
```

其中 `getDefaultTransport()` 方法设置成员参数，`connect()` 完成 socket 通信的建立——

```java
this.socket = this.socketFactory.create(host, port);
this.os = new TransportOutputStreamImpl(this.socket.getOutputStream());
if(this.level2BufferSize <= 0) {
    this.is = new TransportInputStreamImpl(this.socket.getInputStream(), this.level1BufferSize);
} else {
    this.is = new TransportInputStreamImpl(new ActiveBufferedInputStream(this.socket.getInputStream(), this.level2BufferSize), this.level1BufferSize);
}
```

这里注意有一层逻辑判断，是否开启二级缓存，后面会提到其中的区别。

## 发送 binlog 请求

连接建立后，open-replicator 开始向目标 MySQL 发送 binlog 请求。参考 `dumpBinlog()` 方法：

```java
protected void dumpBinlog() throws Exception {
    final ComBinlogDumpPacket command = new ComBinlogDumpPacket();
    command.setBinlogFlag(0);
    command.setServerId(this.serverId);
    command.setBinlogPosition(this.binlogPosition);
    command.setBinlogFileName(StringColumn.valueOf(this.binlogFileName.getBytes(this.encoding)));
    this.transport.getOutputStream().writePacket(command);
    this.transport.getOutputStream().flush();
    
    final Packet packet = this.transport.getInputStream().readPacket();
    if(packet.getPacketBody()[0] == ErrorPacket.PACKET_MARKER) {
        final ErrorPacket error = ErrorPacket.valueOf(packet);
        throw new TransportException(error);
    } 
}
```

## binlog 解析

MySQL 接收到 binlog 请求后，会返回 binlog 信息，open-replicator 进行 binlog 解析。解析动作由 open-replicator 注册的 parser 执行，默认注册的 parser 如下——

```java
protected ReplicationBasedBinlogParser getDefaultBinlogParser() throws Exception {
    final ReplicationBasedBinlogParser r = new ReplicationBasedBinlogParser();
    r.registerEventParser(new StopEventParser());
    r.registerEventParser(new RotateEventParser());
    r.registerEventParser(new IntvarEventParser());
    r.registerEventParser(new XidEventParser());
    r.registerEventParser(new RandEventParser());
    r.registerEventParser(new QueryEventParser());
    r.registerEventParser(new UserVarEventParser());
    r.registerEventParser(new IncidentEventParser());
    r.registerEventParser(new TableMapEventParser());
    r.registerEventParser(new WriteRowsEventParser());
    r.registerEventParser(new UpdateRowsEventParser());
    r.registerEventParser(new DeleteRowsEventParser());
    r.registerEventParser(new WriteRowsEventV2Parser());
    r.registerEventParser(new UpdateRowsEventV2Parser());
    r.registerEventParser(new DeleteRowsEventV2Parser());
    r.registerEventParser(new FormatDescriptionEventParser());
    r.registerEventParser(new GtidEventParser());
    
    r.setTransport(this.transport);
    r.setBinlogFileName(this.binlogFileName);
    return r;
}
```

因此 parser 是可插拔的，开发者可自定义配置。`binlogParser` 内部创建了一个线程，由该线程解析 binlog，这部分逻辑比较长，拆开讲。

### 解析 binlog event header

binlog event header payload 格式如下：

```
length         field
4              timestamp: 注，此时间戳为秒
1              event type
4              server-id
4              event-size: size of the event (header, post-header, body)
   if binlog-version > 1:
4              log position: position of the next event
2              flags: binlog 标识，参考[官方文档](https://dev.mysql.com/doc/internals/en/binlog-event-flag.html)
```

按上述 payload 格式，从 socket 中读取字节流并解析对应的属性值，完成 header 的解析。

参考 [Binlog Event header](https://dev.mysql.com/doc/internals/en/binlog-event-header.html)。

### 解析 binlog event body

从 binlog header 中获取到 `event type` 后，从之前注册的 `BinlogEventParser` 列表中找出匹配的解析器，实际的解析过程委托给解析器接口的对应实现。
以 `WriteRowsEventV2Parser` 实现为例，其中 `WRITE_ROWS_EVENTv2` 的 payload 格式参考 [write-rows-eventv2](https://dev.mysql.com/doc/internals/en/rows-event.html#write-rows-eventv2)。

```java
public void parse(XInputStream is, BinlogEventV4Header header, BinlogParserContext context) throws IOException {
    final long tableId = is.readLong(6);
    final TableMapEvent tme = context.getTableMapEvent(tableId);
    if (this.rowEventFilter != null && !this.rowEventFilter.accepts(header, context, tme)) {
        is.skip(is.available());
        return;
    }
    
    final WriteRowsEventV2 event = new WriteRowsEventV2(header);
    event.setTableId(tableId);
    event.setReserved(is.readInt(2));
    event.setExtraInfoLength(is.readInt(2));
    if (event.getExtraInfoLength() > 2) 
        event.setExtraInfo(is.readBytes(event.getExtraInfoLength() - 2));
    event.setColumnCount(is.readUnsignedLong()); 
    event.setUsedColumns(is.readBit(event.getColumnCount().intValue()));
    event.setRows(parseRows(is, tme, event));

    context.getEventListener().onEvents(event);
}
```

按 payload 格式读取字节流并获取相应属性，再调用 `BinlogEventListener#onEvents()` 回调进行对应的处理。

举个例子，我们自定义的回调处理逻辑可以是如下

```java
public void onEvents(BinlogEventV4 event) {
    try {
        blockingQueue.offer(event, timeout, TimeUnit.MILLISECONDS);
    } catch (InterruptedException e) {
        log.error("Failed to put binlog event to queue, event: " + event, e);
    }
}
```

即把 binlog event 放进内存队列中，再从队列中拉取做相应处理。

open-replicator 的核心逻辑如上过程，整体就是建立连接 -> 获取 binlog -> 解析 binlog -> 回调处理。整理下流程图——

![流程图](/images/open-replicator_sequence.svg)

# 细节分析

## 二级缓存设置

在前面讲建立 socket 通信时，会根据 open-replicator 初始化参数 `level2BufferSize`，决定是否开启二级缓存。相关代码如下：

```java
protected TransportInputStream is;

public void connect(String host, int port) throws Exception {
    // skip some code.
    if(this.level2BufferSize <= 0) {
        this.is = new TransportInputStreamImpl(this.socket.getInputStream(), this.level1BufferSize);
    } else {
        this.is = new TransportInputStreamImpl(new ActiveBufferedInputStream(this.socket.getInputStream(), this.level2BufferSize), this.level1BufferSize);
    }
}
```

区别在于开启二级缓存后，是从封装的 `ActiveBufferedInputStream` 中获取流。`ActiveBufferedInputStream` 初始化是创建了一个线程去不断从 `socket` 的输入流里读取字节流，并存储在 `RingBuffer` 中，这个数据结构的容量即二级缓存的大小，所以 open-replicator 里所谓的「二级缓存」即内存中的 `RingBuffer`。

```java
new Thread(new Runnable() {
    public void run() {
        final byte[] buffer = new byte[512 * 1024];
        while(!this.closed.get()) {
            int r = this.is.read(buffer, 0, buffer.length);
            if(r < 0) throw new EOFException();
            
            int offset = 0;
            while(r > 0) {
                final int w = write(buffer, offset, r);
                r -= w;
                offset += w;
            }
        }
    }
})
```

`ActiveBufferedInputStream` 通过内部的 `RingBuffer` 缓存实现了「生产-消费」模型，生产者向 `RingBuffer` 写入数据，消费者独处数据。

### RingBuffer 数据结构

作者自己实现了 `RingBuffer` 的数据结构，本质上是一个有界的 FIFO 数组，由 head、tail 两个指针标识数据的开始和结束，通过这两个指针的归零实现了逻辑上的环状结构。`size` 是数组当前存储数据的长度，`capcity` 是最大容量。
它的读写过程是：

- 有数据写入时，插入到 `tail` 索引的位置，`tail` 后移所写入数据的长度，`size` 相应增加，当 `tail` 超过 `capcity` 时，`tail` = 0。当 `size` = `capacity` 时表示队列写满；
- 有数据读取时，从 `head` 开始读取，`head` 后移读取数据的长度，`size` 相应减少，当 `head` 超过 `capcity` 时，`head` = 0，当 `size` = 0 时表示队列为空；
着重说下写操作。假设 header 指针标识写的位置，tail 指针标识读的位置，那么存在下面两个情况：

1. head 指针在 tail 指针前面，即 head < tail，形如下图：
![case1](https://i.imgur.com/oy4nkIK.png)
那么 min(capcity - size, byte_steam.length) 为当前可写入字节流长度，即写入空白区域即可，写入完成后，移动 head 指针。

2. head 指针在 tail 后面，即 head > tail，形如下图：
![case2](https://i.imgur.com/xTBOY1z.png)
可以写入的字节流长度为 min(capcity - head, min(capcity - size, byte_steam.length))，如果写入到末尾后还有可写入的字节，则写入到数组头部。数据更新后再移动 head 指针。

总而言之，RingBuffer 需要保证，一定是读到已经写入的数据，写入不会覆盖未读取的数据，这是关键。

## 生产使用存在的问题

可以看到上面的 `RingBuffer` 只有在一个线程读，一个线程写的情况下才是线程安全的，如果生产-消费模型是有多个消费者，需要空间换时间，分别维护。

另外，open-replicator 从组件功能的定位上已经实现的核心能力，基于 binlog 订阅转发和自定义处理的系统需要考虑更多生产环境面临的高可用问题，比如订阅的目标数据库宕掉的情况，这需要接入 open-replicator 的应用完成高可用方面的适配。