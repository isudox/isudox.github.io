---
title: LeetCode 26-30
tags:
  - 算法
categories:
  - Coding
date: 2016-10-17 17:09:15
---


三个月没上 LeetCode了，最近工作不顺心，好想被虐个痛快，接着写 LeetCode 第 26 至 30 题。
<!-- more -->

### Remove Duplicates from Sorted Array

第 26 题 [Remove Duplicates from Sorted Array](https://leetcode.com/problems/remove-duplicates-from-sorted-array/)

> 给定一个有序数组，去掉其中重复的元素，并返回新数组的长度。
> 不要为其他数组分配额外的空间，必须在给定的内存中完成。

假设传入的数组是 `[1, 1, 2]`，得到的结果应该是 2。题意很简单，但是有两个注意点，一个是该数组是有序的，即从小到大排列，另一个是不允许分配新数组的存储空间，这就意味着不用创建新的数组来保存数据，也不能通过 Set 来过滤重复元素。

因为第二点的限，只能在给定的数组上进行数值比较的同时，计算非重复元素的数量；因为第一点的设定，所以可以做到对数组只遍历一次。具体做法就是，在遍历数组元素时，比较前后两个元素，如果相等，则重复元素的数量加一，同时移动当前遍历位置，直到遍历到数组最末元素。

编写 Java 解法如下：

```java
// Rejected ×
public class Solution {
    public int removeDuplicates(int[] nums) {
        int count = nums.length;
        int dup = 0;
        if (count < 2)
            return count;
        for (int i = 0; i < count - 1; i++) {
            if (nums[i] == nums[i + 1])
                dup++;
        }
        return count - dup;
    }
}
```

本地测试结果是正确的，但是提交的 LeetCode 上却被否决，因为上面的方法只计算出了非重复元素的个数 n，没有考虑把有序数组前 n 位修改成正确的有序非重复元素。因此在遍历的同时，需要修改发现重复的位置上的元素。

```java
// Accepted √
public class Solution {
    public int removeDuplicates(int[] nums) {
        int count = nums.length;
        if (count < 2)
            return count;
        int left = 0, right = 1;
        while (right < count) {
            if (nums[left] == nums[right]) {
                right++;
            } else {
                nums[++left] = nums[right++];
            }
        }
        return left + 1;
    }
}
```

**********************************************

### Remove Element

第 27 题 [Remove Element](https://leetcode.com/problems/remove-element/)

> 给定一个数组和一个数，移除数组中所有和给定数相同的数，并返回该数组修改后的长度。
> 不要为其他数组分配额外的空间，必须在给定的内存中完成。
> 数组元素的顺序可以被改变。

例如传入的数组为 `[3, 2, 2, 3]`，数值是 3，函数处理后返回的长度是 2，且数组的前两个元素是 2。

这道题比上题简单，无非就是数组元素和给定数值的比较，如果相等，则去掉，如果不等则保留。唯一需要想办法的是如何把要保留的元素放在数组前面的位置。当找到第一个和给定数不等的元素时，就把它放在数组的首位，再找下一个不等的元素，放在数组的第二个位置，这样递推直到遍历完成。

```java
public class Solution {
    public int removeElement(int[] nums, int val) {
        int index = 0;
        for (int num : nums) {
            if (num != val)
                nums[index++] = num;
        }
        return index;
    }
}
```

*********************************************

### Implement strStr()

第 28 题 [Implement strStr()](https://leetcode.com/problems/implement-strstr/)

> 实现 `strStr()` 方法。
> 判断字符串 `needle` 是否在字符串 `haystack` 中，如果是，则返回首次出现的位置，如果不是，则返回 -1

粗暴的解法很简单，用两个指针分别遍历字符串，逐次比较指针所指向的字符，如果相同指针往下移动，如果不同，`needle` 上的指针回到起始位置 0，`haystack` 上的指针则后退 `needle` 指针移动的距离回到之前和 `needle` 首字符相同的位置后，再往下移动一步。如果 `needle` 上的指针最终完成了遍历，则表明 `haystack` 中首次出现了 `needle`。

Java 解法如下：

```java
public class Solution {
    public int strStr(String haystack, String needle) {
        if (needle.equals(""))
            return 0;
        if (haystack.length() < needle.length())
            return -1;
        int i = 0, j = 0, start = 0;
        while (i < haystack.length() && j < needle.length()) {
            if (haystack.charAt(i) == needle.charAt(j)) {
                i++;
                j++;
            } else {
                i = i - j + 1;
                j = 0;
            }
            if (j == needle.length())
                return i - j;
        }
        return -1;
    }
}
```

**********************************************

### Divide Two Integers

第 29 题 [Divide Two Integers](https://leetcode.com/problems/divide-two-integers/)

> 两个整数做除法，要求不能使用乘法、除法、取余运算。如果结果溢出，则返回 MAX_INT。

整数相除，又不允许使用乘法、除法、取余，那么能想到的只能是减法了。除数不断减去被除数，直到小于除数为止。但是这样做效率很低，试想如果计算 10000 和 1 相除，那么岂不是要做 10000 次减法！就是要找一种方法使得除数能快速接近被除数，除了幂运算外，乘法是最快的，既然不能直接用乘法，那就用位运算，向左位移 n 位就是乘以 2<sup>n</sup>。接下来就相当于做折半操作，每次减去 2<sup>n</sup> 个除数，再递减 n，直到不够做减法为止。当然这个方法有个前提，就是需要把两个整数都取绝对值。

这里还需要注意，Java 里 `-2147483648` 取绝对值还是 `-2147483648`，因为试图把它变成正数时出现越界，又变成了 `-2147483648`。

```java
public class Solution {
    public int divide(int dividend, int divisor) {
        if (divisor == 0 || dividend == Integer.MIN_VALUE && divisor == -1)
            return Integer.MAX_VALUE;
        int result = 0;
        boolean positive = dividend > 0 == divisor > 0;
        long dividend1 = dividend == Integer.MIN_VALUE ? 2147483648 : Math.abs(dividend);
        long divisor1 = divisor == Integer.MIN_VALUE ? 2147483648L : Math.abs(divisor);
        int i = 0;
        while (divisor1 << (i + 1) <= dividend1)
            i++;
        while (dividend1 >= divisor1) {
            if (dividend1 >= divisor1 << i) {
                result = result + (1 << i);
                dividend1 = dividend1 - (divisor1 << i);
            }
            i--;
        }
        return positive ? result : -result;
    }
}
```

**********************************************

### Substring with Concatenation of All Words

第 30 题 [Substring with Concatenation of All Words](https://leetcode.com/problems/substring-with-concatenation-of-all-words)

> 给定一个字符串 s，和单词数组 words，数组中每个单词的长度都是相同的。依次从 s 中找到所有由 words 数组中元素能组成的字符串的匹配位置。（不需要考虑 words 是空字符串）
> 例如，
> s: "barfoothefoobarman"
> words: ["foo", "bar"]
> 处理的结果为 [0, 9]。对顺序不作要求。

题意比较绕，根据上面给出的例子，words 数组元素可组成 `foobar` 和 `barfoo` 两个字符串，从 s 中查找这两个字符串的首次匹配位置，分别是 0 和 9，所以结果是 [0, 9]。

最暴力直接的思路就是用 words 数组元素所有可能的组合去撞字符串 s，如果匹配到，就记录下匹配位置。但是这种方法性能很差，一来组合的字符串可能出现重复，二来每个字符串都要和 s 进行比较，产生大量冗余操作。

换个方向，用 s 去撞 words。从初始位置 i = 0 开始，截取 s 中起止位置为 i 和 i + len 的子字符串 substring，其中 len 为 words 中每个元素的长度。如果 substring\_1 是 words 数组中的元素，则再截取 s 中起止位置为 i 和 i + count 的子字符串 substring\_2，count 为 words 数组所有元素的总长度，然后用这个 substring\_2 去匹配 words 中的元素，匹配的思路也是一样，从 substring\_2 拆分成每个元素长度为 len 的列表 list，再用 list 去匹配 words 中的元素，如果没有匹配到，就放弃该 substring\_2，继续从 i + 1 处截取 s 的子字符串；如果匹配到，则继续下一个匹配，直到全部匹配 words，保存索引位置 i 到结果中。

```java
public class Solution {
    public List<Integer> findSubstring(String s, String[] words) {
        List<Integer> result = new ArrayList<Integer>();
        if (words.length == 0)
            return result;
        List<String> wordList = Arrays.asList(words);
        int len = words[0].length();
        int sLen = s.length();
        if (len > sLen)
            return result;
        int wordsLen = len * (words.length);
        int i = 0;
        while (i <= sLen - wordsLen) {
            String word = s.substring(i, i + len);
            if (wordList.contains(word)) {
                String substr = s.substring(i, i + wordsLen);
                if (isValid(substr, wordList, len))
                    result.add(i);
            }
            i++;
        }
        return result;
    }

    private boolean isValid(String str, List<String> wordList, int len) {
        List<String> list = new ArrayList<String>();
        for (int i = 0; i < str.length() / len; i++) {
            String s = str.substring(i * len, (i + 1) * len);
            list.add(s);
        }
        for (String s : wordList) {
            if (list.contains(s)) {
                list.remove(s);
            } else {
                return false;
            }
        }
        return true;
    }
}
```

上面的代码中把 Array 转换成 List，借 Java Collections 现成的方法，偷懒省去了一些原本需要自己实现的方法。

另，LeetCode 的 OJ 系统有 bug，同样的代码，提交时偶尔会报 "Time Limit Exceeded"，而实际是正确的，再次提交运行就通过了……