---
title: LeetCode 31-35
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---

记录 LeetCode 31-35 题的思考。

<!-- more -->

### Next Permutation

第 31 题 [Next Permutation](https://leetcode.com/problems/next-permutation/)

> 实现下一个排列：把数字重新排列成字典排序中下一个更大的数字排列。
> 如果不存在这样一种排列，则重新排列成字典排序中最小的数字排列。
> 直接在原有存储空间上进行修改，不允许申请新的存储空间。
> 例如：
> `1,2,3` 的下一个排列为 `1,3,2`
> `3,2,1` 的下一个排列为 `1,2,3`
> `1,1,5` 的下一个排列为 `1,5,1`



```java
public class Solution {
    public void nextPermutation(int[] nums) {
        if (nums.length < 2) return;
        int i = nums.length - 2;
        while (i >= 0 && nums[i] >= nums[i + 1]) i--;
        if (i >= 0) {
            int j = nums.length - 1;
            while (nums[j] <= nums[i]) j--;
            swap(nums, i, j);
        }
        reverse(nums, i + 1, nums.length - 1);
    }

    private void swap(int[] nums, int i, int j) {
        int temp = nums[i];
        nums[i] = nums[j];
        nums[j] = temp;
    }

    private void reverse(int[] nums, int i, int j) {
        while (i < j) swap(nums, i++, j--);
    }
}
```

**************************************
