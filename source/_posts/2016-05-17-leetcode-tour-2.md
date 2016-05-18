---
title: LeetCode 探险第二弹
date: 2016-05-17 21:14:04
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---

接着之前的[第一弹](/2015/11/23/leetcode-1st-week/)，第二弹从第四题开始。

<!-- more -->

### Median of Two Sorted Arrays

第四题 [Median of Two Sorted Arrays](https://leetcode.com/problems/median-of-two-sorted-arrays/)

> 长度分别为 m, n 的有序数组 nums1 和 nums2，找出这两个数组的中位数。要求时间复杂度为 O(log(m+n))

这题是 Hard 难度，但题目本身并不复杂，主要是对时间复杂度有要求，因此需要细细思考下。

要找两个有序数组的中位数，最直接的想法就是将两个数组合并排序，中位数自然而然就找到了。

```java
// MedianOfTwoSortedArrays.java
public class Solution {
    public double findMedianSortedArrays(int[] nums1, int[] nums2) {
        int m = nums1.length;
        int n = nums2.length;
        int mid = (m + n) / 2;
        int curr = 0;
        for (int i = 0, j = 0; i < (m < n ? m : n) && j < (m < n ? m : n);;) {
            if (num1[i] < num2[i]) {
                i++;
                curr++;
                if (curr == mid) {
                    return num1[i];
                }
            } else {
                j++;
                curr++;
            }
        }
    }
}
```

### Longest Palindromic Substring

第五题 [Longest Palindromic Substring](https://leetcode.com/problems/longest-palindromic-substring/)

> 给出一个字符串 S，从 S 中找出其最长的回文子串。可以假定 S 的最大长度为 1000，并且存在唯一的最长回文子串。

回文字符串就是正序和反序相同，也就是说回文以中心点对称，如 "abcba"。所以可以考虑从中心点向两侧扩展枚举，如果两侧相等，则记录下当前回文长度，并即时更新最大回文长度；否则，则移动中心点，重复枚举操作。这个思路有一个需要注意的地方，就是回文长度的奇偶，这两种枚举的处理有所不同。

```java
// LongestPalindromicSubstring.java
public class Solution {
    public String longestPalindrome(String s) {
        int len = s.length();
        if (len <= 1) {
            return s;
        }
        
    }
}
```