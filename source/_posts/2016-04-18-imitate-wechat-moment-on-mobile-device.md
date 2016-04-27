---
title: 移动端仿微信朋友圈发布图文
date: 2016-04-18 19:55:14
tags: Canvas
categories: Coding
---

最近一个项目需要在移动端开发一个类似微信朋友圈的功能，从前端到后端都遇到了一些坑，其中有些经过还是很值得记录下来。

<!-- more -->

由于微信朋友圈的火爆和用户基础，因此 JD 的这个项目中类朋友圈的原型设计基本也是抄袭的微信，只不过换成 HTML5 的样式，所以原型图就不贴出来了……要实现的功能大致等于微信朋友圈，用户通过手机相册或摄像头上传图片，发布到京东 App 的一个版块里，由于一期不开发社交功能，因此没有朋友圈留言功能（电商 App 不务正业，我也是无力吐槽）。
从项目前端开始讲吧。

### 前端

在移动端通过 HTML 页面上传图文，并不能粗暴的沿用以往 PC 端上的做法。在 PC 端，通常我们会使用百度的 [WebUploader](http://fex.baidu.com/webuploader/) 组件，或者 [jQuery-File-Upload](https://github.com/blueimp/jQuery-File-Upload)，再久远些还有用 Flash 做的文件上传插件，略过不表。移动端的玩法却不大一样，最主要的还是因为网络环境的差异，现在手机拍照动辄就好几兆的文件大小，如果像朋友圈发状态一次上传好几张图片，客户端不做处理的话，无论是传输时间还是流量损耗都是不能接受的。因此移动端需要在上传前默认对大体积图片进行压缩处理，后面会完整说明。

#### input 标签

移动端上传文件仍然采用 HTML5 的 input 标签，区别于 PC 端上，移动设备除了调用文件浏览器外，还可以调用摄像头进行拍照上传，需要加入 capture 参数
``` html
<input type="file" name="file" accept="image/*" capture="camera">
```
但是这里存在一个坑，关于在 iOS 和 Android 系统上浏览行为的差异，我们知道在 input 标签里加入 multiple 参数是可以控制多选文件的，这在 PC 和 iOS上都兼容，但 Android 却不支持，只能一次选一个文件。因为没有在 Android 上找到可靠的修补方案，我在开发中也放弃了点开浏览并多选的功能，退而求其次点选一张图片。

关于 input 标签，通常产品经理是不能忍受原始的 input 标签的样式的，因为真的太简陋了。前端设计的页面静态文件里的添加按钮往往都不是 input 标签，那怎么办呢，一个比较通用的解决方案是监听自定义样式添加按钮的 DOM 事件，触发点击隐藏 input 标签，曲线救国完成任务。
``` html
<!-- 图片添加按钮 -->
<ul id="previewer" class="upload-list">
    <li id="select-image" class="add-pic-btn"><a href="javascript:;" onclick="clickBrowse();">+</a></li>
    <!-- 预览列表 -->
</ul>
<!-- 隐藏的 input -->
<input type="file" id="browsefile" name="imageselect" style="visibility: hidden" accept="image/*" capture="camera">
```
其中 clickBrowse() 方法为监听 input 标签 change 事件的函数。
```javascript
// footprint-add.js
$(function () {
    if (window.File && window.FileReader && window.FormData) {
        log("支持File对象");
        var inputFiled = $('#browsefile');
        inputFiled.on('change', function (e) {
            log("有添加动作");
            if (imageIndex == 9) {
                // 如果已经预选了9张，则不再添加
                mTips.show('最多添加9张图片哦', 2000);
                return;
            }
            var images = e.target.files;
            var count = images.length;  // 图片数量
            for (var i = 0; i < count; i++) {
                var image = e.target.files[i];
                if (image) {
                    if (!/\/(?:jpeg|jpg|png)/i.test(image.type)) {
                        return;
                    }
                    readFile(image);  // 读取图片
                }
            }
        })
    }
})
```

#### FileReader

### 后端

### 优化
