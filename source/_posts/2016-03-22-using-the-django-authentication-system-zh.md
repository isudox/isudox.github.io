---
title: 【译】使用 Django 认证系统
date: 2016-03-22 22:31:20
tags:
- Django
categories:
- Translation
---

> 译自 [Django Documentation](https://docs.djangoproject.com/en/1.9/topics/auth/default/)，版本1.9。没有逐字逐句翻译，啰嗦的内容都省去了。

本文介绍了 Django 认证系统在默认配置下的使用。默认配置已经发展到能够满足大多数项目需求，处理相当数量的任务，而且具备严谨的密码和权限实现。对于有自定义验证需求的项目，Django 支持[扩展验证](https://docs.djangoproject.com/en/1.9/topics/auth/customizing/)。
Django 认证系统提供认证和授权功能，由于两部分功能有耦合，因此通常简称为认证系统。

## User 对象

[User](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User) 对象是认证系统的核心。该对象一般抽象表示与网站进行交互的用户，被用来进行权限控制，信息注册，关联内容及其创建者。Django 框架中只存在一种 User 类，像`superusers`，`staff`只是具有一些特殊属性的 User 对象，而不是不同类的 User 对象。

默认的 user 有如下主要属性：
- [username](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.username)
- [password](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.password)
- [email](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.email)
- [first_name](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.first_name)
- [last_name](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.last_name)

全面的参考请阅读[完整 API 文档](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User)，下文更偏向业务导向。

### 创建 users

创建 user 最直接的方式是调用内置的 `create_user()` 辅助方法：
``` bash
>>> from django.contrib.auth.models import User
>>> user = User.objects.create_user('john', 'lennon@thebeatles.com', 'johnpassword')

# At this point, user is a User object that has already been saved
# to the database. You can continue to change its attributes
# if you want to change other fields.
>>> user.last_name = 'Lennon'
>>> user.save()
```
如果已经安装了 `Django admin` ，也可以[交互式创建 users](https://docs.djangoproject.com/en/1.9/topics/auth/default/#auth-admin)。
**************************************
### 创建 superusers

使用 `createsuperuser` 命令创建 superusers：
```bash
$ python manage.py createsuperuser --username=joe --email=joe@example.com
```
控制台会提示输入密码，输入密码后，superuser 就创建完成了。如果没有加上 [--username](https://docs.djangoproject.com/en/1.9/ref/django-admin/#cmdoption-createsuperuser--username) 或 [--email](https://docs.djangoproject.com/en/1.9/ref/django-admin/#cmdoption-createsuperuser--email) 选项，控制台会提示输入对应值。
**************************************
### 修改密码

Django 不会在 user 模型里存储原密码（明文），而是哈希值（详情参阅[密码是如何管理的](https://docs.djangoproject.com/en/1.9/topics/auth/passwords/)）。因此，不要试图直接操作 user 密码。这就是为什么要使用辅助函数创建 user 。

要修改用户密码，有如下几种选择：
[manage.py changepassword *username*](https://docs.djangoproject.com/en/1.9/ref/django-admin/#django-admin-changepassword) 提供了由命令行修改用户密码的方法。它会提示你必须输入两次密码以对原密码进行修改，如果两次输入一致，新密码生效。如果没有指定 user ，则控制台会尝试修改与当前系统用户名相匹配的 user 密码。

也可以通过程序代码修改密码，使用函数 [set_password()](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.set_password):
``` python
from django.contrib.auth.models import User
u = User.objects.get(username='john')
u.set_password('new password')
u.save()
```
如果已经安装了 Django admin，也可以在[认证系统管理员页](https://docs.djangoproject.com/en/1.9/topics/auth/default/#auth-admin)修改密码。
Django 同时提供可能会用于用户修改自己密码的 [views](https://docs.djangoproject.com/en/1.9/topics/auth/default/#built-in-auth-views) 和 [forms](https://docs.djangoproject.com/en/1.9/topics/auth/default/#built-in-auth-forms)。
如果 Django 的 [SessionAuthenticationMiddleware](https://docs.djangoproject.com/en/1.9/ref/middleware/#django.contrib.auth.middleware.SessionAuthenticationMiddleware) 已开启，则修改用户密码会登出改用户的所有 session。具体细节查阅[修改密码导致 session 失效](https://docs.djangoproject.com/en/1.9/topics/auth/default/#session-invalidation-on-password-change)。
