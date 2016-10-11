---
title: JUnit + Mockito 单元测试的风云汇
tags:
  - Java
categories:
  - Coding
date: 2016-10-10 22:12:35
---


[JUnit](http://junit.org/junit4/) 是 2015 年 Java 开发者引用最多的库，是 Java 单元测试框架里无可争议的 No.1。JUnit 基本上能覆盖大部分接口的测试，但如果待测接口依赖外部服务，比如我之前写的这篇[小文](/2016/08/03/imitate-rpc-invoke-locally-by-spring-aop)里描述的情况，JUnit 就可能捉襟见肘了。而 [Mockito](http://mockito.org/) 在 Mock 数据方面功能强大，正好弥补了 JUnit 在这方面的不足。风云合璧，摩诃无量。

<!-- more -->

上面其实已经点到 JUnit 和 Mockito 的不同了，虽然二者都是运用在单元测试中，但 JUnit 侧重对接口的运行状态和结果的测试，而 Mockito 侧重 "Mock" 数据，即对对象的模拟，尤其是不容易构造的复杂对象。

JUnit + Mockito 组合的优势是显而易见的，对于服务化的系统，有了这个组合，就能实现各上下游模块并行开发，同时进行单元测试验证可用性，减少串行联调的时间。

### JUnit

> PS: 虽然 [JUnit5](http://junit.org/junit5/) 已经发布，但目前使用最多的还是 JUnit4，所以本文仍然基于 JUnit4。

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
    public int evaluate(String expression) throws Exception {
        if (expression == null)
            throw new Exception("null value");
        int sum = 0;
        for (String summand: expression.split("\\+"))
            sum += Integer.valueOf(summand);
        return sum;
    }
}
```

然后在 src/test/ 路径下创建同样的包，将测试类命名为 CalculatorTest.java，如果是用 IntelliJ IDEA，可以直接在待测试类下通过快捷键 Ctrl+Shift+T 生成对应的测试类——

```java
// CalculatorTest.java
import org.junit.Test;
import static org.junit.Assert.*;

public class CalculatorTest {
    @Test
    public void evaluate() throws Exception {
        Calculator calculator = new Calculator();
        int sum = calculator.evaluate("1+2+3");
        assertEquals(6, sum);
    }
}
```

执行 `mvn test`，反馈得接口运行正确。
在上面这段简单的代码里，引入了 JUnit 的 `@Test` 注解和 `Assert` 下的系列静态断言方法。其中 `@Test` 注解把方法包装为测试方法，`assertEquals` 方法用来断言两个入参是否一致。通过这个简单的例子就实现了对待测方法的测试。

JUnit 支持丰富的测试规则，除了 `@Test` 注解外，还有下面这些注解——

- `@Before` 注解的作用是使被标记的方法在测试类里每个方法执行前调用；同理 `After` 使被标记方法在当前测试类里每个方法执行后调用。
- `@BeforeClass` 注解的作用是使被标记的方法在当前测试类被实例化前调用；同理 `@AfterClass` 使被标记的方法在测试类被实例化后调用。
- `@Ignore` 注解的作用是使被标记方法暂时不执行。

参考下面这段代码的运行：

```java
import org.junit.*;
import static org.junit.Assert.*;

public class CalculatorTest {

    public CalculatorTest() {
        System.out.println("Constructor");
    }

    @BeforeClass
    public static void beforeThis() throws Exception {
        System.out.println("BeforeClass");
    }

    @AfterClass
    public static void afterThis() throws Exception {
        System.out.println("AfterClass");
    }

    @Before
    public void setUp() throws Exception {
        System.out.println("Before");
    }

    @After
    public void tearDown() throws Exception {
        System.out.println("After");
    }

    @Test
    public void evaluate() throws Exception {
        Calculator calculator = new Calculator();
        int sum = calculator.evaluate("1+2+3");
        assertEquals(6, sum);
        System.out.println("Test evaluate");
    }

    @Test
    public void idiot() throws Exception {
        assertTrue(true);
        System.out.println("Test idiot");
    }

    @Ignore
    public void ignoreMe() throws Exception {
        System.out.println("Ignore");
    }

}
```

测试结果如下，从输出结果可以印证不同注解对执行顺序的影响：

```
BeforeClass
Constructor
Before
Test idiot
After
Constructor
Before
Test evaluate
After
AfterClass
```

另外，每个测试方法执行时都会实例化一次测试类，JUnit 这样处理的原因是保证每个测试方法彼此独立互不干扰。

对于 `@Test` 注解标记的方法，`@Test` 支持两个参数的设置：`timeout` 和 `expected`。前者是设置待测方法的执行超时时间，后者是设置对待测方法期望的抛出异常。修改 `evaluate` 测试方法的注解：

```java
@Test(timeout = 100, expected = Exception.class)
public void evaluate() throws Exception {
    Calculator calculator = new Calculator();
    int sum = calculator.evaluate(null);
    assertEquals(6, sum);
    i++;
    System.out.println("Test evaluate " + i);
}
```

Maven 运行测试，从结果可以看到，方法抛出了异常，测试通过。

### Mockito

相对于 JUnit，Mockito 则是 Mock 数据的测试框架，它简化了对有外部依赖的类的单元测试。Mockito 的工作流程如下图示（[图片来源](http://www.vogella.com/tutorials/Mockito/article.html)）：

![](https://o70e8d1kb.qnssl.com/mockito.webp)

首先在 pom.xml 中导入 mockito 依赖，

pom.xml 依赖中添加 Mockito：
```xml
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>2.2.0</version>
    <scope>test</scope>
</dependency>
```

再静态导入 `org.mockito.Mockito.*;` 里的静态方法，这样就能在测试方法进行对象的 Mock。Mockito 支持通过静态方法 `mock()` 来 Mock 对象，或者通过 `@Mock` 注解，来创建 Mock 对象，但必须将其实例化。先演示下如何 Mock 对象：

```java
import static org.mockito.Mockito.*;

@Test
public void mockIterator() {
    Iterator i = mock(Iterator.class);
    when(i.next()).thenReturn("hello").thenReturn("world");
    String result = i.next() + " " + i.next();
    assertEquals("hello world", result);
}
```

mock 出来的对象拥有和源对象同样的方法和属性，`when()` 和 `thenReturn()` 方法是对源对象的配置，怎么理解，就是说在第一步 `mock()` 时，mock 出来的对象还不具备被 Mock 对象实例的行为特征，而 `when(...).thenReturn(...)` 就是根据条件去配置源对象的预期行为，即：当执行 `when()` 中的操作时，返回 `thenReturn()` 中的结果。比如上面的代码中，mock 出来的 `i` 实例在被遍历时会依次输出 "hello" 和 "world"，`assertEquals()` 就是对预期结果和实际结果的判断。

同理，也可以 Mock 网络请求，比如 `HttpServletRequest` 里的参数，也可以通过上面的方式来设定被 Mock 的源对象的表现行为。

对于 `when()` 不定条件，Mockito 定义了 `any()`、 `anyInt()`、`anyString()`、`anySet()` 等方法来匹配指定类型的不定输入，`anyInt()` 匹配 int 参数，`anyString()` 匹配 String 参数, `any()` 匹配 任意类型的参数。如果需要匹配自定义的类型，可以通过 `any(CustomedClass.class)` 来配置。

`when()` 中可以设置不定条件，但如果想获得不定的返回值呢，比如返回一个方法的执行结果，而不是像上面那样返回一个确定值，Mockito 可以通过 `thenAnswer()` 方法来返回自定义方法的执行结果。参考 StackOverflow 上的这篇问答 [Mockito : thenAnswer Vs thenReturn](http://stackoverflow.com/questions/36615330/mockito-thenanswer-vs-thenreturn)

```java
@Test
public void testAnswer() throws Exception {
    Dummy dummy = mock(Dummy.class);
    Answer<Integer> answer = new Answer<Integer>() {
        public Integer answer(InvocationOnMock invocation) throws Throwable {
            String string = invocation.getArgumentAt(0, String.class);
            return string.length() * 2;
        }
    };
    when(dummy.stringLength("dummy")).thenAnswer(answer);
    doAnswer(answer).when(dummy).stringLength("dummy");
}
```

**********************************

参考资料：
  - [JUnit4 Wiki](https://github.com/junit-team/junit4/wiki)
  - [Mockito Wiki](https://github.com/mockito/mockito/wiki)
  - [Getting Started with Mocking in Java using Mockit](https://dzone.com/articles/getting-started-mocking-java)
  - [Unit tests with Mockito - Tutorial](http://www.vogella.com/tutorials/Mockito/article.html)