---
title: Spring AOP 那些事儿
date: 2017-05-24 19:25:56
tags:
  - Java
  - Spring
categories:
  - Coding
---

AOP 即 Aspect-Oriented Programming，**面向切面编程**，是对 OOP 编程思想的补充。OOP 核心是继承、封装、多态，是实现 OOP 模块化的基础。当 OOP 达到一定规模后，对于遍布各处的横向代码的处理就开始捉襟见肘，而 AOP 正好弥补了这个不足。

<!-- more -->

## 引入 AOP

下图是很常见的编程场景──

![redundant code](https://o70e8d1kb.qnssl.com/redundant_code.png)

我们经常会遇到需要在多个方法中实现相同的一部分功能，面向过程的办法就是像图示在每个方法里都复制粘贴相同的一段代码，但是如果要改动就要改动 N 处代码。在有了 OOP 思想后，我们就进阶了一大步，可以将相同的代码段抽离出来，避免了到处改动的问题。

![clean code](https://o70e8d1kb.qnssl.com/clean_code.png)

一般像上图去实现代码就能应付大多数场景了。但随着软件规模的升级，有些问题就开始凸显了。首先共同功能的实现需要在各个方法中显示的去调用；其次，共同功能的控制权分散在代码各处；再次，对共同功能的依赖加重了类之间的耦合，降低了可重用性，如果共同功能并非各个方法的核心功能，那么就不应该耦合进各个对象中。AOP 则可以解决这些问题。

AOP 把系统功能分为两部分：**核心关注点**，**横切关注点**。核心关注点是代码的主要逻辑，横切进多个模块，但不是模块主要逻辑的就是横切关注点。不是简单的把公共模块抽离出来，而是把那些与具体业务无关的，却为业务模块所共同调用的逻辑或责任封装起来，减少冗余代码，降低模块间耦合度，提升可维护性。

## 基本概念

### 什么是 AOP

《Sping 实战》中对 AOP 有一段非常形象的描述──

> 每家每户都需要用电，电力公司会安装电表会记录用电量，会派员工查电表。但是如果没有电表也没有人来查看用电量，相信大多数家庭都不会去记录电量并缴费，因为这不是家庭重点关注的问题。软件开发中，类似记录用电量这种散布于应用中多处的功能被称为**横切关注点**（cross-cutting concern），从概念上是与应用的业务逻辑相分离的（但往往会直接嵌入到业务逻辑中）。把横切关注点与业务逻辑相分离正是 AOP 所要解决的问题。

知道 AOP 大致是做什么的后，再来了解下 AOP 的专用术语：

- 切面 Aspect：横切关注点模块化的类；
- 连接点 Join point：程序的执行点，比如方法的执行，或者异常的处理。在 Spring AOP 中，连接点总是表示方法执行；
- 通知 Advice：切面在某个具体的连接点上执行的动作。且可以定义动作执行的时机，比如 `around`、`before`、`after` 等。包括 Spring 在内的许多 AOP 框架，都会把通知模块化成拦截器，围绕连接点构建拦截链；
- 切点 Poincut：匹配通知所要执行的一个或多个连接点。通常明确指定或者使用正则表达式匹配类名.方法。
- 引入 Introduction：即向已有的类添加新方法或属性。Spring AOP 允许向被通知的类添加新的接口（和其实现）。
- 目标对象 Target objection：被一个或多个切面通知的类。因为在 Spring 中，AOP 是通过运行时代理实现的，所以目标对象总是代理对象。
- AOP 代理：由 AOP 框架创建的为实现 aspect 的对象，在 Spring 中，AOP 代理是 JDK 动态代理或 CGLIB 代理。
- 织入 Weaving：把切面应用到目标对象并创建新的代理对象的过程。切面在指定的连接点被织入到目标对象中。织入可以在对象生命周期的编译期、类加载期、运行期完成。Spring AOP 因为采用动态代理，所以是在**运行期**完成织入。

### 代码演示

```java
@Component
public class PrinterServiceImpl implements PrinterService {

    public void run(String message) {
        System.out.println("Your message: " + message);
    }
}
```

```java
@Aspect
public aspect MethodAspect {

}
```

## Spring AOP

AOP 有多种实现方案，比如 [AspectJ](http://www.eclipse.org/aspectj/) 和 Spring AOP。前者需要安装 AspectJ 扩展包，在编译器生成 AOP 代理类，后者则是在运行时动态生成代理类。下文就 Spring AOP 的实现原理做简单的展开。

### 代理模式

> 通过在代理类中包裹切面，Spring 在运行期把切面织入到 Spring 管理的 bean 中。如下图所示，代理类封装了目标类，并拦截被通知方法的调用，再把调用转发给真正的目标 bean。当代理拦截到方法调用时，在调用目标 bean 方法之前，会执行切面逻辑。

![aop proxy model](https://o70e8d1kb.qnssl.com/aop-proxy.png)

Spring AOP 的实现本质上是采用了代理模式。

> 为其他对象提供一种代理以控制对这个对象的访问。──GoF《设计模式》

通俗的解释下代理模式，比如以前玩魔兽世界，如果南方玩家直接玩华北的服务器延迟会很高，于是有了各种游戏代理服务器，通过走代理直连游戏服务器可以有效缓解高延迟问题，还有 FQ 代理也是同样的道理。运用代理模式的目的是**对其他对象提供一种代理以控制对这个对象引用的访问**，这样设计的好处是，可以在目标对象实现的基础上，增强额外的功能操作，即扩展目标对象的功能。

代理模式包含 4 中角色，参考如下 UML 图：

* 主题接口：代理类和真实对象所实现的共同接口；
* 真实对象：被代理的对象，即实际引用的对象；
* 代理对象：封装了真实对象的代理类，并提供与真实对象相同的接口以便随时代替真实对象，同时可以对真实对象的操作进行加强；
* 客户端：代理对象的调用者；

![代理模式 UML](https://o70e8d1kb.qnssl.com/proxy-uml.png)

根据代理类的生成时期，可以分为静态代理和动态代理，静态代理是在编译期生成代理类的 `.class` 文件，动态代理是在运行时通过反射动态生成代理类。

#### 静态代理

参考 UML 图，我们可以用 Java 写一个简单的静态代理：

```java
// Manager 抽象类
abstract class Manager {

    private String name;

    abstract void handle(String param);

    String getName() {
        return name;
    }

    void setName(String name) {
        this.name = name;
    }
}
```

```java
// 具体的 Manager 实现
public class DepartmentManager extends Manager {

    public void handle(String param) {
        System.out.println("Today Plan: " + param);
    }

}
```

```java
// Manger 代理类
public class ManagerProxy extends Manager {

    private Manager manager;

    public ManagerProxy(Manager manager) {
        this.manager = manager;
    }

    public void handle(String param) {
        this.manager.handle(param);
    }

}
```

```java
// 测试
public class ManagerProxyTest {

    @Test
    public void handle() throws Exception {
        Manager manager = new DepartmentManager();
        manager.setName("Pay Team");
        Manager proxy = new ManagerProxy(manager);
        proxy.handle("Monthly Review");
    }
    // ----console output:-----
    // Today Plan: Monthly Review
}
```

上面的例子演示了代理模式的一个基本实现，不过有人可能会产生疑问，如果只是简单地让 Department Manager 去做一件事，为什么要费劲创建一个代理类去完成，这不是舍近求远吗？前面讲到了，代理模式的目的是为了控制对目标对象的引用，也就是说，如果对目标对象的需求有所变动，遵循开闭原则不应该直接修改目标对象的代码，通过代理类就能不侵入的实现。以上面的代码为例，如果 Department Manager 需要在制定今日任务前输出今日日期，在制定任务后签署姓名，在代理模式下，只需要对 Proxy 略微做修改即可改变真实对象引用的行为。修改后的代码如下──

```java
public class ManagerProxy extends Manager {

    private Manager manager;

    public ManagerProxy(Manager manager) {
        this.manager = manager;
    }

    public void handle(String param) {
        preHandle();
        this.manager.handle(param);
        postHandle();
    }

    private void preHandle() {
        System.out.println(new SimpleDateFormat("yyyy/MM/dd").format(new Date()));
    }

    private void postHandle() {
        System.out.println("Signed by: " + this.manager.getName());
    }
    // ----console output----
    // 2017/05/24
    // Today Plan: Monthly Review
    // Signed by: Pay Team
}
```

上述静态代理有个不好处理的地方，如果有 N 个真实对象，就需要指定 N 个代理类来代理，这增加了类的数量，代理类的代码也存在重复冗余，同事也损失了程序的灵活性。动态代理则是在程序运行时动态的生成代理类，可以灵活指定被代理的对象。

#### 动态代理



#### 小结

对代理模式做个简单的小结──

1. Subject 定义 ReaelSubject 和 Proxy 的公共接口，目的是让 Proxy 可以代替 RealSubject；
2. RealSubject 定义被代理的目标实体；
3. Proxy 会需持有目标对象的引用，使得代理可以访问到目标实体；
4. Proxy 对外提供和目标对象接口一致的实现，即直接通过代理替代目标实体；

> Spring AOP defaults to using standard JDK dynamic proxies for AOP proxies. This enables any **interface (or set of interfaces)** to be proxied.
> Spring AOP can also use CGLIB proxies. This is necessary to proxy classes rather than interfaces. CGLIB is used by default if a business object **does not implement an interface**.

### JDK Proxy

### CGLIB 

******

参考资料：

- [Spring 实战](https://book.douban.com/subject/26767354/)
- [Spring Docs](https://docs.spring.io/spring/docs/current/spring-framework-reference/html/aop.html)
- [Spring AOP 实现原理与 CGLIB 应用](https://www.ibm.com/developerworks/cn/java/j-lo-springaopcglib/)