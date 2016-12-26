---
title: 2016 年前端补习之 Webpack 篇
date: 2016-12-26 10:40:41
tags:
  - Frontend
  - Webpack
categories:
  - Coding
---

对于前端开发者而言，2016 又是一个风不平浪不静的一年。今年新冒出的框架工具，如果不是专职前端，估计现在和我是差不多的状态，一脸懵逼外加黑人问号脸，ES5 到 ES6 的更替，Angular、Vue、React 的三国演义，Grunt、Gulp、Browserify、Webpack 的混战，npm 用了没多久又来了个 yarn……为了以后和前端协作时不被鄙视成原始人，努力在 2016 年结束前，赶紧先上车，这就是我一个后端开发做前端补习的动机，本文是 Webpack 篇，后续还会更新 React、Redux 等。

<!-- more -->

> 鉴于本人对前端的认知停留在三脚猫的水平，因此本文不会执著于对不同框架/工具的优劣比较，谨作为个人浅尝辄止的学习记录。

## Webpack 基础命令

![What is webpack](https://webpack.github.io/assets/what-is-webpack.png)

[Webpack](https://webpack.js.org/) 是一个前端的模块（Module Bundler）打包工具，如上图所示，它可以对各种类型的静态文件做统一的加载和处理。在展开对它的学习之前，先把准备工作做好，Webpack 的安装很简单，全局或本地安装：

```bash
# globally install
npm install webpack -g
# locally install
npm install webpack --save-dev
```

安装后，就可以在控制台执行 `webpack` 命令了，

Webpack 有 4 个核心概念

## Webpack Config

如果每次都要手动去设置命令参数，那太低效了，尤其是当工程文件很多时。`webpack.config.js` 就解决了这个问题，Webpack 会根据根目录下的这个 config 文件，获取工程的配置信息。参考阮一峰老师的 demo，是一个最简单的配置：

```javascript
// webpack.config.js
module.exports = {
  entry: './main.js',
  output: {
    filename: 'bundle.js'
  }
};
```


*************************************************

参考资料：
  - Webpack - [Docs](https://webpack.github.io/docs/)
  - 阮一峰 - [webpack-demos](https://github.com/ruanyf/webpack-demos)