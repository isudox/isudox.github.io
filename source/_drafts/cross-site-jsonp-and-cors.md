---
title: 关于跨域：JSONP 和 CORS
tags:
  - Frontend
  - JavaScript
categories:
  - Coding
---

Web 开发中，跨域请求是个经常碰到的问题，因为涉及到网站安全，所以浏览器是拒绝跨域请求的。通常解决跨域会采用 [JSONP](https://en.wikipedia.org/wiki/JSONP)(JSON with Padding) 和 [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS)(Cross-Origin Resource Sharing)。

<!-- more -->

首先理清一个经常会被混淆的概念，AJAX(Asynchronous JavaScript and XML) 和跨域请求是两个不同的概念，AJAX 是异步请求和解析处理 XML 文档的方式，它也是无法跨域的。

### 跨域请求

跨域请求，顾名思义，就是从 A 地址向非同源的 B 地址发起了请求。参考 MDN 上对同源的定义:

> 如果两个页面拥有相同的协议（protocol），端口（如果指定），和主机，那么这两个页面就属于同一个源（origin）。

MDN 给了同源检测的示例，如果是相对 http://store.company.com/dir/page.html

| URL | 结果 | 原因 |
|:--:|:--:|:--:|
| http://store.company.com/dir2/other.html | 成功 | |
| http://store.company.com/dir/inner/another.html | 成功 | |	 
| https://store.company.com/secure.html | 失败 | 协议不同 |
| http://store.company.com:81/dir/etc.html | 失败 | 端口不同 |
| http://news.company.com/dir/other.html | 失败 | 主机名不同 |

跨域请求和同源请求在浏览器行为上就有区别，先看同源请求的请求头：

```

```

### JSONP

### CORS

参考：
  - Mozilla Developer Network
  - 阮一峰的网络日志
