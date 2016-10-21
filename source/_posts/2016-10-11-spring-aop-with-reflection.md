---
title: 敏捷开发实战：Spring AOP + 反射
tags:
  - Java
  - Spring
categories:
  - Coding
date: 2016-10-11 11:40:04
---


双十一前遭到产品突袭，要把非自营商家的处方药购买流程改为预约流程（出于某种考虑），内心一万只草泥马呼啸而过，那么多接口只给几天时间怎么改的过来……好在需要调用的购物车服务已经为新的预约流程分离了单独的 Redis 存储分组，要做的工作就是在恰当的时候调用恰当的服务。

<!-- more -->

如果直接在原有的相关接口方法中进行修改，一方面改动面太大，另一方面回归测试的压力也大，这种侵入式的代码不可取；从本质上看，从购买流程改预约流程无非就是改变相关服务的调用，是对行为的改变，这正是 AOP 的施展舞台。通过 AOP 在切面上织入切点，由 Advice 改变切面的行为，配合反射，根据业务决定动态的调用适配的方法，在不影响原有流程的同时，实现了业务行为的改变。总而言之四个字——亦可赛艇！

Spring AOP 有多种写法，XML 写法的，Java 写法的，Java 的写法会比 XML 来的更灵活，但对 Spring 的版本要求会高一点。受 《Spring 实战》一书的影响，我倾向于 Java 写法（由于项目是基于 Spring 3.0.5，因此还是需要写一点 XML）。

### 写法一

#### 后端部分

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

#### 前端部分

虽然后端完成了对流程调用的拆分，但是前端是复用的同一个工程，也就是说，还需要对来自同一个页面的请求进行分离，这样才能在上面的 Java 代码中完成 `if-else` 条件。具体就是区别哪些请求是调用原有的购物流程，哪些请求是调用新的预约流程。

思路很简单，先在页面模板上种下一个隐藏域作为不同业务流程的区分，如果业务是预约流程，就拦截所有来自这个页面的 Ajax 请求，修改其请求参数，然后再放行。其实就是前端的拦截器，而 jQuery 自带能拦截 Ajax 请求的神器方法—— `jQuery.ajaxPrefilter()`，参考 jQuery 的 API [文档](http://api.jquery.com/jquery.ajaxprefilter/)。

```javascript
$.ajaxPrefilter(function(options, originalOptions, jqXHR) {
  // Modify options, control originalOptions, store jqXHR, etc
});
```

`jQuery.ajaxPrefilter()` 必须传入一个 `handler` 函数，用来完成对被拦截到的 Ajax 请求的自定义。`handler` 方法内包含 3 个参数：

- `option` 从请求中获取到的参数字典；
- `originalOptions` 是原始传给 `$.ajax()` 方法的字典对象，没有被修改过，也就是说，不包含由 `$.ajaxSetup` 设置的参数（如果有的话）；
- `jqXHR` 是请求的 jqXHR 对象；

所以，前端的 Ajax 请求拦截器可以这么写：

```javascript
// 拦截 Ajax 请求，并修改请求参数，再放行
$.ajaxPrefilter(function (options, originalOptions, jqXHR) {
    if ($('#hidden_type').val() === 'xyz') {
        options.data += '&type=xyz';
    }
});
```

上面还提到了 `$.ajaxSetup` 方法，它和 `$.ajaxPrefilter` 的区别可以参考 stackoverflow 上的这篇问答 [$.ajaxPrefilter() Vs $.ajaxSetup() - jQuery Ajax](http://stackoverflow.com/questions/29843732/ajaxprefilter-vs-ajaxsetup-jquery-ajax)。简单总结下，`$.ajaxSetup` 用来对页面上的 Ajax 请求设置预设值，比如预设 url 参数，这是在 Ajax 请求发出前；`$.ajaxPrefilter` 用来修改页面上的 Ajax 请求里的参数，比如像上面一个增加一个参数，这是在请求发出后。这有点类似单元测试里的 `setup()` 和 `tear_down()`。