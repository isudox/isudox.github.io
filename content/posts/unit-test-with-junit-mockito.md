---
title: JUnit + Mockito 单元测试的风云际会
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

`thenReturn()` 返回的是一个确定值，这在模拟可见的行为时是没问题的，但有时候，我们需要得到一个复杂的不定输出的行为，比如返回一个回调方法，或者返回一个类实例，Mockito 可以通过 `thenAnswer()` 来实现。参考 StackOverflow 上的这篇问答 [Mockito : thenAnswer Vs thenReturn](http://stackoverflow.com/questions/36615330/mockito-thenanswer-vs-thenreturn)。

```java
    @Test
public void count() throws Exception {
    Duplicator counter = mock(Counter.class);
    Answer<Integer> answer = new Answer<Integer>() {
        public Integer answer(InvocationOnMock invocationOnMock) throws Throwable {
            return ((String) invocationOnMock.getArguments()[0]).length();
        }
    };
    when(counter.count(anyString())).thenAnswer(answer);
}
```

`InvocationOnMock` 接口提供了获取被测试方法的调用信息的几个重要方法：

  - `getMock()` 接口返回 mock 对象；
  - `getMethod()` 接口返回被调用方法的 Method 对象；
  - `getArguments()` 接口返回被测试方法的入参列表；
  - `getArgument()` 接口返回北侧方法指定位置的入参；
  - `callRealMethod()` 接口返回实际的调用方法；

上面的例子已经说明了 Mockito 能跟踪被 Mock 对象所有的方法调用和它们的入参。除了对方法调用结果是否正确的测试，有时还需要验证一些方法的行为，比如验证方法被调用的次数，验证方法的入参等，Mockito 通过 `verify()` 方法实现这些场景的测试需求。这被称为“行为测试”。

```java
@Test
public void testVerify() {
    Duplicator mock = mock(Duplicator.class);
    when(mock.getUniqueId()).thenReturn(43);

    mock.duplicate("Halo");
    mock.getUniqueId();
    mock.getUniqueId();

    verify(mock).duplicate(Matchers.eq("Halo"));
    verify(mock, times(2)).getUniqueId();
    verify(mock, never()).someMethod();
    verify(mock, atLeastOnce()).someMethod();
    verify(mock, atLeast(2)).someMethod();
    verify(mock, atMost(3)).someMethod();;
}
```

`verify()` 内的条件设置简洁明了，第一个参数是 mock 对象，第二个参数可选，作为状语描述，从方法的名称上就能知道具体的用法，不多赘述了。

Mockito 支持通过 `@Spy` 注解或 `spy()` 方法包裹实际对象，除非明确指定对象，否则都会调用包裹后的对象。这种方式实现了对实际对象的部分自定义修改。

```java
@Test
public void testSpy() {
    List<String> spyList = spy(new ArrayList<String>());

    assertEquals(0, spyList.size());

    doReturn(100).when(spyList).size();
    assertEquals(100, spyList.size());
}
```

上面的测试代码中，`spy()` 修改了 `ArrayList` 对象的 `size()`。但是如果只是在执行某个操作是返回一个期望值，用之前的 `mock()` 也能实现，`spy()` 存在的理由是什么，看下面的代码能解释二者之间的差异：

```java
@Test
public void differMockSpy() {
    List mock = mock(ArrayList.class);
    mock.add("one");
    verify(mock).add("one");
    assertEquals(0, mock.size());

    List spy = spy(new ArrayList());
    spy.add("one");
    verify(spy).add("one");
    assertEquals(1, spy.size());
}
```

从上面的运行结果可以看出，`mock()` 传入的是类，创建出来的是一个裸的实例，只是为了跟踪该实例下的方法调用，而不会对实例有其他副作用产生；而 `spy()` 传入的是类实例，它会对该实例进行包裹，创建出来的实例和源实例相同，唯一的不同在于，`spy()` 包裹后的实例可以对实例内部进行自定义的改动。

对于依赖注入，Mockito 支持通过 `@InjectMocks` 注解将被标记的对象自动注入，其依赖会由 mock 出来的对象实例来填充。Mockito 会依次尝试通过 constructor injection、 property injection 和 filed injection，注意，如果其中任一注入策略失败，Mockito 也不会报告错误，就必须自行解决依赖。

- **Constructor injection**：`@InjectMocks` 优先选择的注入策略，如果对象通过构造函数成功 mock 出来，则不会再进行后面的注入策略。
- **Property setter injection**：会首先根据属性的类型（如果类型匹配则忽略变量名），如果有多个匹配项，则选择 mock 名和属性名相同的变量进行注入。
- **Field injection**：同样首先根据域的类型（如果类型匹配则忽略变量名），如果有多个匹配项，则选择 mock 名和域名相同的变量进行注入。

参考下面的样例代码：

```java
public class ArticleManagerTest extends SampleBaseTestCase {
    @Mock
    private ArticleCalculator calculator;
    @Mock(name = "database")
    private ArticleDatabase dbMock; // note the mock name attribute
    @Spy
    private UserProvider userProvider = new ConsumerUserProvider();

    @InjectMocks
    private ArticleManager manager;

    @Test
    public void shouldDoSomething() {
        manager.initiateArticle();
        verify(database).addListener(any(ArticleListener.class));
    }
}

public class SampleBaseTestCase {
    @Before
    public void initMocks() {
        MockitoAnnotations.initMocks(this);
    }
}
```

上面代码中，`@InjectMocks` 注解会把 mock 出来的 `dbMock` 和 `calculator` 注入进 `manager` 中。`ArticleManager` 可以只有一个有参构造函数，或者只有无参构造器，或者都有。需要注意的是，Mockito 无法实例化 inner class、local class、abstract class 和 interface。

对需要注入的域，Constructor injection 会发生在下面的代码中：

```java
public class ArticleManager {
    ArticleManager(ArticleCalculator calculator, ArticleDatabase database) {
        // parameterized constructor
    }
}
```

Property setter injection 在下面的代码中完成：

```java
public class ArticleManager {
    // no-arg constructor
    ArticleManager() {  }

    // setter
    void setDatabase(ArticleDatabase database) { }

    // setter
    void setCalculator(ArticleCalculator calculator) { }
}
```

Field injection：

```java
public class ArticleManager {
    private ArticleDatabase database;
    private ArticleCalculator calculator;
}
```

**********************************

参考资料：
  - [JUnit4 Wiki](https://github.com/junit-team/junit4/wiki)
  - [Mockito Wiki](https://github.com/mockito/mockito/wiki)
  - [Getting Started with Mocking in Java using Mockit](https://dzone.com/articles/getting-started-mocking-java)
  - [Unit tests with Mockito - Tutorial](http://www.vogella.com/tutorials/Mockito/article.html)