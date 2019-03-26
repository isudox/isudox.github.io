---
title: JavaScript ES6 和 Python 中的 Generator
date: 2018-04-22 23:20:03
tags:
  - Python
  - JavaScript
categories:
  - Coding
---

这几天折腾的一个 RSS 聚合爬虫，前端部分涉及到 `redux-saga`，对 ES6 里引入的 Generator 运用很花哨，看起来会云里雾里，其实和 Python 的 `generator`、`yield` 从思想上到写法上基本是一致的，之前也写过 Python 里的用法，这里也简单的写下我对动态语言里 `generator` 的学习和理解。

<!-- more -->

## 通识
首先，`generator` 本质上还是 `function`，只是行为略微特殊。
普通 `function` 会在执行结束时通过 `return` 返回；
`generator` 可以中断 `function` 的执行过程，并重新回到断点现场继续执行。具体实现就是通过 `yield` 将结果返回给调用方并中断，通过 `next()` 方法继续回到断点再执行到下一个 `yield` 断点处。
普通函数只会返回一次，就是在执行结束的时候；`generator` 函数在执行过程中可以多次返回，即在 `yield` 断点处取代了 `return`。

还有一个和 `generator` 紧密相关的概念是 `iterator`，简单的描述二者的关系就是──`generator` 实现的目的是生成一个 `iterator`，它是 `iterable` 的，也就是说是可以循环遍历的。

## ES6

JavaScript ES6 的 `generator` 和普通函数相比，最明显的不同在于它的关键字包含星号 `*` 和 `yield`，比如 MDN 文档上的代码示例：

```javascript
function* generator(i) {
  yield i;
  yield i + 10;
}

var gen = generator(10);

console.log(gen.next().value);
// expected output: 10

console.log(gen.next().value);
// expected output: 20
```

来看看上面的代码先后发生了什么──
1. `function* generator(i) {}` 代码块声明了一个 `generator`，此时什么都没发生；
2. `var gen = generator(10)` 创建了一个 `generator` 并赋给变量 `gen`；
3. 第一次调用 `gen.next().value` 时，执行了 `generator` 进入到第一个 `yield` 的地方，中断执行并返回 i，即 10；
4. 第二次调用 `gen.next().value` 时，回到 `generator` 断点现场继续执行直到第二个 `yield` 再次中断并返回 i + 10，即 20；

可以预料的，如果第三次调用 `gen.next().value` 得到的会是 `undefined`，因为这个 `generator` 在第二次调用时已经结束了所有断点完成了“生成”的任务。

注意到 `next()` 方法，它返回的是一个包含两个属性的 JSON 对象：

```javascript
{
  value: object,
  done: boolean
}
```

value 即 `generator` 创建的 `iterator` 里的元素，done 则表示该 `iterator` 是否结束。

再来看 `generator` 的经典场景，生成 Fibonacci 数列。

```javascript
// generator pattern
function* genFib(n) {
  yield a = 0
  b = 1

  while(b <= n) {
    yield b
      b = b + a
      a = b - a
  }
}

var fib = genFib(100)

for (let value of fib) {
    console.log(value)
}
```

由之前的过程分析，这个 Fibonacci 数列生成过程就非常好理解了。
换个写法，如果是普通的循环迭代生成 Fibonacci 数列，一般就是类似下面代码的形式。

```javascript
// loop pattern
function genFib(n) {
  let a = 0
  let b = 1
  let fib = [0]

  while(b <= n) {
    fib.push(b)
      b = b + a
      a = b - a
  }

  return fib
}
```

乍一看两者似乎只是写法上的不同，实际运行速度因为样本数量级太小也比较不出差异。但仔细观察，就不难发现，第二种循环迭代的写法会把结果全部存储在内存中，只有当它完全生成后，才会返回；而第一种生成器的写法，每次只会生成一个元素并立刻返回。当数量 n 很大时，`generator` 的资源和性能收益就很可观了。

JavaScript 就像一匹脱缰的野马，语法实在是太灵活了，有好多写法会让程序员觉得怪异，就比如 `yield*` 的用法，这个表达式其实是用来将一个 `generator` 委托给另一个 `generator`，笑 cry……

比如前面的例子里，`generator` 是赋给一个普通变量，而 `yield* [[expression]]` 则是将右侧表达式的 `generator` 的每个元素都做一次 `yield`。

```javascript
function* gen1() {
  yield 1;
  yield 2;
  yield 3;
}

function* gen2() {
  yield* gen1();
  yield 4;
}

[...gen2()];
// [ 1, 2, 3, 4 ]
```

JavaScript 内置的支持 `iterable` 的对象有 `String`，`Array`，`TypedArray`，`Map`，`Set`。所以这些内置对象也支持 `yield*` 表达式，`for-of` 表达式和 `...` 表达式，非常“灵活”。

理解了 JavaScript ES6 里的 `generator`，对 redux-saga 状态管理的理解就比较轻松了，后面有时间了再写关于 redux-saga 的内容。

## Python

Python 中的 `generator` 和 JavaScript 的实现基本是相同的。还是用 Fibonacci 举例。

```python
def gen_fib(n):
    yield 0
    a, b = 0, 1

    while b <= n:
        yield b
        b = b + a
        a = b - a

for value in gen_fib(100):
    print(value)
```

Python 版本只是增加了 `yield` 关键字，并没有在函数声明的地方设计 `*` 来表征 `generator`。
之前的博客[理解 Python 生成器](/2016/10/26/python-generator-guide/) 写的很浅，这里试着从 Magic Method 着手更深入的写写。

Python 内置了一些由双下划线包裹、被称为 Magic Method 的特殊方法，像常用的 `__init__`，`__new__`，`__str__`。这些 Magic Method 设计的初衷是为了描述对象的内在行为，而无需外部显性调用。比如我们声明一个对象，并编写它的 `__init__` 方法：

```python
class Book:

    def __init__(self, name, author):
        self.name = name
        self.author = author


book = Book('Harry Potter', 'J.K Rowling')
book.__getattribute__('name')
book.__getattribute__('author')
```

我们并没有直接调用 `__init__` 方法，但 Python 解释能理解并调用 `__init__` 初始化对象。
