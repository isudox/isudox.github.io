---
title: Java String 在内存中的存储
date: 2016-06-22 13:00:53
tags:
  - Java
  - Memory
categories:
  - Coding
---

在之前写的一篇博客中（[String, StringBuilder, StringBuffer 区别](/2016/02/17/difference-between-string-stringbuilder-stringbuffer/)），提到了 String 对象在内存中的存储问题，当时只是一笔带过，在本篇里，对这个问题做一点深入的探讨。

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
- 栈 [statck](https://en.wikipedia.org/wiki/Stack-based_memory_allocation): 栈区是内存中遵循先进后出（LIFO）原则的一块存储区域。在现代计算机系统中，每个线程在内存中都保有自己的一段栈空间。栈区存储基本类型，如 int, char, double, float, boolean 等，以及对象的引用，比如 `int a = 1;` a 存储在栈区里。线程中方法的调用也记录在栈区中，使得方法的结果能返回到正确的位置。栈区内存由系统自动分配并释放；
- 堆 [heap](https://en.wikipedia.org/wiki/Memory_management#HEAP): 堆区存放由用户通过 new 操作创建的对象。系统不会自动释放堆区内存，比如 C 语言中执行 `malloc` 分配内存，执行 `free` 释放被占用的内存。Java 因为 GC 机制，由 JVM 承担了手动释放内存的操作。

```c
int foo()
{
    char *pBuffer; //<--nothing allocated yet (excluding the pointer itself, which is allocated here on the stack).
    bool b = true; // Allocated on the stack.
    if(b)
    {
        //Create 500 bytes on the stack
        char buffer[500];
        //Create 500 bytes on the heap
        pBuffer = new char[500];
    }//<-- buffer is deallocated here, pBuffer is not
}//<--- oops there's a memory leak, I should have called delete[] pBuffer;
```