---
title: "译 Paxos Made Simple"
date: 2021-06-03T14:28:07+08:00
tags: [分布式系统, 共识算法]
draft: true
---

**摘要**：Paxos 算法，用大白话来解释，是非常简单的。

<!-- more -->

# 1 引入｜Introduction

由于一开始对分布式系统容错的 Paxos 算法的描述，对许多读者而言都过于极客，因此被认为是非常晦涩难懂<sup>[5]</sup>。实际上，它是最简单、直观的分布式算法。其本质是一种共识算法——论文<sup>[5]</sup>中的 “synod” 算法。在下一节中会展示该共识算法几乎严格地实现了我们所要求的特性。在最后一节，会阐释完整的 Paxos 算法，通过将共识直接应用在状态机上，来构建分布式系统。这种方法应该是广为人知的，因为它大概算是分布式系统理论中被引用最多的论文主旨。

# 2 共识算法｜The Consensus Algorithm


## 2.1 问题｜The Problem

Assume a collection of processes that can propose values. A consensus algorithm ensures that a single one among the proposed values is chosen. If no value is proposed, then no value should be chosen. If a value has been chosen, then processes should be able to learn the chosen value. The safety requirements for consensus are:

假设有一组能发起提案的进程。共识算法要保证在多个提案中只有一个被选中。如果没有提案，则不会选择提案。如果一个提案被选中，则所有进程都应该知晓该选中的决议。该共识算法的可靠性，有以下要求：

- Only a value that has been proposed may be chosen,
- Only a single value is chosen, and
- A process never learns that a value has been chosen unless it actually has been.

## 2.2 选择 value

## 2.3 获知已选 value

## 2.4 推进

## 2.5 实现

# 3 实现一个状态机

-------

# 参考文档

[1] Michael J. Fischer, Nancy Lynch, and Michael S. Paterson. Impossibility of distributed consensus with one faulty process. Journal of the ACM, 32(2):374–382, April 1985.

[2] Idit Keidar and Sergio Rajsbaum. On the cost of fault-tolerant consensus when there are no faults—a tutorial. TechnicalReport MIT-LCS-TR-821, Laboratory for Computer Science, Massachusetts Institute Technology, Cambridge, MA, 02139, May 2001. also published in SIGACT News 32(2) (June 2001).

[3] Leslie Lamport. The implementation of reliable distributed multiprocess systems. Computer Networks, 2:95–114, 1978.

[4] Leslie Lamport. Time, clocks, and the ordering of events in a distributed system. Communications of the ACM, 21(7):558–565, July 1978.

[5] Leslie Lamport. The part-time parliament. ACM Transactions on Computer Systems, 16(2):133–169, May 1998.

