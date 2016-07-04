---
title: LeetCode 探险第四弹
date: 2016-07-04 15:06:59
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---

本篇记录 LeetCode 算法部分第 16-20 题。

<!-- more -->

### 3Sum Closest

第 16 题 [3Sum Closest](https://leetcode.com/problems/3sum-closest/)

> 给定一个包含 n 个整型数的数组 S，找出 S 中的三个数，使得三者求和的结果和目标值最接近。返回求和结果，假定 S 中一定存在唯一解。
> 举例：数组 S = { -1 2 1 -4 }，目标值 target = 1。最接近目标值的求和结果为 (-1 + 2 + 1 = 2)

这题是第 15 题的延伸。沿用前一题的思路，先对数组进行排序，取 a(i) + a(i+k) + a(n) 求和，如果结果和目标值一致，则直接将求和结果返回；如果结果大于目标值，则表明需要减小下标 n 的值，逐次减小，每次比较当前求和结果与目标值的差值和前一次求和比较的差值，取绝对值较小的保留，同时保留当前的求和结果；如果结果小于目标值，则需要增大下标 (i+k)。Java 代码如下

```java
// ThreeSumClosest.java v1.0
public class Solution {
    public int threeSumClosest(int[] nums, int target) {
        int sum = Integer.MAX_VALUE;
        int diff = Integer.MAX_VALUE;
        int count = nums.length;
        Arrays.sort(nums);
        for (int i = 0; i < count - 2; i++) {
            int j = i + 1, k = count - 1;
            while (j < k) {
                int curSum = nums[i] + nums[j] + nums[k];
                int curDiff = curSum - target;
                if (curDiff == 0) return curSum;
                diff = Math.abs(diff) < Math.abs(curDiff) ? diff : curDiff;
                sum = target + diff;
                if (curDiff > 0) {
                    k--;
                    while (j < k && nums[k] == nums[k + 1]) k--;
                } else {
                    j++;
                    while (j < k && nums[j] == nums[j - 1]) j++;
                }
            }
        }
        return sum;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 120 / 120 | 13 ms | Java |

```java
// ThreeSumClosest.java v1.1
public class Solution {
    public int threeSumClosest(int[] nums, int target) {
        int sum = Integer.MAX_VALUE;
        int diff = Integer.MAX_VALUE;
        int count = nums.length;
        Arrays.sort(nums);
        for (int i = 0; i < count - 2;) {
            int j = i + 1, k = count - 1;
            while (j < k) {
                int curSum = nums[i] + nums[j] + nums[k];
                int curDiff = Math.abs(curSum - target);
                if (curDiff == 0) return curSum;
                if (curDiff < diff) {
                    diff = curDiff;
                    sum = curSum;
                }
                if (curSum > target) {
                    k--;
                    while (j < k && nums[k] == nums[k + 1]) k--;
                } else {
                    j++;
                    while (j < k && nums[j] == nums[j - 1]) j++;
                }
            }
            i++;
            while (i < count - 2 && nums[i] == nums[i - 1]) i++;
        }
        return sum;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 120 / 120 | 11 ms | Java |

Python 代码

```python
# 3sum_closest.py
class Solution(object):
    def threeSumClosest(self, nums, target):
        """
        :type nums: List[int]
        :type target: int
        :rtype: int
        """
        res, diff = sys.maxsize, sys.maxsize
        count = len(nums)
        nums.sort()
        for i in range(count - 2):
            if i > 0 and i < count -2 and nums[i] == nums[i - 1]:
                continue
            j, k = i + 1, count - 1
            while j < k:
                cur_sum = nums[i] + nums[j] + nums[k]
                cur_diff = cur_sum - target
                if cur_diff == 0:
                    return cur_sum
                diff = diff if abs(diff) < abs(cur_diff) else cur_diff
                res = target + diff
                if cur_diff > 0:
                    k -= 1
                    while j < k and nums[k] == nums[k + 1]:
                        k -= 1
                else:
                    j += 1
                    while j < k and nums[j] == nums[j - 1]:
                        j += 1
        return res
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 120 / 120 | 148 ms | Python |

**************************************

### Letter Combinations of a Phone Number

第 17 题 [Letter Combinations of a Phone Number](https://leetcode.com/problems/letter-combinations-of-a-phone-number/)

> 给定一个数字型的字符串，返回这些数字在手机九宫格键盘上所有可能表示的字母组合。
> 举例，输入字符串 "23"，输出结果：[ "ad", "ae", "af", "bd", "be", "bf", "cd", "ce", "cf" ]
> ![](https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/Telephone-keypad2.svg/200px-Telephone-keypad2.svg.png)

```java
// LetterCombinationsOfaPhoneNumber.java
public class Solution {
    public List<String> letterCombinations(String digits) {
        
    }
}
```

**************************************
