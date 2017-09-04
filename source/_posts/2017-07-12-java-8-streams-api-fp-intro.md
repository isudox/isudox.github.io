---
title: Java 8 Stream API 和函数式编程
date: 2017-07-12 11:10:03
tags:
  - Java
categories:
  - Coding
---

流的操作在很多地方我们都使用过，比如 Linux Shell 操作时经常用到的 `ps aux | grep xxx`、Python 中的 `mapreduce` 方法等。

<!-- more -->

在引出主题前，先看一道简单的算法题，分别用 Java 和 Python 来实现。

> 给定的一个整型数组，将其中每个元素变为它的平方。

```java
public class Solution {
    public List<Integer> square(List<Integer> nums) {
        List<Integer> res = new ArrayList<>();
        for (Integer n : nums) {
            res.add(n * n);
        }
        return res;
    }
}
```

```python
class Solution(object):
    def square(self, nums):
        return [i ** 2 for i in nums]
```

上面两个实现都是对这个问题最直接的解法，遍历数组中每个元素，同时计算其平方。对于 Python 的算法，如果了解过 lambda 表达式的话，还可以想出下面这种写法──

```python
class Solution(object):
    def square(self, nums):
        return list(map(lambda x: x ** 2, nums))
```

而对于 Java，在 Java 8 以前是没办法像 Python 等脚本语言一样去处理的，但 Java 8 引入了 Stream API，使得 Java 也有了流式处理和 Lambda 表达式。因此，Java 解法可以这样写──

```java
public class Solution {
    private List<Integer> func(List<Integer> nums) {
        return nums.stream().map(n -> n * n).collect(Collectors.toList());
    }
}
```

使用 Stream API 一个直观的变化是，Java 代码更简洁了。

# Lambda 表达式

很多脚本语言都支持 Lambda 表达式，比如 JavaScript ES6 引入的箭头函数：

```javascript
var a = [ "Hydrogen", "Helium", "Lithium", "Beryl­lium" ];

var a2 = a.map(function(s){ return s.length });

var a3 = a.map( s => s.length );  // [ 8, 6, 7, 9 ]
```

又比如上面 Python 代码里的 lambda 关键字

```python
lambda x: x ** 2

def f(x):
    return x ** 2
```

## Lambda 表达式语法

在 Java 8 以前，如果想将行为传入方法中，往往是选择匿名类的方式。当匿名类的实现本身很简单，比如只有一个方法的接口，这种情况下匿名类的语法显得啰嗦、不清晰。Java 8 的 Lambda 表达式优化了匿名类里模板式的代码，其写法就是

```java
( [param,] [param,] ... ) -> expression
( [param,] [param,] ... ) -> { statements; }
```

![](https://o70e8d1kb.qnssl.com/lambda_sample.png)

它包含三部分：
  - 参数列表：由圆括号包裹、逗号分隔；
  - 箭头符号： `->` 把参数列表和 Lambda 主体分隔开；
  - Lambda 主体：是实现匿名表达式逻辑的主要部分，返回了 Lambda 的结果。如果有返回类型，必须由花括号包裹，如果是返回 `void` ，则非必须；

Lambda 表达式看起来非常像方法的声明，可以把它理解为是没有函数名的匿名函数。Lambda 表达式可以作为参数传递给方法或存储在 `FunctionalInterface` 变量中。

![](https://o70e8d1kb.qnssl.com/lambda_sample2.png)

在什么场景中可以运用 Lambda 表达式？现在已经知道，Lambda 表达式的两种使用方式：
- 赋给一个变量；
- 传递给一个接收函数式接口作为行为参数的方法；

总结一下，实际上就是在需要函数式接口的编程场景中。

## 函数式接口

Lambda 表达式可以作为参数递给方法，换句话说，Lambda 表达式本身可以作为方法的一个参数，它将行为参数化。
**函数式接口**是只定义一个抽象方法的接口。Java API 提供了很多函数式接口，如常用的 `Runnable`、`Comparator`、`Predicator` 等（类似 `Comparator` 有两个抽象方法，但 `equals()` 方法在元类中有实现，因此函数式接口的实例会默认实现它），并给函数式接口加上了 `@FunctionalInterface` 注解。当开发者需要编写自定义的函数式接口时，可以使用 `@FunctionalInterface` 注解，如果代码不符合函数式接口的原则，则在编译器就会抛出错误。

函数式接口定义的抽象方法，可以理解为一个动作，比如 `Runnable` 的 `run()` 方法，定义了运行线程这个动作。而 Lambda 表达式实际上就是通过内敛的形式为为函数式接口的抽象方法提供了具体实现，并把整个表达式作为函数式接口具体实现的实例。

参照数学里的函数 `y = f(x)`，函数式接口抽象方法可以抽取出这样一个函数描述符，比如前面提到的比较苹果的重量，就是 (Apple, Apple) -> int，即接收两个 Apple 变量作为参数，返回 int 结果的函数。而 Lambda 表达式的函数描述符必然是和函数式接口抽象方法是一致的（也包括泛型）。比如下面的例子──

```java
public void proc(Runnable r) {
    r.run();
}
proc(() -> System.out.println("Hello World!"));
```

其中的 Lambda 表达式的函数描述符是 `() -> void`，和 `Runnable` 接口中的 `run()` 方法的函数描述符是相同的，因此它可以作为 `Runnable` 行为参数，传递到 `proc()` 方法中。

## 方法引用

对于仅是调用特定方法的 Lambda 表达式，Java 8 提供了**方法引用**简化了 Lambda 表达式。方法引用可以直接访问类或者实例的方法，使得现有的方法定义可以重复使用，并像 Lambda 一样传递它们，而且在可读性上更进一步。

```java
list.sort((Apple a1, Apple a2) -> a1.getWeight().compareTo(a2.getWeight()));

list.sort(comparing(Apple::getWeight));
```

目标引用和目标方法由分隔符 `::` 分隔，例如上面的代码中，就是引用了 Apple 类中定义的 `getWeight()` 方法。方法引用是引用而非调用，所以方法名后是没有括号的。下面是 Lambda 及其等效方法引用的例子。

![](https://o70e8d1kb.qnssl.com/lambda_method_reference.png)

方法引用主要有三类──

- 指向静态方法的引用，如 String 的 `indexOf()` 方法，可以通过 `String::indexOf` 引用；
- 指向任意类型实例方法的引用，如 String 的 `length()` 方法，`String::length`；
- 指向现有对象的实例方法的引用，如 Apple 实例的 `getWeight()` 方法，`apple::getWeight`；

三种使用方式举例如下──

![](https://o70e8d1kb.qnssl.com/lambda_method_reference_usage.png)

## 使用场景

### 取代匿名类

如果在当前方法中新起一个线程去执行一个任务，通常的做法是通过实现 Runnable 的匿名类，它至少是需要 6 行代码，而其中具体行为代码只有 1 行，其他都是模板代码；而 Lambda 表达式来实现，只需要一行代码。

```java
new Thread(new Runnable() {
    @Override
    public void run() {
        System.out.println("Before Java8, too much code for too little to do");
    }
}).start();

new Thread(() -> System.out.println("In Java8, Lambda expression rocks !!")).start();
```

再举一个经常使用的栗子，对 Comparator 匿名类的使用和 Lambda 表达式的改进。

```java
Collections.sort(persons, new Comparator<Person>() {
    @Override
    public int compare(Person o1, Person o2) {
        return o1.getAge().compareTo(o2.getAge());
    }
});

Collections.sort(persons, (o1, o2) -> o1.getAge().compareTo(o2.getAge()));
```

### 对集合迭代

Stream API 和 Lambda 表达式的引入对 Java 集合的操作产生了很大影响（尤其是 Stream API）

```java
public void func1() {
    List<String> list = Arrays.asList("Java", "Python", "Scala", "Haskell", "Smalltalk");
    for (String e : list) {
        if (e.length() > 5) {
            System.out.println(e);
        }
    }
}

public void func2() {
    List<String> list = Arrays.asList("Java", "Python", "Scala", "Haskell", "Smalltalk");
    list.forEach(e -> {
        if (e.length() > 5) {
            System.out.println(e);
        }
    });
}
```

# Stream API

Java 8 为集合处理提供了新的 API──Stream API，Oracle 对 Stream 的[官方定义](http://www.oracle.com/technetwork/articles/java/ma14-java-se-8-streams-2177646.html)是：
> A sequence of elements from a source that supports aggregate operations.

- 元素序列：流提供了一个接口，可以访问特定元素类型的一组有序值。和集合不同的是，流实际上不存储元素，它只是在需要的时候进行计算。而集合是数据结构，目的是以特定的时间/空间复杂度存储和访问元素。流侧重计算，集合侧重数据。
- 源：即数据源，流通过它来获取数据并作计算，如集合、数组、I/O 资源。
- 数据处理操作：流支持像 SQL 操作和函数式编程中的常用操作（filter, map, reduce, find, match, sorted 等）。
- 管道操作：很多流操作本身就返回流，因此多个操作可以组合成链式调用。
- 内部迭代：和集合的外部迭代不同，流的迭代操作是在内部完成的。

![](https://o70e8d1kb.qnssl.com/java8_operations.png)

## 基准测试

## 调试

*************

参考资料：

- [Java 8 实战](https://book.douban.com/subject/26772632/)
- [Java 8 中的 Streams API 详解](https://www.ibm.com/developerworks/cn/java/j-lo-java8streamapi/)
- [Java 8 新特性：全新的 Stream API](http://www.infoq.com/cn/articles/java8-new-features-new-stream-api)
- [Java 8 Lambda 表达式 10 个示例](http://www.importnew.com/16436.html)
- [Lambda Expressions](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html)