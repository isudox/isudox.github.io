---
title: Git 一般实践
date: 2016-03-10 18:01:32
tags: [Git]
categories: [Coding]
---

之前一个人玩开发时，用 Git 做版本管理很舒心愉快，因为从来不会有冲突，Git 玩来玩去就是 `git pull`、`git commit`、`git push` 的三件套。严格意义上讲，绝大多数时候我只是把 Git 当成了个人代码存储而不是协作开发的版本管理工具。Git 还有很多强大的功能并没有在个人小型开发中使用到，而在 JD 的工作中，实际上遇到了不少在使用 Git 协作开发时的问题。正好组长让我总结其间的问题和最佳实践，就把这些实践经验记录在本文中。另，Git 本来就是一个命令工具集，所以我就以类 Unix 系统下的命令行操作为基准，各个平台下的 Git GUI 工具花样百出，操作也不统一，就一并略过了。

<!-- more -->

> 其实很多问题都是在你并不了解规律的情况下产生的，不仅仅是对 coding 而言

### 常用操作

#### 创建 Git 仓库
创建 Git 仓库有几种不同的情况：

创建空的 Git 仓库，很简单，一条命令
```bash
git init <repo-name>
```
该目录就是一个 Git 本地仓库了，目录下会有一个隐藏文件夹 `.git/`，看看它的目录结构
```bash
tree .git
.git
├── branches
├── COMMIT_EDITMSG
├── config
├── description
├── FETCH_HEAD
├── HEAD
├── hooks
├── index
├── info
│   └── exclude
├── logs
│   ├── HEAD
│   └── refs
│       ├── heads
│       │   ├── master
│       │   └── source
│       └── remotes
│           └── origin
│               ├── HEAD
│               ├── master
│               └── source
├── objects
│   ├── 18
│   │   └── f66c7ed1e9d6dadb9aa71836fdf58d5217fd26
│   ├── info
│   └── pack
│       ├── pack-137f36f2b48c9ee4fb17518f99ec9b9f842fcd81.idx
│       ├── pack-137f36f2b48c9ee4fb17518f99ec9b9f842fcd81.pack
├── packed-refs
├── refs
│   ├── heads
│   │   ├── master
│   │   └── source
│   ├── remotes
│   │   └── origin
│   │       ├── HEAD
│   │       ├── master
│   │       └── source
│   └── tags
└── smartgit.config
```
上面是我这个静态博客 Git 仓库下 `.git/` 目录结构。其中几个主要子目录和文件的基本作用如下——
* `COMMIT_EDITMSG`: 该文件存放最新的commit message；
* `config`: 该文件保存Git的配置；
* `description`: Git仓库的描述信息；
* `index`: Git本地暂存区，是二进制文件；
* `HEAD`: 该文件为Git仓库当前分支的引用；
* `hooks`: 该目录存放Git脚本钩子，用以触发Git自动执行某些操作，例如本人博客的Git钩子就自定义了文件更新后自动部署的操作；
* `info`: 存放Git仓库信息；
* `logs`: 存放Git log的信息；
* `objects`: 存放所有Git Object，每次提交Git都会生成一个Git Object，其SHA1值的前2位是文件夹名称，后38位是Object名；
* `refs`: 包含 heads、remotes、tags 三个子目录，分别存储当前head指针指向的 commit，服务器端远程仓库的header指针及分支、Git tags 标签；

创建空的 Git 仓库是最常用的操作，还有比较常用操作的是把已有的工程加入 Git
```bash
cd existing-dir
git init
git add .
git commit -m 'first commit'
```

还有一种情况并不多见，就是创建裸仓库，有别于 `git init`
```bash
git init --bare
```
Git 仓库其实就是 Git 仓库下的 `.git` 目录，存储上面提到的那些子目录和文件，记录该 Git 仓库的所有记录。Git 裸仓库一般用在远程服务器上的仓库初始化。

#### 添加到远程仓库
在本地创建 Git 仓库后，还需要推到远程仓库上，比如大名鼎鼎的 GitHub，或者私有的 Git 服务器如 GitLab。首先在服务器上新建远程仓库，取到 Git 远程仓库地址，然后就可以把本地仓库推到远程。
```bash
git remote add <origin remote repo URL>
git push origin master
```

#### 提交改动
当对 Git 仓库文件进行增删改操作后，需要把有必要提交的改动 commit 到本地，再 push 到远程仓库。想查看本地仓库有哪些改动可以执行 `git status` 命令。确认后执行 `git add <filename or .>` 把文件改动提交到 Git 仓库的__暂存区__，此时再通过 `git status` 就能看到提示信息与之前的变化。但暂存区顾名思义只是暂存改动，并未提交到本地仓库，因此还需要 `git commit -m 'blabla'` 将改动提交到本地仓库。这样就把改动提交上去了，至于是否需要再提交到远程仓库，视需要而定，`git push origin <branch-name>` 就是提交到上面绑定的远程仓库。

#### 回滚/撤销
本地仓库经过修改和提交后，`.git/` 就会记录下每次提交的版本。这里有两个概念：1)回滚；2)撤销。回滚是将 Git 仓库从当前的版本回滚到指定的版本，撤销则是将本地仓库的修改撤销掉，回滚是发生在 commit 之后，撤销是发生在 commit 之前。

先说回滚的事。`git log` 查看仓库 `commit` 提交的记录，控制台显示
```bash
commit 061888eece36843cb14d9eb56c7979379aacd530
Author: programmer_a <programmer_a@jd.com>
Date:   Thu Mar 10 18:51:16 2016 +0800

    成长推荐添加购物车 获取cookie

commit 88bb88109456d3c0c3f4f172e187ca21257f7422
Author: programmer_b <programmer_b@gmail.com>
Date:   Thu Mar 10 18:07:34 2016 +0800

    修改购物车WebOriginId属性

commit 7dde62b5ef08fba5f6c4bcc5868a4a9c075f9af0
Author: programmer_b <programmer_b@gmail.com>
Date:   Thu Mar 10 16:58:52 2016 +0800

    提出common.js
```
每个 `commit log` 的第一行是其 id（SHA1 编码，杜绝版本号重复的可能）。如果要回滚到上一个版本，可以执行 `git reset` 命令
```bash
$ git reset --hard 061888eece36843cb14d9eb56c7979379aacd530
HEAD is now at 061888eece36843cb14d9eb56c7979379aacd530 成长推荐添加购物车 获取cookie
```
其中 `commit id` 不需要写全，只要能让 git 识别到唯一的 id 就行。如果不想通过 id 去回滚，还有另外一种方式，仓库指针 HEAD 表示当前版本，上一 commit 版本为 `HEAD^`，上上版本为 `HEAD^^`，往前推第N个版本为 `HEAD~N`。回滚版本实际上就是移动 Git 指针的指向，因此回滚操作是向前向后都支持的，无非移动指针的方向不同而已。如果我想再回退到最新的提交版本上，只需要指定最新一次的 `commit id`。

下面接着说撤销操作。当本地仓库的文件被修改后，需要执行 `git add {filename}` 讲文件改动提交到本地暂存区。如果本地修改没有被add进暂存区，则不会被commit提交到仓库中。加入现在需要讲改动撤销掉，有两种可能的情形：
- 修改尚未被add到暂存区: 执行 `git checkout -- filename` 可以撤销修改，视情况恢复到上一次 `git add` 或 `git commit` 的文件；
- 修改已经被add进暂存区: 这种情况下撤销本地工作区的改动实际上就是回滚到HEAD指针指向的版本。因此执行 `git reset HEAD {filename}...` 完成对暂存区的撤销操作。
另外，`git checkout -- {filename}` 还可以恢复被删除的文件。

#### 推送/更新
很简单，两条很形象的命令
```bash
$ git push origin <branch-name>
$ git pull origin <branch-name>
```

在了解了 Git 的基本操作后，基本已经可以让 Git 在团队协作开发中发挥作用了，但团队开发不同于个人开发很重要的一点是，前者往往有更高的管理成本和管理需求，而个人开发在这方面几乎是零。所以还需要更多高阶的 Git 操作。

### Git 进阶

很多软件开发人员在发布版本时往往会标明 `stable`，`beta`，`alpha`，`v1.0`，`v1.1` 等，源代码管理也有同样的需求，这就涉及到 Git 的分支概念。另外当多个开发人员对同一文件的同一内容修改时，就会产生冲突。Git 到底是采纳a开发的代码还是b开发的代码，这是个问题。还有当项目开发到一定进度，可以正式发布时，需要给这个版本注明一个Tag，Git Tag 可以实现这个需求。

#### Git 分支
分支类似沙盒，不同分支之间彼此互不干扰，比如我想给当前稳定版的软件里新加一个杀手级的功能，但是一时半会没法完成，就可以新开一个分支，在新分支下进行开发，完全不会影响稳定版分支里的代码。Git 分支可以随时创建，切换，删除。

Git仓库的默认分支是 `master`，我个人的习惯通常是再创建一个 `dev` 分支作为开发分支，开发到一定程度后再把 `dev` 分支里的代码合并进 `master` 分支发布。
```bash
$ git branch dev
$ git checkout dev
```
`merge` 命令合并 `dev` 到 `master`
```bash
$ git checkout master
$ git merge dev
```
合并到主干分支后，如果不再需要 `dev` 分支，则可以丢弃
```bash
$ git branch -d dev
```

#### 冲突
冲突一般发生在什么时候？如果了解过并发就很好理解，一个资源被多个操作者同时处理时就会发生冲突，通常在多线程编程里，我们会采用“文件锁”、“信号量”等方式防止这种情况的产生。但再用 Git 进行协同开发时，这种办法是很难奏效的。因为 Git 是一个分布式的版本管理工具，当开发者 A 在修改一段代码时，Git 是不能在开发者 B 的仓库里锁住这段代码，而不让 B 去进行修改。所以冲突是避免不了的，也是正常问题，试着去解决就行了。

下面就结合近期开发过程中的具体场景作个分析。
正常情况下，我从 `master` 分支里 `commit id` 为 `aaabbbccc` 的版本分出 `dev` 分支，然后在 `dev` 分支下开发并 commit，此时切回 `master` 并将 `dev` 中的 commit 合并进来是不会有冲突的。有一回，我在 `dev` 分支上开发，并把提交推送到服务器上的远程仓库，同事把代码 pull 下来后，在 `master` 分支上进行了 commit，而恰好我的的提交和同事在本地 `master` 分支上的 commit 都对同一内容块进行了修改。这样的话，同事在进行 `merge` 合并时就发生了冲突，就需要人工解决。执行 `git status` 查看是哪个文件冲突，然后打开该文件尝试解决。
```
<<<<<<< HEAD
这里是本地仓库master提交的内容
=======
这里是本地仓库dev提交的内容
>>>>>>> dev
```
需要完成的工作就是人工进行取舍，选择保留哪个改动，或者重新写一段新的内容，保存后即解决了冲突。之后在将冲突解决后的改动 `add` 进暂存区，并 `commit` 到仓库。

类似的，如果是本地修改了代码段 A，同事同样修改了代码段 A，并将修改推送到远程仓库上，那么我在 `pull` 操作后会收到冲突提醒，代码段 A 被多个人同时修改，跟上面的操作一样，人工解决。

#### Stash 贮存
比如遇到这样一种状况：我正在 `dev` 下开发需求，临时接到测试人员提交的 bug，优先级上 bug 比当前待开发的需求更高，只能放下手头的需求去修复 bug。但是当前正在开发的功能代码既没完成又不想丢弃，难道真成了鸡肋了？交给 Git 贮存起来吧，既不会丢失辛辛苦苦写的代码，也不需要把未完成的半残代码提交到仓库导致整个工程没法运行。`git stash` 帮你排忧解难。

首先执行 `git stash` 把当前工作区里的代码改动贮存在一个特殊的地方，使得整个分支是干净的。
```bash
$ git stash
Saved working directory and index state WIP on dev: ec1c949 修改小功能
HEAD is now at ec1c949 修改小功能
```
再来执行 `git status` 查看分支状态
```bash
$ git status
On branch dev
nothing to commit, working directory clean
```
Ok，没问题，已经把之前的改动藏起来了，接着就可以修改测试提交的 bug，bug 修复后，再来找回先前藏起来的代码
```bash
$ git stash pop
```
如果工作区有多次 `stash` 操作，可以通过 `git stash list` 查看 stash 操作记录，如果想恢复指定的某一次 `stash` 操作，执行 `git stash apply stash@{}`。

#### Tag 标签
互联网公司的项目往往是需要快速迭代的，比如一期我们只上简单的几个功能，版本就取 v1.0 吧，当我们一期项目上线发布时，可以在仓库里对需要发布的版本进行打标。标签的作用类似分支，但分支是可以随着代码的改动向前推移，标签所定义的指针位置是固定不变的，只要标签不被删除丢弃，任何时候都能取出指定标签所代表的仓库版本。设想下如果二期 v1.1 上线后用户反响很糟糕，强烈要求退回到 v1.0，那么我们重新上线标签为 v1.0 的版本即可，随时随地都可以做到。

Git打标操作是有 `git tag <tag-name> [commit-id]` 实现的
```bash
$ git tag v1.0
$ git tag
v1.0
```
如果 `git tag` 命令不指定 `commit id` 的话，默认是对最近一次 commit 后的版本打标。删除标签的操作和上面的类似，加上参数 `-d` 即可。
```bash
$ git tag -d v1.0
Deleted tag 'v1.0' (was ec1c949)
```
打标确认无误就可以push到远程仓库了
```bash
$ git push origin <tag-name>
```

#### 忽略文件
团队协作中，各人的开发平台不同，IDE不同，可能会有各种各样的配置，如果你改一下，我改一下，那要疯了……最好的处理方法是将这些差异性的文件加入 `.gitignore` 文件中。
在仓库的根目录下创建 `.gitginore` 文件，比如 Java 工程，那些 build 后的文件我不需要提交到仓库中，C/C++ 项目编译后生成的 .so 文件我也不想把他们加进仓库，那么都可以统统扔进 `.gitignore` 里忽略掉。并且 `.gitignore` 支持通配符，可以根据后缀名把文件一并过滤掉。例如一般 Java 工程里通常会排除 `target/` 目录、`.class`、`.war`、`.jar` 等文件，还有 IntelliJ IDEA 或 Eclipse 的工程管理目录，那就可以这样处理
```xml
*.jar
*.war
*.class
target/
.idea/
.project
.classpath
```

#### 协作细节
在进行 Git 操作时，有一些个人经验想写一下，也是一些我觉得比较好的习惯。
- 什么时候需要 commit，我觉得不是写两行代码或者写 100 行代码就得提交一下，而是完成一个小功能或修复一个 bug，并且整个功能能正常运行，不会影响其他开发人员调试，那么就可以提交上去，无论是改了一行代码还是 100 行代码。另外，commit时认真写注释还是很重要的，既方便自己也方便他人，不至于想回滚时都不知道哪次提交都改了什么。
- 在 `push` 操作之前，先 `pull` 远程的代码，因为别人可能已经把他们开发的代码推送上去了，本地版本比远程版本旧，是无法推送上去的。此外，`pull` 后可以尽早发现可能的冲突，尽早解决，不然后期一堆冲突文件会抓狂的。
- 合并到 master 分支上的代码必须要上线，如果合并进 master 却又没有上线部署，极有可能会导致线上代码和仓库代码不一致的情况，发生状况的话很难排查，血的教训……
- 暂时只想到了这几点，想到了再补上……荆轲刺秦王，毛腿肩上扛
