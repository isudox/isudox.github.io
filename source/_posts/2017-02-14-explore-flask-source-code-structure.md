---
title: 读 Flask 源码：源码结构
date: 2017-02-14 19:47:11
tags:
  - Flask
  - Python
categories:
  - Coding
---

打算对 Flask 的学习做个整理，以 [Flask](https://github.com/pallets/flask) 的 GitHub 代码库的 `master` 分支为参考。其实早期的 0.3 版本还是单文件版，整个 `flask.py` 就 1426 行代码，非常简洁，很适合作为 Python 源码学习的教材。拿到源码先不着急，就像一本书一样，不妨浏览下目录，有个全局的了解。

<!-- more -->

**********************************

参考资料：
  - [Flask Documentation](http://flask.pocoo.org/docs/0.12/)