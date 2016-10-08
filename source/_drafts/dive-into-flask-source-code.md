---
title: Flask 源码浅读
date: 2016-09-29 15:40:04
tags:
  - Flask
  - Python
categories:
  - Coding
---

Flask 是非常 Pythonic 的开源项目，非常值得深入学习，最新的稳定版是 0.11，由许多模块组成，相比 0.3 版的单文件工程，源码的阅读难度上也有所增加（0.3 还没有引入 Blueprint），本文就从 Flask 0.3 版的源码展开。

<!-- more -->

###

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run()
```

**************************************

参考资料：
  - [Flask Docs](http://flask.pocoo.org/docs/0.11/)
  - [Web Server Gateway Interface](https://en.wikipedia.org/wiki/Web_Server_Gateway_Interface)