---
title: LeetCode-136 Single Number
date: 2019-03-26 20:20:20
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---
> [136. Single Number](https://leetcode.com/problems/single-number/solution/)
>
> Easy

<!-- more -->

Given a non-empty array of integers, every element appears twice except for one. Find that single one.

**Note:**

> Your algorithm should have a linear runtime complexity. Could you implement it without using extra memory?

Example 1:

```
Input: [2,2,1]
Output: 1
```

Example 2:

```
Input: [4,1,2,1,2]
Output: 4
```

## Solution

Actually it's quite simple to solve, but we should make clear that it requires `O(N)` complexity and no extra memory usage. So we need to find out the single one during several iterations.
As is well-known,

```
a XOR a = 0
0 XOR a = a
```

So all the duplicate numbers will be calculated to `0` after looping xor, and the result of the iteration of xor must be the single number value.
Here is the sample code:

```python
class Solution:
    def single_number(self, nums: List[int]) -> int:
        # xor each sibling num
        return reduce(lambda a, b: a ^ b, nums)
```

```java
public class SingleNumber {

    public int singleNumber(int[] nums) {
        for (int i = 1; i < nums.length; i++) {
            nums[0] ^= nums[i];
        }
        return nums[0];
    }
}
```

## Complexity Analysis

Time complexity of this approach is `O(N)`;
Space complexity is `O(1)`;

******

[GitHub Link](https://github.com/isudox/leetcode-solution/blob/master/docs/136.single-number.md)

```
Forgive my poor English, I just wanna improve my writing skill.
So if I make some stupid mistakes in writing, forget about them.
Let's focus on the code :)
```