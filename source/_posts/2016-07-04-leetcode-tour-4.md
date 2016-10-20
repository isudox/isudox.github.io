---
title: LeetCode 16-20
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

抽象的看这道题，其实就是排列组合。键盘上 "23" 按钮可能的输出结果就是 "abc" 和 "def" 两个字符串中字符的所有组合情况。从每个数字所代表的字符串中选取一个，并和下一个数字所代表的字符串中字符组合，逐个拼接，很显然，可以通过递归处理，递归深度为数字键的个数。

```java
// LetterCombinationsOfaPhoneNumber.java
public class Solution {
    private static String[] keymap = {"abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"};

    public List<String> letterCombinations(String digits) {
        List<String> res = new ArrayList<>();
        if (digits == null || digits.length() == 0) return res;
        this.combineLetters(digits, "", digits.length(), 0, res);
        return res;
    }

    private void combineLetters(String digits, String str, int len, int pos, List<String> list) {
        String key = keymap[digits.charAt(pos) - '2'];
        for (int i = 0; i < key.length(); i++) {
            if (pos == len - 1) list.add(str + key.charAt(i));
            else combineLetters(digits, str + key.charAt(i), len, pos + 1, list);
        }
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 25 / 25 | 1 ms | Java |

**************************************

### 4Sum

第 18 题 [4Sum](https://leetcode.com/problems/4sum/)

> 给定 n 个整型数组成的数组 S，从中找出所有可能的 4 个整数 a, b, c, d 使得 a + b + c + d = 目标值 target。要求去重。
> 如 S = [ 1, 0, -1, 0, -2, 2 ] target = 0，则结果为 [ [-1,  0, 0, 1], [-2, -1, 1, 2], [-2,  0, 0, 2] ]

LeetCode 第 15 题 [3Sum](/2016/06/15/leetcode-tour-3/#3Sum) 已经给出了数组中取 3 个数求和为零，本题为 4 个数求和为目标值。可以直接借用 3Sum 的算法，先选取数组中一个数，把剩下的数组元素和所需要的差值传递给 3Sum 方法，如果 3Sum 返回了有效结果，则把当前选取的数分别插入 3Sum 的结果中。代码如下：

```java
// FourSum.java v1.0
public class Solution {
    public List<List<Integer>> fourSum(int[] nums, int target) {
        List<List<Integer>> res = new ArrayList<>();
        if (nums == null || nums.length < 4) return res;
        Arrays.sort(nums);
        int count = nums.length;
        for (int i = 0; i < count - 3; i++) {
            while (i > 0 && i < count - 3 && nums[i] == nums[i - 1]) i++;
            int diff = target - nums[i];
            List<List<Integer>> lists = this.threeSum(Arrays.copyOfRange(nums, i + 1, count), diff);
            if (lists.isEmpty()) continue;
            for (List<Integer> list : lists) {
                list.add(nums[i]);
                res.add(list);
            }
        }
        return res;
    }
    // 3Sum
    private List<List<Integer>> threeSum(int[] nums, int target) {
        List<List<Integer>> lists = new ArrayList<>();
        if (nums == null || nums.length < 3) return lists;
        int count = nums.length, i = 0;
        while (i < count - 2) {
            int j = i + 1;
            int k = count - 1;
            while (j < k) {
                int sum = nums[i] + nums[j] + nums[k];
                if (sum == target) {
                    List<Integer> list = new ArrayList<>();
                    list.add(nums[i]);
                    list.add(nums[j++]);
                    list.add(nums[k--]);
                    lists.add(list);
                    while (j < k && nums[j] == nums[j - 1]) j++;
                    while (j < k && nums[k] == nums[k + 1]) k--;
                } else if (sum < target) {
                    j++;
                    while (j < k && nums[j] == nums[j - 1]) j++;
                } else {
                    k--;
                    while (j < k && nums[k] == nums[k + 1]) k--;
                }
            }
            i++;
            while (i < count - 2 && nums[i] == nums[i - 1]) i++;
        }
        return lists;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 282 / 282 | 71 ms | Java |

### Remove Nth Node From End of List

第 19 题 [Remove Nth Node From End of List](https://leetcode.com/problems/remove-nth-node-from-end-of-list/)

> 给定一个链表，移除倒数第 n 个节点，返回该链表的首节点。
> 例如链表  **1 -> 2 -> 3 -> 4 -> 5**，**n = 2**，移除倒数第 2 节点后的链表为 **1 -> 2 -> 3 -> 5**
> 假定 n 是有效的。

普通链表是单向，假如是正向的移除第 n 个节点，很好做，但是反向的移除就需要动下脑筋。最直接的办法就是先遍历链表求其长度，减去 n 就是正向的节点位置，然后再做依次顺序遍历，找到要移除的节点。这种方法需要两次遍历。还有一种略微机智的方法，只需要做一次遍历，先让早起步的头指针移动 n 次，再让另一个慢起步的头指针开始移动，这样等早起步头指针到达最后一个节点的时候，后一个指针正好到达要移除的节点。

```java
// RemoveNthNodeFromEndOfList.java
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *     int val;
 *     ListNode next;
 *     ListNode(int x) { val = x; }
 * }
 */
public class Solution {
    public ListNode removeNthFromEnd(ListNode head, int n) {
        ListNode res = new ListNode(0);
        res.next = head;
        ListNode node1 = res, node2 = res;
        for (int i = 0; i < n; i++) node1 = node1.next;
        while (node1.next != null) {
            node1 = node1.next;
            node2 = node2.next;
        }
        node2.next = node2.next.next;
        return res.next;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 207 / 207 | 1 ms | Java |

### Valid Parentheses

第 20 题 [Valid Parentheses](https://leetcode.com/problems/valid-parentheses/)

> 给出一个仅包含字符 `'('`, `')'`, `'{'`, `'}'`, `'['` 和 `']'` 的字符串，判断它是否有效。
> 有效的字符串必须是闭合的，如 `"()"` `{[()]}` 和 `"()[]{}"` 是有效的，而 `"(]"` 和 `"([)]"` 是无效的。

从有效字符串的形式 `"()"` `{[()]}` 和 `"()[]{}"` 中可以看出，这很像是四则运算的中缀表达式。而四则运算的中缀表达式可以通过栈这种数据结构来存储。因为左半括号必定再其对应右半括号的前面，所以遍历到当前字符为左半括号时，将其入栈。遍历到右半括号时，将栈顶字符出栈，比较是否匹配。直到栈元素为空。

```java
// ValidParentheses.java
public class Solution {
    public boolean isValid(String s) {
        char[] stack = new char[s.length()];
        int index = 0;
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) == '(' || s.charAt(i) == '[' || s.charAt(i) == '{') {
                stack[index++] = s.charAt(i);
            } else if (s.charAt(i) == ')') {
                if (index == 0 || stack[--index] != '(') return false;
            } else if (s.charAt(i) == ']') {
                if (index == 0 || stack[--index] != '[') return false;
            } else {
                if (index == 0 || stack[--index] != '{') return false;
            }
        }
        return index == 0;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 65 / 65 | 0 ms | Java |

下一篇：[LeetCode 探险第五弹](/2016/07/08/leetcode-tour-5/)