---
title: LeetCode 探险第二弹
date: 2016-05-17 21:14:04
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---

接着上篇 [LeetCode 探险第一弹](/2015/11/23/leetcode-1st-week/)，本篇从第四题开始写。

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

**************************************

### ZigZag Conversion

第六题 [ZigZag Conversion](https://leetcode.com/problems/zigzag-conversion/)

> 字符串 `"PAYPALISHIRING"` 是由如下排列的字符串通过 ZigZag 形式读取所得。
> ```
P   A   H   N
A P L S I I G
Y   I   R
```
> 如果按行读取则为 `"PAHNAPLSIIGYIR"`
> 请编写代码将给定行数的 zigzag 形式字符串转换为行形式的字符串：
> ```
string convert(string text, int nRows);
```
> 比如 `convert("PAYPALISHIRING", 3)` 得到 `"PAHNAPLSIIGYIR"`

这道 ZigZag 题很好玩，让我想起小时候做过的奥数题。从 ZigZag 型字符串中找规律，可以看到第一行和最后一行很容易挑出来，因为其字符的步进是固定的，即 2\*(nRows-1)。然而中间的行的规律就不那么规则了，其步进间距是跳跃的，如果继续按 2\*(nRows-1) 步进查找的话，会漏掉步进间距小于该值的字符。但是仔细观察除掉首行和末行的 ZigZag 排列字符串，可以发现它仍然是 ZigZag 字符串，只不过行数再减小，与之相应的步进间距也在变化，但始终符合 2\*(nRows-1) 的规律。找到这个特性后，在步进查找时把中间行组成的 ZigZag 字符串的步进间距也作查询，就不会漏掉了。

```java
// ZigZagConversion.java
public class Solution {
    public String convert(String s, int numRows) {
        int len = s.length();
        if (len <= 2 || numRows == 1) {
            return s;
        }
        String result = "";
        int step = 2 * (numRows - 1);
        for (int currRow = 0; currRow < numRows; currRow++) {
            for (int currIndex = currRow; currIndex < len; currIndex += 2 * (numRows - 1)) {
                result += s.charAt(currIndex);
                if (currRow != 0 && currRow != numRows - 1 && currIndex + 2 * (numRows - currRow - 1) < len) {
                    result += s.charAt(currIndex + 2 * (numRows - currRow - 1));
                }
            }
        }
        return result;
    }
}
```

OJ 测试结果：

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 1158 / 1158 | 42 ms | Java |

**************************************

### Reverse Integer

第七题 [Reverse Integer](https://leetcode.com/problems/reverse-integer/)

> 翻转整型数的数位，例如：
> x = 123，返回 321；x = -123，返回 -321；

题目解法很简单，但是有几个注意点要留心：

- 如果数字末尾为 0，则翻转过来后的数字应该去掉头部的 0。比如 100 -> 1；
- 如果数字是负数，则翻转后的结果也得是负数；
- 入参肯定是在 int 范围内，但翻转后得到的数字就不一定了。所以要考虑到溢出的情况，比如 1999999999 -> 9999999991；

假定如果翻转后的结果超出范围，则返回 0。先单细胞的思考下，不考虑优化，简单粗暴的先把问题解开。

```java
// ReverseInteger.java v1.0
public class Solution {
    public int reverse(int x) {
        boolean isNeg = false;
        long result = 0L;
        if (x < 0) {
            isNeg = true;
            x = 0 - x;
        }
        while (x != 0) {
            result = result * 10 + x % 10;
            x /= 10;
        }
        if (result > Integer.MAX_VALUE) {
            return 0;
        }
        if (isNeg) {
            result = -result;
        }

        return Math.toIntExact(result);
    }
}
```

自测了几个用例后自信满满的提交了代码，LeetCode 抛出了运行时错误，出现错误的用例为 `-2147483648`，然后我就发现了自己愚蠢的错误：不止是在翻转结束时会发生溢出，在负数转正数的时候也会发生，当且仅当入参为 `-2147483648` 时！打个补丁吧，这方法真是太蠢了！

```java
// ReverseInteger.java v1.1
public class Solution {
    public static int reverse(int x) {
        boolean isNeg = false;
        long result = 0L;
        if (x == -2147483648) {
            return 0;
        }
        if (x < 0) {
            isNeg = true;
            x = -x;
        }
        while (x != 0) {
            result = result * 10 + x % 10;
            x /= 10;
        }
        if (result > Integer.MAX_VALUE) {
            return 0;
        }
        if (isNeg) {
            result = -result;
        }

        return Math.toIntExact(result);
    }
}
```

OJ 测试结果：

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 1032 / 1032 | 2 ms | Java |

**************************************

### String to Integer (atoi)

第八题是经典到无以复加的[字符串数转整型数](https://leetcode.com/problems/string-to-integer-atoi/)！也就是实现 C 语言里的 atoi 函数。

> 提示：仔细考虑所有可能的传参，题目没有指定输入类型。

提示说的很明白了，把所有可能出现异常情况的传参都想到，我现在能想到的有如下情况：

- 正常的 int 范围内的字符串数；
- 超出 int 范围的大数字符串；
- 字符串中包含非数字字符，包括空格符，字母、标点等；
- 首字符是 `"+"`, `"-"`;

仔细考虑可能出现的情况：
1) 正常的 int 型数值字符串，很好处理，依次取字符转换为 int 型并做数值相加；
2) 首字符为 `"+"`, `"-"` 时，截取去掉正负号的子字符串，再进行如上处理；
3) 若首字符为空格，则去掉该空格，比如 "   123" 转换结果应该为 123；
4) 若字符串中出现非数字，则舍弃该位以及后面的字符；
5) 弱字符串转换结果超出了整型数值范围，则取整型数的边界值，比如 "-999999999" 转换结果是 -2147483648

再充分考虑到可能情况后，递归调用可以简化处理步骤，下面是我的解法，多说一句，LeetCode 上这道题的描述实在是太简略了，不少特殊情况的处理规则都是我提交代码试错的出来的，比如上面罗列出来的规则 3, 4 和 5。

```java
public class Solution {
    public int myAtoi(String str) {
        if (str == null || Objects.equals(str, ""))
            return 0;
        if (str.charAt(0) == '-')
            return subAtoi(str.substring(1), true);
        if (str.charAt(0) == '+')
            return subAtoi(str.substring(1), false);
        if (str.charAt(0) == ' ')
            return myAtoi(str.substring(1));
        return subAtoi(str, false);
    }

    private int subAtoi(String str, boolean neg) {
        if (str == null || str.equals("")) {
            System.out.println("a");
            return 0;
        }
        int res = 0;
        for (int i = 0; i < str.length(); i++) {
            if (!Character.isDigit(str.charAt(i)))
                return res;
            int digit = Character.getNumericValue(str.charAt(i));
            if (neg) {
                if (i == 9) {
                    int diff = res - Integer.MIN_VALUE / 10;
                    if (diff < 0 || (diff == 0 && digit > 8))
                        return Integer.MIN_VALUE;
                }
                if (i >= 10)
                    return Integer.MIN_VALUE;
                res = 10 * res - digit;
            } else {
                if (i == 9) {
                    int diff = res - Integer.MAX_VALUE / 10;
                    if (diff > 0 || (diff == 0 && digit > 7))
                        return Integer.MAX_VALUE;
                }
                if (i >= 10)
                    return Integer.MAX_VALUE;
                res = digit + 10 * res;
            }
        }
        return res;
    }
}
```

OJ 测试结果：

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 1047 / 1047 | 8 ms | Java |