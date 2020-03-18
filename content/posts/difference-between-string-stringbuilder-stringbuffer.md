---
title: String, StringBuilder, StringBuffer 区别
date: 2016-02-17 15:22:01
tags:
  - Java
categories:
  - Coding
---
今天下午浏览代码时看到 IDEA 给出了一段提示：
StringBuffer variables may be declared as StringBuilder.

回想了下，除了印象中 StringBuffer 是线程安全，而 StringBuilder 非线程安全之外，已经想不到二者其他的区别和使用场景的差异。遂谷歌之，看到阿里的 Android 大牛 Trinea 在 Github 上提的 [issue](https://github.com/android-cn/android-discuss/issues/5)，正好是关于它们之间区别的讨论。我也凑个热闹，查漏补缺。

<!-- more -->

#### CharSequence

首先，String、StringBuilder 和 StringBuffer 都是实现的 CharSequence 接口。下面是 CharSequence 的源码：
```java
package java.lang;

public interface CharSequence {

    int length();

    char charAt(int index);

    CharSequence subSequence(int start, int end);

    public String toString();

}
```
CharSequence 抽象了 char 序列，提供了求序列长度的方法 length()，获取指定位置字符的方法 charAt()，截取子序列的方法 subSequence() 和转换为 String 型的方法 toString()。实际运用中，我们很少直接用等到 CharSequence，因为它的实现 String、StringBuffer 和 StringBuilder 满足绝大多数使用场景。

#### String

先看 JDK 里的源码：
```java
package java.lang;

public final class String
    implements java.io.Serializable, Comparable<String>, CharSequence {
    /** The value is used for character storage. */
    private final char value[];

    /** Cache the hash code for the string */
    private int hash; // Default to 0
```

String 具有 immutable 特性，即不可变，一旦创建后就无法再被更改。String 变量被存储在内存的常量字符串池中。因为不可变对象都是线程安全的，所以 String 也是线程安全的。对 String 变量进行拼接、截取等操作后，原有的字符串对象保持不变，操作后得到的结果返回给新的 String 对象。值相同的 String 对象共享同一段内存池区域，即引用同一块内存地址。
```java
public static void main(String[] args) {
    String nameA = "zhangsan";
    String nameB = "lisi";
    String nameC = "lisi";
    System.out.println(nameB == nameC); // true
}
```

但如果是通过 new 创建的 String 对象被分配在 heap 中，即使值一样，所引用的内存空间也是不同的。这里涉及到操作符 `==` 和方法 `equals()` 的区别，直接用代码说话：
```java
public static void main(String[] args) {
    String a = new String("hello world");
    String b = new String("hello world");
    String c = "hello world";
    System.out.println(a == b); // false
    System.out.println(Objects.equals(a, b)); // true
    System.out.println(a == c); // false
    System.out.println(Objects.equals(a, c)); // true
}
```

`==` 比较了对象所引用的内存地址，地址相同则返回 true；`Objects.equals()` 方法则只是比较了对象的值。因此上面代码中字符串 a 和 c 虽然值相同，但是引用的地址不一样，所以在比较 `==` 时返回了 false。

关于上面的涉及到的 String 对象在内存中的分配，我在后边的一篇[博客](/2016/06/22/memory-model-of-string-in-java/)中做了更新。

#### StringBuilder 和 StringBuffer

StringBuilder 和 StringBuffer 比较类似，就放在一起比较。二者都是继承了类 AbstractStringBuilder，和 String 不同，它们都是 mutable 的，随时可以改变值。StringBuffer 拥有和 StringBuilder 部分相同的方法，下面截取了 JDK 的源码：

```java
 public final class StringBuffer extends AbstractStringBuilder
        implements java.io.Serializable, CharSequence {
    public synchronized StringBuffer insert(int offset, char c) {
        super.insert(offset, c);
        return this;
    }
}
```
```java
public final class StringBuilder extends AbstractStringBuilder
        implements java.io.Serializable, CharSequence {
    public StringBuilder insert(int offset, char c) {
        super.insert(offset, c);
        return this;
    }
```
可以看到在 StringBuffer 的方法里加入了关键字 synchronized 修饰，表明 StringBuffer 是线程安全的，相反的，StringBuilder 就是非线程安全。也正因此，StringBuffer 的处理效率不如 StringBuilder。到这，就算是理解了为什么 IDEA 会给出建议性的提示，把 StringBuffer 变量声明为 StringBuilder 变量。

#### 结论

把上面的异同汇总在下面的表格里

|  | String | StringBuilder | StringBuffer |
|:------:|:------:|:--------:|:--------:|
| 内存区 | 常量 String 池 | 堆 | 堆 |
| 线程安全 | 是 | 否 | 是 |
| 可变性 | 否 | 是 | 是 |
| 性能 | 快 | 快 | 慢 |

参考的应用场景
- String: 如果不需要改变字符串的值，考虑使用 String 变量；
- StringBuilder: 如果需要改变字符串的值，且只会被一个线程访问，可以使用 StringBuilder 变量；
- StringBuffer: 如果需要改变字符串的值，且可能被多个线程访问，使用 StringBuffer 变量以保证线程安全；