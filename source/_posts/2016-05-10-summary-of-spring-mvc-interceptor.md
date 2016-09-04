---
title: Spring MVC 拦截器使用小结
date: 2016-05-10 16:38:39
tags:
  - Java
  - Spring
categories:
  - Coding
---

之前用 Django 开发的时候，Django 内置的 middleware 提供了 login_required() 装饰器作登录拦截。强大的 Spring MVC 也支持拦截器，可以通过不算复杂的配置非常灵活的控制请求拦截策略。拦截器普遍用在用户登录验证上，也应用在其他需要对一些信息进行验证的场景下。

<!-- more -->

## 实现拦截

### 请求流程

Spring MVC 请求的生命周期
![](https://o70e8d1kb.qnssl.com/summary-of-spring-mvc-interceptor-1.png)

图示给出了一次请求从发送到处理到接收响应的整个过程，非常标准的 M-V-C。

### 接口实现

Spring MVC 拦截器由 `HandlerInterceptor` 实现。`HandlerInterceptor` 接口包含三个方法：
```java
public interface HandlerInterceptor {
    boolean preHandle(HttpServletRequest req, HttpServletResponse resp, Object handler) throws Exception;

    void postHandle(HttpServletRequest req, HttpServletResponse resp, Object handler, ModelAndView modelAndView) throws Exception;

    void afterCompletion(HttpServletRequest req, HttpServletResponse resp, Object handler, Exception ex) throws Exception;
}
```
从这三个方法名就能看出各自执行的事件节点：分别在请求处理之前、请求处理之后但在渲染视图之前、请求完成之后。

`preHandle()` 在请求进到 Controller 前就对请求进行预处理。如果处理结果返回 true 则请求放行并继续往下执行，进到 Controller 或 下一个拦截器中；如果处理结果为 false 则中断处理请求，直接返回响应。

`postHandle()` 只有当 `preHandle()` 返回 true 时才会执行，也就是在请求进入到 Controller 之后再执行。它可以对 `ModelAndView` 进行处理，再返回给前端进行渲染。

`afterCompletion()` 在请求被完整处理完成后执行，也就是在渲染视图后。

拦截器的关键就是在请求处理之前将其拦截，所以最重要的方法就是 `preHandle()`，它是必须要实现的，而 `postHandle()` 和 `afterCompletion()` 的实现可以为空。Spring MVC servlet.handler 包里内置的 `HandlerInterceptorAdapter` 适配器实现 `HandlerInterceptor` 接口的 `preHandle()` 方法。通常可以直接继承该适配器。

```java
public class ExampleInterceptor extends HandlerInterceptorAdapter {
    @Override
    public boolean preHandle(HttpServletRequest req, HttpServletResponse resp, Object obj) throws Exception {
        // hanle the request...
        if (OK) {
            System.out.println(req.GetRuestURI());
            return true;
        } else {
            resp.sendRedirect("http://isudox.com");
            return false;
        }
    }
}
```

### 拦截配置

Spring MVC 配置文件通过 `mvc:interceptors` 标签声明并配置拦截器链，拦截的顺序由声明的顺序确定。其中，`mvc:mapping` 标签指定要拦截的 URL 以及忽略的 URL，支持通配符；`bean` 标签指定处理该 URL 的拦截器。
```xml
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mvc="http://www.springframework.org/schema/mvc"
	xmlns:context="http://www.springframework.org/schema/context"
	xsi:schemaLocation="
        http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc-3.0.xsd
        http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.0.xsd
        http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-3.0.xsd">

    <mvc:interceptors>
        <bean class="org.springframework.web.servlet.i18n.LocaleChangeInterceptor" />
        <mvc:interceptor>
            <mapping path="/**"/>
            <exclude-mapping path="/admin/**"/>
            <bean class="org.springframework.web.servlet.theme.ThemeChangeInterceptor" />
        </mvc:interceptor>
        <mvc:interceptor>
            <mapping path="/secure/*"/>
            <bean class="org.example.SecurityInterceptor" />
        </mvc:interceptor>
    </mvc:interceptors>

</beans>
```

或者也可以通过 Java 代码来配置拦截器：
```java
@Configuration
@EnableWebMvc
public class WebConfig extends WebMvcConfigurerAdapter {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LocaleInterceptor());
        registry.addInterceptor(new ThemeInterceptor()).addPathPatterns("/**").excludePathPatterns("/admin/**");
        registry.addInterceptor(new SecurityInterceptor()).addPathPatterns("/secure/*");
    }

}
```

## Ajax请求

对于拦截 Ajax 请求的场景，有些细节处理需要注意。拦截器通常需要获取请求来源页面的 URL，使其能在处理完成后能返回之前的页面，比如从某个页面跳转到登录页，登录后再跳转回之前浏览的页面。但如果是 Ajax 请求，比如在页面上点击一个按钮发起请求，改变局部页面元素或行为，这时候拦截器所需要的来源页 URL 被记录在请求头的 `referer` 中。

首先判断一个请求是否为 Ajax。Ajax 请求的头部会带上 `X-Requested-With:XMLHttpRequest`。

```java
private boolean isAsyncRequest(HttpServletResponse request) {
    String header = request.getHeader("X-Requested-With");
    return header != null && "XMLHttpRequest".equalsIgnoreCase(header);
}
```

获取 referer 信息

```java
public boolean preHandle(HttpServletRequest req, HttpServletResponse resp, Object obj) throws Exception {
    String referer = req.getHeader("Referer");
    JSONObject jsonObject = new JSONObject();
    jsonObject.put("requestURI", URLEncoder.encode(referer, "UTF-8"));
    resp.getWriter().write(JSONObject.toJSONString(jsonObject));
    return false;
```
