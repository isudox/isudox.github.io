---
title: uWSGI 部署 Django 应用到 Nginx
date: 2016-06-01 17:24:27
tags:
  - DevOps
  - Django
  - Nginx
  - uWSGI
  - Python
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

在安装好 Django 项目专有 Python 环境后，就是部署工作。Nginx 和 uWSGI 是不错的选择，uWSGI 是服务器网关接口 WSGI 的一种实现，它可以通过 Unix socket 或端口将客户端请求打到 Django 的路由，