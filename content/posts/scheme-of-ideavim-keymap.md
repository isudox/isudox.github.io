---
title: JetBrains IDE Vim 模式的方案
tags:
  - Vim
categories:
  - Coding
date: 2016-07-26 16:47:03
---


之前的一篇[博客](/2016/05/17/intellij-idea-keymap-zh/)翻译了 IntelliJ IDEA 的默认快捷键操作。快捷操作的功能覆盖面已经很全了，但如果想进阶键盘流，可能还需要一点文本编辑上的快操，比如 Vim 模式。用户有需求，良心厂商 JetBrains 就自己开发了一款强大插件 [Ideavim](https://github.com/JetBrains/ideavim)，模拟 Vim 编辑器的操作。

<!-- more -->

在安装 ideavim 插件后，IDE 可能会处在几种不同的模式下：

- Vim 模拟器关闭模式（Vim Emulator off）
- Vim 模拟器开启模式（Vim Emulator on）
- Vim 命令模式（Command mode）
- Vim 插入模式（Insert mode）
- Vim 末行命令模式（Last line mode）

当关闭 Vim 模拟器时，IDE 的 Keymap 会恢复到安装 Ideavim 之前的状态，因此最好是在自己自定义设置并熟悉 IDE 自带的 keymap 后安装 Ideavim 插件。开启/关闭 Vim 模拟器的快捷键可以北自定义，默认的切换快捷键是 `Ctrl` + `Alt` + `V`，这个切换方式和 IDE 自带的快捷键冲突，可以考虑改成更合适的映射。我把切换 Vim 开关状态的快捷键修改成了 `Ctrl` + `;`，这样，如果 `Caps` 键映射成 `Ctrl` 键，左手右手一个慢动作，可以很方便的开启/关闭 Vim 模拟器。

Vim 模拟器关闭状态下就不多讲了，之前都翻译过。在 Vim 模拟器开启后，IDE 就拥有了 Vim 编辑器的强大功能（不是全部，但也很强大了）。Vim 的三个模式基本都耳熟能详了，命令模式下的键盘动作会被识别为命令，而不是字符输入，比如 `a` 进入 append 输入，`i` 进入 insert 输入，`x` 删除光标所在的字符，`X` 删除光标之前的字符，`dd` 删除光标所在行，`yy` 复制当前行，`p` 粘贴等。插入模式就是正常的文本输入编辑，`Esc` 键退出插入模式，或者 `Ctrl` + `[`。末行命令模式是从命令模式下按 `:` 键进入，可以执行保存、退出、`set:options` 等操作。

Vim 模拟器的很多快捷键都和 IDE 默认的快捷键有冲突，比如常用的 `Ctrl` + `C`，IDE 在第一次检测到快捷键冲突时会弹框让用户选择该快捷键的功能是 IDE 默认还是 Vim 模式，我的选择是尽量把冲突的快捷键定义为 Vim 模式，然后去修改 IDE 的默认快捷键。下面列了一张 vim 和 IDEA 快捷键的冲突表，并标注了自己的取舍修改方案——

> 注：`Ctrl` `Alt` `Shift` 键下面用了缩写，比如 C + A 表示 Ctrl + A， C\_A + A 表示 Ctrl + Alt + A，C\_S + A 表示 Ctrl + Shift + A；
标记有 √ 符的表示采用该快捷键，被<del>标记划掉</del>则表示舍去该方案，如果 Vim 内置快捷键中不包含该功能，则提供建议的替代方案来实现原功能；

| 快捷键 | JetBrains IDE 功能 | Vim 功能 |
|:------:|:------:|:--------:|
| Ctrl+2 | Project Directory √ | <del>空缺</del> |
| Ctrl+Shift+2 | 插入/取消标记 2 √ | <del>空缺</del> |
| Ctrl+Shift+6 | 插入/取消标记 6 √ | <del>空缺</del> |
| Ctrl+A | 全选 √ | <del>光标所在数字递增</del> |
| Ctrl+B | 跳转至引用 √ | <del>向上翻一屏</del> |
| Ctrl+C | <del>复制</del> | 退出插入模式 √ |
| Ctrl+D | <del>复写当前行</del> | 向下翻半屏 √ |
| Ctrl+E | <del>打开最近的文档</del> **（改成 C_A + R）** | 向下滚动行 √ |
| Ctrl+F | 查找 √ | <del>向下翻一屏</del> |
| Ctrl+G | <del>跳转到指定行</del> | 打印当前文件名 √ |
| Ctrl+H | <del>当前类型的继承关系</del> **（改为 Alt + H）** | 光标退格 √ |
| Ctrl+I | <del>Implement 方法</del> **（改为 Alt + I）** | 跳转到 [Jump List](http://vim.wikia.com/wiki/Jumping_to_previously_visited_locations) 下一个位置 √ |
| Ctrl+M | <del>光标所在行滚动到屏幕中央</del> **（改为 Alt + M）** | 移动到下一行的首个非空字符 √ |
| Ctrl+N | <del>查找指定 Class</del> **（改为 Alt + N）** | 移动到下一行，光标相对位置不变 √ |
| Ctrl+O | <del>Override 方法</del> **（改为 Alt + O）** | 跳转到 [Jump List](http://vim.wikia.com/wiki/Jumping_to_previously_visited_locations) 上一位置 √ |
| Ctrl+P | <del>Show/Hide path text<del> **（改为 Alt + P）** | 移动到上一行，光标相对位置不变 √ |
| Ctrl+Q | <del>Quick Documentation</del> **（改为 C_A + Q）** | 代替 Ctrl-V 开启 Visual |
| Ctrl+R | <del>替换文本</del> **（改为 Alt + R）** | 恢复上一次修改 √ |
| Ctrl+S | 保存全部改动 √ | <del>分割窗口</del> |
| Ctrl+T | <del>更新工程<del> **（改为 Alt + T）** | 跳转到 [Tag Stack](http://vim.wikia.com/wiki/Browsing_programs_with_tags) 上一位置 √ |
| Ctrl+U | <del>跳转至父类方法</del> **（改为 Alt + U）** | 向上翻半屏 √ |
| Ctrl+V | 粘贴 √ | <del>开启 Visual 模式</del> |
| Ctrl+W | <del>智能选中</del> **（改为 Alt + W）** | 窗口命令，后接具体指令 |
| Ctrl+X | 剪切 √ | <del>光标所在数字递减</del> |
| Ctrl+Y | <del>删除光标所在行</del> | 向上滚动行 √ |
| Ctrl+[ | <del>光标移动到代码块的起始位置</del> **（改为 Alt + [）** | 退出插入模式 √ |
| Ctrl+] | <del>光标移动到代码块的结束位置</del> **（改为 Alt + ]）** | 跳转到关键字的声明处 √ |

上述所有冲突的快捷键尽量保留 Vim 功能，而 IDE 原有的快捷键功能会被覆盖掉。其中部分被覆盖掉的 IDE 快捷键非常有用，建议重新绑定新的快捷键映射。比如 Ctrl+H 原来绑定的查看当前类型的继承关系，Ctrl+W 智能选中，都是非常好用的功能，而且在 Vim 中没有提供的。

![ideavim-conflict-keymap](https://o70e8d1kb.qnssl.com/ideavim-keymap.png)

还有一个细节可能会造成困扰，就是当 Vim 模拟器关闭时，光标是呈竖条状；Vim 模拟器开启时，光标在命令模式时呈竖块状，在插入模式时呈竖条状。这就导致一个问题，当光标是竖条状时，怎么知道当前是处在 Vim 模拟器关闭状态，还是 Vim 模拟器的插入模式呢？
暂时还没想到特别聪明的办法，不过笨一点可以在不知道当前是那个编辑状态时，按 Esc 键，如果光标变成竖块状，就证明 Vim 模拟器是开启状态，否则就是关闭状态。