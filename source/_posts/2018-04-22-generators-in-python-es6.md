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

## 共性
首先，`generator` 本质上还是 `function`，只是行为略微特殊。
普通 `function` 会在执行结束时通过 `return` 返回；
`generator` 可以中断 `function` 的执行过程，并重新回到断点现场继续执行。具体实现就是通过 `yield` 将结果返回给调用方并中断，通过 `next()` 方法继续回到断点再执行到下一个 `yield` 断点处。

## Python

## ES6