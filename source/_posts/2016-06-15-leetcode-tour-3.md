---
title: LeetCode 探险第三弹
date: 2016-06-15 20:18:15
tags:
  - Algorithm
  - LeetCode
categories:
  - Coding
---

继上篇 [LeetCode 探险第二弹](/2016/05/17/leetcode-tour-2/)，第三弹记录第 11 到 15 题。

<!-- more -->

### Container With Most Water

第 11 题 [Container With Most Water](https://leetcode.com/problems/container-with-most-water/)

> 给出 n 个非负整数 a<sub>1</sub>, a<sub>2</sub>, ..., a<sub>n</sub>，每个数指向一个坐标点 (i, a<sub>i</sub>)。该 n 个坐标点画出了 n 条纵线，即从 (i, a<sub>i</sub>) 到 (i, 0) 之间的线段。找出其中的两条线段和 x 轴形成的容器能装满最多的水。

假设待求的这两条线段的坐标分别为(i, 0)-(i, a<sub>i</sub>) 和 (j, 0)-(j, a<sub>j</sub>)，那么容器的底座长度 L=Math.abs(i - j)，高度 H=Math.min(a<sub>i</sub>, a<sub>j</sub>)，容积 V=L*H。

最笨也是最直接的办法就是在循环里暴力枚举。把所有能组成的容器都测量一遍，不多说了，直接撸代码：

```java
// ContainerWithMostWater.java v1.0
public class Solution {
    public int maxArea(int[] height) {
        int maxV = 0, curV = 0;
        int count = height.length;
        for (int i = 0; i < count - 1; i++) {
            for (int j = i + 1; j < count; j++) {
                curV = (j - i) * (height[i] < height[j] ? height[i] : height[j]);
                maxV = Math.max(maxV, curV);
            }
        }
        return maxV;
    }
}
```

提交后被 Lee他Code 婉拒，因为 Time Limit Exceeded，这种解法时间复杂度是 O(n<sup>2</sup>)，当 n 很大时，运行时间随指数增长会非常可怕。只能想办法精简处理过程，是不是所有 0.5(n\*(n-1)) 中组合都要计算一遍，必须不是。涉及两个变量长和高，因为长的最大值是已知的，从长度取最大开始比较：
先取首末两个点 1 和 n，容积是 V=(n-1)\*Math.min(a<sub>1</sub>, a<sub>n</sub>)。除此之外的选点，长度不可能比这种情况大，要使长度变小的前提下，容积更大，必要条件就是 Math.min(a<sub>i</sub>, a<sub>j</sub>) 要大于 Math.min(a<sub>1</sub>, a<sub>n</sub>)。所以可以从首末两端往中间移动，求取容积并存储当前最大容积后，放弃两侧高度较小的那个点，并向中心移动，这样处理可以省去很多不必要的计算，时间复杂度降低到 O(n)。

```java
// ContainerWithMostWater.java v1.1
public class Solution {
    public int maxArea(int[] height) {
        int maxV = 0, curV = 0;
        int i = 0, j = height.length - 1;
        while (i < j) {
            if (height[i] < height[j]) {
                curV = (j - i) * (height[i++]);
            } else if (height[i] > height[j]) {
                curV = (j - i) * (height[j--]);
            } else {
                curV = (j - i) * (height[i++]);
                j--;
            }
            maxV = Math.max(maxV, curV);
        }
        return maxV;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 45 / 45 | 5 ms | Java |

**************************************

### Integer to Roman

第 12 题 [Integer to Roman](https://leetcode.com/problems/integer-to-roman/)

> 给出一个整型数，将其转换为罗马数字。输入的整数在 1-3999 之间。

先来整理下罗马数字的表达方式：
1-9: "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"
10-90: "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"
100-900: "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"
1000-3000: "M", "MM", "MMM"

I 表示单位 1，V 表示单位 5。同理，X 表示 10，L 表示 50；C 表示 100，D 表示 500；M 表示 1000。单位较小的如果在单位较大的符号左边，则是相减关系，反之则是相加关系。

比如数字 432，先拆分成 400+20+3，即分别为 CD、XXX、II，所以转换结果是 CDXXXII；再比如 98，拆分为 90+8，即 XCVIII。
算法的关键就是把整数拆分成各个数位上所代表的数值的相加。通过二维字符串数组的索引位置和值的映射实现各个加和整数与罗马数字的对应。

```java
// IntegerToRoman.java v1.0
public class Solution {
    public String intToRoman(int num) {
        String[] ones = {"", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"};
        String[] tens = {"", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"};
        String[] hundreds = {"", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"};
        String[] thousands = {"", "M", "MM", "MMM"};
        String[][] romans = {ones, tens, hundreds, thousands};
        String res = "";
        int len = String.valueOf(num).length();
        for (int i = len - 1; i >= 0; i--) {
            int x = num / pow(10, i);
            res = res + romans[i][x];
            num = num % pow(10, i);
        }
        return res;
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
| Accepted | 3999 / 3999 | 15 ms | Java |

这种做法在细节上处理的很不好，算法复杂度略高，因为整数的分拆和转换罗马数字是从最高位开始，所以需要幂运算，浪费了一些运算时间。如果从整数的最低位开始处理，就不需要做幂运算了。
```java
// IntegerToRoman.java v1.1
public class Solution {
    public String intToRoman(int num) {
        String[] ones = {"", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"};
        String[] tens = {"", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"};
        String[] hundreds = {"", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"};
        String[] thousands = {"", "M", "MM", "MMM"};
        String[][] romans = {ones, tens, hundreds, thousands};
        String res = "";
        int digit = 0;
        while (num > 0) {
            int x = num % 10;
            res = romans[digit][x] + res;
            num = num / 10;
            digit++;
        }
        return res;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 3999 / 3999 | 12 ms | Java |

另外再提供一个思路，罗马数字 1 - 3999 的匹配过程中，9\*10<sup>n</sup>，5\*10<sup>n</sup> 和 4\*10<sup>n</sup> 是特殊的符号，因此把它们单独放进映射列表中。让整数从高位作消减，每减去一个数，就拼接该数所对应的罗马数字，直到不能再减为止。 
```java
// IntegerToRoman.java v1.2
public class Solution {
    public String intToRoman(int num) {
        String[] romans = {"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"};
        int[] ints = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
        StringBuilder res = new StringBuilder();
        for (int i = 0; i < ints.length; i++) {
            while (num >= ints[i]) {
                res.append(romans[i]);
                num -= ints[i];
            }
        }
        return res.toString();
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 3999 / 3999 | 8 ms | Java |

**************************************

### Roman to Integer

第 13 题 [Roman to Integer](https://leetcode.com/problems/roman-to-integer/)

> 给出一个罗马数字，将其转换为整型数。范围在 1-3999 之间。

这题就是前一题的逆向。可以借用上面的思路，从字符串的首位开始寻找匹配的罗马数字，如果从首位开始的字符串能匹配罗马数字，则把该字符串截掉，继续匹配；如果没有匹配，则换下一个罗马数字继续判断是否匹配。这里有一个注意点，就是一旦匹配后截取子字符串时，要根据被截掉的罗马数字的长度来定截取的起始位置。Java 代码如下：
```java
// RomanToInteger.java v1.0
public class Solution {
    public int romanToInt(String s) {
        String[] romans = {"M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"};
        int[] ints = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
        int res = 0;
        for (int i = 0; i < romans.length;) {
            int index = s.indexOf(romans[i]);
            if (index == 0) {
                res += ints[i];
                s = s.substring(index + romans[i].length());
            } else {
                i++;
            }
        }
        return res;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 3999 / 3999 | 10 ms | Java |

再换种思路，前一题分析时讲到，小单位在大单位左边时时相减的关系，反之则是相加的关系，比如 "IV" 表示 V-I=4，而 "VI" 表示 V+I=6。每次在匹配当前罗马数字时再去和前一位罗马数字进行比较，如果是比之前的大，则在加上当前罗马数字所代表的整数后还要减去前一位所代表的数字；如果比之前的要小，就只需要加上当前的数字。还有一个细节，如果当前罗马数字比前一位大，由于上一次操作时已经把前一位的数字加上去了，所以在操作当前罗马数字时需要减两次前一罗马数字。

```java
// RomanToInteger.java v1.1
public class Solution {
    public int romanToInt(String s) {
        int pre = 0, cur = 0, res = 0;
        for (int i = 0; i < s.length(); i++) {
            switch (s.charAt(i)) {
                case 'M': cur = 1000;
                    break;
                case 'D': cur = 500;
                    break;
                case 'C': cur = 100;
                    break;
                case 'L': cur = 50;
                    break;
                case 'X': cur = 10;
                    break;
                case 'V': cur = 5;
                    break;
                case 'I': cur = 1;
                    break;
            }

            if (cur > pre) {
                res += cur - pre * 2;
            } else {
                res += cur;
            }
            pre = cur;
        }
        return res;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 3999 / 3999 | 7 ms | Java |

**************************************

### Longest Common Prefix

第 14 题 [Longest Common Prefix](https://leetcode.com/problems/longest-common-prefix/)

> 编写一个函数，找出给定的字符串数组中最长的公共前缀字符串。

这是一道非常非常经典的算法题，江湖人称 "LCP"。由于限定了是前缀字符串，使得子字符串的起始位置是固定的，因此题目变得很好处理。
先判断两种特殊输入，字符串数组为空或者 `null`，以及字符串数组仅包含一个字符串这两种情况。
然后找出字符串数组中的最短字符串的长度，因为这个长度限定了最长公共前缀字符串的最大长度。接下来就从字符串的首位依次往后比较，一旦出现不相同的情况，保存当前的公共前缀字符串，立即终止比较。

```java
// LongestCommonPrefix.java
public class Solution {
    public String longestCommonPrefix(String[] strs) {
        if (strs == null || strs.length == 0) return "";
        if (strs.length == 1) return strs[0];
        int minLen = strs[0].length();
        for (String str : strs) {
            minLen = str.length() < minLen ? str.length() : minLen;
        }
        for (int i = 0; i < minLen; i++) {
            for (int j = 0; j < strs.length - 1; j++) {
                if (strs[j].charAt(i) != strs[j + 1].charAt(i)) {
                    return strs[j].substring(0, i);
                }
            }
        }
        return strs[0].substring(0, minLen);
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 117 / 117 | 2 ms | Java |

**************************************

### 3Sum

第 15 题 [3Sum](https://leetcode.com/problems/3sum/)

> 有 n 个整型数组成的数组 S，其中是否存在 a, b, c 三个数，使得 a + b + c = 0？找出所有的组合。
> 比如给出数组 S = [ -1, 0, 1, 2, -1, -4 ]，结果就是：[ [-1, 0, 1], [-1, -1, 2] ]
> 注，需要去重。

首先排除数组元素小于 3 的异常情况。因为三者求和为 0，因此必然包含正数和负数，所以把数组排序后如果首个元素大于 0，或者最后一个元素小于 0 都可以直接终止算法。另外，由于最终的结果不能有重复的组合，所以有必要对数组进行排序，这样方便去掉重复的数字组合。
对递增排序后的数组枚举，枚举时选定一个数 nums[i] 作为最小数，然后再从后面的数中选定中间数 nums[i+1] 和最大数 nums[n]，三者求和。如果结果等于 0，则需要把中间数和最大数的下标同时往中间移动，如果移动后的数和之前一样，则继续向中间移动，这样处理是一方面是节省不必要的运算，更重要的是为了去重；如果结果大于 0，相应的把最大数减小，即向左移动下标 n；如果结果小于 0，则把中间数的下标向右移动；直到中间数和最大数相遇为止。

```java
// 3Sum.java
public class Solution {
    public List<List<Integer>> threeSum(int[] nums) {
        List<List<Integer>> res = new ArrayList<>();
        if (nums == null || nums.length < 3) return res;
        Arrays.sort(nums);
        int count = nums.length, i = 0;
        while (nums[i] <= 0 && nums[count - 1] >= 0 && i < count - 2) {
            int j = i + 1;
            int k = count - 1;
            while (j < k) {
                int sum = nums[i] + nums[j] + nums[k];
                if (sum == 0) {
                    res.add(Arrays.asList(nums[i], nums[j++], nums[k--]));
                    while (j < k && nums[j] == nums[j - 1]) j++;
                    while (j < k && nums[k] == nums[k + 1]) k--;
                } else if (sum < 0) {
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
        return res;
    }
}
```

| Status | Tests | Run Time | Language |
|:------:|:------:|:--------:|:--------:|
| Accepted | 311 / 311 | 9 ms | Java |

下一篇：[LeetCode 探险第四弹](/2016/07/04/leetcode-tour-4/)