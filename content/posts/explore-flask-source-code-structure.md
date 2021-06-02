---
title: 读 Flask 源码：源码结构
date: 2017-02-14 19:47:11
tags:
  - Python
categories:
  - Coding
---

打算对 [Flask](https://github.com/pallets/flask) 的学习做个整理，以 Flask 的 GitHub 代码库的 `master` 分支为参考。其实早期的 `0.3` 版还是单文件，整个 `flask.py` 加上注释也只有 1426 行代码，非常简洁，很适合作为 Python 源码学习的教材。

<!-- more -->
拿到源码先不着急，就像读书一样，不妨浏览下目录，以便有个全局的了解。Flask 的源码有一个非常好的优点，就是它的注释非常完备，即使不看源码，只看注释，也能有个大概的理解。

从 Flask 根目录下的 `setup.py` 可以看到，Flask 依赖的组件主要有 3 个：
- [Werkzeug](http://werkzeug.pocoo.org/docs/)：一个 HTTP 和 WSGI 的工具集；
- [Jinja2](http://jinja.pocoo.org/docs/)：Python 的前端模板引擎；
- [itsdangerous](http://pythonhosted.org/itsdangerous/)：处理并传递可信数据的辅助函数集；

Flask 的核心代码都在 `flask` 目录下，其目录结构如下：

```
flask
├── ext
│   └── __init__.py     flask 扩展
├── __init__.py         导入模块
├── __main__.py         命令行运行
├── _compat.py          Py2/3 兼容性模块
├── app.py              核心模块
├── blueprints.py       蓝图模块
├── cli.py              命令行支持模块
├── config.py           flask 配置模块
├── ctx.py              flask context 模块
├── debughelpers.py     debug 辅助函数
├── exthook.py          flask 扩展迁移，flaskext.foo 迁移到 flask_foo
├── globals.py          flask 全局变量模块，包括 `g`，`current_app`，`request`
├── helpers.py          辅助函数模块
├── json.py             JSON 支持模块
├── logging.py          日志模块
├── sessions.py         基于 itsdangerous 的 cookie 和 session 模块
├── signals.py          基于 blinker 的信号模块
├── templating.py       桥接 Jinja2 的模板模块
├── testing.py          测试模块
├── views.py            view_func 模块
└── wrappers.py         WSGI request 和 response 的封装模块
```

**********************************

参考资料：
- [Flask Documentation](http://flask.pocoo.org/docs/0.12/)