---
title: LeetCode 探险第二弹
date: 2016-05-17 21:14:04
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---

接着上篇 [LeetCode 探险第一弹](/2015/11/23/leetcode-1st-week/)，本篇记录第 6 到 10 题。

<!-- more -->

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

**************************************

### Palindrome Number

第九题 [Palindrome Number](https://leetcode.com/problems/palindrome-number/)
> 判断一个整型数是否为回文数，不要使用额外的存储空间。

题目不难，无非就是判断该整数是否是轴对称，因为负整数有符号，所以不是回文数。因此主流程只需要对正整数的情况进行处理。
那么现在的问题就简化成，如何判断一个正整数是否轴对称。如果把正整数转换为字符串，通过栈 FILO 的特性翻转字符串肯定是可以判断其是否对称，但是这样做的话，申请了额外的存储空间。那如果直接翻转正整数呢，会存在两种特殊情况，一是超出整型数的范围，二是末位是 0 的数。但实际上，这两种情况都无需考虑，这里有一个关于假设的小伎俩：假定整数是回文数，那么翻转该整数得到的数就是相同的整数，就必然不存在超出整型数范围或末位为 0 的情况；反之，如果不是回文，那翻转过来的结果无论是溢出整型范围还是位数减少，都和原整数不相同，也就不是回文。所以这道题可以直接通过除十取余的方法来解决。Java 代码如下：

```java
// PalindromeNumber.java v1.0
public class Solution {
    public boolean isPalindrome(int x) {
        if (x < 0) return false;
        int y = 0;
        int bak = x;
        while (x > 0) {
            int temp = x;
            x = temp / 10;
            y = y * 10 + temp % 10;
        }
        return y == bak;
    }
}
```

OJ 测试结果：

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 11506 / 11506 | 11 ms | Java |

但这种耍小聪明的方法并不优雅，因为它没有直接处理上面提到的两种特殊情况。校验是否轴对称，其实本质上就是校验首位数和末位数是否相等，那么可以依次比较整数的首位和末位，如果校验通过，则将整数去掉首位和末位，再次比较。

```java
// PalindromeNumber.java v1.1
public class Solution {
    public boolean isPalindrome(int x) {
        if (x < 0) return false;
        if (x == 0) return true;
        int count = 0;
        int temp = x;
        while (temp > 0) {
            temp /= 10;
            count++;
        }
        for (int i = count; i > 0; i -= 2) {
            if (x / this.pow(10, i - 1) != x % 10) return false;
            x = (x % this.pow(10, i - 1)) / 10;
        }
        return true;
    }
    private int pow(int x, int y) {
        int z = 1;
        for (; y > 0; y--) z *= x;
        return z;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 11506 / 11506 | 14 ms | Java |

```java
// PalindromeNumber.java v1.2
public class Solution {
    public boolean isPalindrome(int x) {
if (x < 0) return false;
        int digits = 0;
        int temp = x;
        while (temp > 0) {
            temp /= 10;
            digits++;
        }
        int j = digits;
        for (int i = 1; j > i; i++, j--) {
            if (digit(x, digits, j) != digit(x, digits, i)) return false;
        }
        return true;
    }
    private int pow(int x, int y) {
        int z = 1;
        for (; y > 0; y--) z *= x;
        return z;
    }
    private int digit(int x, int i, int j) {
        return x / pow(10, j - 1) % 10;
    }
}
```
| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 11506 / 11506 | 15 ms | Java |

哎，越来越慢，讲道理，还是把整数转换为字符串去处理是最简单的……

所以，用 Python 来做的话，代码简直不能更简洁，因为 Python 直接支持翻转

```python
# palindrome_number.py
class Solution(object):
    def isPalindrome(self, x):
        """
        :type x: int
        :rtype: bool
        """
        return x >=0 and str(x) == str(x)[::-1]
 ```
| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 11506 / 11506 | 272 ms | Java |

Python 处理速度虽然比 Java 有数量级的差距，但是，编程的过程真是轻松太多了，真的就只用了一行代码解决战斗！在这里必须要喊一句口号——
> **人生苦短，我用 Python！**

**************************************

### Regular Expression Matching

第十题 [Regular Expression Matching](https://leetcode.com/problems/regular-expression-matching/)

> 实现正则表达式，使得支持 `'.'` 和 `'*'` 符。其中，`'.'` 匹配任意单个字符，`'*'` 匹配该符号前之前的零个或任意多个字符。

这道题难道不是很简单吗，就算是用笨重的 Java 写，一行代码也能解决，你看——
```java
// RegularExpressionMatching.java v1.0
public class Solution {
    public boolean isMatch(String s, String p) {
        return java.util.regex.Pattern.compile(p).matcher(s).matches();
    }
}
```

开个玩笑，这种作弊行为当然不算数。LeetCode 上这道题的难度为 Hard 级，肯定是要求用自己的方式实现 `'.'` 和 `'*'` 符的正则匹配，因为这两个符号分别的组合可以形成多种匹配形式，所以逐条分析：
- 正则式 p 不包含 `'.'` 和 `'*'` 符，字符串长度（判明空串）后再依次比较字符；
- 正则式 p 仅包含 `'.'` 符，因为它只能表示一个任意字符，因此首先比较长度，长度一致再比较 `'.'` 符以外位置的字符是否相同；
- 正则式 p 仅包含 `'*'` 符，记录 `'*'` 符前面的字符（`'*'` 符不会在首位），这里有一点需要注意，当 `'*'` 符在第二位时，可能会匹配 0 个它之前的字符，所以还得判断正则式第三位开始的子串正则式的匹配情况；当 `'*'` 符不在第二位时，就按部就班的从第一个字符开始依次比较；
- 正则式 p 同时包含 `'.'` 和 `'*'` 符，复杂度最高，同时考虑情况 2 和 3；

```java
// RegularExpressionMatching.java v1.1
public class Solution {
    public boolean isMatch(String s, String p) {
        int lenS = s.length(), lenP = p.length();
        if (lenP == 0) return lenS == 0;
        if (lenP == 1) {
            if (p.charAt(0) == '.') return lenS == 1;
            return lenS == 1 && s.charAt(0) == p.charAt(0);
        }
        if (p.charAt(1) == '*') {
            if (isMatch(s, p.substring(2))) return true;
            if(s.length() > 0 && (p.charAt(0) == '.' || s.charAt(0) == p.charAt(0))) {
                return isMatch(s.substring(1), p);
            }
            return false;
        } else {
            if(lenS > 0 && (p.charAt(0) == '.' || s.charAt(0) == p.charAt(0))) {
                return isMatch(s.substring(1), p.substring(1));
            }
            return false;
        }
    }
}
```
大致讲解下上面的思路：
1) 先判断空串的情况，当正则式 p 为空串时，当且仅当字符串 s 也是空串时才能匹配；
2) 当正则式 p 长度为 1 时，当 p 为 `'.'` 且 s 长度也为 1 时匹配，当 p 不为 `'.'` 时，只有当 s 长度为 1 且 s 和 p 相同时匹配；
3) 当正则式 p 长度大于 1 且第二个字符为 `'*'` 时，情况就比较多变了。由于 `'*'` 可以匹配任意多个字符，所以如果取p `'*'` 后的子串能匹配 s，则 p 也能匹配上 s；如果 s 的长度非 0 且 p 首字符是 `'.'` 或者 s 和 p 的首字符相同，则 s 去掉首位的子字符串如果能和 p 匹配，意味着 s 和 p 匹配。因此，这里要用到递归调用。
4) 当正则式 p 长度大于 1 且第二个字符非 `'*'` 时，只有当 s 长度大于 0 且 s 和 p 首字符相同或者 p 的首字符为 `'.'` 时才匹配；

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 445 / 445 | 116 ms | Java |

自己的实现不如 Java 内置的正则匹配算法效率高，类 Pattern 的完成上述测试用例匹配的时间是 87 ms。

下一篇：[LeetCode 探险第三弹](/2016/06/15/leetcode-tour-3/)