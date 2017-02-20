---
title: 探索 Spring MVC 重定向和转发
date: 2017-02-16 11:35:09
tags:
  - Spring
  - Java
categories:
  - Coding
---

最近参与的一个微信公众号相关项目的开发中，业务包含大量的页面跳转逻辑，以及拦截器的数据获取校验。其间也遇到一些困惑，在探究 Spring MVC 中 redirect 和 forward 的源码后，把经验归纳整理出来，遂成此文。

<!-- more -->

比如客户端的请求进到 Controller 方法中，我们会判断当前用户状态，可能会跳转到用户中心页，也可能会跳转到等待页，又或者错误页。类似的场景很多，都需要用到请求的重定向和转发。Sping MVC 实现重定向或转发的方法有很多，我先大致梳理下，然后再通过源码加深理解。

## 常用处理方式

Controller 视图方法间的跳转，无非就是带参跳转和不带参跳转。常用的方法有通过 String 映射 RequestMapping 实现重定向，或者通过 `ModelAndView` 对象，又或者是 `RedirectView` 对象，下面逐一说明。

### String 重定向

是 return 映射到另一个 Controller 方法的字符串。如果有请求参数，就拼接在 RequestMapping 映射的字符串后面。

```java
// 返回字符串映射的方式
@RequestMapping("hello")
public String hello(HttpServletRequest req, HttpServletResponse resp) {
    doSomething();
    return "redirect:/bye";
    // return "redirect:/bye?username=sudoz";
}
```

### ModelAndView 重定向

另一种方法是通过返回 `ModelAndView` 对象来实现跳转。类似的，如果有请求参数，也可以通过类似 GET 参数拼接的方式：

```java
// 返回 ModelAndView 对象
@RequestMapping("hello")
public ModelAndView hello(HttpServletRequest req, HttpServletResponse resp) {
    doSomething();
    return new ModelAndView("redirect:/bye");
    // return new ModelAndView("redirect:/bye?username=sudoz");
}
```

### RedirectView 重定向

还有一种方法是通过返回 `RedirectView` 对象实现跳转，该方法和上面的不同之处在于，`RedirectView` 对象不需要设置 redirect 前缀：

```java
// 返回 RedirectView 对象
@RequestMapping("hello")
public RedirectView hello() {
    doSomething();
    return new RedirectView("/bye");
    // return new RedirectView("bye?username=sudoz");
}
```

## 带参跳转

在做方法跳转时，如果要把参数带给下一个方法，像上面代码里通过拼接 URL 参数的方法有时候并不实用。因为参数不一定都是是字符串，而且浏览器对 URL 的长度是有限制的。`RedirectAttributes` 对象可以用来保存请求重定向时的参数。利用 `RedirectAttributes` 改写上面的代码：

```java
@RequestMapping("/")
public RedirectView hello(RedirectAttributes attrs) {
    attrs.addAttribute("message", "hello");    
    attrs.addFlashAttribute("username", "sudoz");
    return new RedirectView("hello");
}

@RequestMapping("hello")
    Map<String, String> hello(@ModelAttribute("username") String username,
                              @ModelAttribute("message") String message) {
    Map<String, String> map = Maps.newHashMap();
    map.put("username", username);
    map.put("message", message);
    return map;
}
```

上面的代码中，调用 `addAttribute()` 和 `addFlashAttribute()` 方法往 `RedirectAttributes` 对象中插入了两个值，如果看源码，就能知道，`RedirectAttributes` 接口的实现类 `RedirectAttributesModelMap` 继承了 `ModelMap`，本质上就是 `HashMap` 的子类，因此可以用来存储 Key-Value 对。这两个方法都很常用，使用上也必然存在不同：
- `addAttribute()` 方法会把 Key-Value 作为请求参数添加的 URL 的后面；
- `addFlashAttribute()` 方法会把 Key-Value 暂存在 session 中，在跳转到目标方法后，即完成任务，会从 session 中删掉；

用 `curl` 命令来测试：

```bash
curl -i http://localhost:8080/

HTTP/1.1 302 
Set-Cookie: JSESSIONID=D1CC5E15FA8EF9474C4CED7D4F660E66;path=/;HttpOnly
Location: http://localhost:8080/hello;jsessionid=D1CC5E15FA8EF9474C4CED7D4F660E66?username=sudoz
Content-Language: en-US
Content-Length: 0
Date: Thu, 16 Feb 2017 12:33:46 GMT
```

可以看到，通过 `addAttribute()` 添加的键值对变成了 URL 后面的参数，`addFlashAttribute()` 方法添加的键值对则没有出现在 URL 上，而是存储在了 session 中。跳转的目标方法通过 `@ModelAttribute("key")` 注解指定接收的参数。

## redirect 和 forward 的区别

上面列出的 3 种方法，其实都是 Spring MVC 在处理请求时的重定向，即 redirect 跳转。另一种分发请求的方式是转发，即 forward。（我不确定这么翻译是否正确，所以下面就直接用 redirect 和 forward 来表述），二者的区别从 HTTP 的规范中就明确了：
- redirect 的 HTTP 返回码是 302，且跳转的新 URL 会存储在 HTTP Response Headers 的 Location 字段中。客户端在接收到 Response 后，会发起另一次请求，这次请求的 URL 就是重定向的 URL；
- forward 的转发过程只发生在服务端；Servlet 容器会直接把源请求打向目标 URL，而不会经由客户端发起请求；因此客户端接收到的响应是来自转发后的目标方法，但是浏览器呈现的 URL 却并不会改变，且 forward 不能将参数转发出去。

## Spring Boot 测试

为了更清晰的比较各种方法，我把 Spring Boot 的测试代码贴出来。

```java
@Controller
public class HomeController {
    @Value("sudoz")
    private String username;

    @GetMapping("/")
    String index() {
        return "redirect:hello?username=jim&message=how are you";
    }

    @GetMapping("redirectView")
    RedirectView redirectView() {
        return new RedirectView("hello");
    }

    @GetMapping("forward")
    ModelAndView forward(RedirectAttributes attrs) {
        attrs.addFlashAttribute("username", username);
        attrs.addAttribute("message", "hello");
        return new ModelAndView("forward:hello");
    }

    @GetMapping("redirect")
    ModelAndView redirect(RedirectAttributes attrs) {
        attrs.addFlashAttribute("username", username);
        attrs.addAttribute("message", "hello");
        return new ModelAndView("redirect:hello");
    }

    @GetMapping("hello")
    @ResponseBody
    Map<String, String> hello(Model model, @ModelAttribute("username") String username,
                              @ModelAttribute("message") String message) {
        Map<String, String> map = Maps.newHashMap();
        map.put("username", username);
        map.put("message", message);
        return map;
    }
}
```

## 分析源码

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

***

参考资料
- [Spring MVC Documentation](https://docs.spring.io/spring/docs/current/spring-framework-reference/html/mvc.html)