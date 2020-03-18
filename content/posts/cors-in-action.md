---
title: CORS 跨域调试记录
date: 2016-11-12 00:31:58
tags:
  - HTTP
  - SpringMVC
categories:
  - Coding
---

之前写了篇关于 JSONP 和 CORS 解决跨域请求的博客，在最近和深圳凹凸团队前后端联调时实打实的实战了一把 CORS。还是应了纸上得来终觉浅的老话，因为实际运用中会存在不同的状况，只是看文档理解概念并不能真正成为实战派。

<!-- more -->

这次联调采用前后端分离的方式，后端由 Spring MVC 提供数据接口，前端通过异步的方式做数据渲染，和以往不同的是，由于前端开发全部交给深圳的凹凸实验室，所以静态文件都跑在独立的一个域名上，就是京东的通天塔项目。因此所有来自前端的请求都成了跨域请求。

JSONP 确实是通过一种巧妙的伎俩解决了跨域请求被浏览器拒绝的问题，但是它并不能解决 POST 跨域，联调的接口是跨域上传头像，采用 POST 发送 FormData 对象的方式。所以由服务端 CORS 来处理。

对于服务端，Spring MVC 设置 CORS 很简单，如果 springframework 版本是 4.2 及以上，Spring MVC 可以直接由注解 `@CrossOrigin` 对标记的控制器方法设置 CORS。例如下面的示例代码：

```java
@CrossOrigin(origins = "http://localhost:9000")
@GetMapping("/greeting")
public Greeting greeting(@RequestParam(required=false, defaultValue="World") String name) {
    System.out.println("==== in greeting ====");
    return new Greeting(counter.incrementAndGet(), String.format(template, name));
}
```

`@CrossOrigin` 注解可以通过设置 `origins`、`methods`、`maxAge`、`allowHeaders`、`allowCredentials` 等参数来确定 CORS 接受跨域的来源域，请求类型，请求头等。如果 origins 设置为星号，则对所有来源域的请求都允许跨域，methods 设置为 POST 就只允许请求类型为 POST 的跨域请求。

前端正常发送异步请求，类似如下代码：

```javascript
var formData = new FormData();
formData.append('avatar', 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEX/TQBcNTh/AAAAAXRSTlPM0jRW/QAAAApJREFUeJxjYgAAAAYAAzY3fKgAAAAASUVORK5CYII=');
var req = new XMLHttpRequest();
req.open('POST', '//xxx.jd.com/xxx/xxx');
req.send(fromData);
```

但是结果并不如人意，返回码 302，请求被强制跳转京东的统一登录，这就是一个问题点，因为上传头像要求登录状态，所以浏览器请求时必须带上本地的 cookies，如果是 JSONP 的方式，它默认会传递 cookies。所以需要将 XMLHttpRequest 的凭证信息标识位设为 true：

```javascript
var req = new XMLHttpRequest();
req.withCredentials = true;
```

这里有一点需要留意，如果请求带上了 cookies 那么服务端 CORS 的 origins 不能是 `*` 号，必须明确指定允许的来源 origin。再次联调测试，跨域还是失败了，看服务端日志发现，请求根本没有进入到 Controller 层，在登录拦截器里就被拒绝了。这是另外一个问题，因为 Spring MVC 设置了 interceptors，符合规则的请求都会被 interceptor 拦截，要么排除该跨域请求，但这是不可取，因为必须是登录用户才能进行的操作。所以需要在拦截器的 `preHandle()` 方法里进行处理，把来源域的加入到响应头的 `Access-Control-Allow-Origin` 字段中，同时设置 `Access-Control-Allow-Headers`：

```java
public class LoginInterceptor extends HandlerInterceptorAdapter{
	// before the actual handler will be executed
	public boolean preHandle(HttpServletRequest request,
		HttpServletResponse response, Object handler) throws Exception {
            response.addHeader("Access-Control-Allow-Origin", "http://h5.m.jd.com");
            response.addHeader("Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS");
            response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, isAjaxRequest");
            return true;
	}
}
```

心想这次总该 OK 了吧，还是没调通，我摔！但是这次是有进步的，因为请求进到 Controller 的方法里，执行完了头像上传，只是浏览器的到的响应体为空，打开浏览器的控制台看到一段错误信息：

> XMLHttpRequest cannot load http://xxxp.jd.com/xxx/xxx. Credentials flag is 'true', but the 'Access-Control-Allow-Credentials' header is ''. It must be 'true' to allow credentials. Origin 'http://h5.m.jd.com' is therefore not allowed access.

这是第三个问题，POST 请求是标记了凭证信息标识位，但是服务端回传的响应头的 `Access-Control-Allow-Credentials` 字段却是空，而不是 `true`，解决办法显而易见了，设置 `HttpServletResponse` 响应字段为 `true` 即可：

```java
public boolean preHandle(HttpServletRequest request,
    HttpServletResponse response, Object handler) throws Exception {
        response.addHeader("Access-Control-Allow-Credentials", "true");        
        return true;
}
``` 

这样处理后，浏览器就收到的 Controller 层方法返回的 JSON 结果。

以上就是这次由服务端 CORS 实现的跨域请求的调试过程。其实从结果看真的很简单，只是有些问题如果实际开发中没有遇到，很容易疏漏，仅仅是看文档学怎么用还是不够的。
