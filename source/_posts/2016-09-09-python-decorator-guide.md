---
title: 深入理解 Python 装饰器
tags:
  - Python
categories:
  - Coding
date: 2016-09-09 22:42:36
---


前一篇水文里记录的 Click 包，大量的运用了 Python 的装饰器。装饰器是非常实用的编程思想，Java 开发里经常看到的 AOP 也是同样的思想。Python 装饰器使用很简单，只需要在需要装饰的方法前加上注解 `@decorator` 函数进行包裹。但是经常用不代表能理解到位，下文就来尝试捋一捋 Python 装饰器的来龙去脉。

<!-- more -->

### 管窥装饰器

下面是一个很简单的 Python 方法：

```python
def call():
    print('call me')

call()
```

很简单，这会得到 "call me" 的文本输出。现在增加一个时间标记，告知是什么时间呼叫的我，可以这么改：

```python
import time

def call():
    print('call me')
    print('at ', time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time()))))
          
call()
```

这么做有一个麻烦的地方，就是在 `call()` 方法内部做了改动。在很多场景下，我们不希望去改变方法本身的行为，因为这个方法可能在很多地方都被调用了，如果在方法内部做了修改，那么对每个调用都会产生影响，但我们只希望在某些调用时才去改变它的行为。比较常见的实用场景如用户登录拦截。

不改变函数本身，那么该如何对 `call()` 加上时间标记呢？这就到装饰器大显身手的时候了。装饰器可以把被装饰的方法包裹起来，被装饰者本身的行为不会变，装饰器只是在它之外添加了额外的功能。下面这张图解释的很形象：

![](https://o70e8d1kb.qnssl.com/qxf2-gun-decorator1.jpg)

```python
import time

def call():
    print('call me ')

def mark_time(func):
    def wrapper(*args, **kwargs):
        func()
        print('at',
              time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())))

    return wrapper


call = mark_time(call)
call()
```

上面就实现了简朴的装饰器，Python 内置了对装饰器的语法支持，可以更便捷的实现装饰功能，就是上面提到的 `@decorator`，这相当于是 `func = decorator(func)` 的作用。

```python
import time

def mark_time(func):
    def wrapper(*args, **kwargs):
        func()
        print('at',
              time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())))

    return wrapper

@mark_time
def call():
    print('call me ')

call()
```

可以看出，`@mark_time` 的作用等同于 `call = mark_time(call)`，得到一个可调用的函数名。

如果需要多个装饰器来实现功能，只需要按顺序对方法进行装饰，装饰的顺序是从下到上：

```python
@f1(arg)
@f2
def foo():
    pass

foo()
```

等效于执行 `f1(arg)(f2(foo))()`

### 认识函数

了解装饰器的基础用法只是皮毛，深入理解装饰器前，得先理解函数究竟是什么。

首先明确一点，在 Python 中，函数 function 也是一种对象 Object。这就意味着：
  - 函数可以被指派为参数（作为传入或返回值）；
  - 函数可以被定义在函数体中；

因此，函数的返回值可以是另一个函数。手写一段示例代码来印证这一点：

```python
def get_drink(choice='tea'):
    def serve_tea():
        return 'Green tea'

    def serve_coffee():
        return 'Coffee latte'

    if choice == 'tea':
        return serve_tea
    else:
        return serve_coffee

my_drink = get_drink()

print(my_drink)  # <function get_drink.<locals>.serve_tea at 0x7f313f307f28>

print(my_drink())  # Green tea

print(get_drink('coffee')())  # Coffee latte
```

这样之前写的装饰器函数返回的 `wrapper` 就不难明白了。装饰器的本质就是实现了在被装饰的方法执行之前/之后，执行装饰的动作。

### 带参装饰器

假设有这么个需求，在前面的 `call()` 方法之前加上主语，实现 "{who} calls me at {time}"，可以考虑给装饰器函数本身传递一个入参 {who}。
已有的装饰器是这样的：

```python
call = mark_time(call)
call()
```

增加入参的装饰器是这样的：

```python
call = mark_time('sudoz')(call)
call()
```

拆开来看上面的代码：先执行 `mark_time('sudoz')` 返回一个回调函数 wrapper\_1（假设是这个函数名），然后执行 `wrapper_1(call)`，得到另一个回调函数 wrapper\_2，`call()` 实际上运行的是 `wrapper_2()`。这么拆解开来，就很好实现带参的装饰器方法了，就是相比不带参的装饰器外面多套一层以返回 wrapper\_1：

```python
import time

def mark_time(who):
    def wrapper_1(func):
        def wrapper_2(*args, **kwargs):
            print('%s' % who)
            func()
            print('at',
                  time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(time.time())))
        return wrapper_2
    return wrapper_1

@mark_time('sudoz')
def call():
    print('call me ')

call()
```

### 内置装饰器

Python 类有 3 个内置的装饰器：`@staticmethod`，`@classmethod`，`property`——
  - `@staticmethod` 装饰的方法是类的静态方法，即无需通过类的实例去调用，因此方法的参数中没有类实例 `self`；
  - `@classmethod` 装饰的方法是类方法，方法的第一个参数是类对象 `cls`，可以在方法内调用类对象本身；
  - `@property` 装饰的方法是类的属性，装饰器内部定义了 `getter` 和 `setter` 方法，这种方式和 Java 里的 `getXXX`、`setXXX` 非常相像；

代码演示下：

```python
class Demo:
    def __init__(self, name, city):
        self._name = name
        self._city = city

    @staticmethod
    def test_static_method():
        print('nothing to do.')

    @classmethod
    def test_class_method(cls):
        print(cls.__name__)

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self, name):
        self._name = name

    @property
    def city(self):
        return self._city


demo = Demo('sudoz', 'beijing')
Demo.test_static_method()  # nothing to do
demo.test_static_method()  # nothing to do
demo.test_class_method()   # Demo
print(demo.name)           # sudoz beijing
demo.name = 'anonymous'
print(demo.name)           # anonymous
try:
    demo.city = 'hangzhou'
    print(demo.city)
except Exception as e:
    print(e)              # can't set attribute
```

注意上面的代码，如果被 `@property` 装饰的属性没有设置 `setter` 方法，那么该属性就是类的只读属性，不能被修改，因此上面试图修改 city 属性，抛出异常。

### functools 进阶

装饰器在执行时，有一个隐蔽的小动作可能会被忽略：它把被装饰的函数的 `__name__` 属性给置换成回调函数的属性了。测试下上面代码里被装饰后的 `call` 的 `__name__` 属性，不再是 "call" 而是 "wrapper_2"。Python 2.5 版本新增的 `functools.wraps()` 解决了这个问题，它会把被装饰方法的名称，模块复制到装饰器内。而`functools.wraps()` 本身也是一个装饰器。

```python
import functools


def foobar(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        print('foo')
        return func(args)

    return wrapper


@foobar
def say_hello(*args, **kwargs):
    print('Hello %s' % args[0])


print(say_hello.__name__)  # Output: bar

say_hello('sudoz')  # Output: Hello sudoz
```
