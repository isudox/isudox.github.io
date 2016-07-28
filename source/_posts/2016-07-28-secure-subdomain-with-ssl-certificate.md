---
title: 为子域名安装 SSL 证书
date: 2016-07-28 17:07:42
tags:
  - HTTPS
  - Nginx
categories:
  - DevOps
---

今天把小站所在 Linode 服务器升级到了 4G 2CPUs 的套餐，可以搞搞大新闻了，打算用 Docker 部署下 GitLab 作为和前辈小伙伴们合作开发的代码库，把 GitLab 绑定到小站的子域名下。另外还得再加上 SSL 证书。
Docker 部署 GitLab 的事下期再写，先记下给子域名安装证书的事。

<!-- more -->

### 解析子域名

从域名提供商买到域名后，可以用在多个不同的网站上。比如经常可以看到类似这样的域名，`bss.example.com`，`blog.example.com`，其实这俩是彼此独立的网站，但是都访问到 `sample.com` 域名下，这就是在同一域名下部署多个网站的范例。

域名和 IP 通过 DNS 关联在一起，所以无论常见多少个子域名，都是要通过 DNS 解析到关联 IP 的服务器上。如果要新增子域名，需要在提供 DNS 解析服务的提供商处建立一条解析，将子域名关联到根域名的 IP 上。

本人小站的域名是从 Godaddy 上购买，但域名解析服务是并没有用 Godaddy 默认提供的服务，而是用了 Linode 提供的免费解析服务。但操作都是相同的，在 DNS 的 `zone file` 中添加一条 A/AAAA 记录：

```
git        A        45.33.47.109
git        AAAA     2600:3c01::f03c:91ff:fe18:68b6
```

添加完后等待 DNS 服务更新，大概 15 分钟后就能 ping 通这条新建的子域名。这就意味着对子域名的访问已经通过 DNS 解析指向了我的 Linode 服务器上。

现在要完成的就是通过 HTTP Server 将访问请求打到网站的目录下，我是用 Nginx，在 Nginx conf 里添加子域名解析的针对性配置或者泛子域名解析的通用配置。较新版本的 Nginx 的多站点配置默认保存在 `/etc/nginx/conf.d/*.conf` 文件里，而不再是 `site-enabled` 里。新建 `subdomain.conf` 配置文件：

```conf
server {
    listen 80;
    server_name ~^(?<subdomain>.+)\.isudox\.com$;  # 通配符匹配子域名
    server_tokens off  # 隐藏 nignx 信息
    location / {
        root /usr/share/nginx/html/$subdomain;
        index index.html index.htm
    }
}

```

在 Nginx 默认的网站根目录下新建 `git` 目录，写一个 `Hello, Git` 的 index.html，浏览器访问下，OK！

如果后续还要新增其他子域名，可以类似的再写一个 Nginx conf 配置，或者直接用泛子域名解析的 conf 文件。

### 安装证书

接下来就是给子域名安装 SSL 证书。小站域名 `isudox.com` 绑定了 Comodo 颁发的证书，但从 Comodo 买的这张证书并不支持通配符域名，因此这张证书就没法用在二级域名 `<subdomain.isudox.com>`。那么还得再去申请一张证书。
有钱的话，买什么样的证书都行；然而没钱，那就只能从下面几家能提供免费 SSL 证书的提供商里挑了。

- [WoSign](https://www.wosign.com/)
- [StartSSL](https://www.startssl.com/)
- [Let’s Encrypt](https://letsencrypt.org/)

其中，Let's Encrypt 的逼格应该是最高的，StartSSL 口碑比较好，WoSign 弃之。先述说 Let’s Encrypt 证书的申请。

#### Let’s Encrypt 证书

Let's Encrypt 证书的申请需要一点点动手能力，它提供了一个官方的脚本生成工具 [certbot](https://certbot.eff.org/)，只支持 Unix-liked 系统，把脚本下载本地，并添加执行权限。

```bash
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
```

certbot 支持几种不同的插件（apache、webroot、standalone、manual、nginx），用来获取和安装证书。但插件 nginx 还是试验阶段，可以使用 webroot 或 standalone 插件。区别是 webroot 插件用在已经运行着网站的服务器上，可以通过指定网站的目录来获取并安装证书：

```bash
./certbot-auto certonly --webroot -w /var/www/example/ -d www.example.com -d example.com -w /var/www/other -d other.example.net -d another.other.example.net
```

而 standalone 插件则用在本地机器上，通过指定网站的域名来获取和安装证书。

```bash
./certbot-auto certonly --standalone -d example.com -d www.example.com
```

Let’s Encrypt 的证书有效期是三个月，可以用 `letsencrypt renew ` 命令重新激活。最后就是将证书的路径写入到 Nginx conf 配置里。

#### StartSSL 证书

StartSSL 的证书生成就傻瓜多了，上手更容易，有效期也有一年之久。
用 `openssL` 生成 .csr 文件，

```bash
openssl req -newkey rsa:2048 -keyout git.isudox.com.key -out git.isudox.com.csr
```

命令会要求输入一个 passphrase 作为解码凭据，生成后将文件内容粘贴到 StartSSL 的网站上进行证书注册。之后就能从 StartSSL 上下载该子域名的证书文件，把 .key 后缀的密钥文件和 StartSSL 提供的证书文件上传到服务器上，并把二者的路径写入到 Nginx conf 里，在原来的子域名 conf 里添加如下内容

```conf
server {
    return 301 https://$subdomain.isudox.com;  # HTTP 访问重定向到 HTTPS
}
server {
    listen 443 ssl http2;
    server_name ~^(?<subdomain>.+)\.isudox\.com$;
    location / {
        root /usr/share/nginx/html/$subdomain;
        index index.html index.htm
    }
    ssl on;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_certificate /path-to-crt/git.isudox.com.crt;
    ssl_certificate_key /path-to-key/git.isudox.com.key;
}
```

重启 Nginx 发现失败了，原因是之前埋了个坑，通过 `openssL` 工具生成密钥对的时候，必须要求输入 passphrase，直接启动 Nginx 服务时没有匹配 passphrase 自然也就失败了。参考 Nginx [官方文档](http://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_password_file)，Nginx 提供了一个参数 `ssl_password_file` 指定记录 passphrase 的文件。把 passphrase 写入该文件，并关联到 `ssl_password_file` 参数就能正常启动 Nginx 了。

当然，如果是用 `ssh-keygen -t rsa` 命令生成密钥对，就不会强制要求 passphrase，也就不会有这个问题。

现在再打开 git.isudox.com，就自动跳转到了 HTTPS 协议，URL 上挂小绿锁的视觉效果确实不错。
![](https://o70e8d1kb.qnssl.com/url-with-green-lock.png)