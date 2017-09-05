---
title: Java 8 Stream API 和函数式编程
date: 2017-07-12 11:10:03
tags:
  - Java
categories:
  - Coding
---

流式操作我们在很多地方都使用过，比如 Shell 操作时经常用到的 `ps aux | grep xxx`、Python 中的 `mapreduce` 方法。Java 8 也引入了 Stream API，并且加入 Lambda 表达式，使得函数也可以成为像类一样的一等公民。

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

先来看下 Java 7 和 Java 8 实现同一个功能的两种写法。有一组 Person 信息，要从中筛选出所有成年人的名字，并按年龄排序：

```java
// Java 7
public static List<String> getAdultNamesInJava7(List<Person> persons) {
    List<Person> adults = Lists.newArrayList();
    for (Person p : persons) {
        if (p.getAge() >= 18) {
            adults.add(p);
        }
    }
    List<String> adultName = Lists.newArrayList();
    Collections.sort(adults, new Comparator<Person>() {
        @Override
        public int compare(Person o1, Person o2) {
            return Integer.compare(o1.getAge(), o2.getAge());
        }
    });
    for (Person p : adults) {
        adultName.add(p.getName());
    }
    return adultName;
}

// Java 8
public static List<String> getAdultNamesInJava8(List<Person> persons) {
    return persons.stream()
            .filter(p -> p.getAge() >= 18)
            .sorted(comparing(Person::getAge))
            .map(Person::getName)
            .collect(toList());
}
```

比较上面的代码，使用 Stream API 实现的代码无论是代码简洁程度和可读性上，都比 Java 7 的实现好很多。Stream API 的特点就是：
- 声明性──说明想完成什么，而不是说明如何实现，结合通过 Lambda 表达式传入的行为参数，代码简洁易读；
- 可复合──可以将多个基础操作连接成管道，来表达复杂的数据处理流水线；
- 可并行──流可以被并行处理，提升了性能；

分析上面 Java 8 的代码，首先对集合（即源）调用 `stream()` 方法获得流，filter、sorted、map、collect 都是对流的数据处理操作。其中，filter、sorted、map 是返回 `Stream` 对象，因此这几个操作复合为一个管道。最后调用 collect 处理流水线，并返回处理结果。整个处理流程就是：
- filter──通过 Lambda 表达式描述的行为，对 Stream 进行筛选，选择年龄大于 18 的 Person 实例；
- sorted──接受 Lambda 表达式对 Stream 进行排序；
- map──由 Lambda 表达式将 Person 转换为其他类型；
- collect──将流转换为其他形式；

## Stream 和 Collection

在使用 Java Collection 接口时，是开发者去实现迭代逻辑，比如 for-each 遍历：

```java
List<String> adultName = Lists.newArrayList();
for (Person p : adults) {
    adultName.add(p.getName());
}
```

for-each 显式迭代，并执行逻辑。而 Stream 是通过内部逻辑自行完成了迭代，只需要开发者提供声明性的语句告诉 Stream 该做什么：

```java
List<String> adultName = adults.stream()
                               .map(Person::getName)
                               .collect(toList());
```

Stream API 内置了很多数据处理操作来实现复杂的查询处理，这些强大的 API 是的迭代的逻辑隐藏进了 Stream 内部。这是 Stream 和 Collection 显著的区别。

## Stream API 的使用

前面的代码中，用到了一些 Stream API，可以将其分为两类：
- 中间操作（Intermediate）：类似 filter、sorted、map、limit 等都是返回流，可以将复合成流水线；
- 终端操作（Terminal）：类似 collect 等真正执行流水线任务；

中间操作只是把数据操作组合成一个查询，但并没有执行。数据处理的执行是在调用终端操作时开始。因此，流的使用包含三个部分：
- 数据源，提供元素序列；
- 中间操作，复合成流水线；
- 终端操作，执行流水线，并生成结果；

下表列出了常用的中间操作和终端操作。

![](https://o70e8d1kb.qnssl.com/java8_operations.png)

### 筛选

```java
List<Integer> nums = Arrays.asList(1, 2, 3, 4, 5);
nums.stream().fitler(n -> n % 2 == 0)
             .distinct()
             .forEach(System.out::println);
```

`filter` 方法接受函数描述符为 T -> boolean 的行为参数作为谓词，通过该行为参数来返回符合条件的元素的流。配合 `distinct` 筛选元素唯一的流，`limit` 方法则是截断流，`skip` 方法是跳过元素。

### 映射

```java
List<String> names = adults.stream()
        .map(Person::getName)
        .collect(toList());
```

`map` 方法接受函数描述符为 T -> R 的 `Function` 实例作为行为参数，该行为参数会作用到流里的每个元素上，并映射成 R 类型的新元素。

### 查找和匹配

Stream API 提供了 `allMatch`、`anyMatch`、`noneMatch`、`findFirst` 和 `findAny` 来实现对元素序列查找匹配的查询。`*Match` 方法接受返回布尔值的行为参数，查找结果为布尔值。

```java
if (persons.stream().anyMatch(Person::isAdult)) {
    System.out.println("This person is an adult.");
}
```

`find*` 方法可能从流中查找到复合条件的元素，也可能查找不到，它返回 `Optional`，`Optional<T>` 是一个容器类，用来盛装存在或者不存在的值。

```java
Optional<Person> adult = persons.stream()
                                .filter(Person::isAdult)
                                .findAny();
```

### Optional

`Optional` 可以让开发者避免 `NullPointerException` 的尴尬。在很多代码里，我们为了避免 NPE，会用防御性的检查 null 引用，如果一个对象的结构比较复杂，需要处理的属性嵌套比较深，null 检查会一层套一层……

```java
if (person != null) {
    Car car = person.getCar();
    if (car != null) {
        // ...
    }
}
```

任何一个可能为 null 的属性，都有检查的必要，这样的代码很强壮，但也很难看。`Optional` 的使用方式是，当变量可能存在也可能不存在时，就不应该声明为具体的类型，而是应该直接将其声明为 Optional<Object> 类型。
当这个变量实际存在时，Optional<Object> 会返回其值，当这个变量不存在时，则是返回 Optional.empty()，可以把它理解为 null，但它是真实有效的对象，不会产生 NPE。参考下面的实例：

```java
public class Person {
    private Optional<Car> car;
    public Optional<Car> getCar() {
        return car;
    }
}
public class Car {
    private Optional<Insurance> insurance;
    public Optional<Insurance> getInsurance() {
        return insurance;
    }
}
public class Insurance {
    private String name;
    public String getName() {
        return name;
    }
}
```

对于既有的代码，比如从 Map<String, Object> 中获取 value，随时可能会得到 null，使用 `Optional` 封装 value，就可以避免 if-else 代码块。

```java
Optional<Object> value = Optional.ofNullable(map.get("key"));
```

对代码中潜在值为 null 的对象，都可以通过 `Optional.ofNullable` 将其安全的转换为 Optional 对象。

对于执行方法过程中可能发生失败而捕获异常的 try-catch 代码块，也可以通过 Optional 让执行失败的方法返回 Optional 对象。

```java
try {
    return Optional.of(Integer.parseInt(str));
} catch(NumberFormatException e) {
    return Optional.empty();
}
```

结合 Java 8 和 Optional 可以让代码更加简洁可读，而且 Optional 是在编译期就处理了 null 问题，避免问题留到运行时发现和解决。

```java
Optional.ofNullable(text).ifPresent(System.out::println);

if (test != null) {
    System.out.print(test);
}

Optional.ofNullable(text).map(String::length).orElse(-1);

return text != null ? text.length() : -1;
```

### 归约

`reduce` 方法可以把流中的元素组合起来，给定一个初始值，然后依次对流中各个元素进行组合。例如元素求和、求均值、求 max/min 值等，实际上都是 `reduce` 操作。对于没有给定初始值的 `reduce` 操作，因为可能没有足够的元素，因此是返回 Optional 对象。


```java
numbers.stream().reduce(0, (a, b) -> a + b);

numbers.stream().reduce(0, (a, b) -> Integer.max(a, b));

Optional<Integer> min = numbers.stream().reduce(Integer::min);
min.ifPresent(System.out::println);
```

### 生成流

上面已经提到的方法中，都是从对集合调用 `stream` 方法得到流。还可以从值序列、数组、文件来创建流。
`Stream.of()` 方法可以显式的创建一个流：

```java
Stream<String> stream = Stream.of("Java 8 ", "Lambdas ", "In ", "Action");
stream.map(String::toUpperCase).forEach(System.out::println);
```

实际上，`Stream.of` 本身是调用了 `Arrays.stream` 方法创建流，也就是可以用过数组创建流：

```java
int[] numbers = {1, 2, 3, 4, 5};
int sum = Arrays.stream(numbers).sum();
```

对于文件操作，`java.nio.file.Files` 内置很多静态方法都会返回流。比如 `Files.lines` 方法将文件的各行转换成 String 流。

```java
// 查询文件中出现了多少个不同的单词
try {
    Files.lines(Paths.get("data.txt"), Charset.defaultCharset())
                                 .flatMap(line -> Arrays.stream(line.split(" ")))
                                 .distinct()
                                 .count();
}
```

还有一些场景，在数学概念上流是无限的，比如质数、勾股数对、斐波拿契数列等。它们不像从集合、文件创建流那样有固定的大小，Stream API 内置了 `iterate` 和 `generate` 方法来生成无限流。

`iterate` 方法接受一个初始值和 Lambda 表达式，Lambda 表达式是作用在初始值和每次作用后的结果值上的一个函数，可以理解为 f(x)、 f(f(x))...比如创建一个偶数流：

```java
Stream.iterate(0, n -> n + 2)
      .limit(10)
      .forEach(System.out::println);
```

`generate` 方法接受函数式接口 `Supplier` 实例作为参数，由 `Supplier.get` 方法生成新的值。比如创建一个随机数流

```java
Random r = new Random();
Stream.generate(r::nextInt)
        .limit(5)
        .forEach(System.out::println);
```

## 基准测试

Stream API 相比传统的写法，除了在灵活性和可读性上的提升，还可以在对集合执行流水线操作时，充分利用多核性能，而不用去人为的去拆分数据，分配多线程，还要避免可能的对同一个资源的竞争。`parallelStream` 方法可以把数据源转化为并行流，或者调用 `Stream.parallel` 方法也可以创建并行流。反过来，并行流可以通过 `Stream.sequential` 方法转化为顺序流。

引入 JMH 对 Stream 和 Collection 进行基准测试。
对集合采用传统的迭代写法，和用 Stream API 的写法，在

```java
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@State(Scope.Benchmark)
public class Benchmarks {

    private static int SIZE = 1000000;

    private static List<Integer> NUM = Lists.newArrayList();
    static {
        Random r = new Random();
        NUM = Stream.generate(r::nextInt)
                .limit(SIZE)
                .collect(toList());
    }

    @Benchmark
    public List<Double> loop() {
        List<Double> res = Lists.newArrayList();
        for (Integer i : NUM) {
            if (i % 2 == 0) {
                res.add(Math.sqrt(i));
            }
        }
        return res;
    }

    @Benchmark
    public List<Double> stream() {
        return NUM.stream()
                .filter(i -> i % 2 == 0)
                .map(Math::sqrt)
                .collect(toList());
    }

    @Benchmark
    public List<Double> pstream() {
        return NUM.parallelStream()
                .filter(i -> i % 2 == 0)
                .map(Math::sqrt)
                .collect(toList());
    }

    public static void main(String[] args) throws RunnerException {
        Options options = new OptionsBuilder()
                .include(Benchmarks.class.getSimpleName())
                .forks(1)
                .warmupIterations(5)
                .measurementIterations(5)
                .build();
        new Runner(options).run();
    }
}
```

```
# Run complete. Total time: 00:00:48

Benchmark           Mode  Cnt   Score    Error  Units
Benchmarks.loop     avgt    5  19.292 ± 13.102  ms/op
Benchmarks.pstream  avgt    5   8.188 ±  0.337  ms/op
Benchmarks.stream   avgt    5  21.923 ± 13.496  ms/op
```

从上面这个简单的基准测试结果中，大概能推断出，对于基本类型，在大数据量的操作时，Stream API 并行处理比传统的外部迭代在性能上有所提升。

## 调试

对 Stream API 的调试，IDEA 官方开发了一个 Plugin──[Java Stream Debugger](https://plugins.jetbrains.com/plugin/9696-java-stream-debugger) 来扩展 IDEA 中的 debug 工具。在 debug 的工具栏上增加了 Trace Current Stream Chain 按钮──
![](https://blog.jetbrains.com/idea/files/2017/05/Screen-Shot-2017-05-11-at-15.06.58.png)
打开跟踪调试窗口，IDEA 用图像化的方式把数据源整个执行过程展示出来。
![](https://blog.jetbrains.com/idea/files/2017/05/Screen-Shot-2017-05-11-at-15.06.18.png)

*************

参考资料：

- [Java 8 实战](https://book.douban.com/subject/26772632/)
- [Java 8 中的 Streams API 详解](https://www.ibm.com/developerworks/cn/java/j-lo-java8streamapi/)
- [Java 8 新特性：全新的 Stream API](http://www.infoq.com/cn/articles/java8-new-features-new-stream-api)
- [Java 8 Lambda 表达式 10 个示例](http://www.importnew.com/16436.html)
- [Lambda Expressions](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html)