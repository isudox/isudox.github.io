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
// 日志切面
@Aspect
@Component
public class LogAspect {

    @AfterReturning(pointcut = "execution(* com.isudox.service.impl.*.*(..))")
    public void log() {
        System.out.println("Job completed time: " + new Date());
    }
}
```

```java
// 事物切面
@Aspect
@Component
public class TransactionAspect {

    @Around("execution(* com.isudox.service.impl.*.*(..))")
    public Object transact(ProceedingJoinPoint joinPoint) throws Throwable {
        System.out.println("----Transaction begins----");
        Object result = joinPoint.proceed();
        System.out.println("----Transaction end----");
        return result;
    }
}
```

```xml
<!-- spring-aop-config.xml -->
<bean class="org.springframework.aop.aspectj.annotation.AnnotationAwareAspectJAutoProxyCreator"/>

<context:component-scan base-package="com.isudox"/>
<aop:aspectj-autoproxy/>
```

```java
// Main 方法
public class App {
    public static void main(String[] args) {
        ApplicationContext ctx = new ClassPathXmlApplicationContext("spring-aop-config.xml");
        PrinterService printer = ctx.getBean("printerServiceImpl", PrinterService.class);
        printer.run("Hello AOP");
    }
}
// ----Transaction begins----
// Your message: Hello AOP
// ----Transaction end----
// Job completed time: Thu Jun 01 16:27:37 CST 2017
```

## 代理模式

AOP 有多种实现方案，比如 [AspectJ](http://www.eclipse.org/aspectj/) 和 Spring AOP。前者需要安装 AspectJ 扩展包，在编译器生成 AOP 代理类，后者则是在运行时动态生成代理类。总之，AOP 的实现是基于代理模式，所以先介绍下代理模式这种经典的设计模式。

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

### 静态代理

参考 UML 图，我们可以用 Java 写一个简单的静态代理：

```java
// Manager 接口
public interface Manager {

    void handle(String param);

}
```

```java
// 具体的 Manager 实现
public class DepartmentManager implements Manager {

    public void handle(String param) {
        System.out.println("Today Plan: " + param);
    }
    
}
```

```java
// Manger 代理类
public class ManagerProxy implements Manager {

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
// 静态代理测试
public class ManagerProxyTest {

    @Test
    public void handle() throws Exception {
        Manager manager = new DepartmentManager();
        Manager proxy = new ManagerProxy(manager);
        proxy.handle("Monthly Review");
    }
    // ----console output:-----
    // Today Plan: Monthly Review
}
```

上面的例子演示了代理模式的一个基本实现，不过有人可能会产生疑问，如果只是简单地让 Department Manager 去做一件事，为什么要费劲创建一个代理类去完成，这不是舍近求远吗？前面讲到了，代理模式的目的是为了控制对目标对象的引用，也就是说，如果对目标对象的需求有所变动，遵循开闭原则不应该直接修改目标对象的代码，通过代理类就能不侵入的实现。以上面的代码为例，如果 Department Manager 需要在制定今日任务前输出 Manger 的职位，在制定任务后输出日期，在代理模式下，只需要对 Proxy 略微做修改即可改变真实对象引用的行为。修改后的代码如下──

```java
public class ManagerProxy implements Manager {

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
        System.out.println("Position: " + manager.getClass().getSimpleName());
    }

    private void postHandle() {
        System.out.println(new SimpleDateFormat("YYYY/MM/dd").format(new Date()));
    }
    // ----console output:-----
    // Position: DepartmentManager
    // Today Plan: Monthly Review
    // 2017/05/24
}
```

静态代理有其不足的地方，如果有 N 个真实对象，就需要指定 N 个代理类来代理；如果主题接口增加了方法，那么所有实现类和代理类都需要实现这个新方法。这无疑增加了代码维护的难度。另外，如果事先并不知道被代理的真实对象是什么，该如何实现代理。动态代理可以代理多个真实对象，并且可以动态指定，虽然在程序性能上不如静态代理，但在灵活性上显著优于静态代理。

### 动态代理

创建动态代理的方式有多种，可以通过 JDK 自带的 `java.lang.reflect` 包、[CGLIB](https://github.com/cglib/cglib) 实现。JDK 实现动态处理相对简单，核心是利用反射，先介绍 JDK 的动态代理实现。

#### JDK 动态代理

JDK 实现动态代理的过程如下：

1. 在运行期通过反射创建实现主题接口的代理类；
2. 代理类的字节码将在运行时生成并载入当前代理的 ClassLoader，运行时生成的 class，需要提供真实对象的一组接口，然后该 class 就标示已实现这一组接口，但此时创建的代理类还只是空壳，没有代理的实际作用，因为只是对外声称实现了接口，实际并没有；
3. 接口所声明的所有方法都会委托给调用处理器 `InvocationHandler` 作统一的处理，每个方法的调用都会经过 `InvocationHandler.invoke()` 方法，实现了对真实对象方法的调用，而无需对每一个方法都做一个实现；

这个过程主要涉及下面两个类：

* `java.lang.reflect.Proxy`：提供 `Proxy.newProxyInstance()` 生成代理类；
* `java.lang.reflect.InvocationHandler`：调用处理器，是一个接口，执行真实对象的方法时，会出发调用处理器的方法，动态生成的代理类需要完成的具体任务由调用处理器的实现来处理；

`Proxy.newProxyInstance()` 第一个参数是加载该代理类到 JVM 的类加载器；第二个参数是代理类需要实现的接口；第三个参数是调用处理器的实现。方法源码精简如下：

```java
public static Object newProxyInstance(ClassLoader loader,
                                      Class<?>[] interfaces,
                                      InvocationHandler h) {
    
    // 由类加载器和接口创建指定的代理类
    Class<?> cl = getProxyClass0(loader, interfacess);
    // 获得代理类的带参构造函数
    final Constructor<?> cons = cl.getConstructor(new Class[] {InvocationHandler.class});
    // 创建代理对象实例，参数为调用处理器
    return cons.newInstance(new Object[]{h});
}
```

`InvocationHandler` 中只有一个 `invoke()` 方法，第一个参数是代理类实例；第二个参数是被调用的方法；第三个参数是被调用方法的入参──

```java
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable;
```

实现一个动态代理的简单例子：

```java
// 动态代理类
public class DynamicProxy {

    private Manager manager;

    public DynamicProxy(Manager manager) {
        this.manager = manager;
    }

    public Object getProxyInstant() {
        return Proxy.newProxyInstance(
                manager.getClass().getClassLoader(),
                manager.getClass().getInterfaces(),
                new InvocationHandler() {
                    public Object invoke(Object proxy, Method method, Object[] args)
                            throws Throwable {
                        preHandle();
                        Object result = method.invoke(manager, args);
                        postHandle();
                        return result;
                    }
                }
        );
    }

    private void preHandle() {
        System.out.println("Position: " + manager.getClass().getSimpleName());
    }

    private void postHandle() {
        System.out.println(new SimpleDateFormat("YYYY/MM/dd").format(new Date()));
    }

}
```

```java
// 动态代理测试
public class DynamicProxyTest {
    @Test
    public void getProxyInstant() throws Exception {
        Manager manager = new DepartmentManager();
        System.out.println(manager.getClass());

        Manager proxy = (Manager) new DynamicProxy(manager).getProxyInstant();
        System.out.println(proxy.getClass());

        proxy.handle("Monthly Review");
    }
    // ----console output----
    // class com.isudox.proxy.DepartmentManager
    // class com.sun.proxy.$Proxy4
    // Position: DepartmentManager
    // Today Plan: Monthly Review
    // 2017/05/24
}
```

从运行结果可以看出，创建的动态代理类工作正常。

#### CGLIB 动态代理

CGLIB 又被称作子类代理，它的动态代理实现方式是通过转换字节码生成新的子类，从而扩展真实对象的功能。当需要被代理的真实对象是单纯的类时，就可以使用 CGLIB 子类代理来实现动态代理，当然对接口实现类也同样支持。

CGLIB 包下有 `MethodInterceptor` 接口，起到拦截方法调用的作用。CGLIB 动态代理类需要实现该接口，重写 `intercept()` 方法，把被调用的方法和入参传入给真实对象。

还用到 CGLIB 包下的 `Enhancer` 类，通过 `setSuperclass()` 设置父类，通过 `setCallback()` 设置回调方法，类似 `Proxy` 的 `invoke()` 方法。

参考下面的示例代码：

```java
// CGLIB 动态代理类
public class CglibDynamicProxy implements MethodInterceptor {

    private Object target;

    public CglibDynamicProxy(Object target) {
        this.target = target;
    }

    public Object getProxyInstant() {
        Enhancer enhancer = new Enhancer();
        enhancer.setSuperclass(this.target.getClass());
        enhancer.setCallback(this);
        return enhancer.create();
    }

    public Object intercept(Object o, Method method,
                            Object[] objects,
                            MethodProxy methodProxy) throws Throwable {

        preHandle();
        Object result = methodProxy.invokeSuper(o, objects);  // 调用父类即被代理类的方法
        postHandle();
        return result;
    }

    private void preHandle() {
        System.out.println("Position: " + target.getClass().getSimpleName());
    }

    private void postHandle() {
        System.out.println(new SimpleDateFormat("YYYY/MM/dd").format(new Date()));
    }
    
}
```

```java
// 测试
public class CglibDynamicProxyTest {
    @Test
    public void intercept() throws Exception {
        Manager manager = new DepartmentManager();
        System.out.println(manager.getClass());

        Manager proxy = (Manager) new CglibDynamicProxy(manager).getProxyInstant();
        System.out.println(proxy.getClass());

        proxy.handle("Monthly Review");
    }
    // ----console output----
    // class com.isudox.proxy.DepartmentManager
    // class com.isudox.proxy.DepartmentManager$$EnhancerByCGLIB$$56f0605c
    // Position: DepartmentManager
    // Today Plan: Monthly Review
    // 2017/05/24
}
```

从运行结果可以看出，代码里的 `proxy` 实例是被代理的真实对象的子类，这是和 JDK 动态代理明显不同的地方，因此 CGLIB 可以实现对非接口实现类的动态代理。

### 小结

对代理模式做个简单的小结──

1. Subject 定义 ReaelSubject 和 Proxy 的公共接口，目的是让 Proxy 可以代替 RealSubject；
2. RealSubject 定义被代理的目标实体；
3. Proxy 会需持有目标对象的引用，使得代理可以访问到目标实体；
4. Proxy 对外提供和目标对象接口一致的实现，即直接通过代理替代目标实体；

## Spring AOP 实现

在了解了动态代理的实现过程后，就可以深入源码对 Spring AOP 的实现原理一探究竟了。引用官方文档里的一段话──

> Spring AOP defaults to using standard JDK dynamic proxies for AOP proxies. This enables any **interface (or set of interfaces)** to be proxied.
> Spring AOP can also use CGLIB proxies. This is necessary to proxy classes rather than interfaces. CGLIB is used by default if a business object **does not implement an interface**.

简单地说，Spring AOP 对接口实现的类，默认采用 JDK 动态代理；对没有实现接口的类，则默认采用 CGLIB 实现动态代理。Spring 会自行判断，无需开发者人为去选择。

### JdkDynamicAopProxy

还是参考本文开头的 Spring AOP 示例代码，在执行 `run()` 方法处加断点 debug，可以看到 `PrinterService` 实例是代理对象实例：

![](https://o70e8d1kb.qnssl.com/spring-aop-breakpoint.jpeg)

因为目标对象实现了接口，Spring AOP 使用了内部封装的 `JdkDynamicAopProxy` 类实现动态代理，底层还是 JDK 动态代理。来看下它的源码──

```java
final class JdkDynamicAopProxy implements AopProxy, InvocationHandler, Serializable {
    ...
}
```

`Serializable` 无需赘述了，先来看 `AopProxy`：

```java
public interface AopProxy {
    // 通过 AopProxy 默认的类加载器获取新的代理对象
    Object getProxy();
    // 通过指定的类加载获取新的代理对象
    Object getProxy(ClassLoader classLoader);
}
```

再来看 `JdkDynamicAopProxy` 对 `AopProxy` 的实现：

```java
@Override
public Object getProxy() {
    return getProxy(ClassUtils.getDefaultClassLoader());
}

@Override
public Object getProxy(ClassLoader classLoader) {
    if (logger.isDebugEnabled()) {
        logger.debug("Creating JDK dynamic proxy: target source is " + this.advised.getTargetSource());
    }
    Class<?>[] proxiedInterfaces = AopProxyUtils.completeProxiedInterfaces(this.advised, true);
    findDefinedEqualsAndHashCodeMethods(proxiedInterfaces);
    // 调用 JDK Proxy 生成代理对象实例
    return Proxy.newProxyInstance(classLoader, proxiedInterfaces, this);
}
```

参考前文讲的 JDK 动态代理，`Proxy.newProxyInstance()` 方法传入类加载器，被代理的接口，以及 InvocationHandler 实现，生成动态代理对象的实例。

`JdkDynamicAopProxy` 中对 `InvocationHandler.invoke()` 的实现本质上和前面的实例代码也是一样的。

### CglibAopProxy

从源码中还能看到，在 Spring AOP 中，`AopProxy` 还有一个实现，就是 `CglibAopProxy`，这个类封装了 CGLIB 创建动态代理的实现。其定义如下：

```java
class CglibAopProxy implements AopProxy, Serializable {
    ...
}
```

奇怪的是，这似乎和之前自己实现的 `CglibDynamicProxy` 不一样，它没有实现 CGLIB 的 `MethodInterceptor`。这里有一点需要注意，代理类实例实际上是由 `Enhancer.create()` 生成的，而在构建 `Enhancer` 实例时，需要通过 `Enhancer.setCallback()` 设置回调方法，这个回调方法是 `MethodInterceptor` 的具体实现。所以只需要将回调方法实现 `MethodInterceptor` 即可。具体看源码是怎么做的：

```java
@Override
public Object getProxy(ClassLoader classLoader) {
    // 配置 CGLIB Enhancer
    Enhancer enhancer = createEnhancer();
    enhancer.setSuperclass(proxySuperClass);
    enhancer.setInterfaces(AopProxyUtils.completeProxiedInterfaces(this.advised));
    enhancer.setNamingPolicy(SpringNamingPolicy.INSTANCE);
    enhancer.setStrategy(new ClassLoaderAwareUndeclaredThrowableStrategy(classLoader));

    // 获取回调方法，即 MethodInterceptor 的实现
    Callback[] callbacks = getCallbacks(rootClass);
    ...
    // 生成代理类并创建代理实例
	return createProxyClassAndInstance(enhancer, callbacks);
}

protected Object createProxyClassAndInstance(Enhancer enhancer, Callback[] callbacks) {
    enhancer.setInterceptDuringConstruction(false);
    // 在这设置了回调方法 callbacks
    enhancer.setCallbacks(callbacks);
    return (this.constructorArgs != null ?
            enhancer.create(this.constructorArgTypes, this.constructorArgs) :
            enhancer.create());
}
```

从源码中可以发现，`CglibDynamicProxy` 是通过调用 `getCallbacks()` 来获取回调方法的，再看它的代码：

```java
private Callback[] getCallbacks(Class<?> rootClass) throws Exception {
    ...
    // Choose an "aop" interceptor (used for AOP calls).
	Callback aopInterceptor = new DynamicAdvisedInterceptor(this.advised);
    ...
}

private static class DynamicAdvisedInterceptor implements MethodInterceptor, Serializable {
    @Override
    public Object intercept(Object proxy, Method method, Object[] args, MethodProxy methodProxy)
            throws Throwable {
        ...
    }
}
```

`DynamicAdvisedInterceptor` 确实是实现了 `MethodInterceptor`。

## Q&A

Q: 为什么 JDK 只能动态代理接口实现类，而不能对类创建动态代理？
A: 因为 Java 是单继承的，每个代理类都继承了 Proxy 类，因此不能对类创建代理类，只能对接口实现类。

Q: JDK 如何确保对代理对象方法的调用都会经过调用处理器 `InvocationHandler.invoke()` 方法？
A: JDK 在创建动态代理类时，内部的过程可以简单理解为下面的过程，所以只要是对代理类方法的调用，都会经过 `invoke()` 处理。
```java
public final class $Proxy1 extends Proxy implements Subject{
    private InvocationHandler h;
    private $Proxy1() {}
    public $Proxy1(InvocationHandler h) {
        this.h = h;
    }
    public int request(int i) {
        Method method = Subject.class.getMethod("request", new Class[] {int.class});
        return (Integer) h.invoke(this, method, new Object[] {new Integer(i)});
    }
}
```

Q: 代理模式和装饰器模式的区别？
A: 这两种设计模式非常相似，都是用一个类包装目标类，但在使用目的上有些许不同。代理模式侧重增强对目标对象的控制，装饰器模式侧重对目标对象的增强。

******

参考资料：

- [Spring 实战](https://book.douban.com/subject/26767354/)
- [Spring Docs](https://docs.spring.io/spring/docs/current/spring-framework-reference/html/aop.html)
- [Spring AOP 实现原理与 CGLIB 应用](https://www.ibm.com/developerworks/cn/java/j-lo-springaopcglib/)