---
title: "Paxos Made Simple 翻译"
date: 2021-06-03T14:28:07+08:00
tags: [分布式系统, 共识算法]
---

**摘要**：用大白话来解释 Paxos 算法是非常简单的。

<!-- more -->

# 1 引入｜Introduction

由于一开始对分布式系统容错的 Paxos 算法的描述，对许多读者而言都过于极客，因此被认为是非常晦涩难懂<sup>[5]</sup>。实际上，它是最简单、直观的分布式算法。其本质是一种共识算法——论文<sup>[5]</sup>中的 *synod* 算法。在下一节中会展示该共识算法几乎严格地实现了我们所要求的特性。在最后一节，会阐释完整的 Paxos 算法，通过将共识直接应用在状态机上，来构建分布式系统。这种方法应该是广为人知的，因为它大概算是分布式系统理论中被引用最多的论文主旨。

# 2 共识算法｜The Consensus Algorithm

## 2.1 问题｜The Problem

假设有一组能发起提案的进程。共识算法要保证在多个提案中只有一个被选中。如果没有提案，则不会选择提案。如果一个提案被选中，则所有进程都应该知晓该选中的决议。该共识算法的可靠性，有以下要求：

- 只有被发起的提案，才有机会被选中通过；
- 所有提案中，只能有一个被选中通过；
- 只有在提案确定通过后，进程才能获知该结果；

我们不会尝试详细说明精确的成立条件。但算法的目标是要保证已提出的提案最终会被选中通过，且当某个提案被选中后，进程最终都会获悉该结果。

在共识算法中，我们让三类代理人分别扮演各自角色：*Proposers*、*Acceptors* 和 *Learners*。在具体实现中，一个进程可能会担任多个角色，但我们不用关心代理人和进程的映射关系。

假设这些代理人可以通过发送消息进行交流。我们使用常见的非「拜占庭」异步模型：

- 代理人的处理速度随机，可能会停机导致失败，可能会重启。因为所有代理人都可能会在某个提案被选中后发生故障然后重启，所以某些信息必须要被出现故障和重启的代理人记录下来；
- 通信的消息长度任意，可以重复，可以丢失，但消息内容不会被篡改；

## 2.2 选中提案｜Choosing a Value

最简单的选中提案的方式就是，只有一个 Acceptor：Proposer 向 Acceptor 发起提议，Acceptor 选择最先收到的提议。虽然实现简单，但这个方式会在 Acceptor 故障时无法继续运转。

所以需要尝试其他方式来选择提案。我们使用多个 Acceptor，Proposer 向一组 Acceptor 发送提案，Acceptor 可能会采纳该提案。只有当足够多的 Acceptor 都采纳，该提案才能通过。那么什么才叫「足够多」？为了确保只有一个提案被通过，我们使「足够多」的 Acceptor 是由大多数 Acceptor 组成。因为任意两个包含大多数 Acceptor 的子集，必然存在包含至少一个 Acceptor 的交集，当 Acceptor 最多只能采纳一个提案时，该方式是可行的。（在很多论文中都对「大多数」做了概括，很显然是发轫于论文<sup>3</sup>）

在不考虑故障和消息丢失的情况下，我们期望即使只有一个 Proposer 发起一个提案，系统也能通过提案。这需要满足以下条件：

1. **P1**. An acceptor must accept the ﬁrst proposal that it receives.

2. P2. If a proposal with value v is chosen, then every higher-numbered proposal that is chosen has value v.

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

