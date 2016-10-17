---
title: 敏捷开发实战：Spring AOP + 反射
tags:
  - Java
  - Spring
categories:
  - Coding
date: 2016-10-11 11:40:04
---


双十一前遭到产品突袭，要把非自营商家的处方药购买流程改为预约流程（出于某种考虑），内心一万只草泥马呼啸而过，那么多接口只给几天事件怎么改的过来……好在需要调用的购物车服务已经为新的预约流程分离了单独的分组，要做的工作就是在恰当的时候调用恰当的服务。

<!-- more -->

如果直接在原有的相关接口方法中进行修改，一方面改动面太大，另一方面回归测试的压力也大，这种侵入式的代码不可取；从本质上看，从购买流程改预约流程无非就是改变相关服务的调用，是对行为的改变，这正是 AOP 的施展舞台。通过 AOP 在切面上织入切点，由 Advice 改变切面的行为，配合反射，根据业务决定动态的调用适配的方法，在不影响原有流程的同时，实现了业务行为的改变。总而言之四个字——亦可赛艇！

Spring AOP 有多种写法，XML 写法的，Java 写法的，Java 的写法会比 XML 来的更灵活，但对 Spring 的版本要求会高一点。受 《Spring 实战》一书的影响，我倾向于 Java 写法（由于项目是基于 Spring 3.0.5，因此还是需要写一点 XML）。

### 写法一

假设创建的 AOP 类为 `DemoAspect`，在 Spring 的配置文件中，将其注册到 aop 配置中：

```xml
<bean id="demoAspect" class="com.isudox.aspect.DemoAspect"/>
<aop:aspectj-autoproxy>
  <aop:include name="demoAspect"/>
</aop:aspectj-autoproxy>
```

把流程改造相关的服务 bean 再次声明一份，修改其 id 和新流程的分组，以作为新流程所需服务的 bean（配置就省略了）。下面用 Java 的方式来声明切面和织入的方法：

```java
@Aspect
public class DemoAspect {
    @Resource
    private CartService cartService2;

    @Around("bean(cartService)")
    public Object advice(ProceedingJoinPoint joinPoint) throws Throwable {
        Object result;
        try {
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            Method method = signature.getMethod();
            String clazz = method.getDeclaringClass().getSimpleName();
            Object[] args = joinPoint.getArgs();
            if (...) {
                // 新的流程
                BeanClass bean = getBean();
                result = method.invoke(bean, args);
            } else {
                // 既定流程
                result = joinPoint.proceed();
            }
        } catch (Exception e) {
            throw e;
        }
        return result;
    }
}
```

思路很简单，`@Aspect` 注解将 DemoAspect 声明为一个 Aspect，`@Around("bean(cartService)")` 注解则将织入方法 `advice` 声明为织入名为 cartService 的 bean 的方法，意在运行时修改 cartService 里所有方法的行为。
