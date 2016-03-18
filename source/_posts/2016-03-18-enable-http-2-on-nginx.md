---
title: Nginx启用HTTP/2
date: 2016-03-18 16:53:47
tags:
- HTTP
- Nginx
categories: Web
---
今天上班偷闲逛v站时感受到了一阵强烈的安利风，好像所有个人站都已经从HTTP/1.1升级到了HTTP/2。呵呵，跟风也要讲基本法！立即着手升级工作。
上Google搜索关键字，才知道自己已经滞后了6个月，Nginx从1.9.5版本开始已经加入了对HTTP/2的官方支持[NGINX Open Source 1.9.5 Released with HTTP/2 Support](https://www.nginx.com/blog/nginx-1-9-5/)。这篇文章里也提到了Nginx从1.9.5开始，会停止对SPDY的支持，同时移除Nginx的SPDY模块。OK，看明白了之后，剩下的工作就简单了，升级Nginx，开启HTTP/2。

挂着小站的服务器上跑着的Nginx一直是Nginx1.8.x，看了一眼conf文件，没有SPDY的参数设置，可以平滑升级到1.9.x了。由于Nginx1.9发布在mainline上，如果想采用`apt`升级，还需要配置下source源。先安装Nginx的apt源的签名[key](http://nginx.org/keys/nginx_signing.key)，把key添加进apt源。
```bash
sudo apt-key add nginx_signing.key
```
修改`/etc/apt/sources.list`，在文件后追加nginx mainline的deb包源和deb-src源
```bash
deb http://nginx.org/packages/mainline/ubuntu/ codename nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ codename nginx
```
此处的`codename`是系统版本的别称，比如我的服务器系统版本是Ubuntu 14.04 LTS，别名是`trusty`，`codename`即为`trusty`。更新系统，Nginx顺利升级到1.9.12
```bash
nginx -V
nginx version: nginx/1.9.12
built by gcc 4.8.4 (Ubuntu 4.8.4-2ubuntu1~14.04.1)
built with OpenSSL 1.0.1f 6 Jan 2014
TLS SNI support enabled
configure arguments:
--prefix=/etc/nginx
--sbin-path=/usr/sbin/nginx
--conf-path=/etc/nginx/nginx.conf
--error-log-path=/var/log/nginx/error.log
--http-log-path=/var/log/nginx/access.log
--pid-path=/var/run/nginx.pid
--lock-path=/var/run/nginx.lock
--http-client-body-temp-path=/var/cache/nginx/client_temp
--http-proxy-temp-path=/var/cache/nginx/proxy_temp
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp
--http-scgi-temp-path=/var/cache/nginx/scgi_temp
--user=nginx
--group=nginx
--with-http_ssl_module
--with-http_realip_module
--with-http_addition_module
--with-http_sub_module
--with-http_dav_module
--with-http_flv_module
--with-http_mp4_module
--with-http_gunzip_module
--with-http_gzip_static_module
--with-http_random_index_module
--with-http_secure_link_module
--with-http_stub_status_module
--with-http_auth_request_module
--with-mail
--with-mail_ssl_module
--with-file-aio
--with-http_v2_module
--with-ipv6
--with-threads
--with-stream
--with-stream_ssl_module
--with-http_slice_module
```
可以看到Nginx已经把1.8.x时代的Nginx参数列表里的`--with-http_spdy_module`替换为`--with-http_v2_module`，而这个module就是开启HTTP/2支持的模块。

修改`/etc/nginx/conf.d/xxx.conf`站点配置文件，在443端口监听的server设置里加上`http2`参数，80端口访问强制跳转https
```bash
server {
    listen 443 ssl http2 default_server;
}
server {
    listen 80;
    location / {
        return 301 https://$host$request_uri;
    }
}
```
改造的同时，我顺便把SSL证书换成StartSSL。重新载入Nginx配置`sudo service nginx reload`。迫不及待的打开小站测试，然后呵呵哒，Chrome返回not available的错误信息
```
This webpage is not available
ERR_SPDY_INADEQUATE_TRANSPORT_SECURITY
```
原来在Nginx的站点配置里有一行参数`ssl_prefer_server_ciphers on;`，如果开启了这个选项，那么当Nginx配置的SSL ciphers不支持HTTP/2时，就会发生上述错误，浏览器会拒绝该HTTP/2连接请求。所以需要把站点配置里的`ciphers`参数改成支持HTTP/2的设置
```bash
ssl_ciphers 'kEECDH+ECDSA+AES128 kEECDH+ECDSA+AES256 kEECDH+AES128 kEECDH+AES256 kEDH+AES128 kEDH+AES256 DES-CBC3-SHA +SHA !aNULL !eNULL !LOW !kECDH !DSS !MD5 !EXP !PSK !SRP !CAMELLIA !SEED';
```
好了，小站顺利打开，检查下是否走的HTTP/2
![](http://7xs161.com1.z0.glb.clouddn.com/isudox-enable-http-2-on-nginx-1.png)
在protocol栏看到协议已经是h2了，表明开启HTTP/2成功。

对本站的小幅改进就到这里完工了。计划下周在工作之余，一锅乱炖HTTP/1.1和HTTP/2，一直以来对HTTP协议这块的认识很欠缺，论一个Web开发者的自我修养……
