---
title: "数据结构和算法在存储中的经典应用"
date: 2020-09-26T14:25:46+08:00
draft: true
tags:
  - Algorithm
  - Database
  - Data Structure
---

> Algorithms + Data Structures = Programs —— Niklaus Wirth

先搬出写了 Pascal、拿了图灵奖的大牛的名言，不讨论这个定义的合理性，只作为本文的引子。在数据库领域，当我们谈论其原理，绕不开存储中的数据结构。本文从几个经典应用出发，管窥数据结构在存储中的重要性。

<!-- more -->

# LSM Tree

## 引入

先抛出问题，假如要实现一个数据库系统，实现最简单的写入/读取数据的功能，该如何设计它的存储。我们已经知道，磁盘的顺序读写比随机读写更快<sup>[1]</sup>（参考下图），那么最佳的写入方案就是把数据行更新到文件末尾。为了避免 `O(N)` 的逐行查询，我们还需要建立索引，可以考虑 Hash，但是要付出 `O(N)` 的空间复杂度。如果数据写入时已经做好排序，树就可以派上用场。由于树的特点，在索引查询起到至关重要的作用，比如 `B-Tree`、`B+ Tree` 以及变体 `B* Tree`（后文均以 `B-Tree` 统称）。

![Comparing Random and Sequential Access in Disk and Memory](/images/jacobs3.jpg)
上图援引自 [ACM Queue](https://queue.acm.org/detail.cfm?id=1563874)

当数据库用户越来越多，并发写入量越来越大，`B-Tree` 需要处理大量的数据，不断变更树的结构，因此类似 MySQL InnoDB 采用的方法是通过 WAL(Write Ahead Log) 减少对 `B-Tree` 的写次数。执行过程参考下图——

![]()

由此可见，`B-Tree` 的瓶颈在于写。那对于这种高并发写的场景，有没有其它适用的数据结构可以优化写问题？`LSM Tree` 的出现优化了这个问题，这种树结构将随机读写优化为顺序读写，从而提升数据库并发写的吞吐能力。

## LSM Tree 基本原理

数据库保障事务正确可靠的 ACID，其中 A 和 C 通过 WAL(Write-ahead Logging) 机制来实现，即事务提交前预写日志，在 MySQL 中就是 redo 和 undo 日志。先写 WAL，再插入到内存中的 `MemTable`<sup>[2]</sup>，它同时提供数据的读写，并且 Key-Value 按 Key 排序，从而在 flush 到磁盘时能保持顺序性。

当 `MemTable` 写入到一定阈值后，系统会将其转变成 `Immutable Memtable`，再 flush 到磁盘，它只读，同时创建新的 `MemTable` 提供写。存储中设计这两种 `MemTable` 本质是空间换时间的朴素思想，目的是在 `MemTable` flush 到磁盘时不阻塞新数据的写入。

`SSTable`(Sorted String Table)<sup>[3]</sup> 是 `MemTable` flush 到磁盘的文件 ，其存储结构如下图示。当文件很大时，可以采用图中左边的 `key:offset` 索引快速定位到 KV 的偏移量。`SSTable` 只读，新的写入操作会存储到新的文件中。

![SSTable Storage](/images/sstable.png)
上图援引自 [SSTable and Log Structured Storage: LevelDB](https://www.igvita.com/2012/02/06/sstable-and-log-structured-storage-leveldb/)

所以数据流的整个过程可以简单理解为：`MemTable` -> `Immutable MemTable` -> `SSTable`

那么 `LSM Tree` 又是如何解决 `B-Tree` 在定时 flush WAL 时随机 I/O 导致的写瓶颈？

# Bw-Tree

# Skiplist

前面提到 `MemTable`，比较典型的实现是通过 `Skiplist`。

# Circular Buffer

在 MySQL 数据同步中，核心处理是订阅 binary log，转换并存储事件，等待消费，这是典型的发布-订阅模型。其中对事件的存储，直观的思路是采用队列。包括开源的 Databus、open-replicator，美团 DTS，都使用到了一种特殊的队列——Circular Buffer。

----

# 参考资料

- [The Pathologies of Big Data](https://queue.acm.org/detail.cfm?id=1563874)
- [LSM Tree 论文](https://www.cs.umb.edu/~poneil/lsmtree.pdf)
- [论 B+ 树索引的演进方向（上）](http://mysql.taobao.org/monthly/2018/11/01/)
- [MyRocks: LSM-Tree Database Storage Engine Serving Facebook's Social Graph](http://www.vldb.org/pvldb/vol13/p3217-matsunobu.pdf)
- [MemTable](https://github.com/facebook/rocksdb/wiki/MemTable)
- [Databus 2.0 Event Buffer Design](https://github.com/linkedin/databus/wiki/Databus-2.0-event-buffer-design)

# 注释

- [1] 对 HDD 而言，顺序读写时磁头几乎不用换道，或者换道的时间很短；而随机读写时磁头会频繁换道。
- [2] `MemTable` 更多细节参考 [RocksDB Wiki](https://github.com/facebook/rocksdb/wiki/MemTable)
- [3] `SSTable` 顾名思义是按 Key 排序、不可修改的字符串 KV 文件