---
title: Python Click 学习笔记
date: 2016-09-03 01:22:37
tags:
  - Python
categories:
  - Coding
---

[Click](https://pypi.python.org/pypi/click) 是 Flask 的团队 pallets 开发的优秀开源项目，它对命令行工具的开发封装了大量方法，使开发者只需要专注于功能实现。恰好我最近在开发的一个小工具需要在命令行环境下操作，就做个学习笔记。

<!-- more -->

国际惯例，先来一段 "Hello World" 程序（假定已经安装了 Click 包）。

```python
# hello.py
import click

@click.command()
@click.option('--count', default=1, help='Number of greetings.')
@click.option('--name', prompt='Your name',
              help='The person to greet.')
def hello(count, name):
    """Simple program that greets NAME for a total of COUNT times."""
    for x in range(count):
        click.echo('Hello %s!' % name)

if __name__ == '__main__':
    hello()
```

执行 `python hello.py --count=3`，不难猜到控制台的输出结果。除此之外，Click 还悄悄地做了其他的工作，比如帮助选项：

```shell
$ python hello.py --help
Usage: hello.py [OPTIONS]

  Simple program that greets NAME for a total of COUNT times.

Options:
  --count INTEGER  Number of greetings.
  --name TEXT      The person to greet.
  --help           Show this message and exit.
```

### 函数秒变 CLI

从上面的 "Hello World" 演示中可以看出，Click 是通过装饰器来把一个函数方法装饰成命令行接口的，这个装饰器方法就是 `@click.command()`。

```python
import click

@click.command()
def hello():
    click.echo('Hello World!')
```

`@click.command()` 装饰器把 `hello()` 方法变成了 `Command` 对象，当它被调用时，就会执行该实例内的行为。而 `--help` 参数就是 `Command` 对象内置的参数。

不同的 `Command` 实例可以关联到 `group` 中。`group` 下绑定的命令就成为了它的子命令，参考下面的代码：

```python
@click.group()
def cli():
    pass

@click.command()
def initdb():
    click.echo('Initialized the database')

@click.command()
def dropdb():
    click.echo('Dropped the database')

cli.add_command(initdb)
cli.add_command(dropdb)
```

`@click.group` 装饰器把方法装饰为可以拥有多个子命令的 `Group` 对象。由 `Group.add_command()` 方法把 `Command` 对象关联到 `Group` 对象。
也可以直接用 `@Group.command` 装饰方法，会自动把方法关联到该 `Group` 对象下。

```python
@click.group()
def cli():
    pass

@cli.command()
def initdb():
    click.echo('Initialized the database')

@cli.command()
def dropdb():
    click.echo('Dropped the database')
```

命令行的参数是不可或缺的，Click 支持对 `command` 方法添加自定义的参数，由 `option()` 和 `argument()` 装饰器实现。

```python
@click.command()
@click.option('--count', default=1, help='number of greetings')
@click.argument('name')
def hello(count, name):
    for x in range(count):
        click.echo('Hello %s!' % name)
```

通过 Click 编写了简单的命令行方法后，还需要把 .py 文件转换成可以在控制台里运行的命令行工具。最简单的办法就是在文件末尾加上如下代码：

```python
if __name__ == '__main__':
    command()
```

Click 支持使用 `setuptools` 来更好的实现命令行打包。