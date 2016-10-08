---
title: Mockito + JUnit 单元测试的风云
tags:
  - Java
categories:
  - Coding
---

[JUnit](http://junit.org/junit4/) 是 2015 年 Java 开发者引用最多的库，是 Java 单元测试框架里无可争议的 No.1。JUnit 基本上能覆盖大部分接口的测试，但如果待测接口依赖外部服务，比如我之前写的这篇[小文](/2016/08/03/imitate-rpc-invoke-locally-by-spring-aop)里描述的情况，JUnit 就可能捉襟见肘了。而 [Mockito](http://mockito.org/) 在 Mock 数据方面功能强大，正好弥补了 JUnit 在这方面的不足。风云合璧，摩诃无量。

<!-- more -->

上面其实已经点到 JUnit 和 Mockito 的不同了，虽然二者都是运用在单元测试中，但 JUnit 侧重对接口的运行状态和结果的测试，而 Mockito 侧重 "Mock" 数据，即对对象的模拟，尤其是不容易构造的复杂对象。

JUnit + Mockito 组合的优势是显而易见的，对于服务化的系统，有了这个组合，就能实现各上下游模块并行开发，同时进行单元测试验证可用性，减少串行联调的时间。

### JUnit

> PS: 虽然 JUnit5 已经发布，但目前使用最多的还是 JUnit4，所以本文仍然基于 JUnit4。

利用 Maven 初始化一个简单的 Java 应用：

```shell
mvn archetype:generate -DgroupId=com.isudox -DartifactId=test-demo -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
```

Maven 会自动创建好类文件和测试类，路径如下：

```
test-demo
├── pom.xml       ---- pom 依赖配置文件
└── src           ---- 源码路径
    ├── main      ---- 类文件
    │   └── java
    │       └── com
    │           └── isudox
    │               └── App.java
    └── test      ---- 测试类
        └── java
            └── com
                └── isudox
                    └── AppTest.java
```

在 pom.xml 中引入 JUnit4，

```xml
<dependencies>
    <!-- junit4 -->
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.12</version>
        <scope>test</scope>
    </dependency>
</dependencies>
```

引入 JUnit 依赖后，就能在测试类中，通过 JUnit 提供的注解和静态方法，对接口进行测试了。先编写一个简单的待测试类 Calculator.java

```java
// App.java
public class Calculator {
    public int evaluate(String expression) {
        int sum = 0;
        for (String summand: expression.split("\\+"))
            sum += Integer.valueOf(summand);
        return sum;
    }
}
```

然后在 src/test/ 路径下创建同样的包，将测试类命名为 CalculatorTest.java，如果是用 IntelliJ IDEA，可以直接在待测试类下通过快捷键 Ctrl+Shift+T 生成相应的测试类——

```java
// CalculatorTest.java
import org.junit.*;
import static org.junit.Assert.*

public class CalculatorTest {
    @Test
    public void evaluate() throws Exception {
        Calculator calculator = new Calculator();
        int sum = calculator.evaluate("1+2+3");
        assertEquals(6, sum);
    }
}
```

在 IDE 下运行这个单元测试，查看结果。
上面这段简单的代码里，

### Mockito
pom.xml 依赖中添加 Mockito：
```xml
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>1.10.19</version>
    <scope>test</scope>
</dependency>
```


参考资料：
  - [JUnit4 Wiki](https://github.com/junit-team/junit4/wiki)
  - [Getting Started with Mocking in Java using Mockit](https://dzone.com/articles/getting-started-mocking-java)