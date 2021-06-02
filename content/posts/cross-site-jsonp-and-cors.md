---
title: 跨域请求之 JSONP 和 CORS
tags:
  - 前端
categories:
  - Coding
date: 2016-09-24 23:55:52
---


Web 开发中，跨域请求是个经常碰到的问题，因为涉及到网站安全，所以浏览器是拒绝跨域请求的。通常解决跨域会采用 [JSONP](https://en.wikipedia.org/wiki/JSONP)(JSON with Padding) 和 [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS)(Cross-Origin Resource Sharing)。

<!-- more -->

首先理清一个经常会被混淆的概念，AJAX(Asynchronous JavaScript and XML) 和跨域请求是两个不同的概念，AJAX 是异步请求和解析处理 XML 文档的方式，它在服务器端没有提供支持（CORS 是一种解决方案）的前提下，也是无法跨域的。

### 跨域请求

跨域请求，顾名思义，就是从 A 地址向非同源的 B 地址发起了请求。参考 MDN 上对同源的定义:

> 如果两个页面拥有相同的协议（protocol），端口（如果指定）和主机，那么这两个页面就属于同一个源（origin）。

MDN 给了同源检测的示例，如果是相对 http://store.company.com/dir/page.html，那么

| URL | 结果 | 原因 |
|:--:|:--:|:--:|
| http://store.company.com/dir2/other.html | 成功 | |
| http://store.company.com/dir/inner/another.html | 成功 | |	 
| https://store.company.com/secure.html | 失败 | 协议不同 |
| http://store.company.com:81/dir/etc.html | 失败 | 端口不同 |
| http://news.company.com/dir/other.html | 失败 | 主机名不同 |

严格的说，浏览器并不是拒绝所有的跨域请求，否则如果想从百度搜索结果页跳转到其他页面就是个伪命题，实际上拒绝的是跨域的读操作。浏览器的同源限制策略是这样执行的：

  - 通常浏览器允许进行跨域写操作（Cross-origin writes），如链接，重定向；
  - 通常浏览器允许跨域资源嵌入（Cross-origin embedding），如 `img`、`script` 标签；
  - 通常浏览器不允许跨域读操作（Cross-origin reads）。

对于跨域资源的嵌入，实际开发中用的非常频繁，从外部引入 js、css、img 这些静态文件，都是被浏览器接受的。

下面对浏览器的同源策略做个测试，探探究竟。

```javascript
// cross-origin request
var url = "http://search.jd.com/Search?keyword=python&enc=utf-8&wq=python";
var request = new XMLHttpRequest();
request.open("GET", url);
request.send(null);
```

浏览器控制台会出现错误信息（信息中的 Origin 为 null 是因为我是用浏览器直接打开 html，而不是通过 http server 访问 html）：

> XMLHttpRequest cannot load http://search.jd.com/Search?keyword=python&enc=utf-8&wq=python. No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'null' is therefore not allowed access.

该请求来源的 Origin 不在可允许范围内，这种情况就是跨域请求被拒。下面是一个简单的本地 http server：

```javascript
// local http server writtern by Node.js
var http = require('http');
var port = 8080; 

function handleRequest(request, response){
    response.end('Hello');
    console.log('request url: ' + request.url);
}

var server = http.createServer(handleRequest);
server.listen(PORT, function(){
    console.log("Server listening on: http://localhost:%s", port);
});
```

`node simple-server.js` 运行，把请求的 URL 改成 http://localhost:8080，可以看到命令行终端输出日志，这就表明，请求实际上是从浏览器发出了，服务器也接收到了请求，但是浏览器在读取跨域返回的数据时被拒绝了。这就印证了 MDN 文档上说明的，浏览器不允许跨域读操作。

### JSONP

JSONP 并不在 HTML 的标准里，而是开发者为了实现跨域请求而创造的一个 trick。在 HTML 中，可以通过 "src"、"img" 标签引入非同源的静态资源，这就给 JSONP 的实现提供了可能。

JSONP 的实现很简单，需要客户端和服务端配合。客户端在 HTML 中动态生成 `script` 标签，在 "src" 中引入请求的 URL + 回调函数，这样请求服务器返回的数据会交由回调函数处理，这样就实现了跨域读请求；服务端在接收到客户端请求后，首先取得客户端要回调的函数名，再生成 JavaScript 代码段返回给浏览器，浏览器在获取到返回结果后直接调用回调函数完成任务。

手写一段简陋的 JS 代码演示下 JSONP 的整个流程：

```javascript
function handleCallback(result) {
    console.log(result.message);
}

var jsonp = document.createElement('script');
var ele = document.getElementById('demo');
jsonp.type = 'text/javascript';
jsonp.src = 'http://localhost:8080?callback=handleCallback';
ele.appendChild(jsonp);
ele.removeChild(jsonp);
```

JSONP 只支持 GET 请求，而且需要服务器端来配合，如果服务器端返回一段恶意代码，客户端也会毅然决然的执行……JSONP 是一个伟大的创造，但还不够好。

### CORS

CORS 是W3C 推荐的一种新的官方方案，能是服务器支持 XMLHttpRequest 的跨域请求。CORS 实现起来非常方便，只需要增加一些 HTTP 头，让服务器能声明允许的访问来源。

浏览器对 CORS 的使用场景做了区分，有简单请求和非简单请求之分。MDN 对简单请求的定义条件是：

  - 只使用 GET, HEAD 或者 POST 请求方法。如果使用 POST 向服务器端传送数据，则数据类型(Content-Type)只能是 application/x-www-form-urlencoded, multipart/form-data 或 text/plain中的一种；
  - 不会使用自定义请求头；

浏览器（支持 CORS）对简单的跨域请求，会在请求头里加上 `Origin` 字段，向服务器说明请求源信息，包括协议、域名和端口，由服务器判断请求源是否在允许的域中。

编写一个简单请求，跨域获取信息：

```javascript
var url = "https://ipinfo.io/54.169.237.109/json?token=iplocation.net";
$.ajax({
    url: url
});
```

查看请求头信息：

```
Accept:*/*
Accept-Encoding:gzip, deflate, sdch, br
Accept-Language:zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4
Cache-Control:max-age=0
Connection:keep-alive
DNT:1
Host:ipinfo.io
Origin:https://isudox.com
Referer:https://isudox.com/test.html
User-Agent:Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/52.0.2743.116 Chrome/52.0.2743.116 Safari/537.36
```

浏览器自动给请求头添加了 `Origin` 字段，请求的服务端如果允许来自该 `Origin` 来源的请求，就会在响应头中添加 `Access-Control-Allow-Origin` 字段，参考上面请求的响应头：

```
Access-Control-Allow-Origin:*
Connection:keep-alive
Content-Encoding:gzip
Content-Length:231
Content-Type:application/json; charset=utf-8
Server:nginx/1.8.1
X-Content-Type-Options:nosniff
```

`Access-Control-Allow-Origin` 字段表明服务器接受来自任何请求源的跨域请求。因此，通过客户端的 `Origin` 和 服务端的 `Access-Control-Allow-Origin` 实现了跨域的 XMLHttpRequest 请求。

MDN 对非简单请求的定义条件为

  - 以 GET、HEAD、或者 POST 以外的方法发起，或者是请求数据为 application/x-www-form-urlencoded, multipart/form-data 或者 text/plain 以外的数据类型；
  - 使用自定义请求头（比如添加诸如 X-PINGOTHER）

非简单请求会先向服务器发送一个 `OPTIONS` 的“预请求”（preflight），来确认该跨域请求是否能被服务端允许，如果允许，则继续发送费简单请求，否则，XMLHttpRequest 的 onerror 回调函数会捕获到错误信息。

编写一个非简单请求：

```javascript
var url = 'http://aruner.net/resources/access-control-with-post-preflight/';
var xhr = new XMLHttpRequest();
xhr.open('POST', url, true);
xhr.setRequestHeader('X-PINGOTHER', 'pingpong');
xhr.setRequestHeader('Content-Type', 'application/xml');
xhr.send(); 
```

预请求的请求头：

```
OPTIONS /resources/post-here/ HTTP/1.1
Host: bar.com
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Connection: keep-alive
Origin: http://foo.example
Access-Control-Request-Method: POST
Access-Control-Request-Headers: X-PINGOTHER
```

预请求由 `OPTIONS` 请求发出，`Access-Control-Request-Method` 字段标识跨域请求的方式，`Access-Control-Request-Headers` 字段标识跨域请求的自定义请求头名称，再加上 `Origin` 字段，服务端就能判断还没正式发过来的跨域请求是否是安全可允许的。

如果服务端允许该跨域请求，其响应头类似如下形式：

```
HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:15:39 GMT
Server: Apache/2.0.61 (Unix)
Access-Control-Allow-Origin: http://foo.com
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Headers: X-PINGOTHER
Access-Control-Max-Age: 1728000
Vary: Accept-Encoding, Origin
Content-Encoding: gzip
Content-Length: 0
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Content-Type: text/plain
```

其中，响应头中的 `Access-Control-*` 字段的具体含义如下：
 
  - `Access-Control-Allow-Origin` 标识可接受的跨域请求源；
  - `Access-Control-Allow-Methods` 标识可接受的跨域请求方法；
  - `Access-Control-Allow-Headers` 标识可接受的跨域请求自定义头；
  - `Access-Control-Max-Age` 标识本次预请求的有效时间（秒），期间内无需再发送预请求；

如果拒绝该跨域请求，错误信息也会被 `onerror` 回调捕获。

XMLHttpRequest 请求可以发送凭证请求（HTTP Cookies 和验证信息），通常不会跨域发送凭证信息，但也有一些情况需要打通不同的登录态，可以把 XMLHttpRequest 的 `withCredentials` 设置为 `true`，这样浏览器就能跨域发送凭证信息。

```javascript
var xhr = new XMLHttpRequest();
xhr.withCredentials = true;
```

服务端返回的响应头中的 `Access-Control-Allow-Credentials` 字段存在且为 `true` 时，浏览器才会将响应结果传递给客户端程序。另外，`Access-Control-Allow-Origin` 必须指定请求源的域名，否则响应失败。

```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://foo.com
Access-Control-Allow-Credentials: true
Set-Cookie: pageAccess=3; expires=Wed, 31-Dec-2008 01:34:53 GMT
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Content-Type: text/plain
```

**************************************

参考：
  - Mozilla Developer Network
  - 阮一峰的网络日志
