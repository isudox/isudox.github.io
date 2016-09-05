---
title: Python Click 包学习笔记
tags:
  - Python
categories:
  - Coding
---

[Click](https://pypi.python.org/pypi/click) 是 Flask 的开发小组 pallets 另一个非常优秀的开源项目。Click 包封装了大量命令行的交互实现，开发者只需要专注于要实现的功能。正好自己最近正在写的一个小工具需要在命令行下进行文件处理，借此做个入门学习笔记。

<!-- more -->

国际惯例，先来看 Click 的 "Hello World" 程序（假设已经安装了 click 包）——

```python
# hello.py
import click


@click.command()
@click.option('--count', default=1, help='Number of greetings.')
@click.option('--name', prompt='Your name', help='The person to greet.')
def hello(count, name):
    """Simple program that greets NAME for a total of COUNT times."""
    for x in range(count):
        click.echo('Hello %s!' % name)

if __name__ == '__main__':
    hello()
```

执行 `python hello.py --count=3`，不难猜到控制的输出结果。除此之外，Click 还悄悄实现了更多的功能：

```bash
$ python hello.py --help
Usage: hello.py [OPTIONS]

  Simple program that greets NAME for a total of COUNT times.

Options:
  --count INTEGER  Number of greetings.
  --name TEXT      The person to greet.
  --help           Show this message and exit.
```

