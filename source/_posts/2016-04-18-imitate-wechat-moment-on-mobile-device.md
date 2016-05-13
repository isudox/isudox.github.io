---
title: 移动端仿微信朋友圈发布图文
date: 2016-04-18 19:55:14
tags: [Canvas,HTML5,FE]
categories: [Coding]
---

最近一个项目需要在移动端开发一个类似微信朋友圈的功能，从前端到后端都碰到了一些坑，自认为还是挺值得记录下来的。

<!-- more -->

由于微信朋友圈的火爆和用户基础，因此 JD 的这个项目中类朋友圈的原型设计基本也是抄袭的微信，只不过换成 HTML5 的样式，所以原型图就不贴出来了……要实现的功能大致等于微信朋友圈，用户通过手机相册或摄像头上传图片，发布到京东 App 的一个版块里，由于一期不开发社交功能，因此没有朋友圈留言功能（电商 APP 不务正业，我也是无力吐槽）。
从项目前端开始讲吧。

### 前端

在移动端通过 HTML 页面上传图文，并不能粗暴的沿用以往 PC 端上的做法。在 PC 端，通常我们会使用百度的 [WebUploader](http://fex.baidu.com/webuploader/) 组件，或者 [jQuery-File-Upload](https://github.com/blueimp/jQuery-File-Upload)，再久远些还有用 Flash 做的文件上传插件，略过不表。移动端的玩法却不大一样，最主要的还是因为网络环境的差异，现在手机拍照动辄就好几兆的文件大小，如果像朋友圈发状态一次上传好几张图片，客户端不做处理的话，无论是传输时间还是流量损耗都是不能接受的。因此移动端需要在上传前默认对大体积图片进行压缩处理，后面会完整说明。

#### input 标签

移动端上传文件仍然采用 HTML5 的 input 标签，区别于 PC 端上，移动设备除了调用文件浏览器外，还可以调用摄像头进行拍照上传，需要加入 capture 参数
``` html
<input type="file" name="file" accept="image/*" capture="camera">
```
但是这里存在一个坑，关于在 iOS 和 Android 系统上浏览行为的差异，我们知道 input 标签里加入 multiple 参数是可以控制多选文件的，PC 和 iOS上都支持该特性，但 Android 却不兼容，只能一次选一个文件。因为没有在 Android 上找到可靠的修补方案，我在开发中也放弃了点开浏览并多选的功能，退而求其次点选一张图片。

关于 input 标签，通常产品经理是不能忍受原始的 input 标签的样式的，因为真的太简陋了。前端设计的页面静态文件里的添加按钮往往都不是 input 标签，那怎么办呢，一个比较通用的解决方案是监听自定义样式添加按钮的 DOM 事件，触发点击隐藏 input 标签，曲线救国完成任务。
```html
<!-- 图片添加按钮 -->
<ul id="previewer" class="upload-list">
    <li id="select-image" class="add-pic-btn"><a href="javascript:;" onclick="clickBrowse();">+</a></li>
    <!-- 预览列表 -->
</ul>
<!-- 隐藏的 input -->
<input type="file" id="browsefile" name="imageselect" style="visibility: hidden" accept="image/*" capture="camera">
```

```javascript
/* footprint-add.js */

// 自定义图片添加按钮的click事件
function clickBrowse() {
    log("点击添加");
    $('#browsefile').click();
}

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
其中 clickBrowse() 方法为监听 input 标签 change 事件的方法。另外参照了微信朋友圈的做法，图片数量限制为 9 张。上面代码里最终的一步就是 readFile() 方法，它实现了对相册和摄像头图片的读取和处理。ReadFile() 调用了 HTML5 的 [FileReader API](https://developer.mozilla.org/en-US/docs/Web/API/FileReader)，接下来的小节就具体说说 HTML5 的 FileReader。

#### FileReader

在具体展开讲 FileReader 之前，得先了解在 Web 中使用 [File](https://developer.mozilla.org/en-US/docs/Using_files_from_web_applications) 接口，MDN 的这篇文章详细介绍了如何在 Web 应用中使用 File 接口。简言之，File API 提供了在 Web 应用中对文件对象的抽象功能，对于 type="file" 的 input 标签，所选的文件被抽象为 [FileList](https://developer.mozilla.org/en-US/docs/Web/API/FileList) 对象，可以像数组一样去调用 FileList 中的 File 对象。其中，File 对象中的属性主要有：

- name: 当前File对象所引用文件的文件名，不包含任何路径信息，只读
- size: 当前File对象所引用文件的文件大小，单位为字节，只读
- type: 当前File对象所引用文件的文件类型(MIME类型)，如果类型未知,则返回空字符串，只读

对照上一节贴出来的代码，程序里调用了 File 接口获取 File 对象，并将 File 对象传递给 readFile() 方法，由 FileReader 读取 File 对象。
参考 MDN 的权威解释，FileReader 可以异步的读取存储在用户计算机上的文件（或原始数据缓存）内容。创建 FileReader 对象的方法就是 new 一个对象出来：

```javascript
var reader = new FileReader();
```

FileReader 读取文件内容的方法有：

- abort(): 中止该读取操作。在返回时，eadyState 属性的值为 DONE
- readAsArrayBuffer(): 开始读取指定的 Blob 对象或 File 对象中的内容。当读取操作完成时，readyState 属性的值会成为 DONE，如果设置了 onloadend 事件处理程序，则调用之。同时，result 属性中将包含一个 ArrayBuffer 对象以表示所读取文件的内容
- readAsBinaryString(): 当读取操作完成时，readyState 属性的值会成为 DONE。同时，result 属性中将包含所读取文件的原始二进制数据
- readAsDataURL(): 当读取操作完成时，readyState 属性的值会成为 DONE。同时，result 属性中将包含一个data: URL格式的字符串以表示所读取文件的内容
- readAsText(): 当读取操作完成时,readyState 属性的值会成为 DONE。同时，result属性中将包含一个字符串以表示所读取的文件内容

FileReader 有如下事件处理标识：
- onabort: 当读取操作被中止时调用
- onerror: 当读取操作发生错误时调用
- onload: 当读取操作成功完成时调用
- onloadend: 当读取操作完成时调用,不管是成功还是失败.该处理程序在onload或者onerror之后调用
- onloadstart: 当读取操作将要开始之前调用
- onprogress: 在读取数据过程中周期性调用

```javascript
function readFile(image) {
    var reader = new FileReader();
    reader.onloadend = function () {
        var previewer = $('#previewer');
        var src = this.result;  // base64
        previewer.append('<li><img src="' + src + '" alt=""><i class="remove"></i></li>');
        // 清除图片上传input的值
        $('#browsefile').val("");
        // 对图片进行本地Canvas处理
        processFile(reader.result, image.type);
    };
    reader.onerror = function () {
        log('读取图片异常');
    };
    reader.readAsDataURL(image);
}
```

上面贴出的 readFile() 方法中，创建了 FileReader 对象对入参 File 对象进行处理，调用 readAsDataUrl() 方法获取 File 的 base64 字符串。在读取操作完成时，执行自定义的操作，在我的程序里做了图片预览和 Canvas 处理。在进行 Canvas 操作时有个坑，编码时并不知道，到测试时才发现的，因此放到后面再展开。
在图片文件读取到后，紧接着要做的就是调用 Canvas API 对图片进行前端压缩处理。

#### Canvas

Canvas 对图片的处理放在了 processFile() 方法中，我的做法略粗暴，对图片的高宽设定了固定的限值，只对超过高宽限值的图片做压缩处理。其实应该采取更合理的压缩策略，比如根据图片文件的大小，后期迭代时再完善吧。先把这部分的代码贴出来。

```javascript
// Canvas处理
function processFile(dataURL, fileType) {
    var maxWidth = 800, maxHeight = 800;
    var image = new Image();
    image.src = dataURL;
    image.onload = function () {
        var width = image.width;
        var height = image.height;
        var shouldResize = (width > maxWidth) || (height > maxHeight);
        if (!shouldResize) {
            // 无需压缩
            imageIndex++;
            imageData['imageData' + imageIndex] = dataURL;
            return;
        }
        var newWidth, newHeight;
        // 等比压缩
        if (width > height) {
            newHeight = height * (maxWidth / width);
            newWidth = maxWidth;
        } else {
            newWidth = width * (maxHeight / height);
            newHeight = maxHeight;
        }
        var canvas = document.createElement('canvas');
        canvas.width = newWidth;
        canvas.height = newHeight;
        var context = canvas.getContext('2d');
        context.drawImage(this, 0, 0, newWidth, newHeight);
        dataURL = canvas.toDataURL(fileType);   // base64
        imageIndex++;
        imageData['imageData' + imageIndex] = dataURL;
        return;
    };
    image.onerror = function () {
        log('图片处理时异常！');
    }
}
```

重点看 Canvas API 部分。MDN 上有相当完善的 [tutorial](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial)。首先通过 createElement() 创建 canvas 元素，并设置 canvas 的高宽。

```html
<canvas id="tutorial" width="150" height="150"></canvas>
```

canvas 元素创建了一个固定大小的画布，在这个上下文 context 中可以绘制和处理要展示的内容。初始的 canvas 元素是空白的，要在上面绘制内容，需要先获取它的上下文。上面的代码里通过 getContext() 方法获取 canvas 元素的上下文。

```javascript
var context = canvas.getContext('2d');
```

在取得 canvas 上下文后，就能通过 drawImage() 方法将图片绘制到 canvas 元素里。

```javascript
context.drawImage(image, x, y, width, height);
```

其中参数 image 是 image 或者 canvas 对象，x 和 y 是其在目标 canvas 里的其实坐标，width 和 height 控制 canvas 绘制时的缩放宽高。drawImage() 函数支持更多传参，具体可参考 MDN 上的文档。

在 canvas 元素上绘出图像后，再调用 canvas.toDataURL() 方法，就能获取到该 canvas 对象中所包含图片编码后的 data: URL 字符串。到此，canvas 的处理流程就完成了，接下来的步骤就是将处理后的图片数据发送到后端。

#### FormData

HTML5 新增加了 [FormData](https://developer.mozilla.org/en-US/docs/Web/API/FormData) 接口，FormData 类似 HashMap，通过 append() 方法插入键值对，模拟待提交的表单元素，FormData 相比普通 ajax 提交的优势在于，它可以异步上传二进制文件。

```javascript
// 发布按钮事件
function submit() {
    var tag = $('#tag').val();
    var content = $('#feeling').val();
    formData.append("tag", tag);
    formData.append("content", content);
    formData.append("profileId", window.localStorage.getItem("profileId"));
    var i = 0;
    for (var key in imageData) {
        formData.append("imageData_" + i, imageData[key]);
        i++;
    }
    formData.append("count", i);    // 图片数量
    $.ajax({
        type: 'POST',
        url: '/footprint/upload',
        data: formData,
        contentType: false,
        processData: false,
        success: function (data) {
            log(data);
            if (data.success) {
                // handler
            } else {
                // handler
            }
        },
        error: function (data) {
            // handler
        }
    });
}
```

FormData 的 api 里有一需要注意的地方，我一开始也没有留心。因为产品的设计是仿 (chao) 照 (xi) 微信的，对于图文的发布限制了最多上传 9 张图片，同时支持删除待提交图片，所以需要动态的监控待提交的图片数量，FormData 有一个删除键值对的方法 formdata.delete(key)，我当时想既然有这个方法就可以即时删除待提交的图片数据，然而我错了，delete() 方法在浏览器里支持可以说很糟糕，参考 MDN 给出的兼容列表：

![](https://o70e8d1kb.qnssl.com/imitate-wechat-moment-on-mobile-device-1.png)

只能另寻他途。

```javascript
// 监听图片删除按钮点击
$(document).on('click', '.remove', function (e) {
    var i = $(this).index();
    log('remove index ' + i);
    // 删除FormData和页面上的图片
    $(this).parent().remove();
    delete imageData['imageData' + i];
    imageIndex--;
});
```

#### iOS 调试兼容性

前面在讲 canvas 处理时提到一个坑，再功能测试时才发现，就是经过 canvas 处理后的图片上传服务器后读取出来会发生旋转的问题。多次测试后发现，只有当调用摄像头竖拍上传时才会发生这个错误，横拍或者调用相册选图上传就正常。通常这种不知道从哪冒出来的 bug 找谷歌就行了，关键字 canvas upload image ios rotation 搜索到 stackoverflow 上有同样的[问题](http://stackoverflow.com/questions/19463126/how-to-draw-photo-with-correct-orientation-in-canvas-after-capture-photo-by-usin)，道出了问题发生的根源，就是摄像头竖拍照片的 EXIF 的信息发生了变化。读取 EXIF 并修正照片的旋转。

Github 上有一个读取照片 EXIF 信息的 [exif.js](https://github.com/exif-js/exif-js) 库，提供了读取 API，在上面的 readFile() 方法中加入 EXIF 读取：

```javascript
// 读取图片
function readFile(image) {
    // 省略...
    reader.onloadend = function () {
        EXIF.getData(image, function () {
            EXIF.getAllTags(this);
            orientation = EXIF.getTag(this, 'Orientation');
        });
        processFile(reader.result, image.type, orientation);
    };
}

// Canvas处理图片
function processFile(dataURL, fileType, orientation) {
    var device = "";
    if (navigator.userAgent.match(/iphone/i)) {
        device = 'iphone';
    } else if (navigator.userAgent.match(/android/i)) {
        device = 'android';
    } else {
        device = 'other';
    }
    // 省略...
    // bugfix: 解决iOS设备上传竖拍照片后被逆时针旋转90°的问题
    if (device === 'iphone') {
        switch (orientation) {
            case 8:
                context.rotate(90*Math.PI/180);
                break;
            case 3:
                context.rotate(180*Math.PI/180);
                break;
            case 6:
                context.rotate(-90*Math.PI/180);
                break;
        }
    }
}
```

调整 orientation 属性后，iOS 设备测试正常。

### 后端

### 优化
