---
title: '[译] 一个行之有效的 Git 分支模型'
date: 2017-02-18 14:51:10
tags:
  - Git
categories:
  - Translation
---

原文 [A successful Git branching model](http://nvie.com/posts/a-successful-git-branching-model/) 是 [gitflow](https://github.com/nvie/gitflow) 的作者 nvie 于 2010 年撰写的，最近才看到此文，恨晚。网上和微信公众号推送的 Git 最佳实践多多少少应该从这篇文章中获得过经验值。虽然文中有些表述略显唠叨和陈旧，但不缺干货，搬运过来做个日常开发手册也是好的。

<!-- more -->

> 上面是废话，下面是译文。

***

本文里，我会介绍一个在一年前就引入进多个项目（包括工作和个人项目）中的开发模型，实践表明该模型很成功。为此专门写篇文章的想法由来已久，但始终没挤出时间来做，直到现在。我不会细究项目的具体细节，仅仅是项目开发的分支策略和发布管理。

<p align="center"><img src="https://o70e8d1kb.qnssl.com/git-model@2x.png" width="575"></p>

该模型专注于使用 [Git](https://git-scm.com/) 作为代码版本管理工具。（另外，如果你对 Git 感兴趣，我司的 GitPrime 提供了一些很棒的软件性能实时数据分析功能）

## 为什么使用 Git

关于 Git 相比于中心化的代码管理系统的优劣，可以从网上找到很多相关讨论。作为开发者，我选择 Git。Git 确实改变了开发者们对分支和合并的理解。在之前使用经典的 CVS/Subversion 时，新建分支和合并分支总是有点吓人（小心代码合并时的冲突，它们会咬你）。

但是用 Git 时，这些日常工作流的主要操作都变得简便易行。举例来说，在 CVS/Subversion 的相关书籍中，分支和合并操作会在靠后的章节中介绍（面向高阶读者），而 Git 的书中，往往是前三章的基础操作里就会做说明。

由于 Git 的简单性和重用性（repetitive），分支和合并不再是令人生畏的高危操作。版本管理工具应该更多的协助代码的新建分支和合并分支。

闲言少叙，进入开发模型的正题吧。我要介绍的模型基本上只是团队里每个成员都要遵循的一组开发流程规范。

## 去中心化也中心化

在分支模型下工作良好的代码库，实际上有一个真实的中心代码库。注意这个库被视为一个中心（因为 Git 是分布式的版本管理工具，所以从技术角度上说并不存在中心代码库）。我们将其视为为 origin，因为所有 Git 用户都熟悉这个名称。

<img align="center" src="https://o70e8d1kb.qnssl.com/centr-decentr@2x.png" width="487">

每个开发者对 origin 进行 pull 和 push 操作。但是除了中心化的 push-pull，每个开发者也可能会建立子团队并 pull 同个子团队里其他成员的代码改动。比如，和两个或更多开发者合作开发一个大的新功能时，避免过早的将开发进行过程中的代码 push 上去。上图中，有 Alice 和 Bob 的小团队，Clair 和 David 的小团队。

本质上说，这实际上就像是 Alice 定义了一个 Git 远程分支，名叫 bob，并指向 Bob 的代码库，反之亦然。

## 主干分支

<img align="right" src="https://o70e8d1kb.qnssl.com/main-branches@2x.png" width="267">
我的开发模型实际上从现有的模型中得到很多启发。中心库保有两个伴随代码库整个生命流程的主要分支：
- master
- develop

Git 用户应该对 origin 上的 `master` 分支很熟悉。此外，另一个分支命名为 `develop`。

我们将 `origin/master` 分支作为一个主干分支，使得它的 HEAD 指针始终指向可发布的生产状态（production-ready state）。

`origin/develop` 分支作为另一主干分支，而它的 HEAD 指针始终指向为下一发版而做的最新开发改动。有人把这成为 integration 分支。通常这就是 nightly 版本发布的出处。

当 `develop` 分支上的代码开发到 stable 状态并且已经可以发布时，所有的改动都应该 merge 到 `master` 分支上，然后打上发布版本号的标签。后面会继续讲如何执行这一系列操作。

因此，每次把改动合并到 `master` 分支上后，就生成了一个新的可发布的生产状态。我们对合并到 `master` 分支的行为把控严格，所以理论上，每当 `master` 分支上有 commit 操作时，我们可以通过 Git hook 脚本实现自动构建并把应用推送到生产服务器上。

## 辅助分支

主干分支之外，我们的开发模型使用了很多辅助分支来帮助团队成员间的并行开发，减轻功能跟踪的成本，预备新版的发布，协助快速修复已发布版本的问题。和主干分支不同，这些辅助分支只有有限的生命期，最终会被移除。

我们可能会用到的辅助分支有：
- Feature 分支
- Release 分支
- Hotfix 分支

上面的每个辅助分支都有一个特定的目标，且严格限制哪些是起源分支，哪些是合并的目标分支。我们一会儿会详细解释。

这些辅助分支并不特别，分支的类型是按照我们如何使用它们而划分的，也就是普通的 Git 分支而已。

### Feature 分支

<img align="right" src="https://o70e8d1kb.qnssl.com/fb@2x.png" width="133">
从 `develop` 分支派生；
必须 merge 回 `develop` 分支；
辅助分支的命名惯例是：除 master，develop，release_\* 和 hotfix-\* 以外的任意命名。

Feature 分支，或者叫 topic 分支，是用来为未来的发版而开发新 features 的分支。当开始 feature 的开发时，。Feature 分支的本质它会在 feature 的开发期内存在，但最终会合并回 `develop` 分支（以明确的将 feature 添加进即将 release 的版本中），或者被直接丢弃掉（在令人失望的情况下）。

Feature 分支通常只存在于开发者的 repo 中，而不会在中心库 origin repo 中。

<center>**创建 Feature 分支**</center>

要创建一个新的 Feature 分支，从 `develop` 分支上派生：

```bash
$ git checkout -b myfeature develop
Switched to a new branch "myfeature"
```

<center>**已完成的 feature 合并回 develop**</center>

已开发完成的 features 应该被合并至 `develop` 分支上，将 features 添加到即将发 release 的代码版本中。

```bash
$ git checkout develop
Switched to branch 'develop'
$ git merge --no-ff myfeature
Updating ea1b82a..05e9557
(Summary of changes)
$ git branch -d myfeature
Deleted branch myfeature (was 05e9557).
$ git push origin develop
```

`--no-ff` 标识使得 merge 操作总是创建一个新的 commit，即使 merge 可以使用 fast-forward。这避免了 feature 分支历史信息的丢失，而且把所有 commit 归并在一起。比较下图的两个案例：

<p align="center"><img src="https://o70e8d1kb.qnssl.com/merge-without-ff@2x.png" width="478"></p>

右边的案例中，无法从 Git 历史中找到是哪些 commit 实现了 feature，你必须要手工的去检查所有的 log 信息。撤销一个 feature 对后一案例而言简直是头疼，而如果使用了 --no-ff 标志，则很容易完成。

是的，它会付出创建更多的 commit 的代价，但所得更多。

### Release 分支

从 `develop` 分支派生；
必须 merge 回 `develop` 分支和 `master` 分支；
分支命名惯例：release-\*

Release 分支为新的生产版本做预备。They allow for last-minute dotting of i’s and crossing t’s. 此外，Release 分支也可以用来修复小 bug 和准备发布版本的元数据（版本号，构建日期等）。通过 Release 分支，`develop` 分支将被清理以便接收下一个大版本的发布。

从 `develop` 分支派生新分支的关键时刻是在开发几乎要到达预期的 release 状态时。至少所有针对要构建版本的 feature 必须已经 merge 到 `develop` 分支上了。而针对未来的 release 的 feature 则需要等到当前的 release 分支派生以后。

正是在 Release 分支的开始时，而不是之前，即将到来的 release 才被分配版本号。直到那时，`develop` 分支才反映了 next release 的改动，但直到 release 分支开始前，next release 是 0.3 版还是 1.0 版并不确定。对 release 版本的决定是在 release 分支开始时，并由项目的版本号规则来拟定。

<center>**创建 release 分支**</center>

Release 分支是由 `develop` 分支派生而来。例如，当前的生产版本是 1.15，且即将有一个大迭代。`develop` 分支的状态已经为 next release 做好准备，我们也已经决定好即将到来的版本是 1.2。因此我们从当前的 `develop` 分支上派生并命名该 `release` 分支为新的版本号：

```bash
$ git checkout -b release-1.2 develop
Switched to a new branch "release-1.2"
$ ./bump-version.sh 1.2
Files modified successfully, version bumped to 1.2.
$ git commit -a -m "Bumped version number to 1.2"
[release-1.2 74d9424] Bumped version number to 1.2
1 files changed, 1 insertions(+), 1 deletions(-)
```

创建并切换到新分支后，我们 bump 了版本号。在这里，`bump-version.sh` 是一个虚拟出来的 shell 脚本，用来修改一些文件，使其能体现新版本。之后，新的版本被 commit 上去。

该新分支可能会存在一段时间，知道 release 可以确定被发布出来。在此期间，分支上可能会修复一些 bug（而不是在 `develop` 分支上）。严禁在该分支上添加大的 feature 进来。release 分支最后必须被 merge 回 `develop` 分支上，然后继续等待下一个大版本的发布。

<center>**完成 release 分支**</center>

当 release 分支的开发状态到了真正可以发布的时候，就需要采取一些行动了。首先， release 分支得 merge 到 `master` 分支（记住，`master` 上的每个 commit 都是一个新的 release）。然后，提交到 `master` 上的 commit 必须被标记上 Tag，以便将来参考该历史版本。最后，release 分支上的改动还需要 merge 回 `develop` 分支，以便将来的 release 也能包含这些 bug fixes。

开始的两步操作：

```bash
$ git checkout master
Switched to branch 'master'
$ git merge --no-ff release-1.2
Merge made by recursive.
(Summary of changes)
$ git tag -a 1.2
```

到此，release 已经完成，并且标记了 Tag。（你可能还想使用 `-s` 或 `-u` 参数来对 Tag 进行加密）

为了让 release 分支上的改动能保留下来，继续将改动 merge 回 `develop` 分支，Git 操作如下：

```bash
$ git checkout develop
Switched to branch 'develop'
$ git merge --no-ff release-1.2
Merge made by recursive.
(Summary of changes)
```

这些操作可能会导致代码冲突，尝试解决冲突后再提交。
现在，我们已经彻底完成工作并且 release 分支已经可以被移除了：

```bash
$ git branch -d release-1.2
Deleted branch release-1.2 (was ff452fe).
```

### Hotfix 分支

<img align="right" src="https://o70e8d1kb.qnssl.com/hotfix-branches@2x.png" width="316">
从 `master` 分支派生；
必须 merge 回 `develop` 分支和 `master` 分支；
分支命名惯例：hotfix-\*

Hotfix 分支和 release 分支很类似，都是为发布新的生产版本而准备，虽然是计划外的。其存在的必要性是由于当前生产版本处于需要紧急修复的状态。当生产版本发生严重 bug 时，就必须立即修复，hotfix 分支可以从生产版本的 `master` 分支上的相应 Tag 派生出来。

实质上，在 `develop` 分支上开发的人员可以继续，另一边，其他人员则可以快速的进行生产版本的修复工作。

<center>**创建 release 分支**</center>

Hotfix 分支从 `master` 派生。比如，当前线上运行的生产版本是 1.2 版，遇到严重 bug，但是 `develop` 分支上的版本还不到稳定版，就可以派生 hotfix 分支来修复线上发现的 bug：

```bash
$ git checkout -b hotfix-1.2.1 master
Switched to a new branch "hotfix-1.2.1"
$ ./bump-version.sh 1.2.1
Files modified successfully, version bumped to 1.2.1.
$ git commit -a -m "Bumped version number to 1.2.1"
[hotfix-1.2.1 41e61bb] Bumped version number to 1.2.1
1 files changed, 1 insertions(+), 1 deletions(-)
```

别忘了在派生新分支后 bump 了版本号。
然后，修复 bug 并提交上去：

```bash
$ git commit -m "Fixed severe production problem"
[hotfix-1.2.1 abbe5d6] Fixed severe production problem
5 files changed, 32 insertions(+), 17 deletions(-)
```

<center>**完成 release 分支**</center>

当 bug 修复完成，修复代码需要合并到 `master` 分支上，同时还得 merge 到 `develop` 分支，以保证下一个 release 版本不会出现此 bug。这和 release 分支的结束过程是非常类似的。

首先，`master` 分支合并修复代码，然后为新的 release 标记 Tag：

```bash
$ git checkout master
Switched to branch 'master'
$ git merge --no-ff hotfix-1.2.1
Merge made by recursive.
(Summary of changes)
$ git tag -a 1.2.1
```

然后，轮到 `develop` 分支合并修复代码：

```bash
$ git checkout develop
Switched to branch 'develop'
$ git merge --no-ff hotfix-1.2.1
Merge made by recursive.
(Summary of changes)
```

有一个例外的原则是，如果当前有一个 release 分支存在，那么 hotfix 分支上的改动需要 merge 到 release 分支，而不是 `develop` 分支。当 release 分支结束时，merge 到 release 分支上的修复代码最终还是会 merge 到 `develop` 上。

最后，移除已经完成历史使命的分支：

```bash
$ git branch -d hotfix-1.2.1
Deleted branch hotfix-1.2.1 (was abbe5d6).
```

## 总结

这个分支模型虽然没什么令人耳目一新的东西，不过文章一开始给出的那张大图已经呈现了它对我们项目的裨益。它构造了一个优雅的模型，易于理解，并允许团队成员对分支的派生和发布有共同的认识。