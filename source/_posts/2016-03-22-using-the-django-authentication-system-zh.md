---
title: '[译] 使用 Django 认证系统'
date: 2016-03-22 22:31:20
tags:
  - Django
categories:
  - Translation
---

> 译自 [Django Documentation](https://docs.djangoproject.com/en/1.9/topics/auth/default/)，版本 1.9。原文遵循 BSD 协议，已向 Django Project 确认翻译自由。

<!-- more -->

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

全面的参考请阅读[完整 API 文档](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User)，下文更偏业务导向。

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
*************************************
### 验证 users
**<font color="green">authenticate(\*\*credentials)<font>[[source](https://docs.djangoproject.com/en/1.9/_modules/django/contrib/auth/#authenticate)]**
要验证给定的用户名和密码，使用 [authenticate()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.authenticate) 方法。它的入参形式为 keyword ，默认的设置为 `username` 和 `password`，如果验证通过，会返回一个 `User` 对象，如果验证失败，则返回 None 。例子如下：
``` python
from django.contrib.auth import authenticate
user = authenticate(username='john', password='secret')
if user is not None:
    # the password verified for the user
    if user.is_active:
        print("User is valid, active and authenticated")
    else:
        print("The password is valid, but the account has been disabled!")
else:
    # the authentication system was unable to verify the username and password
    print("The username and password were incorrect.")
```
> 注
> 这是一个低层次的验证方法；举例来说，它在 [RemoteUserMiddleware](https://docs.djangoproject.com/en/1.9/ref/middleware/#django.contrib.auth.middleware.RemoteUserMiddleware) 中使用。除非要编写自定义的认证系统，否则可能并不需要使用它。如果需要一个限制登录用户操作的方法，参考 [login_required()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.decorators.login_required)。

## 权限和认证

Django 内置一个简单的权限系统。它提供了分配权限给指定用户和指定分组用户的方法。
Django admin site 使用了权限系统，但也可以在自己的代码里使用它。
Django admin site 使用的权限如下所示：
- 查看 "add" 表单和限制拥有该对象 "add" 资格的用户执行 add 操作的权限
- 查看 "change" 列表、"change" 表单和限制拥有该对象 "change" 资格的用户执行 change 操作的权限
- 限制拥有指定对象 "delete" 资格的用户执行 delete 操作的权限
权限不仅可以针对每个对象类型设置，还可以针对具体的对象实例进行设置。通过调用 [ModelAdmin](https://docs.djangoproject.com/en/1.9/ref/contrib/admin/#django.contrib.admin.ModelAdmin) 类提供的 [has_add_permission()](https://docs.djangoproject.com/en/1.9/ref/contrib/admin/#django.contrib.admin.ModelAdmin.has_add_permission)、[has_change_permission()](https://docs.djangoproject.com/en/1.9/ref/contrib/admin/#django.contrib.admin.ModelAdmin.has_change_permission)和[has_delete_permission()](https://docs.djangoproject.com/en/1.9/ref/contrib/admin/#django.contrib.admin.ModelAdmin.has_delete_permission)方法，可以实现对同一对象的不同实体的自定义权限。
User 对象有两个 many-to-many 字段：**group** 和 **user_permissions**。User 对象可以通过和其他 [Django model](https://docs.djangoproject.com/en/1.9/topics/db/models/) 一样的方式访问和它相关的对象：
``` python
myuser.groups = [group_list]
myuser.groups.add(group, group, ...)
myuser.groups.remove(group, group, ...)
myuser.groups.clear()
myuser.user_permissions = [permission_list]
myuser.user_permissions.add(permission, permission, ...)
myuser.user_permissions.remove(permission, permission, ...)
myuser.user_permissions.clear()
```

### 默认权限

当 setting 配置里 [INSTALLED_APPS](https://docs.djangoproject.com/en/1.9/ref/settings/#std:setting-INSTALLED_APPS) 列表里有 **django.contrib.auth**,它会确保为已安装的 Django 应用下的每个 Django model 创建三个权限——add、change 和 delete。
这些权限会在你执行 **[manage.py migrate](https://docs.djangoproject.com/en/1.9/ref/django-admin/#django-admin-migrate)** 时创建；在 **INSTALLED_APPS** 里添加 **django.contrib.auth** 后第一次运行 **migrate** 时，Django 会给之前安装和正在安装的 model 建立默认权限。此后，当你每次执行 **manage.py migrate** 时，会为新安装的 model 创建默认权限（创建权限的方法被 **[post_migrate()](https://docs.djangoproject.com/en/1.9/ref/signals/#django.db.models.signals.post_migrate)** 信号关联）。
假设你安装了 **[app_label](https://docs.djangoproject.com/en/1.9/ref/models/options/#django.db.models.Options.app_label)** 为 **foo** ，model 名为 **Bar** 的应用，我们可以用如下方式测试其基本权限：
- add: **user.has_perm('foo.add_bar')**
- change: **user.has_perm('foo.change_bar')**
- delete: **user.has_perm('foo.delete_bar')**
很少会直接调用 **[permission](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.Permission)** model。
**********************************************
### 组
**[django.contrib.auth.models.Group](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.Group)** model 是用户分类的通用方式，通过它可以应用权限或其他标签到用户上。一个用户可以归属于任意数量的组。
组内的用户会自动获得组的权限。比如说，网站编辑组拥有编辑首页的权限，那么该组所有用户都有这个权限。
除了权限外，组还提供了便利的方法去给用户贴标签和扩展功能。比如，你可以创建 Special users 用户组，然后编写代码赋予他们站点会员权限，或者发送会员专属邮件。
**********************************************
### 编程创建权限
尽管在模型的 **Meta** 类里可以自定义权限，你也可以直接定义权限。比如在 **myapp** 的 **BlogPost** 模型里创建 **can_publish** 权限：
``` python
from myapp.models import BlogPost
from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType

content_type = ContentType.objects.get_for_model(BlogPost)
permission = Permission.objects.create(codename='can_publish',
                                       name='Can Publish Posts',
                                       content_type=content_type)
```
这个权限可以通过 **user_permissions** 属性分配给一个 **User** 或通过 **permissions** 属性分配给组。
**********************************************
### 权限缓存
**[ModelBackend](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.backends.ModelBackend)** 在首次访问 User 对象以检查权限时，缓存了它们的权限。这对于“请求-响应”循环中权限并不是在添加后立即被检查的情况是比较合适的。如果你正在添加权限，而且随即要在测试或视图里进行检查，，最简单的方法就是从数据库中重新获取 **User** 对象，举例如下：
``` python
from django.contrib.auth.models import Permission, User
from django.shortcuts import get_object_or_404

def user_gains_perms(request, user_id):
    user = get_object_or_404(User, pk=user_id)
    # any permission check will cache the current set of permissions
    user.has_perm('myapp.change_bar')

    permission = Permission.objects.get(codename='change_bar')
    user.user_permissions.add(permission)

    # Checking the cached permission set
    user.has_perm('myapp.change_bar')  # False

    # Request new instance of User
    user = get_object_or_404(User, pk=user_id)

    # Permission cache is repopulated from the database
    user.has_perm('myapp.change_bar')  # True

    # ......
```

## 在 Web 请求中认证

Django 使用 [sessions](https://docs.djangoproject.com/en/1.9/topics/http/sessions/) 和 middleware 使认证系统拦截 **[request 对象](https://docs.djangoproject.com/en/1.9/ref/request-response/#django.http.HttpRequest)**。
每个 request 请求都内置一个代表当前 user 的 [request.user](https://docs.djangoproject.com/en/1.9/ref/request-response/#django.http.HttpRequest.user) 属性。如果当前 user 并未登录，该属性就会被设为 [AnonymousUser](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.AnonymousUser) 实例，反之则设置为 [User](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User) 实例。
可以通过 [is_authenticated](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.is_authenticated) 对两者进行区分：
``` Python
if request.user.is_authenticated():
    # Do something for authenticated users.
    # ...
else:
    # Do something for anonymous users.
    # ...
```

### 如何登录用户

如果想把已授权的用户绑定进当前会话中，[login()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.login) 方法可以实现。

login（request, user）[[source](https://docs.djangoproject.com/en/1.9/_modules/django/contrib/auth/#login)]
使用 [login()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.login) 从 view 中登录用户。它接收一个 [HttpRequest](https://docs.djangoproject.com/en/1.9/ref/request-response/#django.http.HttpRequest) 对象和一个 [User](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User) 对象。login() 方法会通过 Django 的 session 框架在当前 session 里保存该登录用户的 id。
注意，任何在匿名会话中设置的数据都会保留在用户登入后的会话中。
下面这个例子展示了如何使用 authenticate() 和 login() 方法。

```python
from django.contrib.auth import authenticate, login

def my_view(request):
    username = request.POST['username']
    password = request.POST['password']
    user = authenticate(username=username, password=password)
    if user is not None:
        if user.is_active:
            login(request, user)
            # Redirect to a success page.
        else:
            # Return a 'disabled account' error message
            ...
    else:
        # Return an 'invalid login' error message.
        ...
```

> 先调用 authenticate() 方法：
> 当手动登录一个用户时，必须要在调用 login() 之前先调用 authenticate() 方法成功认证用户。authenticate() 在 User 对象里设置一个标识了哪种认证后台成功认证的属性（具体细节参考 [backends documentation](https://docs.djangoproject.com/en/1.9/topics/auth/customizing/#authentication-backends)），这个属性信息在之后的 login 过程中会被用到。如果试图登录直接从数据库中取出的用户对象则会被抛出错误。

#### 选择 authentication backend

当用户登录时，认证过程中会用到用户 ID 和 backend，并且保存进用户 session 里。它允许同一个 [authentication backend](https://docs.djangoproject.com/en/1.9/topics/auth/customizing/#authentication-backends) 在以后的的请求中获取用户信息。保存 session 的 authentication backend 由以下情况确定：

1. 如果已提供可选的 backend 参数，则使用该参数指定的 backend；
2. 如果存在 user.backend 属性，则使用该属性指定的 backend；
3. 使用 [AUTHENTICATION_BACKENDS](https://docs.djangoproject.com/en/1.9/ref/settings/#std:setting-AUTHENTICATION_BACKENDS) 内的 backend；
4. 以上情况之外，则抛出异常；

在情况 1 和 2 中，backend 参数值或 user.backend 属性应该是一个 "." 开头的引入路径字符串(类似 [AUTHENTICATION_BACKENDS](https://docs.djangoproject.com/en/1.9/ref/settings/#std:setting-AUTHENTICATION_BACKENDS))，而不是一个实际的 backend 类。

**********************************************

### 如何登出用户

logout(request)[[source](https://docs.djangoproject.com/en/1.9/_modules/django/contrib/auth/#logout)]

要登出一个已通过 [django.contrib.auth.login()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.login) 方法登录的用户，在 view 中调用 [django.contrib.auth.logout()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.logout)。logoout() 方法需要传入一个 [HttpRequest](https://docs.djangoproject.com/en/1.9/ref/request-response/#django.http.HttpRequest) 对象，没有返回值。示例：
```python
from django.contrib.auth import logout

def logout_view(request):
    logout(request)
    # Redirect to a success page.
```

注意，[logout()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.logout) 即使在用户没有登录的情况下调用也不会抛出任何错误。

当调用 [logout()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.logout) 时，当前请求的 ession 数据会被彻底清除。这是为了防止其他人使用这台浏览器登录并获取前一用户 session 数据。如果你想在登出用户后立即访问存入 session 的数据，请在调用 [django.contrib.auth.logout()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.logout) 之后存入。

**********************************************

### 登录用户访问限制

#### 原始的方法

简单的、原始的限制访问页面的方法是检查 [request.user.is_authenticated()](https://docs.djangoproject.com/en/1.9/ref/contrib/auth/#django.contrib.auth.models.User.is_authenticated)，验证不通过的话重定向到登录页。
```python
from django.conf import settings
from django.shortcuts import redirect

def my_view(request):
    if not request.user.is_authenticated():
        return redirect('%s?next=%s' % (settings.LOGIN_URL, request.path))
    # ...
```

……或者显示一个错误页：
```python
from django.shortcuts import render

def my_view(request):
    if not request.user.is_authenticated():
        return render(request, 'myapp/login_error.html')
    # ...
```

#### login_required 装饰器

login_required(redirect_field_name='next', login_url=None)[[source](https://docs.djangoproject.com/en/1.9/_modules/django/contrib/auth/decorators/#login_required)]

可以使用 [login_required()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.decorators.login_required) 装饰器作为便捷方式：
```python
from django.contrib.auth.decorators import login_required

@login_required
def my_view(request):
    ...
```

[login_required()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.decorators.login_required)
做了下面这些事：
- 如果用户未登录，跳转到 [settings.LOGIN_URL](https://docs.djangoproject.com/en/1.9/ref/settings/#std:setting-LOGIN_URL) 指定的页面，并传递当前请求的绝对路径。例如：/accounts/login/?next=/polls/3/
- 如果用户已登录，正常执行 view。view 代码可以安全的假定用户是登录状态。

默认情况下，在用户成功认证后应该被重定向的路径存储在"next"参数中。如果你希望自定义参数名，[login_required()](https://docs.djangoproject.com/en/1.9/topics/auth/default/#django.contrib.auth.decorators.login_required) 接收一个可选参数 redirect_field_name：
```python
from django.contrib.auth.decorators import login_required

@login_required(redirect_field_name='my_redirect_field')
def my_view(request):
    ...
```

注意，如果不指定 login_url 参数，则需要确保在 settings.LOGIN_URL 已经跟登录视图正确关联。例如，采用默认配置，在 URLConf 路由里添加以下内容：
```python
from django.contrib.auth import views as auth_views

url(r'^accounts/login/$', auth_views.login),
```

[settings.LOGIN_URL](https://docs.djangoproject.com/en/1.9/ref/settings/#std:setting-LOGIN_URL) 也接收视图函数名和 URL 命名模式。这使得你可以自由地重映射 URLconf 中的登录视图而不用更新设置。

> 注意，login_required 装饰器并不会检查用户的 is_active 标识。
> 另外，如果你要给 Django's admin 编写自定义的视图（或者是需要内置视图使用的认证检查），可以采用 [django.contrib.admin.views.decorators.staff_member_required()](https://docs.djangoproject.com/en/1.9/ref/contrib/admin/#django.contrib.admin.views.decorators.staff_member_required) 装饰器取代 login_required()。

#### LoginRequired Mixin
