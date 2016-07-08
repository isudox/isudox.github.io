---
title: LeetCode 探险第五弹
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
date: 2016-07-08 21:25:43
---

本篇记录 LeetCode 算法部分第 21 至 25 题。

<!-- more -->

### Merge Two Sorted Lists

第 21 题 [Merge Two Sorted Lists](https://leetcode.com/problems/merge-two-sorted-lists/)

> 将两个有序链表合并成一个新的有序链表。

题目不复杂，取两个指针分别往下遍历两个链表的每个节点，逐次指向节点的值，取其较小值，并移动该指针，另一指针不动。继续往下比较，知道其中有一个指针到达末端为止。
循环解法：
```java
// MergeTwoSortedLists.java v1.0
// Definition for singly-linked list.
// public class ListNode {
//     int val;
//     ListNode next;
//     ListNode(int x) { val = x; }
// }
public class Solution {
    public ListNode mergeTwoLists(ListNode l1, ListNode l2) {
        ListNode res = new ListNode(0);
        ListNode temp = res;
        while (l1 != null && l2 != null) {
            if (l1.val < l2.val) {
                temp.next = l1;
                l1 = l1.next;
            } else {
                temp.next = l2;
                l2 = l2.next;
            }
            temp = temp.next;
        }
        if (l1 == null) temp.next = l2;
        else temp.next = l1;
        return res.next;
    }
}
```
递归解法：
```java
// MergeTwoSortedLists.java v1.1
public class Solution {
    public ListNode mergeTwoLists(ListNode l1, ListNode l2) {
        ListNode res = new ListNode(0);
        pickListNode(l1, l2, res);
        return res.next;
    }

    private void pickListNode(ListNode l1, ListNode l2, ListNode res) {
        if (l1 == null || l2 == null) {
            res.next = l1 == null ? l2 : l1;
        } else if (l1.val < l2.val) {
            res.next = l1;
            l1 = l1.next;
            pickListNode(l1, l2, res.next);
        } else {
            res.next = l2;
            l2 = l2.next;
            pickListNode(l1, l2, res.next);
        }
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 208 / 208 | 1 ms | Java |

**************************************

### Generate Parentheses

第 22 题 [Generate Parentheses](https://leetcode.com/problems/generate-parentheses/)

> 给定 n 对括号，编写方法生成所有可能的有效组合形式。
> 例如，n = 3，所有的组合情况为：[ "((()))", "(()())", "(())()", "()(())", "()()()" ]

这题很容易想起之前做过的第 20 题 [Valid Parentheses](/2016/07/04/leetcode-tour-4/#Valid-Parentheses)，当时利用了栈的 FILO 特性去检验括号组合的有效性。一个很直接的想法就是枚举全部的组合，然后传给 Valid Parentheses 方法去做有效性检验。但是这种方法平方级的时间复杂度太高，因为要判断所有组合。
n + 1 对括号的组合，可以发现，其实就是将新增的一对括号和之前的 n 对括号的组合拼起来。因此这里就可以利用递归的思想。

```java
// GenerateParentheses.java

```

**************************************

### Merge Two Sorted Lists

第 23 题 [Merge Two Sorted Lists](https://leetcode.com/problems/merge-two-sorted-lists/)

> 

**************************************

### Swap Nodes in Pairs

第 24 题 [Swap Nodes in Pairs](https://leetcode.com/problems/swap-nodes-in-pairs/)

> 给定一个 Linked list，两两交换相邻节点，返回该链表。
> 例如，给定的链表为 `1 ->2 -> 3 -> 4`，返回结果为 `2 -> 1 -> 4 -> 3`。

首先需要新建一个 ListNode 保存给定 ListNode 的头指针,这样在交换相邻节点时,该指针位置能保持固定不动。此外还需要另一个 ListNode 作为移动的指针来交换相邻节点，因此还需要创建两个临时的 ListNode，一左一右作交换。

```java
// SwapNodesinPairs.java
public class Solution {
    public class ListNode {
        int val;
        ListNode next;
        ListNode(int x) { val = x; }
    }
    public ListNode swapPairs(ListNode head) {
        ListNode res = new ListNode(0);
        ListNode curNode = res;
        res.next = head;
        while (curNode.next != null && curNode.next.next != null) {
            ListNode l = curNode.next, r = curNode.next.next;
            curNode.next = r;
            l.next = r.next;
            r.next = l;
            curNode = l;
        }
        return res.next;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 55 / 55 | 0 ms | Java |

**************************************

### Merge Two Sorted Lists

第 25 题 [Merge Two Sorted Lists](https://leetcode.com/problems/merge-two-sorted-lists/)

> 
