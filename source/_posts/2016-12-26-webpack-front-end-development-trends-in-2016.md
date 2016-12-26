---
title: 2016 年前端补习篇一：Webpack
date: 2016-12-26 10:40:41
tags:
  - Frontend
  - Webpack
categories:
  - Coding
---

对于前端开发者而言，2016 又是一个风不平浪不静的一年。今年新冒出的框架工具，如果不是专职前端或全栈，估计现在和我是差不多的状态，一脸懵逼外加黑人问号脸。为了以后和前端协作时不被鄙视，努力在 2016 年结束前，赶紧先上车，这就是我一个后端开发做前端补习的动机，本文是 Webpack 篇，后续还会更新 Yarn、React、Redux 等。

<!-- more -->

> 因为我对前端的认知停留在三脚猫的水平，因此本文不会执著于对不同框架/工具的优劣比较，谨作为个人浅尝辄止的学习记录。

## Webpack 基础命令

### Hello World

![What is webpack](https://o70e8d1kb.qnssl.com/what-is-webpack.png)

[Webpack](https://webpack.js.org/) 是一个前端的模块（Module Bundler）打包工具，如上图所示，它可以对各种类型的静态文件做统一的加载和处理。在展开对它的学习之前，先把准备工作做好，Webpack 的安装很简单，全局或本地安装：

```bash
# globally install
yarn global add webpack
# locally install
yarn add webpack
```

安装完后，就可以在控制台使用 `webpack` 命令了。在目录下执行 `webpack`，首先需要配置 `webpack.config.js` 文件，由该配置文件来控制 `webpack` 的操作。参考阮一峰老师 GitHub 上的示例如下：

```javascript
// webpack.config.js
module.exports = {
  entry: './main.js',
  output: {
    filename: 'bundle.js'
  }
};
```

然后执行 `webpack` 命令就可以按照配置文件的设置，把目录下的 `main.js` 打包成 `bundle.js`。

### 核心概念

Webpack 有 4 个核心概念必须要了解：[Entry](https://webpack.js.org/concepts/entry-points/)、[Output](https://webpack.js.org/concepts/output/)、[Loaders](https://webpack.js.org/concepts/loaders/) 和 [Plugins](https://webpack.js.org/concepts/plugins/)。

#### Entry

webpack 为 web 应用的依赖关系创建了图表，而 Entry 则是告诉 webpack 这张图表的入口位置并循着依赖关系去打包，webpack 通过对 webpack configuration object 设置 `entry` 属性来定义 Entry，参考下面的代码：

```javascript
# webpack.config.js
module.exports = {
  entry: './path/to/my/entry/file.js'
};
```

如果要指定多个 Entry，则需要将 `entry` 属性从 `string` 改为 `Array<string>`，比如 ['./main.js', './index.js']。也可以使用 Object 语法，把 `entry` 属性设置为一个 key-value 对象，这是更具扩展性的定义 `entry` 的写法：

```javascript
const config = {
  entry: {
    app: './src/app.js',
    vendors: './src/vendors.js'
  }
};
module.exports = config;
```

#### Output

既然由 Bundle 的入口 Entry，相应的必然也会有 Bundle 的出口，这就是 Output。我们需要告知 webpack 对打包后的静态资源如何处置，存放在哪，文件名是什么。webpack 的 `output` 属性描述了该如何处理打包后的代码。

```javascript
# webpack.config.js
var path = require('path');

module.exports = {
  entry: './path/to/my/entry/file.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'my-first-webpack.bundle.js'
  }
};
```

对于 `output.filename`，如果 `entry` 属性配置了多个文件，则需要使用命名替换的方式确保 output filename 不重名。其中，占位符 `[name]` 采用 chunk 的名称作为替换，`[hash]` 是采用编译后文件的 hash 值替换，而 `[chunkhash]` 则是根据 chunk 的 hash 值来替换。

```javascript
{
  entry: {
    app: './src/app.js',
    search: './src/search.js'
  },
  output: {
    filename: '[name].js',
    path: __dirname + '/build'
  }
}
```

对于 `output.path` 属性，必须设置为绝对路径，占位符 `[hash]` 会被编译后文件的 hash 值替换：

```javascript
output: {
    path: "/home/proj/public/assets",
    publicPath: "/assets/"
}
```

#### Loaders

#### Plugins

## Webpack Config

参考阮一峰老师的 demo，是一个最简单的配置：

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