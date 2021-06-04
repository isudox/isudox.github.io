---
title: "Paxos Made Simple 中译"
date: 2021-06-03T14:28:07+08:00
tags: [分布式系统, 共识算法]
---

**摘要**：用大白话来解释 Paxos 算法是非常简单的。

<!-- more -->

# 1 引入｜Introduction

由于一开始对分布式系统容错的 Paxos 算法的描述，对许多读者而言都过于极客，因此被认为是非常晦涩难懂<sup>[5]</sup>。实际上，它是最简单、直观的分布式算法。其本质是一种共识算法——论文<sup>[5]</sup>中的 *synod* 算法。在下一节中会展示该共识算法几乎严格地实现了我们所要求的特性。在最后一节，会阐释完整的 Paxos 算法，通过将共识直接应用在状态机上，来构建分布式系统。这种方法应该是广为人知的，因为它大概算是分布式系统理论中被引用最多的论文主旨。

# 2 共识算法｜The Consensus Algorithm

## 2.1 问题｜The Problem

Assume a collection of processes that can propose values. A consensus algorithm ensures that a single one among the proposed values is chosen. If no value is proposed, then no value should be chosen. If a value has been chosen, then processes should be able to learn the chosen value. The safety requirements for consensus are:

假设有一组能发起提案的进程。共识算法要保证在多个提案中只有一个被选中。如果没有提案，则不会选择提案。如果一个提案被选中，则所有进程都应该知晓该选中的决议。该共识算法的可靠性，有以下要求：

- 只有被发起的提案，才有机会被选中通过；
- 所有提案中，只能有一个被选中通过；
- 只有在提案确定通过后，进程才能获知该结果；

我们不会尝试详细说明精确的成立条件。但算法的目标是要保证已提出的提案最终会被选中通过，且当某个提案被选中后，进程最终都会获悉该结果。

在共识算法中，我们让三类代理人分别扮演各自角色：*Proposers*、*Acceptors* 和 *Learners*。在具体实现中，一个进程可能会担任多个角色，但我们不用关心代理人和进程的映射关系。

假设这些代理人可以通过发送消息进行交流。我们使用常见的非「拜占庭」异步模型：

- 代理人的处理速度随机，可能会停机导致失败，可能会重启。因为所有代理人都可能会在某个提案被选中后发生故障然后重启，所以某些信息必须要被出现故障和重启的代理人记录下来；
- 通信的消息长度任意，可以重复，可以丢失，但
- Messages can take arbitrarily long to be delivered, can be duplicated, and can be lost, but they are not corrupted.

假设这些代理之间可以通过互相发送消息来通信。我们使用的非“拜占庭”异步模型是这样的3：
每个代理都会以任意速度执行，可能会因为停止而导致出错，可能会重启。由于所有代理都可能在某个值被选定后出错然后重启，因此有些信息需要被这些出错或重启的进程记录下来；
消息长度不限，可以在进程间传递或复制，也有可能丢失，但是消息内容不会被修改。


## 2.2 选择 value

## 2.3 获知已选 value

## 2.4 推进

## 2.5 实现

# 3 实现一个状态机

-------

# 参考文档

- [1] Michael J. Fischer, Nancy Lynch, and Michael S. Paterson. Impossibility of distributed consensus with one faulty process. Journal of the ACM, 32(2):374–382, April 1985.

- [2] Idit Keidar and Sergio Rajsbaum. On the cost of fault-tolerant consensus when there are no faults—a tutorial. TechnicalReport MIT-LCS-TR-821, Laboratory for Computer Science, Massachusetts Institute Technology, Cambridge, MA, 02139, May 2001. also published in SIGACT News 32(2) (June 2001).

- [3] Leslie Lamport. The implementation of reliable distributed multiprocess systems. Computer Networks, 2:95–114, 1978.

- [4] Leslie Lamport. Time, clocks, and the ordering of events in a distributed system. Communications of the ACM, 21(7):558–565, July 1978.

- [5] Leslie Lamport. The part-time parliament. ACM Transactions on Computer Systems, 16(2):133–169, May 1998.

