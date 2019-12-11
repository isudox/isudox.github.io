---
title: LeetCode-39 Combination Sum
date: 2019-03-29 21:54:41
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---

> [39. Combination Sum](<https://leetcode.com/problems/combination-sum/>)
>
> Medium

<!-- more -->

## Problem

Given a **set** of candidate numbers (`candidates`) **(without duplicates)** and a target number (`target`), find all unique combinations in `candidates` where the candidate numbers sums to `target`.

The **same** repeated number may be chosen from `candidates` unlimited number of times.

**Note:**

- All numbers (including `target`) will be positive integers.
- The solution set must not contain duplicate combinations.

**Example 1:**

```
Input: candidates = [2,3,6,7], target = 7,
A solution set is:
[
  [7],
  [2,2,3]
]
```

**Example 2:**

```
Input: candidates = [2,3,5], target = 8,
A solution set is:
[
  [2,2,2,2],
  [2,3,3],
  [3,5]
]
```

## Solution

Obviously, what we have to do to solve this prolem is traversal. Then let's think how to reduce the comlexity of traversal.

Let's say we've already find out some numbers stored in a `list`, if the next number `x` in candidate numbers is less than `target - sum(list)`, then we can append this number in `list` ans continue to find next number `y`;

If `x` equals to `target - sum(list)` then we find out one combination , and if the candidate numbers is in ascending order, there is no need to check the next number `y`, we just stop here and move back to last position, put the next number after `x` and check the sum.

Thus, we need to sort these candidate numbers firstly. Let's assume the argument `candidates` is `[a, b]`, and `a < b`, imagine a tree as followed:

```
             0
         /       \
        a         b
     /     \   /     \
    a       b a       b
```

- if `a + a < target`, then try to test `a + b`;
- if `a + a = target`, then pop the newest appended number and return to the last node of first `a`, pop the last number and try the sibling number `b`;

Here we make it clear that this is a recursive algorithm, which we should record current list which contains the numbers we get from the ordered candidates and the index of the number we start to test.

Show you the code:

```python
class Solution:
    def combination_sum(self, candidates: List[int], target: int) \
            -> List[List[int]]:
        ans = []
        # important, we need it sorted
        candidates.sort()

        def backtrack(nums: List[int], targ: int, start: int, store: List[int]):
            for i in range(start, len(nums)):
                # test the number from `start` position
                num = nums[i]
                if targ < num:
                    # current number is gt current target, break
                    break

                # then we can append current number confidently
                store.append(num)
                if targ == num:
                    # if equals, we find it, pop the number
                    nonlocal ans
                    # deep-copy, important detail
                    ans.append(store[:])
                    store.pop()
                    break
                # keep testing next number from current position
                backtrack(nums, targ - num, i, store)
                # pop current number and test sibling number
                store.pop()

        backtrack(candidates, target, 0, [])

        return ans
```

```java
public class CombinationSum {

    public List<List<Integer>> combinationSum(int[] candidates, int target) {
        Arrays.sort(candidates);
        List<List<Integer>> ans = new ArrayList<>();
        backtrack(candidates, target, 0, new ArrayList<>(), ans);

        return ans;
    }

    private void backtrack(int[] candidates,
                           int target,
                           int start,
                           List<Integer> list,
                           List<List<Integer>> ans) {
        for (int i = start; i < candidates.length; i++) {
            int num = candidates[i];
            if (target < num) {
                break;
            }
            list.add(num);
            if (target == num) {
                ans.add(new ArrayList<>(list));
                list.remove(list.size() - 1);
                break;
            }
            backtrack(candidates, target - num, i, list, ans);
            list.remove(list.size() - 1);
        }
    }
}
```

## Complexity Analysis

Time complexity of this approach is `O(N*logN)`;

Space complexity is `O(N)`;

----

[GitHub Link](https://github.com/isudox/leetcode-solution/blob/master/docs/39.combination-sum.md)

```
Forgive my poor English, I just wanna improve my writing skill.
So if I make some stupid mistakes in writing, forget about them.
Let's focus on the code :)
```
