---
title: 小记 JavaScript 全局变量的一些思考
date: 2015-10-25 19:37:47
tags:
- JavaScript
- Front
categories:
- Coding
---
毕业来JD后完成的第一个任务是写选号中心的前端。由于和PM没有及时沟通，其间改了几次需求，导致一部分工作推倒重来。这个过程中体会较多的是谨慎使用`JavaScript`全局变量，带来便利的同时也有意想不到的坑，更不应滥用，很多时候全局变量并不是一个好选择。

<!-- more -->

一个很重要的原因就是，页面所引用的JS文件里所有变量和函数都是在同一个域(`scope`)中运行，重名的变量和函数被覆盖，bug将随之而来。如果仅仅只是一个展示页或由个人独立开发的项目，这个问题或许并不明显，但对于团队开发，组件化开发而言，全局变量会是深埋的地雷，你不知道什么时候自己会踩上，或者下一时刻会是谁踩上。举个简单的栗子：
```javascript
// example1.js
var vim_fan = true;
var emacs_fan = false;
function judge() {
    if (vim_fan && emacs_fan) {
        alert("You must be burned!");
    }
}
```
```javascript
// example2.js
var emacs_fan = 1;
```
如果HTML页面里引用了这两个JS文件，那么这个既加入Vim党又加入Emacs党的人将被烧死。然而这种情况是不应该存在的。这就是`JavaScript`全局变量的隐患，尤其是在公司里团队开发，当你调用已有的组件时，往往是黑箱操作，当全局变量出现冲突时，就会引发未知错误。

`JavaScript`语法太灵活，有时无意中就声明了一个全局变量，比如忘了加`var`，或者像这样赋值`var a = b = 1;`（值是传递了，但变量的生存期没有传递，b变成了全局变量）。
对应的解决办法也很简单，同时也是很好的`JavaScript`编码习惯，因为同一域下的JS文件都不重名，当需要在当前JS文件里调用全局变量时，创建已该JS文件名命名的全局对象，在全局对象中添加属性。这样即使在同一域下其他JS文件中有同名属性，由于所属对象不同，也不会发生冲突。相当于是在一个域里各自圈地，互不相扰。
```javascript
// bad.js
var current = null;
function init() {
    //...
}
function change() {
    //...
}
function verify() {
    //...
}
```
上面的写法很糟糕，全局变量暴露在外，简直就是不定时炸弹。那么来圈地运动吧。
```javascript
// notbad.js
var NOT_BAD = {
    current: null,
    init: function() {
        //...
    },
    change: function() {
        //...
    },
    verify: function() {
        //...
    }
}
```
如上，这样处理不算糟糕，至少是将当前JS所需要的全局变量包裹在专属对象中，但由此也带来一个问题：当需要调用全局变量时，总要加上对象名，比如`NOT_BAD.current`，这种代码实在是太丑陋了，孰不可忍。再看下一种处理方式：
```javascript
// good.js
var GOOD = (function() {
    var current = null;
    function init() {
        //...
    }
    function change() {
        //...
    }
    function verify() {
        //...
    }
    return {
        init: init,
        change: change
    };
}) ();
```
这种写法就是将全局变量和全局函数包裹进一个匿名函数中，该匿名函数会返回包含了外部所需变量的对象。这就是模块模式（Module Pattern）。
