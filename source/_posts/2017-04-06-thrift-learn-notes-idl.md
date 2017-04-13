---
title: Thrift 学习笔记：IDL
date: 2017-04-06 11:08:26
tags:
  - RPC
  - Thrift
categories:
  - Coding
---

上月底来到了 M 记，氛围和风格都和 J 记有很大不同，很舒服。开发工作还在按照 Mentor 定制的计划学习适应中，部分技术栈之前没接触过，比如 RPC，M 记用的是自己改写的 Thrift，这两天也在看相关的文档，汇总成学习笔记。

<!-- more -->

Thrift 是由 Facebook 开源、Apache 维护的跨语言 RPC 框架。类似 Google 的 protobuf，Thrift 是典型的 C/S 架构，RPC 客户端和服务端间需要定义 IDL(Interface Description Language) 来实现跨语言通信。本文是对 Thrift IDL 学习的总结。

## 基础类型

参考官方[文档](http://thrift.apache.org/docs/types)，Thrift IDL 的基础类型覆盖了绝大多数编程语言的关键类型，共有以下 7 种：
- bool：布尔值，true 或 false
- byte：8-bit 有符号整数
- i16：16-bit 有符号整数
- i32：32-bit 有符号整数
- i64：64-bit 有符号整数
- double：64-bit 浮点数
- string：UTF-8 编码的字符串

文档中说明了，IDL 并没有包含无符号整型，这是由于很多编程语言并没有原生的无符号整型数。

## 特殊类型

Thrift IDL 支持 binary 类型，它是未编码字节序列，是 string 类型的特殊形式。binary 类型提高了和 Java 的互操作性，Thrift 计划在某个时候将其提升为基础类型。

## 结构体

Thrift 结构体定义了公共对象，基本等同于面向对象语言中的类，但没有继承特性。一个结构体有一组强类型的字段，每个字段都有唯一名称标识符。Thrift 接口文件中的结构体类型，编译后会转换成一个类，类的属性就是结构体中的各个类型字段，而类的方法就是对这些类型字段进行处理的相关函数。结构体类型的关键字是 `struct`，参考下面的 IDL 代码：

```idl
struct Student {
    1: i32 id;
    2: string name;
    3: i32 age;
    4: string sex;
    5: i32 grade;
}
```

对应的，Thrift 编译后生成下面的 Student 类：

```java
public class Student {
    private int id;
    private String name;
    private int age;
    private String sex;
    private int grade;
}
```

## 容器

Thrift 容器是强类型的，可以映射成大多数编程语言的容器。Thrift 包含 3 种容器——
- list：元素可重复的有序列表，对应 C++ STL 的 vector、Java 的 ArrayList、脚本语言中的原生数组；
- set：元素不可重复的无序列表，对应 STL 的 set、Java 的 HashSet、Python 的 set；
- map：key 严格唯一的 key-value 字典，对应 STL 的 map、Java 的 HashMap、Python/Ruby 的 字典；

容器元素可能是任意 Thrift 类型。

## 异常

Thrift 异常和结构体形式上类似，只是关键字是 exception，由指定语言的原生异常类派生，Java 的话，就是 `java.lang.Exception`。参考下面的 IDL 声明代码：

```idl
exception RequestException {
    1: i32 code;
    2: string message;
}
```

## 服务

Thrift 中的服务定义类似 OOP 语言中的接口（或纯虚函数）。Thrift 编译后，会创建客户端和服务端相应的函数和方法。服务中定义的每个方法都是具有返回类型的。另外，对于 void 方法，可以额外的加上 oneway 关键字，使得方法在执行时不会等待返回结果，直接异步处理。

## 枚举

Thrift 的枚举和 C/C++ 类似，由 `enum` 关键字声明：

```idl
enum UserType {
    VALID,
    INVALID,
    FROZEN
}
```

当 IDL 未对枚举赋值时，枚举型的第一个元素默认赋值为 0，并逐个递增。

## 类型定义

Thrift 通过关键字 `typedef` 对类型名进行自定义：

```idl
typedef i32 MyInt
typedef string Str
```

## 引入

Thrift 支持 `include` 关键字引入其他 thrift 文件，从而引入外部 thrift 文件中声明的类型。

```idl
include "test.thrift"

service MyService extends test.FacebookService{
}
```

## 小结

Thrift IDL 和 Java 的类型对应关系如下表所示：

| Thrift    | Java |
| :-------- | :---- |
| bool      | 布尔值 |
| byte      | 8 位有符号整型 |
| i16       | 16 位有符号整型 |
| i32       | 32 位有符号整型 |
| i64       | 64 位有符号整型 |
| double    | 64 位浮点数 |
| string    | UTF-8 编码的字符串 |
| struct    | 公共的对象 |
| list      | 元素可重复的有序列表，ArrayList |
| set       | 元素不可重复的无序列表，HashSet |
| map       | key 唯一的字典，HashMap |
| exception | Exception |
| service   | 服务的接口 |

*************************************************

参考资料：
- [Thrift Documentation](http://thrift.apache.org/docs/)
- [Thrfit Tutorial](http://thrift.apache.org/tutorial/java)