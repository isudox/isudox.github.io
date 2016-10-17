---
title: LeetCode 探险第六弹
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
date: 2016-10-17 17:09:15
---


三个月没上 LeetCode了，最近工作不顺，好想被虐个明白，接着写第 6 篇 LeetCode 26 至 30 题。
<!-- more -->

### Remove Duplicates from Sorted Array

第 26 题 [Remove Duplicates from Sorted Array](https://leetcode.com/problems/remove-duplicates-from-sorted-array/)

> 给定一个有序数组，去掉其中重复的元素，并返回新数组的长度。
> 不要为其他数组分配额外的空间，必须在给定的内存中完成。

如果传入的数组是 `[1, 1, 2]`，得到的结果应该是 2。题意很简单，但是有两个注意点，一个是该数组是有序的，即从小到大排列，另一个是不允许分配新数组的存储空间，这就意味着不用创建新的数组来保存数据，也不能通过 Set 来过滤重复元素。

因为第二点的限，只能在给定的数组上进行数值比较的同时，计算非重复元素的数量；因为第一点的设定，所以可以做到对数组只遍历一次。

```java

```
