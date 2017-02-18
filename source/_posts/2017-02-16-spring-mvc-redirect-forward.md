---
title: 探究 Spring MVC 的重定向和转发
date: 2017-02-16 11:35:09
tags:
  - Spring
  - Java
categories:
  - Coding
---

最近参与的一个微信公众号相关的项目开发中，业务逻辑包含大量的页面跳转逻辑，以及数据的拦截器获取校验。其间也遇到一些困惑，在探究 Spring MVC 中 redirect 和 forward 的源码后，把经验归纳整理出来，遂成此文。

<!-- more -->

比如客户端的请求进到 Controller 方法中，我们会判断当前用户状态，可能会跳转到用户中心页，也可能会跳转到等待页，又或者错误页。类似的场景很多，都需要用到请求的重定向和转发。Sping MVC 实现重定向或转发的方法有很多，我先大致梳理下，然后再通过源码加深理解。

## 不同情况的处理

Controller 间方法的跳转，无非就是带参跳转和不带参跳转。通常的做法是 return 映射到另一个 Controller 方法的字符串。如果有请求参数，就拼接在 RequestMapping 映射的字符串后面。

```java
// 返回字符串映射 RequestMapping 的方式
@RequestMapping("hello")
public String hello(HttpServletRequest req, HttpServletResponse resp) {
    doSomething();
    return "redirect:/bye";
    // return "redirect:/bye?username=sudoz";
}
```

另一种方法是通过返回 `ModelAndView` 对象来实现跳转，类似的，如果有请求参数，也可以通过类似 GET 参数拼接的方式：

```java
// 返回 ModelAndView 对象
@RequestMapping("hello")
public ModelAndView hello(HttpServletRequest req, HttpServletResponse resp) {
    doSomething();
    return new ModelAndView("redirect:/bye");
    // return new ModelAndView("redirect:/bye?username=sudoz");
}
```

还有一种方法是通过返回 `RedirectView` 对象实现跳转

```java
@RequestMapping("hello")
public RedirectView hello() {
    doSomething();
    return new RedirectView("");
}
```

```java
public class UrlBasedViewResolver extends AbstractCachingViewResolver implements Ordered {
    public static final String REDIRECT_URL_PREFIX = "redirect:";
    public static final String FORWARD_URL_PREFIX = "forward:";

    @Override
    protected View createView(String viewName, Locale locale) throws Exception {
        // If this resolver is not supposed to handle the given view,
        // return null to pass on to the next resolver in the chain.
        if (!canHandle(viewName, locale)) {
            return null;
        }
        // Check for special "redirect:" prefix.
        if (viewName.startsWith(REDIRECT_URL_PREFIX)) {
            String redirectUrl = viewName.substring(REDIRECT_URL_PREFIX.length());
            RedirectView view = new RedirectView(redirectUrl, isRedirectContextRelative(), isRedirectHttp10Compatible());
            return applyLifecycleMethods(viewName, view);
        }
        // Check for special "forward:" prefix.
        if (viewName.startsWith(FORWARD_URL_PREFIX)) {
            String forwardUrl = viewName.substring(FORWARD_URL_PREFIX.length());
            return new InternalResourceView(forwardUrl);
        }
        // Else fall back to superclass implementation: calling loadView.
        return super.createView(viewName, locale);
    }
}
```

********************************************

参考资料
- [Spring MVC Documentation](https://docs.spring.io/spring/docs/current/spring-framework-reference/html/mvc.html)