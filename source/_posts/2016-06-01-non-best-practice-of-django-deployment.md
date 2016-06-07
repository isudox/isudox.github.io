---
title: Django 部署的非最佳实践
date: 2016-06-01 17:24:27
tags:
  - DevOps
  - Django
  - Nginx
  - uWSGI
  - Python
  - BestPractice
categories:
  - Code
---


上周末接到急差，要重新部署之前开发的 Django 项目。磕磕绊绊遇到很多预想不到的问题，也发现自己对 Django 应用的部署依旧很生疏，遂记一篇水文。

<!-- more -->

### 一些题外话

#### Django 工程结构

在 Django 官方[文档](https://docs.djangoproject.com/en/1.9/intro/tutorial01/#creating-a-project)里，新建 Django 工程用下面的命令完成：

```bash
django-admin startproject mysite
```

这样创建的工程根目录下，会生成一个和项目名称同名的子目录，存放 settings.py wsgi.py 等文件。这样做肯定没问题，但是没必要，也不优雅。对此 Kenneth Reitz 的建议是，在命令的后面加一 `.` 号：

```bash
django-admin.py start-project mysite .
```

这样，Django 工程的配置文件就存放在根目录下了。

#### 虚拟环境 virtualenv

一般在测试服务器上，用 virtualenv 把不同版本的环境隔离开来是首选的方案。此外还有一个工具 [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/)，来管理由 virtualenv 虚拟出来的 Python 环境，非常实用。

pip 安装 virtualenvwrapper 后，需要设置几个全局环境变量。可以把下面的配置添加进 shell 的配置文件里，比如我用的 zsh，那么就是添加进 .zshrc 文件：

```bash
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3.4
export WORKON_HOME=$HOME/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh
```

分别指定默认的 Python 版本和 Python 虚拟环境的目录。设置后，就可以非常方便的通过 workon 命令切换已安装的 Python 虚拟环境，而无需定向到虚拟环境的路径。

#### 导出 pip 列表

在有了 Python 虚拟环境后，还得有快速安装 pip 包的方法，pip 提供了导出 pip 列表的功能 freeze，以及快速安装工程所需 pip 包的功能 install：

```bash
pip freeze > requirements.txt
pip install -r requirements.txt
```

### 部署

#### uWSGI + Nginx

在安装好 Django 项目专有 Python 环境后，就是部署工作。Nginx 和 uWSGI 是不错的选择，uWSGI 是服务器网关接口 WSGI 的一种实现，它可以通过 Unix socket 或指定端口将客户端请求打到 Django 的路由，并将响应通过 WSGI 协议提交到服务器返回给客户端，请求 - 响应的流程如下：

> the web client <-> the web server <-> the socket <-> uwsgi <-> Django

先来配置对应 Django 工程的 Nginx conf

```ini
# mysite_nginx.conf

# the upstream component nginx needs to connect to
upstream django {
    server unix:///path/to/your/mysite/mysite.sock; # for a file socket
}

# configuration of the server
server {
    # the port your site will be served on
    listen      80;
    # the domain name it will serve for
    server_name 127.0.0.1; # substitute your machine's IP address or FQDN
    charset     utf-8;

    # max upload size
    client_max_body_size 75M;   # adjust to taste

    # Django media
    location /media  {
        alias /path/to/your/mysite/media;  # your Django project's media files - amend as required
    }

    location /static {
        alias /path/to/your/mysite/static; # your Django project's static files - amend as required
    }

    # Finally, send all non-media requests to the Django server.
    location / {
        uwsgi_pass  django;
        include     /path/to/your/mysite/uwsgi_params; # the uwsgi_params file you installed
    }
}
```

/static 和 /media 指向的路径应匹配 Django settings.py 里对应的路径参数。此外，还可能遇到一个问题，就是权限，nginx 进程的用户多半是 www-data，但我们在服务器上进行操作的用户往往是 root，因此 nginx 并没有操作 Django 工程的权限，可以把 Django 工程的用户和组改成 www-data，但更好的办法是把 www-data 用户加进 root 用户组：
```bash
sudo usermod -aG root www-data
```

指定 sock 后，就可以连接 Nginx 和 uWSGI 了，启动 uWSGI 伺服 Django 工程：
```bash
uwsgi --http :80 --home /path/to/your/virtualenv/mysite --chdir /path/to/your/mysite -w mysite.wsgi
```
uWSGI 指定了 Django 工程所在的路径和对应的 Python 虚拟环境，并调用 Django 项目的 wsgi.py 文件。每次指定参数不便于管理和迁移，可以把上述参数写进一个 uWSGI 的站点配置文件中：
```ini
# freeman_uwsgi.ini file
[uwsgi]

project = mysite
base = /path/to/your/mysite

# Django-related settings
# the base directory (full path)
chdir           = %(base)
# Django's wsgi file
module          = %(project).wsgi:application
# the virtualenv (full path)
home            = /path/to/your/virtualenv

# process-related settings
# master
master          = true
# maximum number of worker processes
processes       = 10
# the socket (use the full path to be safe
socket          = %(base)/%(project).sock
# ... with appropriate permissions - may be needed
chmod-socket    = 664
# clear environment on exit
vacuum          = true
# autoreload py file
py-autoreload   = 3
```
uWSGI 启动时读取该 ini 文件
```bash
uwsgi --ini mysite_uwsgi.ini
```

#### 开启 emperor 模式

如果修改了 uWSGI 的站点配置文件，就必须得重启 uWSGI，这步可以由 `emperor` 模式自动完成。`emperor` 模式就是实时监控 uWSGI 的配置文件，当发现有改动时，自动重启服务。

给 uWSGI 建立 `emperor` 管理的专有路径，把 Django 工程的 uWSGI 配置文件软链接到该路径下，启动 uWSGI 时，加上 `--emperor`` 参数：
```bash
sudo uwsgi --emperor /etc/uwsgi/vassals --uid www-data --gid www-data
```

### 多环境配置

同一个 Django 工程，在本地开发和在线上部署的版本可能各自有一套配置，比如 settings.py 和 requirements.txt 等。如果把这些差异化的文件加进版本控制的忽略列表里，维护起来又很麻烦，Python 模块化的思想可以很好的运用在这个问题上。

本地测试和线上部署的差异化配置分离出来，放在专门的 conf 目录下，比如新建 local.py 和 product.py。
```
├── conf
│   ├── __init__.py
|   ├── base.py
│   ├── local.py
│   └── product.py
│   └── test.py
└── settings.py
```
在 base.py 中保留通用的配置，其余的文件保存不同环境的差异化配置。比如 local.py
```python
from mysite.conf.base import *

DEBUG = True
INSTALLED_APPS += (
    'some_apps', # and other apps for local development
)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': 'db.sqlite3',
        'USER': '',
    }
}
```
而 product.py 则可能为
```python
from mysite.conf.base import *

DEBUG = False
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'mysite',
        'USER': 'myuser',
        'PASSWORD': 'nopassword',
    }
}
```
从 local.py 或 product.py 中导入的配置会覆盖 base.py 中已存在的对应配置，所以也可以把默认的配置写在 base.py 中。
在根目录下的 settings.py 中增加根据当前环境导入对应配置的逻辑：
```python
import platform

if platform.node() == "localhost":
    from conf.local import *
else:
    from conf.product import *
```

pip 依赖也可以差异化分离，建立 requirements 路径，
```
requirements
├── base.txt
├── __init__.py
├── local.txt
└── product.txt
```

如果 local.txt 想在 base.txt 的基础上新增若干 pip 包，可以像下面这样处理：
```
-r base.txt
django-debug-toolbar==1.3
```

总体上说，Django 应用的单机部署工作到这儿就进行的差不多了。后续有新的改进再补充进来。