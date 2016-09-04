---
title: Hexo 主题美化
date: 2016-07-14 16:01:06
tags:
  - Frontend
  - Hexo
categories:
  - Coding
---

小站有段时间没折{no}腾{zuo}前{no}端{die}了，在浏览别的个人站时总会时不时被里面的设计吸引到，最近闲着没事干，就把别人的主题抄袭过来，嘿嘿。

<!-- more -->

### 头像旋转

[Pacman](https://github.com/A-limon/pacman) 主题布局非常大气，最有心的设计在我看来就是底栏的可旋转的圆形头像，非常可爱。相比之下，鄙人小站侧边栏头像就显得很呆板了。那就抄过来！
可以知道，这是一个鼠标的 `hover` 事件，因此先找到位于 `source/css/_common/components/sidebar/sidebar-author.syl` 模板文件里侧边栏头像的样式 `.site-author-image`

```css
.site-author-image {
    display: block;
    margin: 0 auto;
    padding: $site-author-image-padding;
    max-width: $site-author-image-width;
    height: $site-author-image-height;
    border: $site-author-image-border-width solid $site-author-image-border-color;
}
```

首先要做的事就是把原头像图通过 css 样式改成圆形头像。通过修改 `border-radius` 属性就可以改图片四个角的圆角程度。另外针对不同内核的浏览器也能分别指定。再加上属性变化的动画效果 `transition`。

```css
.site-author-image {
    border-radius: 50%;
    -webkit-border-radius: 50%;
    -moz-border-radius: 50%;
    transition: 1.4s all;
}
```

圆角效果完成后，再做 `hover` 动作。添加 `.site-author-image:hover` 样式，由 `rotate()` 方法实现，旋转 360°

```css
.site-author-image:hover {
    -webkit-transform: rotate(360deg);
    -moz-transform: rotate(360deg);
    -ms-transform: rotate(360deg);
    -transform: rotate(360deg);
}
```

OK，成就达成。

### 侧边滚动条

[Yilia](https://github.com/litten/hexo-theme-yilia) 也是 GitHub 上非常受欢迎的一款 Hexo 主题， 虽然我用的不是 Yilia 主题，但是不妨碍我喜欢它的侧边滚动条，灰色系的性冷淡风很契合我的小站。所以我就把这个样式挪到了我的小站里。
为了不影响小站原主题的样式，最好不要直接在原有样式上做修改。在 `source/css/_custom` 里的 `custom.stl` 模板文件里编写对滚动条的自定义样式。不过有一点，自定义的滚动条只支持 webkit 内核的浏览器，比如 Firefox 和 IE 就爱莫能助了。当然，在 Chrome 上的体验完美！

```styl
// Custom styles.
::-webkit-scrollbar {
  width: 10px;
	height: 10px;
}
::-webkit-scrollbar-button {
	width: 0;
	height: 0;
}
::-webkit-scrollbar-button:start:increment,::-webkit-scrollbar-button:end:decrement {
	display: none;
}
::-webkit-scrollbar-corner {
	display: block;
}
::-webkit-scrollbar-thumb {
	border-radius: 8px;
	background-color: rgba(0,0,0,.2);
}
::-webkit-scrollbar-thumb:hover {
	border-radius: 8px;
	background-color: rgba(0,0,0,.5);
}
::-webkit-scrollbar-track,::-webkit-scrollbar-thumb {
	border-right: 1px solid transparent;
	border-left: 1px solid transparent;
}
::-webkit-scrollbar-track:hover {
	background-color: rgba(0,0,0,.15);
}
::-webkit-scrollbar-button:start {
	width: 10px;
	height: 10px;
	background: url(../images/scrollbar_arrow.png) no-repeat 0 0;
}
::-webkit-scrollbar-button:start:hover {
	background: url(../images/scrollbar_arrow.png) no-repeat -15px 0;
}
::-webkit-scrollbar-button:start:active {
	background: url(../images/scrollbar_arrow.png) no-repeat -30px 0;
}
::-webkit-scrollbar-button:end {
	width: 10px;
	height: 10px;
	background: url(../images/scrollbar_arrow.png) no-repeat 0 -18px;
}
::-webkit-scrollbar-button:end:hover {
	background: url(../images/scrollbar_arrow.png) no-repeat -15px -18px;
}
::-webkit-scrollbar-button:end:active {
	background: url(../images/scrollbar_arrow.png) no-repeat -30px -18px;
}
```

前后对比
![](https://o70e8d1kb.qnssl.com/scrollbars.png)

### 顶部阅读进度条

阅读进度条的宽度是随着页面上下滚动而变化的。当滚动条在顶部时，阅读进度条宽度为浏览器宽度的 0%，当滚动条在页面底部时，阅读进度条宽度为浏览器宽度的 100%。很简单，写好进度条的样式和高度计算的脚本就能轻松实现。
先在 `layout/_partials/header.swig` 模板文件里加上进度条的 div：

```html
<div class="top-scroll-bar"></div>
```

在自定义样式文件 `source/css/_custom/custom.styl` 中加上 `.top-scroll-bar` 的样式，还是一如既往采用克制的灰色系：

```css
.top-scroll-bar {
    position: fixed;
    top: 0;
    left: 0;
    z-index: 9999;
    display: none;
    width: 0;
    height: 2px;
    background: #6d6d6d;
}
```

然后在新建自定义的 js 脚本文件 `source/js/src/custom/custom.js`，计算当前高度的百分比：

```javascript
$(document).ready(function () {
  $(window).scroll(function(){
    $(".top-scroll-bar").attr("style", "width: " + ($(this).scrollTop() / ($(document).height() - $(this).height()) * 100) + "%; display: block;");
  });
});
```

再在 `layout/_scripts/commons.swig` 中把该文件引入进页面的模板中：

```swig
{%
  set js_commons = [
    'src/utils.js',
    'src/motion.js',
    'src/custom/custom.js'
  ]
%}

{% for common in js_commons %}
  <script type="text/javascript" src="{{ url_for(theme.js) }}/{{ common }}?v={{ theme.version }}"></script>
{% endfor %}
```


测试下，可以看到页面顶部出现了一道性感的阅读进度条。

### 页面加载进度条

前一段时间 GitHub 做了一次较大的更新，个人页面的连续 commit 提交天数被去掉了，还有在打开仓库文件时可以看到页面顶部增加了一条发光发亮的加载进度条。通过 Chrome 控制台可以看到，这条加载进度条是由下面的 HTML 代码展示的：

```html
<div id="js-pjax-loader-bar" class="pjax-loader-bar">
  <div class="progress" style="width: 100%;"></div>
</div>
```

思路跟上面的阅读进度条一样。不过需要更改计算进度条宽度的依据，根据资源加载的完成度来改变进度条的宽度，并且当宽度为 100% 时自动隐藏。GitHub 上已经有轮子可用，就是 [nprogress](https://github.com/rstacruz/nprogress)，提供了 `nprogress.css` 和 `nprogress.js` 两个文件。因为是第三方的库，所以把这两个文件加进 `source/vendor/nprogress/` 目录下。
在 `layout/_partials/head.swig` 模板中加入 `nprogress.css`：

```
{% set nprogress_uri = url_for(theme.vendors._internal + '/nprogress/nprogress.css') %}
<link href="{{ nprogress_uri }}" rel="stylesheet" type="text/css" />
```

在 `layout/_scripts/vendors.swig` 模板中加入 `nprogress.js`：

```
{% set js_vendors.nprogress   = 'nprogress/nprogress.js' %}
```

这样就完成了对 nprogress 样式和脚本的引入。在 `custom.js` 里加入页面加载进度条的脚本：

```javascript
$(document).ready(function () {
    // 页面加载进度条
    NProgress.start();
    window.onload = function () {
        NProgress.done();
    };
});
```

大功告成 :)
