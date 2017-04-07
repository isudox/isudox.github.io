---
title: 面试总结
tags:
  - Interview
categories:
  - Coding
---

在和 Leader 说明了要离职后，花了三天集中面试了几家想去的厂子，把面试中有价值的问题记录下来。我觉得面试是个挺好的查漏补缺的方式，很多东西自己以为明白，实则经不起推敲，就好像自以为代码没问题，一测发现全是 bug 一样……

<!-- more -->

## Java & Spring

#### 手写单例

这个没什么难度，主要考点在于私有构造函数，多线程并发访问时的单例失效和访问阻塞。常用的写法有双检法和 Effective Java 推荐写法。

#### 如何线程安全的使用 List

`Collections.synchronizedList(new ArrayList())` 可以返回一个线程安全的 List。需要注意的是，在返回的这个已经被同步的 List 中，迭代子操作必须要放在同步代码块中。

```java
List list = Collections.synchronizedList(new ArrayList());
    ...
synchronized (list) {
    Iterator i = list.iterator(); // Must be in a synchronized block
    while (i.hasNext()) {
        foo(i.next());
    }
}
```

#### SimpleDateFormat 是否线程安全



#### Spring AOP 的实现

#### Java 线程状态

Java 线程有 6 种状态：NEW、RUNNABLE、TIMED_WAITING、WAITING、BLOCKED、TERMINATED

-----------------

## 数据库

#### 对 ACID 的理解

我回答说是 4 个单词的首字母，然后就没然后了，居然只记得原子性这一个原则，给自己跪了……原子性 atomicity、一致性 consistency、隔离性 isolation、持久性 durability。

#### 水平分表的主键生成

单表被水平拆分后，就不能利用 auto_increment 自动生成主键了，会导致重复主键。

#### 学生课程分数表做统计

#### 大数据量时 Limit 分页查询优化

#### MySQL 事务隔离级别

Read Uncommitted、Read Committed、Repeatable Read、Serializable。MySQL 默认的事务隔离级别是 Repeatable Read。

-----------------


## 算法

#### 判断表达式的括号是否正确

比如 `{[()]}` 是正确的，`{[(])}` 是错误的。这道题很容易联想到栈这种数据结构：当读取到左括号时，将符号入栈；当读取到右括号时，从栈中出栈，如果出栈符号和当前符号是左右匹配的，则继续往下读取，直到最后一个符号。这道题还可以复杂一点，如果把场景设置为检验代码里括号的匹配是否正确，则还需要考虑代码里字符串中的括号，这种括号是不需要入栈出栈的。

#### 多个有序链表合并

#### 斐波那契数列的尾递归实现

先写出斐波那契数列的生成函数，递归实现很简单。但如果递归深度过大可能导致栈空间被爆，可以使用尾递归或 for 循环进行改写。

```java
// 递归
public static long recursiveFib(int n) {
    if (n == 1 || n == 2)
        return 1;
    return recursiveFib(n - 1) + recursiveFib(n - 2);
}

// 尾递归
public static long tailCallFib(int n) {
    if (n <= 2) return 1;
    return tailCallFib(0, 1, n);
}

// For 循环
public static long loopFib(int n) {
    if (n <= 2) return 1;
    long a = 1L;
    long b = 1L;
    long c = 0L;
    for (int i = 3; i <= n; i++) {
        c = a + b;
        a = b;
        b = c;
    }
    return c;
}

```

-----------------

## 设计模式

#### 工厂模式的实现方法

参考《设计模式》，就是两种：工厂方法模式（Factory Method），抽象工厂模式（Abstract Factory）。

-----------------

## 其他

#### ZooKeeper 如何实现负载均衡

#### 如何防止优惠券超发

#### Shell 文本处理

#### 手写爬虫脚本

面试官要求当场写一个 Hacker News 的爬虫，磕磕巴巴用编辑器写出来了，离开了 IDE 的 buff 本事得减半。

#### 用 Redis 设计一个简单的微博系统

#### Session Cookie 的区别

#### 项目架构图

比较尴尬，勉强画了张项目结构图，被面试官说，之前没画过架构图吧……