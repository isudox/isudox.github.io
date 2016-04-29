---
title: LeetCode 第一周
date: 2015-11-23 20:50:27
tags: LeetCode
categories: Coding
---

上学时零零碎碎上 [LeetCode](https://leetcode.com/) 观光过，现在工作了忙成狗了反倒想被 LeetCode 好好虐一遍……这篇小记 15 年就写了标题，现在还回来填坑。
按 LeetCode 题目的顺序从头开始刷，每篇 7 道题。大致会按照“翻译-思考-解法”的套路来记录，尽力而为。

<!-- more -->

### Two Sum

第一题 [Two Sum](https://leetcode.com/problems/two-sum/) 算是简单题，题意大致为：
> 给一个整型数组，请返回数组中加和的结果为目标值的两个元素的索引位置。假定整形数组有且仅有两个元素符合该条件。
> 伪代码：
> nums = [2, 7, 11, 15], target = 9
 nums[0] + nums[1] = 2 + 7 = 9
 return [0, 1]


这道题的给定条件相当完整，因此需要考虑的变态因素很少，非常常规且线性的问题，就是考察数组处理。直接给出我的解答
```java
// twoSum.java
public class Solution {
    public int[] twoSum(int[] nums, int target) {
        int len = nums.length;
        int[] res = new int[2];

        if (len < 2) {
            return res;
        }

        for (int i = 0; i < len; i++) {
            for (int j = i + 1; j < len; j++) {
                if (nums[i] + nums[j] == target) {
                    res[0] = i + 1;
                    res[1] = j + 1;
                    break;
                }
            }
        }

        return res;
    }
}
```

```python
# twoSum.py
class Solution(object):
    def twoSum(self, nums, target):
        d = {}
        for i in range(len(nums)):
            x = nums[i]
            if target - x in d:
                return d[target - x], i
            d[x] = i
```
OJ 结果：

| Status | Run Time | Language |
|:--------:|:--------:|:--------:|
| Accepted |  62 ms | java |
| Accepted |  44 ms | python |

### Add Two Numbers

第二题 [Add Two Numbers](https://leetcode.com/problems/add-two-numbers/)

> 给定两个链表(linked list)，以倒序表示正整数。将两数求和并返回该和的链表形式。
> **Input:** (2 -> 4 -> 3) + (5 -> 6 -> 4)
> **Output:** 7 -> 0 -> 8
