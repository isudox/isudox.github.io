---
title: LeetCode 探险第一弹
date: 2015-11-23 20:50:27
tags: [Algorithm,LeetCode]
categories: [Coding]
---

上学时零零碎碎上 [LeetCode](https://leetcode.com/) 观光过，现在工作了忙成狗了反倒想被 LeetCode 好好虐一遍……这篇小记 15 年就写了标题，现在还回来填坑。
LeetCode 探险记会按题目的顺序写，为避免篇幅太长，每篇记录 3 - 5 道题。大致会按照“翻译 - 思考 - 解法”的套路来记录。能力有限，算法可能很糟糕，尽力而为。

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
// TwoSum.java
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
# two_sum.py
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

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 16 / 16 | 62 ms | Java |
| Accepted | 16 / 16 | 44 ms | Python |

**************************************

### Add Two Numbers

第二题 [Add Two Numbers](https://leetcode.com/problems/add-two-numbers/)

> 给定两个链表(linked list)，以倒序表示正整数。将两数求和并返回该和的链表形式。
> **Input:** (2 -> 4 -> 3) + (5 -> 6 -> 4)
> **Output:** 7 -> 0 -> 8

这道题有点拗口，简单解释下题意：用链表表示非负整数，整数的每一位用倒序存储在链表的节点中，例如 342 用链表形式存储则为 2 -> 4 -> 3，给出两个链表表示的正整数，求两数加和的链表形式。

这道题有坑！刚开始解题时并没有把各种可能的情况考虑到，提交两次都被驳回。下面我把我的解法从最开始被拒绝的草稿到最后被接受的过程完整写下来。先抛开诡异的情况，只考虑最主干的思路，把算法的骨架码出来。
涉及到链表，其实下意识的就能联想到链式反应，这在算法里对应的就是递归。我的思路是尝试把链表递归还原成整数，然后再把求和的整数转化成链表。

```java
/**
 * Definition for singly-linked list.
 * public class ListNode {
 *     int val;
 *     ListNode next;
 *     ListNode(int x) { val = x; }
 * }
 */
public class Solution {
    public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
        int sum = listNode2Num(l1) + listNode2Num;

        return num2ListNode(sum);
    }

    public int listNode2Num(ListNode listNode) {
        if (listNode == null) {
            return 0;
        }

        return listNode.val + listNode2Num(listNode.next) * 10;
    }

    public ListNode num2ListNode(int num) {
        ListNode listNode = new ListNode(0);
        if (num == 0) {
            return null;
        }

        listNode.val = num % 10;
        listNode.next = num2ListNode(num / 10);

        return listNode;
    }
}
```

肉眼 debug 了下似乎没有问题，leetcode 的测试用例也通过了，提交代码被 OJ 否决了，问题出在哪了呢？看下面的用例

```
# input
[0], [0]
```

找到出错的点了，在把数值转换为链表的方法 num2ListNode() 里发生了错误，因为传参是 0 直接返回了 null。那么就打补丁吧，在调用 num2ListNode() 前对参数进行判断，修改代码如下：

```java
// AddTwoNumbers.java v1.1
public class Solution {
    public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
        int sum = listNode2Num(l1) + listNode2Num;
        if (sum == 0) {
            return new ListNode(0);
        }

        return num2ListNode(sum);
    }

    public int listNode2Num(ListNode listNode) {
        if (listNode == null) {
            return 0;
        }

        return listNode.val + listNode2Num(listNode.next) * 10;
    }

    public ListNode num2ListNode(int num) {
        ListNode listNode = new ListNode(0);
        if (num == 0) {
            return null;
        }

        listNode.val = num % 10;
        listNode.next = num2ListNode(num / 10);

        return listNode;
    }
}
```

上面的补丁解决了当数值为 0 时的异常情况，再次提交，然后……再次悲剧地被 OJ 婉拒了。OJ 给出了如下的报错测试用例

```
[1], [9,9,9,9,9,9,9,9,9,9,9,9,9]
```

看到这个用例其实就知道代码疏漏点在什么地方，就是没有考虑到对大数的处理。当链表表示的大整数数值超过 int 型的范围时，在链表转换整数的过程中就已经发生错误了。好在 Java 处理大整数比 C/C++ 方便了很多，不需要先转换成 String 类，Java 的 Math 包里内置了 [BigInteger](https://docs.oracle.com/javase/8/docs/api/java/math/BigInteger.html) 类，只要内存够大，就可以表示任意大整数。

```java
// AddTwoNumbers.java v1.2
import java.math.BigInteger;
public class Solution {
    public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
        BigInteger sum = listNode2Num(l1).add(listNode2Num(l2));
        if (BigInteger.ZERO.compareTo(sum) == 0) {
            return new ListNode(0);
        }

        return num2ListNode(sum);
    }

    public BigInteger listNode2Num(ListNode listNode) {
        if (listNode == null) {
            return BigInteger.valueOf(0);
        }

        return BigInteger.valueOf(listNode.val).add(listNode2Num(listNode.next)
                                                    .multiply(BigInteger.valueOf(10)));
    }

    public ListNode num2ListNode(BigInteger num) {
        ListNode listNode = new ListNode(0);
        if (BigInteger.ZERO.compareTo(num) == 0) {
            return null;
        }

        listNode.val = num.mod(BigInteger.valueOf(10)).intValue();
        listNode.next = num2ListNode(num.divide(BigInteger.valueOf(10)));

        return listNode;
    }
}
```

BigInteger 类的方法需要参考 JDK 文档，这里不赘述了。代码提交，OJ 通过，一个赛艇！

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 1556 / 1556 | 24 ms | Java |

解法的时间复杂度堪忧啊，暂时还没想到优化的解法，后续待完善。

**************************************

### Longest Substring Without Repeating Characters

第三题 [Longest Substring Without Repeating Characters](https://leetcode.com/problems/longest-substring-without-repeating-characters/)

> 给出一个字符串，求其最长的无重复字符的子字符串的长度。
> e.g.
> "abcabcbb" => "abc" => 3;
> "bbbbb" => "b" => 1;
> "pwwkew" => "wke" => 3;

这道题的题意很明确，也没有什么隐藏的坑，思路理清就能写出来。

- 首先一定是遍历字符串；
- 从第一个字符开始遍历，在遍历过程中，记录当前字符出现的次数，如果字符是第一次出现，则把当前记录的子串长度加一；如果字符已经出现过，说明该字串已经出现重复字符，则终止遍历，并从上一次遍历的起始位置的下一字符，重新上述步骤；

解法如下：

```java
// LongestSubstringWithoutRepeatingCharacters.java
public class Solution {
    public int lengthOfLongestSubstring(String s) {
        int maxLen = 0;
        int sLen = s.length();
        if (sLen == 0) {
            return 0;
        }
        
        for (int i = 0; i < sLen; i++) {
            int curLen = 0;
            Map<String, Integer> map = new HashMap<>();
            for (int j = i; j < sLen; j++) {
                String key = String.valueOf(s.charAt(j));
                if (map.get(key) == null) {
                    map.put(key, 1);
                    curLen += 1;
                    maxLen = curLen > maxLen ? curLen : maxLen;
                } else {
                    break;
                }
            }
        }
        return maxLen;
    }
}
```

OJ 测试结果：

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 982 / 982 | 138 ms | Java |

**************************************

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

**************************************

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
        int maxLen = 0;
        String palindrome = "";

        for (int i = 0; i < len - 1; i++) {
            // odd
            String oddStr = check(s, i, i, len);
            int oddLen = oddStr.length();
            if (oddLen > maxLen) {
                maxLen = oddLen;
                palindrome = oddStr;
            }
            // even
            String evenStr = check(s, i, i + 1, len);
            int evenLen = evenStr.length();
            if (evenLen > maxLen) {
                maxLen = evenLen;
                palindrome = evenStr;
            }
        }

        return palindrome;
    }

    private String check(String s, int start, int end, int len) {
        while (start >= 0  &&  end <= len - 1 && s.charAt(start) == s.charAt(end)) {
            start--;
            end++;
        }
        return s.substring(start + 1, end);
    }
}
```

OJ 测试结果：

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 88 / 88 | 35 ms | Java |

下一篇：[LeetCode 探险第二弹](/2016/05/17/leetcode-tour-2/)
