---
title: 理解 Python 生成器
tags:
  - Python
categories:
  - Coding
date: 2016-10-26 20:23:03
---


在 Python 里创建一个有一定规律的序列，很直观的做法就是在循环里创建序列的各个元素。但 Python 有更加符合 Pythonic 风格的做法，就是用生成器来实现。

<!-- more -->

举个被写滥的例子吧，用 Python 生成 Fibonacci 数列的前 n 个数字，该怎么做？

```python
def fib(n):
    if n < 2:
        return 1
    return fib(n - 1) + fib(n - 2)

def gen_fib(n):
    res = []
    for i in range(n):
        res.append(fib(i))
    return res
```

而 Pythonic 的写法是像下面这样：

```python
def fib(n):
    if n < 2:
        return 1
    return fib(n - 1) + fib(n - 2)

def gen_fib(n):
    for i in range(n):
        yield fib(i)
```

查看把上面两种做法的返回结果，可以找到二者的不同：

```shell
<class 'list'>
<class 'generator'>
```

前者返回的是 `list` 对象，后者返回的是 `generator` 对象。这就是本文要探讨的点。

### Generator 对象

再看上面的代码，第一种写法里，`gen_fib()` 方法由 `return` 关键字返回结果；在第二种写法里，`gen_fib()` 方法却没有显式的返回，而是通过 `yield` 关键字得到处理结果。

`yield` 关键字的作用是使对象变成一个 `generator`，换句话说，此时 `generator` 对象还没有把结果生成出来。可以通过 `next()` 方法使 `generator` 对象把待生成的元素逐个生成。看下面这段简单的示例代码：

```python
def test_yield(n):
    yield n
    yield n + 1

g = test_yield(1)
next(g)
next(g)
next(g)
```

运行得到的结果是依次输出 1、2 和抛出 `StopIteration` 的异常信息。`yield` 类似程序执行的断点，`next()` 方法进入到断点的现场，执行断点处的代码，再次调用 `next()`，则进入下一个断点处，直到越界为止。注意，虽然上面多次用了 `yield`，但 `generator` 对象只被创建了一次，且并不是再它被创建时就执行了生成元素的全部过程，而是在调用 `next()` 方法时，才去执行了断点所在处的代码，取得变量值。

因为 `generator` 是 iterable 的，因此可以直接在 for 循环中将元素迭代生成出来，也避免了 `next()` 方法在最后一次查找断点现场时发生越界的问题：

```python
g = gen_fib(10)
for e in g:
    do_something(e)
```

`generator` 的好处显而易见，它不需要像普通的写法那样预先创建一个 iterable 的集合再将其返回，它只是在需要生成某个元素时再去执行生成的代码，这有效提升了内存管理。

*************************************************

参考资料：
  - Python Wiki - [Generators](https://wiki.python.org/moin/Generators)
  - [Improve Your Python: 'yield' and Generators Explained](https://jeffknupp.com/blog/2013/04/07/improve-your-python-yield-and-generators-explained/)
