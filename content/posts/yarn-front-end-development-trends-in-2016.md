---
title: 2016 前端补习 Yarn 篇
date: 2016-12-27 22:39:09
tags:
  - 前端
categories:
  - Coding
---

目前使用最广泛的 JavaScript 的包管理工具应该是 npm，可以说是非常时髦的工具。但是在前端圈子，三岁就得叫爷爷，拳怕少壮，不久前 Facebook 和 Google 等联手推出了新的包管理工具 Yarn，一阵横扫之势，GitHub 上狂收 2w+ stars，令人侧目……在上一篇讲 webpack 学习的博客中也尝试使用了 Yarn，本篇就专门写写 Yarn。

<!-- more -->

## 基础操作

如果使用过 npm 的话，能发现二者在使用上非常接近，从 npm 迁移到 Yarn 近乎零成本。

初始化新项目：

```bash
# same as npm init
yarn init
```

执行该命令时，会询问项目名称，入口文件，作者等信息，确认后自动创建包管理文件 `package.json`，以后每次对包的增删更新都会同步到 `package.json` 中。

安装依赖包：

```bash
# same as npm install [package]
yarn add [package]
yarn add [package]@[version]
yarn add [package]@[tag]
```

另外，该命令可以通过标识参数来指定依赖类型：

  - `yarn add --dev` 会把依赖包添加进 `devDependencies` 字段；
  - `yarn add --peer` 会把依赖包添加进 `peerDependencies` 字段；
  - `yarn add --optional` 会把依赖包添加进 `optionalDependencies` 字段；

更新依赖包：

```bash
# same as npm upgrade [package]
yarn upgrade [package]
yarn upgrade [package]@[version]
yarn upgrade [package]@[tag]
```

卸载依赖包：

```bash
# same as npm uninstall [package]
yarn remove [package]
```

根据 `package.json` 安装所有依赖包：

```bash
# same as npm install
yarn install
```

该命令也支持通过标识参数来实现额外的功能：

  - `yarn install --flat` 每个包都只允许安装唯一的版本，第一次运行时会提示用户确认版本；
  - `yarn install --force` 强制联网下载所有包，即使之前下载过；
  - `yarn install --production` 使用该标识符或者环境变量 `NODE_ENV` 为 `production` 时，Yarn 会忽略 `devDependencies` 中的依赖包；

除了 `package.json` 外，Yarn 还维护了 `yarn.lock` 来精确匹配所有依赖包的版本号，来弥补 `package.json` 管理依赖包版本时的不精确问题。因此，如果使用 Yarn，需要把 `yarn.lock` 添加进版本管理中。

Yarn 还有其他一些比较常用的命令：

  - `yarn clean` 命令会清理掉不需要的依赖包，释放 `node_modules` 的空间。在执行该命令后，Yarn 会在项目根目录下创建 `.yarnclean` 文件，它也应该添加到版本管理中；
  - `yarn config set <key> <value> [-g|--global]` 命令会设置默认的 Yarn 信息，相应的，读取的命令是 `yarn config get <key>`。可以设置的 `key` 可以由 `yarn config list` 命令查看到；
  - `yarn global` 是一个前缀命令，可以加在 `add`、`remove` 等命令上，使得作用在全局上，类似 npm 的 `--global` 参数；
  - `yarn info <package>` 命令用来查看依赖包的详细信息；
  - `yarn login` 和 `yarn logout` 命令分别用来登录和登出 npm 的账户；
  - `yarn run [script] [-- <args>]` 命令用来执行 `package.json` 配置的 `scripts` 脚本命令，和 `npm run [script]` 一样；
  - `yarn why [package]` 命令检查安装该依赖包的原因，并列出依赖该包的其他包；

## npm 命令比较

| npm | Yarn |
|:------:|:------:|
|npm install|yarn install|
|(N/A)|yarn install --flat|
|(N/A)|yarn install --har|
|(N/A)|yarn install --no-lockfile|
|(N/A)|yarn install --pure-lockfile|
|npm install [package]|(N/A)|
|npm install --save [package]|yarn add [package]|
|npm install --save-dev [package]|yarn add [package] [--dev/-D]|
|(N/A)|yarn add [package] [--peer/-P]|
|npm install --save-optional [package]|yarn add [package] [--optional/-O]|
|npm install --save-exact [package]|yarn add [package] [--exact/-E]|
|(N/A)|yarn add [package] [--tilde/-T]|
|npm install --global [package]|yarn global add [package]|
|npm rebuild|yarn install --force|
|npm uninstall [package]|(N/A)|
|npm uninstall --save [package]|yarn remove [package]|
|npm uninstall --save-dev [package]|yarn remove [package]|
|npm uninstall --save-optional [package]|yarn remove [package]|
|npm cache clean|yarn cache clean|
|rm -rf node_modules && npm install|yarn upgrade|

## package.json 依赖配置

### 功能区分管理

有的依赖包是为了编译构建工程，而有的包视为了运行，因此不同功能的包在 `package.json` 中被分离到不同的依赖集合中：`dependencies`、`devDependencies`、`optionalDependencies` 和 `peerDependencies`。

参考 Yarn 文档里的示例：

```json
{
  "name": "my-project",
  "dependencies": {
    "package-a": "^1.0.0"
  },
  "devDependencies": {
    "package-b": "^1.2.1"
  },
  "peerDependencies": {
    "package-c": "^2.5.4"
  },
  "optionalDependencies": {
    "package-d": "^3.1.0"
  }
}
```

用的最多的应该是 `dependencies` 和 `devDependencies`，下面按照官方文档具体说明：

  - `dependencies`：记录运行程序时所需的依赖包；
  - `devDependencies`：这是开发的依赖包，是开发构建时所需的依赖包，但在运行时不需要；
  - `peerDependencies`：只有当开发者需要发布自己的包时，才需要配置；
  - `optionalDependencies`：顾名思义就是可选的依赖包，即使安装失败，也不会影响；
  - `bundledDependencies`：是项目内部的包，而不是从 npm 上安装；

### 版本号管理

`package.json` 也对依赖包的版本做了管理，版本号遵循 `major.minor.patch` 的规则，如果是 beta 版，则会在版本号后追加 `-beta.x`。除了明确指定版本号，还可以通过操作符实现指定版本号范围。

最简单易懂的就是 `=`、`>`、`<=` 等符号，这个不多讲，还有两个特殊的符号 `~` 和 `^`：

  - `~` 符：当版本号带有 `minor` 版本时，`~` 表示允许 `patch` 版本在 `minor` 保持不变时，递增变化。比如 `~3.1.4` 等同 `>=3.1.4 <3.2.0`；`~3.1` 等同于 `3.1.x`。当 `~` 后的版本号只有 `major` 时，只允许在 `major` 不变时，`minor` 的变化，比如 `~3` 等同于 `3.x`。
  - `^` 符：允许版本号在不改变第一个非零版本位的范围变动，比如 `^3.1.4` 表示 `>=3.1.4 <4.0.0`，`^0.4.2` 表示 `>=0.4.2 <0.5.0`， `^0.0.2` 表示 `>=0.0.2 <0.0.3`。Yarn 在安装依赖包时，默认使用 `^` 来设置版本号。

还有逻辑符号，用空格表示 `and` 关系，`||` 表示 `or` 关系，比如 `>=2.0.0 <3.1.4` 的意思是版本号大于等于 `2.0.0` 且小于 `3.1.4`。连字符 `-` 很有用，直接表示起止范围，上面这个版本范围用 `-` 符表示的话就是 `2.0.0 - 3.1.4`。

Yarn 的内容不多，使用也很简单，花半小时操练下命令就都了解了。

*************************************************

参考资料：
  - Yarn - [Docs](https://yarnpkg.com/en/docs)
