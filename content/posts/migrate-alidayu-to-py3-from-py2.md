---
title: 阿里大鱼短信 SDK 迁移到 Python 3.x
date: 2016-02-02 11:05:24
tags:
  - Python
categories:
  - Coding
---
近期课余时间开发一个基于 Django 的 RESTful Web Service，需要接入短信验证发送功能，比较之后选定[阿里大鱼](http://www.alidayu.com/)的解决方案。

然而，选 Python 作为技术栈的悲催之处在于，虽然 Python 的第三方库和生态很强大，但是就国内的开发圈而言，Python 是一个相对小众的流派，又由于 Python 2.x 和 Python 3.x 的分化，许多第三方库并没有跟进 Python 3，导致很多时候用 Python 会有些捉襟见肘，尤其是像我这种野路子的 Python 开发。

<!-- more -->

比如阿里大鱼的短信方案，虽然相比其他厂商很良心的在 PHP 、 Java 版 SDK 之外，友情附赠了 Python 版，但集成进 Django 工程并 debug 后，真是握了棵草，它是基于 Python 2.x 开发的，翻了下开发包源码文件，署名为 “lihao” 的这位阿里同学是在 2012 年更新的源码，这竟是一份蒙尘多年的代码啊，当时我的内心是奔溃的……

> 自己动手，丰衣足食。——《毛选》

阿里大鱼短信开发包的源码并不复杂，来来去去无非一些 request，response 和 string 的处理，底层都是在阿里服务端 api 里实现的，短信包只是提供 api 调用、处理功能，因此迁移工作倒也不是很令人拙计。下面就把我填的坑一一道来（难免有遗忘和疏漏，见谅）——

#### 一号坑

```python
# 如果parameters是字典类
keys = parameters.keys()
```
不出所料的话，控制台会输出
`>>>TypeError: 'dict_keys' object does not support indexing`
这是一大坑，在 Python 3.x 里，`dict.keys()`, `dict.values()` 和 `dict.items()` 是返回一个 `dict_keys` 对象（dict_keys 不支持 indexing），而不是 Python 2.x 那样返回一个 `list`。因此最简单的迁移方法就是显式调用 `list()` 处理，
```python
# 如果parameters是字典类
keys = list(parameters.keys())
```
但实际上，这种处理办法并不是最优解，可参考 [Watch out for list(dict.keys()) in Python 3](http://blog.labix.org/2008/06/27/watch-out-for-listdictkeys-in-python-3)

#### 二号坑

```python
sign = hashlib.md5(parameters).hexdigest().upper()
```
哈哈，控制台会报如下错
`>>>Python hashlib problem “TypeError: Unicode-objects must be encoded before hashing”`
言简意赅，debug 信息已经给出了解决方案，上述代码中的 parameters 参数必须先 encoded 后才能 hash。So easy!
```python
sign = hashlib.md5(parameters.encode('utf8')).hexdigest().upper()
```
utf-8 转码后就没问题了，一个赛艇！

#### 三号坑

```python
if (isinstance(pstr, str)):
    return pstr
elif (isinstance(pstr, unicode)):
    return pstr.encode('utf-8')
```
运行后的错误信息：
`>>>NameError: global name 'unicode' is not defined`
Python 3.x 把 `unicode` 类型改名为 `str`，而原来 Python 2.x 下的 `str` 类型被 `bytes` 替代。所以解决办法就是按 Python 3.x 的定义来
```python
if (isinstance(pstr, bytes)):
    return pstr
elif (isinstance(pstr, str)):
    return pstr.encode('utf-8')
```

#### 四号坑

```python
connection = httplib.HTTPConnection(self.__domain, self.__port, False, timeout)
```
这里需要注意的地方有两处，Python 2.x 的 httplib 包的 import 路径为
`import httplib`
在 Python 3.x 里的 import 路径则是：
`import http.client as httplib`
还有一处注意点是，在更改了包路径后，httplib.HTTPConnection(httplib.HTTPConnection() 的参数也发生了变化，
Python 2.x 中该接口为
`httplib.HTTPConnection(host[, port[, strict[, timeout[, source_address]]]])`
其中，strict 默认为 False，而 Python 3.x 里该接口则修改成
`httplib.HTTPConnection(self, host, port=None, timeout=socket._GLOBAL_DEFAULT_TIMEOUT, source_address=None）`
很显然，阿里源码里的传参是按照 Python 2.x 的写法，对照 Python 3.x 接口改过来便是
```python
connection = httplib.HTTPConnection(self.__domain, self.__port, timeout)
```

#### 五号坑

```python
P_TIMESTAMP: str(long(time.time() * 1000))
```
`>>>NameError: name 'long' is not defined`
Python 3.x 已经将 Python 2.x 中的 `int` 和 `long` 型合并为 `int`，因此在 Python 3.x 下，已经不存在 `long` 类型了。修改成`int()`即可
```python
P_TIMESTAMP: str(int(time.time() * 1000))
```

#### 六号坑
```python
from urllib import urlencode
body = urllib.urlencode(application_parameter)
```
Python 3.x 把 Python 2.x 下 `urlencode()` 函数转移到了 `urllib.parse` 里。修改为
```python
from urllib.parse import urlencode
body = urllib.parse.urlencode(application_parameter)
```

#### 七号坑
```
result = response.read()
jsonobj = json.loads(result)
```
Python 3.x 里 JSON 只接收 unicode，因此 result 需要转码为 unicode
```python
result = response.read().decode('utf-8')
jsonobj = json.loads(result)
```

#### 八号坑
```python
for key, value in application_parameter.iteritems():
    pass
```
控制台报错：
`>>>AttributeError: 'dict' object has no attribute 'iteritems'`
字典没有 iteritems 属性？原来是 Python 3.x 已经把 `iteritems()` 给移除掉了，因此不能再调用该方法。
参考 [Python Wiki](https://wiki.python.org/moin/Python3.0):
> Remove dict.iteritems(), dict.iterkeys(), and dict.itervalues().
    Instead: use dict.items(), dict.keys(), and dict.values() respectively.

```python
for key, value in application_parameter.items():
    pass
```

Done!

#### Python 3.x 版本的 base.py

```python
# base.py
# -*- coding: utf-8 -*-
"""
Created on 2012-7-3

@author: lihao
"""

try:
    import httplib
except ImportError:
    import http.client as httplib
import urllib
import time
import hashlib
import json
import top
import itertools
import mimetypes
from urllib.parse import urlencode

'''
定义一些系统变量
'''

SYSTEM_GENERATE_VERSION = "taobao-sdk-python-20151217"

P_APPKEY = "app_key"
P_API = "method"
P_SESSION = "session"
P_ACCESS_TOKEN = "access_token"
P_VERSION = "v"
P_FORMAT = "format"
P_TIMESTAMP = "timestamp"
P_SIGN = "sign"
P_SIGN_METHOD = "sign_method"
P_PARTNER_ID = "partner_id"

P_CODE = 'code'
P_SUB_CODE = 'sub_code'
P_MSG = 'msg'
P_SUB_MSG = 'sub_msg'

N_REST = '/router/rest'


def sign(secret, parameters):
    # ===========================================================================
    # '''签名方法
    # @param secret: 签名需要的密钥
    # @param parameters: 支持字典和string两种
    # '''
    # ===========================================================================
    # 如果parameters 是字典类的话
    if hasattr(parameters, "items"):
        # keys = parameters.keys()
        keys = list(parameters.keys())  # sudoz: Py3
        keys.sort()

        parameters = "%s%s%s" % (secret,
                                 str().join(
                                         '%s%s' % (key, parameters[key]) for key
                                         in keys),
                                 secret)
    # sign = hashlib.md5(parameters).hexdigest().upper()
    sign = hashlib.md5(parameters.encode('utf8')).hexdigest().upper()   # sudoz: Py3
    return sign


def mixStr(pstr):
    if (isinstance(pstr, str)):
        return pstr
    # elif(isinstance(pstr, unicode)):
    elif (isinstance(pstr, str)):  # sudoz: Py3
        return pstr.encode('utf-8')
    else:
        return str(pstr)


class FileItem(object):
    def __init__(self, filename=None, content=None):
        self.filename = filename
        self.content = content


class MultiPartForm(object):
    """Accumulate the data to be used when posting a form."""

    def __init__(self):
        self.form_fields = []
        self.files = []
        self.boundary = "PYTHON_SDK_BOUNDARY"
        return

    def get_content_type(self):
        return 'multipart/form-data; boundary=%s' % self.boundary

    def add_field(self, name, value):
        """Add a simple field to the form data."""
        self.form_fields.append((name, str(value)))
        return

    def add_file(self, fieldname, filename, fileHandle, mimetype=None):
        """Add a file to be uploaded."""
        body = fileHandle.read()
        if mimetype is None:
            mimetype = mimetypes.guess_type(filename)[
                           0] or 'application/octet-stream'
        self.files.append((
                          mixStr(fieldname), mixStr(filename), mixStr(mimetype),
                          mixStr(body)))
        return

    def __str__(self):
        """Return a string representing the form data, including attached files."""
        # Build a list of lists, each containing "lines" of the
        # request.  Each part is separated by a boundary string.
        # Once the list is built, return a string where each
        # line is separated by '\r\n'.  
        parts = []
        part_boundary = '--' + self.boundary

        # Add the form fields
        parts.extend(
                [part_boundary,
                 'Content-Disposition: form-data; name="%s"' % name,
                 'Content-Type: text/plain; charset=UTF-8',
                 '',
                 value,
                 ]
                for name, value in self.form_fields
        )

        # Add the files to upload
        parts.extend(
                [part_boundary,
                 'Content-Disposition: file; name="%s"; filename="%s"' % \
                 (field_name, filename),
                 'Content-Type: %s' % content_type,
                 'Content-Transfer-Encoding: binary',
                 '',
                 body,
                 ]
                for field_name, filename, content_type, body in self.files
        )

        # Flatten the list and add closing boundary marker,
        # then return CR+LF separated data
        flattened = list(itertools.chain(*parts))
        flattened.append('--' + self.boundary + '--')
        flattened.append('')
        return '\r\n'.join(flattened)


class TopException(Exception):
    # ===========================================================================
    # 业务异常类
    # ===========================================================================
    def __init__(self):
        self.errorcode = None
        self.message = None
        self.subcode = None
        self.submsg = None
        self.application_host = None
        self.service_host = None

    def __str__(self, *args, **kwargs):
        sb = "errorcode=" + mixStr(self.errorcode) + \
             " message=" + mixStr(self.message) + \
             " subcode=" + mixStr(self.subcode) + \
             " submsg=" + mixStr(self.submsg) + \
             " application_host=" + mixStr(self.application_host) + \
             " service_host=" + mixStr(self.service_host)
        return sb


class RequestException(Exception):
    # ===========================================================================
    # 请求连接异常类
    # ===========================================================================
    pass


class RestApi(object):
    # ===========================================================================
    # Rest api的基类
    # ===========================================================================

    def __init__(self, domain='gw.api.taobao.com', port=80):
        # =======================================================================
        # 初始化基类
        # Args @param domain: 请求的域名或者ip
        #      @param port: 请求的端口
        # =======================================================================
        self.__domain = domain
        self.__port = port
        self.__httpmethod = "POST"
        if (top.getDefaultAppInfo()):
            self.__app_key = top.getDefaultAppInfo().appkey
            self.__secret = top.getDefaultAppInfo().secret

    def get_request_header(self):
        return {
            'Content-type': 'application/x-www-form-urlencoded;charset=UTF-8',
            "Cache-Control": "no-cache",
            "Connection": "Keep-Alive",
        }

    def set_app_info(self, appinfo):
        # =======================================================================
        # 设置请求的app信息
        # @param appinfo: import top
        #                 appinfo top.appinfo(appkey,secret)
        # =======================================================================
        self.__app_key = appinfo.appkey
        self.__secret = appinfo.secret

    def getapiname(self):
        return ""

    def getMultipartParas(self):
        return []

    def getTranslateParas(self):
        return {}

    def _check_requst(self):
        pass

    def getResponse(self, authrize=None, timeout=30):
        # =======================================================================
        # 获取response结果
        # =======================================================================
        # connection = httplib.HTTPConnection(self.__domain, self.__port, False,
        #                                     timeout)
        connection = httplib.HTTPConnection(self.__domain, self.__port, timeout)    # sudoz: Py3
        sys_parameters = {
            P_FORMAT: 'json',
            P_APPKEY: self.__app_key,
            P_SIGN_METHOD: "md5",
            P_VERSION: '2.0',
            # P_TIMESTAMP: str(long(time.time() * 1000)),
            P_TIMESTAMP: str(int(time.time() * 1000)),  # sudoz: Py3
            P_PARTNER_ID: SYSTEM_GENERATE_VERSION,
            P_API: self.getapiname(),
        }
        if authrize is not None:
            sys_parameters[P_SESSION] = authrize
        application_parameter = self.getApplicationParameters()
        sign_parameter = sys_parameters.copy()
        sign_parameter.update(application_parameter)
        sys_parameters[P_SIGN] = sign(self.__secret, sign_parameter)
        connection.connect()

        header = self.get_request_header()
        if self.getMultipartParas():
            form = MultiPartForm()
            for key, value in application_parameter.items():
                form.add_field(key, value)
            for key in self.getMultipartParas():
                fileitem = getattr(self, key)
                if fileitem and isinstance(fileitem, FileItem):
                    form.add_file(key, fileitem.filename, fileitem.content)
            body = str(form)
            header['Content-type'] = form.get_content_type()
        else:
            # body = urllib.urlencode(application_parameter)
            body = urllib.parse.urlencode(application_parameter)    # sudoz: Py3

        # url = N_REST + "?" + urllib.urlencode(sys_parameters)
        url = N_REST + "?" + urllib.parse.urlencode(sys_parameters)   # sudoz: Py3
        connection.request(self.__httpmethod, url, body=body, headers=header)
        response = connection.getresponse()
        if response.status is not 200:
            raise RequestException('invalid http status ' + str(
                response.status) + ',detail body:' + response.read())
        # result = response.read()
        result = response.read().decode('utf-8')    # sudoz: Py3里JSON只接收unicode
        jsonobj = json.loads(result)
        return jsonobj

    def getApplicationParameters(self):
        application_parameter = {}
        # for key, value in self.__dict__.iteritems():
        for key, value in self.__dict__.items():
            if not key.startswith(
                    "__") and not key in self.getMultipartParas() and not key.startswith(
                    "_RestApi__") and value is not None:
                if (key.startswith("_")):
                    application_parameter[key[1:]] = value
                else:
                    application_parameter[key] = value
        # 查询翻译字典来规避一些关键字属性
        translate_parameter = self.getTranslateParas()
        # for key, value in application_parameter.iteritems():
        for key, value in application_parameter.items():  # sudoz: Py3
            if key in translate_parameter:
                application_parameter[translate_parameter[key]] = \
                application_parameter[key]
                del application_parameter[key]
        return application_parameter
```