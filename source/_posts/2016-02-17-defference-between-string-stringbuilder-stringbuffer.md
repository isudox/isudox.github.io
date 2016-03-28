---
title: String, StringBuilder, StringBuffer 区别
date: 2016-02-17 15:22:01
tags: Java
categories: Coding
---
今天下午浏览代码时看到IDEA给出了一段提示：
`StringBuffer variables may be declared as StringBuilder`
回想了下，除了印象中StringBuffer是线程安全，而StringBuilder非线程安全之外，已经想不到二者其他的区别和使用场景的差异。遂谷歌之，看到阿里的Android大牛Trinea在Github上的一篇[Issue](https://github.com/android-cn/android-discuss/issues/5)，正好是关于String，StringBuilder，StringBuffer，CharSequence区别的讨论。我也凑个热闹，写写我对这个问题的认识。

#### 关于String

首先搬出权威解释，来自Oracle的[Java Documentation](https://docs.oracle.com/javase/8/docs/api/java/lang/String.html)
```java
public final class String
extends Object
implements Serializable, Comparable<String>, CharSequence
```
