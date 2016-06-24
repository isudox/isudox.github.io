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

第十一题 [Container With Most Water](https://leetcode.com/problems/container-with-most-water/)

> 给出 n 个非负整数 a1, a2, ..., an，每个数指向一个坐标点 (i, ai)。该 n 个坐标点画出了 n 条纵线，即从 (i, ai) 到 (i, 0) 之间的线段。找出其中的两条线段和 x 轴形成的容器能装满最多的水。

假设待求的这两条线段的坐标分别为(i, 0)-(i, ai) 和 (j, 0)-(j, aj)，那么容器的底座长度 L=Math.abs(i - j)，高度 H=Math.min(ai, aj)，容积 V=L*H。

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

提交后被 Lee他Code 婉拒，因为 Time Limit Exceeded，这种解法时间复杂度是 O(n^2)，当 n 很大时，运行时间随指数增长会非常可怕。只能想办法精简处理过程，是不是所有 0.5(n*(n-1)) 中组合都要计算一遍，必须不是。涉及两个变量长和高，因为长的最大值是已知的，从长度取最大开始比较：
先取首末两个点 1 和 n，容积是 V=(n-1)*Math.min(a1,an)。除此之外的选点，长度不可能比这种情况大，要使长度变小的前提下，容积更大，必要条件就是 Math.min(ai,aj) 要大于 Math.min(a1,an)。所以可以从首末两端往中间移动，求取容积并存储当前最大容积后，放弃两侧高度较小的那个点，并向中心移动，这样处理可以省去很多不必要的计算，时间复杂度降低到 O(n)。

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