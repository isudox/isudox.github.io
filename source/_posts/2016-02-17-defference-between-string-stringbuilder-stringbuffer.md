---
title: String, StringBuilder, StringBuffer 区别
date: 2016-02-17 15:22:01
tags: Java
categories: Coding
---
今天下午浏览代码时看到 IDEA 给出了一段提示：
StringBuffer variables may be declared as StringBuilder.

回想了下，除了印象中 StringBuffer 是线程安全，而 StringBuilder 非线程安全之外，已经想不到二者其他的区别和使用场景的差异。遂谷歌之，看到阿里的 Android 大牛 Trinea 在 Github 上的一条 [issue](https://github.com/android-cn/android-discuss/issues/5)，正好是关于 String，StringBuilder，StringBuffer，CharSequence 区别的讨论。我也凑个热闹，记录下我对这个问题的认识。

<!-- more -->

#### 关于 String

首先搬出权威解释，来自 Oracle 的 [Java Documentation](https://docs.oracle.com/javase/8/docs/api/java/lang/String.html)

```java
public final class String
extends Object
implements Serializable, Comparable<String>, CharSequence
```

再打开 JDK 8 的源码

```java
public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {
    /** The value is used for character storage. */
    private final char value[];

    /** Cache the hash code for the string */
    private int hash; // Default to 0
```

显而易见，String 类被标识为 final，
