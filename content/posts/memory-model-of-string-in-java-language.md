---
title: Java String 的内存模型
date: 2016-06-22 13:00:53
tags:
  - Java
categories:
  - Coding
---

在之前写的一篇博客中([String, StringBuilder, StringBuffer 区别](/2016/02/17/difference-between-string-stringbuilder-stringbuffer/))，提到了 String 对象在内存中的存储问题，当时只是一笔带过，在本篇里，对这个问题做一点深入的探讨。

<!-- more -->

#### 字符串比较

字符串几乎是 Java 语言里使用频率最高的类型了，尽管程序的各个角落都在使用字符串，但未必对它有完整、正确的认识。创建字符串变量通常有下面两种途径：
```java
String s1 = "hello,world!"; // 通过字面值
String s2 = new String("hello,world!"); // 通过 new 关键字
```
字符串 s1 和 s2 看起来似乎是一样的，那真的一样吗，上代码：
```java
public class Debug {
    public static void main(String[] args) {
        String s1 = "hello,world!";
        String s2 = new String("hello,world!");
        System.out.println(s1 == s2); // false
        System.out.println(Objects.equals(s1, s2)); // true
    }
}
```
值都是 "hello,world!" 的字符串，然而两种比较的方式所得到的结果却不相同。字符串 s1 是通过字面值创建，字符串 s2 是通过关键字 new 创建，在分析这两种创建字符串方式的区别之前，先比较下 `==` 操作符和 `equals()` 方法在进行字符串比较时的差异。

`==` 操作符比较的是两个对象的引用是否指向同一内存地址，如果内存地址相同，则返回 true；`equals()` 比较的只是两个字符串对象的引用指向的内存地址所存储的字面值，而忽略内存地址是否相同。这样再去看上面的代码，从输出结果逆推，s1 和 s2 的引用的值都是 "hello,world!"，因此调用 `equals()` 比较返回 true 不难理解，那 s1 和 s2 内存地址不同，又该怎么解释，下面就进入正题，探讨 Java 里 String 在内存中的存储模型。

#### 内存模型

内存有栈和堆这两个概念：
- 栈 [statck](https://en.wikipedia.org/wiki/Stack-based_memory_allocation): 栈区是内存中遵循先进后出（LIFO）原则的一块存储区域。在现代计算机系统中，每个线程在内存中都保有自己的一段栈空间。栈区存储基本类型，int, short, long, byte, float, double, boolean, char（注意，不包括 String，String 不是基本类型），以及对象的引用，比如 `int a = 1;` a 和 1 都存储在栈区，`Date date = new Date();` date 存储在栈区， new Date() 的对象则存储在堆区。线程中方法的调用也记录在栈区中，使得方法的结果能返回到正确的位置。栈区内存由系统自动分配并释放；
- 堆 [heap](https://en.wikipedia.org/wiki/Memory_management#HEAP): 堆区存放由用户通过 new 操作创建的对象。系统不会自动释放堆区内存，比如 C++ 中执行 `new` 分配内存，执行 `delete` 释放被占用的内存。Java 因为 GC 机制，由 JVM 承担了手动释放内存的操作。

栈因为严格遵循 LIFO， 其存取速度明显快于堆区。但栈区的数据和生命周期是在编译时就确定的，而堆区则可以在运行时动态分配内存空间。

下图展示了堆区和栈区存储内容的差异，图片来自 vikashazrati.files.wordpress.com
![](https://o70e8d1kb.qnssl.com/stacknheap.png)

用接近系统底层的 C++ 语言程序简单演示下堆区和栈区分配内存的示例
```cpp
// example.cpp
int foo()
{
    char *pBuffer; // 没有分配空间，除了指针本身，它被分配在了栈区
    bool b = true; // 分配在栈区
    if(b)
    {
        // 在栈区分配 500 byte 空间
        char buffer[500];
        // 在堆区分配 500 byte 空间
        pBuffer = new char[500];
    } // buffer 的内存被释放, pBuffer 的还存在
} // 如果没有执行 delete[] pBuffer，就会发生内存泄漏;
```

通过字面值和 `new` 关键字创建字符串对象引用 s1、s2 和字符串 "hello,world!" 分别都存储在内存什么地方，一个个分析。
字符串 "hello,world!" 在堆区申请空间存储，因为字符串是常量具有不可变性，它被存储在堆区的一块名叫 "String Constant Pool" 的字符串常量池中，字符串常量池中的字符串只存在一份，即如果常量池中已存在 "hello,world!"，那么 s1 不会在常量池中申请新的空间，而是直接把引用指向已存在的字符串内存地址。另外，s1 是字符串 "hello,world!" 的引用，存储在栈区。前面讲到，由关键字 `new` 创建的对象被分配在了堆区，但和字面值赋值不同的是，`new` 出来的对象不只是在分配在堆区的字符串常量池，在 `new` 一个新的 String 对象时，首先会在堆区创建该 String 对象，并让栈区的对象引用指向它，然后在常量池中查询是否已存在相同内容的字符串，如果有，就将堆区的空间和常量池中的空间通过 `String.inter()` 关联起来，如果没有，则在常量池中申请空间存放该字符串对象，再做关联。参考下面的代码和实例图。
```java
String s1 = "abc"; 
String s2 = "xyz";
String s3 = "123";
String s4 = "A";

String s5 = new String("abc");
char[] c = {'J', 'A', 'V', 'A'};
String s6 = new String(c);
String s7 = new String(new StringBuffer());
```
![](https://o70e8d1kb.qnssl.com/String-Constant-Pool.png)

#### 测试结果

梳理了那么多理论，还是要用实践来印证。测试下面的代码，看看结果如何——
```java
public class TestString {
    public static void main(String[] args) {
        // 由字面值创建字符串
        String s1 = "hello,world!";
        String s2 = "hello,world!";
        System.out.println(s1 == s2);
        System.out.println(Objects.equals(s1, s2));
        // 由 new 关键字创建字符串
        String s3 = new String("hello,world!");
        String s4 = new String("hello,world!");
        System.out.println(s3 == s4);
        System.out.println(Objects.equals(s3, s4));

        System.out.println(s1 == s3);
        System.out.println(s1 == s3.intern());

        String s5 = "hello,";
        String s6 = "world!";
        System.out.println(s1 == s5 + s6);
        System.out.println(s1 == "hello," + "world!");
        System.out.println(s3 == s5 + s6);
        System.out.println(s1 == (s5 + s6).intern());
    }
}

// output: true true false true false true false true false true
```