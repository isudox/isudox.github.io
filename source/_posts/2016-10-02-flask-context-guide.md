---
title: 读源码认识 Flask Context
date: 2016-10-02 20:11:40
tags:
  - Flask
  - Python
categories:
  - Coding
---

Flask Context 类似 Spring 框架的核心组件 Context，给应用程序提供运行时所需的环境（包含状态、变量等）的快照。如果程序本身就包含了运行所需的完备条件，那么它可以独立运行了；如果程序需要外部环境的支持，Context 的存在就有意义。比如 Flask Web 开发中常用的 `current_app`、`request` 都是 Context，可以在不同方法中调用，并且实现通信及交互。

<!-- more -->

### Context 的实现

Flask 提供了 4 个 Context：

| Context | 类型 | 说明 |
|:------:|:------:|:--------:|
| flask.current_app | Application Context | 当前 app 的实例对象 |
| flask.g | Application Context | 处理请求时用作临时存储的对象 |
| flask.request | Request Context | 封装了 HTTP 请求中的内容 |
| flask.session | Request Context | 存储了用户回话 |

这些 Context 分为 Application Context 和 Request Context 两类：
  - Application Context: 是提供给由 `app = Flask(__name__)` 所创建的 Flask app 的 Context；
  - Request Context: 是客户端发起 HTTP 请求时，Flask 对象为 HTTP 请求对象所创建的 Context；

这些 Context 定义在 Flask 源码（v0.11）的 `global.py` 中，截取部分源码如下：

```python
from werkzeug.local import LocalStack, LocalProxy

_request_ctx_stack = LocalStack()
_app_ctx_stack = LocalStack()
```

`_request_ctx_stack` 和 `_app_ctx_stack` 分别是 Flask 保存 request context 和 application context 的全局栈，由 Werkzeug 库的 `LocalStack` 和 `LocalProxy` 创建实例。

#### LocalStack 和 LocalProxy

在认识 LocalStack 之前，先来了解 `local.py` 中的 Local 类，Local 类内由 `__slots__` 确定了唯二两个属性：`__storage__` 和 `__ident_func__`，其中，`__ident_func__` 属性是获取当前线程标识符的方法调用，`__storage__` 属性是字典，其 key 就是当前线程的标识符。参看源码：

```python
# werkzeug.local.Local
class Local(object):
    __slots__ = ('__storage__', '__ident_func__')

    def __init__(self):
        object.__setattr__(self, '__storage__', {})
        object.__setattr__(self, '__ident_func__', get_ident)

    def __getattr__(self, name):
        try:
            return self.__storage__[self.__ident_func__()][name]
        except KeyError:
            raise AttributeError(name)

    def __setattr__(self, name, value):
        ident = self.__ident_func__()
        storage = self.__storage__
        try:
            storage[ident][name] = value
        except KeyError:
            storage[ident] = {name: value}
```

LocalStack 类内置的 `_local` 是 Local 类的实例，总体作用和 Local 类似。不同之处在于，LocalStack "自作主张"的在 `__storage__` 的 value 内维护一个名为 "stack" 的栈， 可以通过 `push`、`pop` 和 `top` 将对象入栈、出栈和取得栈顶元素。源码如下：

```python
# werkzeug.local.LocalStack
class LocalStack(object):
    def __init__(self):
        self._local = Local()

    def push(self, obj):
        rv = getattr(self._local, 'stack', None)
        if rv is None:
            self._local.stack = rv = []
        rv.append(obj)
        return rv

    def pop(self):
        stack = getattr(self._local, 'stack', None)
        if stack is None:
            return None
        elif len(stack) == 1:
            release_local(self._local)
            return stack[-1]
        else:
            return stack.pop()

    @property
    def top(self):
        try:
            return self._local.stack[-1]
        except (AttributeError, IndexError):
            return None
```

LocalStack 的使用非常简单，简单的示例如下:

```
>>> ls = LocalStack()
>>> ls.push(42)
>>> ls.top
42
>>> ls.push(23)
>>> ls.top
23
>>> ls.pop()
23
>>> ls.top
42
```

LocalProxy 类是 werkzeug local 的代理，LocalProxy 类的构造函数必须传入一个可调用的参数（方法），通过调用得到的结果就是 LocalStack 实例化的栈的栈顶元素。`__local` 就是被代理的对象，对 LocalProxy 对象的操作都会作用于实际被代理的对象上。参考源码：

```python
# werkzeug.local.LocalProxy
class LocalProxy(object):
    __slots__ = ('__local', '__dict__', '__name__')

    def __init__(self, local, name=None):
        object.__setattr__(self, '_LocalProxy__local', local)
        object.__setattr__(self, '__name__', name)

    def _get_current_object(self):
        if not hasattr(self.__local, '__release_local__'):
            return self.__local()
        try:
            return getattr(self.__local, self.__name__)
        except AttributeError:
            raise RuntimeError('no object bound to %s' % self.__name__)

    def __getattr__(self, name):
        if name == '__members__':
            return dir(self._get_current_object())
        return getattr(self._get_current_object(), name)
```

#### request 和 session

Flask 对 `request` 的定义如下：

```python
def _lookup_req_object(name):
    top = _request_ctx_stack.top
    if top is None:
        raise RuntimeError(_request_ctx_err_msg)
    return getattr(top, name)
request = LocalProxy(partial(_lookup_req_object, 'request'))
```

由偏函数 `partial()` 将属性名 "request" 传入 `_lookup_req_object()` 得到可调用的方法，该方法的执行结果就是 LocalProxy 代理的 `_request_ctx_stack` 栈顶元素 `RequestContext` 实例。

`RequestContext` 包含了 Request 的所有相关信息，它在请求开始时被创建并被推入到 `_request_ctx_stack` 栈中，在请求结束后出栈。
参考源码：

```python
# flask.ctx.RequestContext
class RequestContext(object):
    def __init__(self, app, environ, request=None):
        self.app = app
        if request is None:
            request = app.request_class(environ)
        self.request = request
        self.session = None
        self._implicit_app_ctx_stack = []

    def push(self):
        """部分省略"""
        app_ctx = _app_ctx_stack.top
        if app_ctx is None or app_ctx.app != self.app:
            app_ctx = self.app.app_context()
            app_ctx.push()
            self._implicit_app_ctx_stack.append(app_ctx)
        else:
            self._implicit_app_ctx_stack.append(None)
        
        _request_ctx_stack.push(self)
    
    def pop(self, exc=_sentinel):
        """省略"""
```

这里需要留意 `push()` 方法，它首先会找出 `_app_ctx_stack` 栈顶元素 `AppContext`，如果栈顶元素为空，或者当前 app 不是栈顶 Context 所属的 app（AppContext 对应所属的 Flask app，这种情况存在于 Flask 应用包含多个 app 时），则将当前的 `AppContext` 入栈到当前 app 的 `_app_ctx_stack` 中，之后再将 `RequestContext` 入栈到 `_request_ctx_stack` 栈中。这就完成了 Request Context 和 Application Context 的关联。

RequestContext 中 `session` 初始化为 `None`，当 RequestContext 入栈时，`session` 被赋值：

```python
# flask.ctx.RequestContext
class RequestContext(object):
    """部分省略"""
    def __init__(self, app, environ, request=None):
        self.session = None

    def push(self):
        self.session = self.app.open_session(self.request)
        if self.session is None:
            self.session = self.app.make_null_session()
```

`app.open_session()` 方法会通过 Flask app 从 `SecureCookieSessionInterface` 实例中打开或创建 session。

正因为 `request` 和 `session` 都是 RequestContext 的属性，所以是由如下方式从 Flask app 中获取：

```python
# flask.globals
request = LocalProxy(partial(_lookup_req_object, 'request'))
session = LocalProxy(partial(_lookup_req_object, 'session'))
```

偏函数 `partial` 把属性名传入可调用的 `_lookup_req_object` 方法中，分别得到当前 Flask app 的 RequestContext 实例中的 `request` 和 `session`。

#### current_app 和 g

继续看 `flask.local` 中对 `current_app` 的定义：

```python
def _find_app():
    top = _app_ctx_stack.top
    if top is None:
        raise RuntimeError(_app_ctx_err_msg)
    return top.app

current_app = LocalProxy(_find_app)
```

`current_app` 是通过 LocalProxy 获取代理的 application request 的栈顶对象。先对它做一个试验：

```python
from flask import Flask, current_app

app = Flask(__name__)
print(current_app.name)
```

运行后会抛出 "RuntimeError: Working outside of application context." 的异常，这是因为在创建 Flask App 时，`AppContext` 还没有压入到 `_app_ctx_stack` 栈内，栈顶没有元素，所以需要先做入栈操作：

```python
app_ctx = app.app_context()  # 手动创建 AppContext
app_ctx.push()  # 把 AppContext 入栈到 _app_ctx_stack
print(current_app.name)
app_ctx.pop()  # 从 _app_ctx_stack 出栈
```

但实际开发中，我们并没有人为的去对 `_app_ctx_stack` 进行入栈出栈操作，那么栈内元素是什么时候入栈的呢？其实之前在分析 RequestContext 时已经涉及到了，因为当请求到达 Flask 应用时，会自动将 Request Context 推入到 `_request_ctx_stack`，因为 Request Context 必须是和 Application Context 关联，即必须在后者的生命周期内，因此如果 `_app_ctx_stack` 为空，会隐式的把 AppContext 入栈。

再看 `g` 的定义：

```python
# flask.globals
def _lookup_app_object(name):
    top = _app_ctx_stack.top
    if top is None:
        raise RuntimeError(_app_ctx_err_msg)
    return getattr(top, name)
g = LocalProxy(partial(_lookup_app_object, 'g'))
```

`g` 其实就是通过 LocalProxy 代理得到 `_app_ctx_stack` 栈顶元素 AppContext 内属性为 "g" 的对象。从 `flask.ctx` 中回溯对属性 "g" 的定义：

```python
# flask.ctx.AppContext
class AppContext(object):
    def __init__(self, app):
        self.g = app.app_ctx_globals_class()
```

属性 "g" 是由 Flask app 调用 `app_ctx_globals_class()` 赋值，继续回溯源码：

```python
# flask.app.Flask
class Flask(_PackageBoundObject):
    app_ctx_globals_class = _AppCtxGlobals
```

`_AppCtxGlobals` 是字典集合，保存了 `flask.g` 的信息。

这里需要插播一条贴士，在 Flask 0.9 里，`flask.g` 是通过 `request_globals_class` 获取，而从 0.10 开始，改为 `app_ctx_globals_class`，因为 `flask.g` 变成了 Application Context。

另外，在 RequestContext 中，还拥有 `flask.g` 的 getter 和 setter：

```python
# flask.ctx.RequestContext
class RequestContext(object):
    def _get_g(self):
        return _app_ctx_stack.top.g
    def _set_g(self, value):
        _app_ctx_stack.top.g = value
    g = property(_get_g, _set_g)
    del _get_g, _set_g
```

也就是说，在每次客户端请求时，生成的 RequestContext 都可以对 `flask.g` 进行读写，因此在每次处理请求时，`flask.g` 可以作为临时存储的对象。

#### 小结

啰啰嗦嗦抄了一大堆源码，写了一大堆废话，归结下来其实就几条结论——

AppContext 是基于 `app = Flask(__name__)` 创建的 Flask app 层面上的 Context。对于同一个 Flask app 下的成员，都拥有同一个 AppContext。

RequestContext 的生命周期在 AppContext 生命周期内，每个请求都会生成一个 RequestContext，不同的 RequestContext 对应一个 AppContext。

RequestContext 内维护一个 `request` 属性，即 `flask.request` 对象。也就是说，每次 HTTP 请求都会新创建一个 `flask.request`，本质上就是 `flask.app.Request` 对象。

**********************************

参考资料：
  - Flask Docs
  - Python Web 开发实战（董伟明）
