---
title: Gunicorn 驱动工厂模式 Flask 应用
date: 2016-08-29 13:45:50
tags:
  - Python
categories:
  - DevOps
---

之前用 uWsgi 部署过 Django 应用，但当时的开发和部署都还手生，有很多不合理的地方，最近写的一个 Flask 应用，用了另一个 wsgi 容器 —— [Gunicorn](http://gunicorn.org/)，并且利用工厂模式对不同开发环境进行了隔离。工厂模式下的 Flask 应用在用 Gunicorn 部署时，需要做一点针对性的改动。

<!-- more -->

### 基础的 Flask 应用部署

先写一个最简单的 Flask 应用 hello：

```python
# hello.py
from flask import Flask

app = Flask(__name__)


@app.route('/')
def hello_world():
    return "Hello World!"


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

然后用 Python 去解释执行这段脚本即可，Flask 内置了简易的 HTTP Server 来处理请求。

当然这仅仅供本地测试的运行方式，线上部署的方案，通常是采用 wsgi 程序来驱动 Flask / Django 应用。Gunicorn 是性能比较好的一个方案（有时间我会做一次 Gunicorn 与 uWsgi 的性能压测对比）。Gunicorn 的驱动 hello 应用的命令如下：

```python
gunicorn -w 4 -b 127.0.0.1:5000 hello:app
```

Gunicorn 的常用运行参数说明：
- -w  WORKERS, --workers: worker 进程的数量，通常每个 CPU 内核运行 2-4 个 worker 进程。
- -b  BIND, --bind: 指定要绑定的服务器端口号或 socket
- -c  CONFIG, --config: 指定 config 文件
- -k  WORKERCLASS, --worker-class: worker 进程的类型，如 sync, eventlet, gevent, 默认为 sync
- -n  APP_NAME, --name: 指定 Gunicorn 进程在进程查看列表里的显示名（比如 ps 和 htop 命令查看）

真正部署到生产环境，一般不会用 Gunicorn 直接处理客户端的 HTTP 请求，而是用类似 Nginx 来做代理，将请求代理到 Gunicorn，再由 Flask 程序进行处理，返回结果。配置 Nginx 如下

```conf
server {
    listen 80;

    server_name _;

    access_log  /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    location / {
        proxy_pass         http://127.0.0.1:5000/;
        proxy_redirect     off;

        proxy_set_header   Host                 $host;
        proxy_set_header   X-Real-IP            $remote_addr;
        proxy_set_header   X-Forwarded-For      $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto    $scheme;
    }
}
```

这样就实现了 Client <-> Nginx <-> Server port / socket <-> Gunicorn <-> Flask 整个请求响应链路。

### 工厂模式的部署

上面给了最简单的应用部署方案，学习练手没问题，实际开发部署就得多考虑一些问题。一个主要的问题就是多环境配置，这个在上一篇关于 Django 非最佳实践里涉及到了，但是当时的方案很挫，只是通过配置文件的替换来解决。利用工厂模式来解决这个问题是更正确合理的方法。

先把上面的 hello 程序做的再复杂一点，把 Flask 的 [Blueprints](http://flask.pocoo.org/docs/0.11/blueprints/#blueprints) 集成进来：

```python
# blueprint.py
from flask import Blueprint, render_template, abort
from jinja2 import TemplateNotFound

simple_page = Blueprint('simple_page', __name__, template_folder='templates',
                        static_folder='static')


@simple_page.route('/', defaults={'page': 'index'})
@simple_page.route('/<page>')
def show(page):
    try:
        return render_template('pages/$s.html' % page)
    except TemplateNotFound:
        abort(404)
```

```python
# hello.py
from flask import Flask
from blueprint import simple_page

app = Flask(__name__)
app.register_blueprint(simple_page)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Flask 的 Blueprints 有很强大的功能，当项目变的比较大型时尤为重要，这里不作展开。上面的代码是通用的一种简单开发模式，就是在创建应用实例时将 Blueprints 注册进来。工厂模式并不是这么处理，相比这种简单模式，工厂模式会把 app 的创建转移到一个专门的方法中，就是所谓的工厂，然后根据要生产的产品类型，创建不同的实例。
这样处理的好处是显而易见的——
- 便于测试。测试环境的配置往往和生产环境不同，这样就能运行不同环境配置的应用实例；
- 多实例。通过工厂模式，可以实现在同一个应用进程下，运行多个实例；

创建工厂：

```python
# manage.py
from flask import Flask


def create_app(config_filename):
    app = Flask(__name__)
    app.config.from_pyfile(config_filename)

    from blueprint import simple_page
    app.register_blueprint(simple_page)

    return app
```

```python
from manage import create_app

app = create_app('config.py')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

根据传入的不同 config，创建不通的 app 实例。创建工厂后，有一点需要留意，就是在 Blueprints 内没法访问 app 对象实例了，因为当 Blueprints 注册时 app 对实例尚未被创建，但也有解决办法，就是通过 Flask 的 current_app：

```python
# blueprints.py
from flask import Blueprint, render_template, abort, current_app
from jinja2 import TemplateNotFound

simple_page = Blueprint('simple_page', __name__, template_folder='templates',
                        static_folder='static')


@simple_page.route('/', defaults={'page': 'index'})
@simple_page.route('/<page>')
def show(page):
    try:
        return render_template(current_app.config['INDEX_TEMPLATE'])
    except TemplateNotFound:
        abort(404)
```

在实现基本的工厂模式后，再回来对 Gunicorn 和 Nginx 进行配置。上面用的是 Server Port，接下来就改为 socket。
Nginx conf 配置：

```conf
server {
    listen 80;

    server_name _;

    access_log  /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    location / {
        proxy_pass         http://unix:/path/to/project.sock;
        proxy_redirect     off;

        proxy_set_header   Host                 $host;
        proxy_set_header   X-Real-IP            $remote_addr;
        proxy_set_header   X-Forwarded-For      $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto    $scheme;
    }
}
```

上面的 proxy_pass 参数也可以使用 upstream 来作反向代理，作用是一样的。然后 Gunicorn 运行：

```shell
gunicorn -w 4 -b unix:/path/to/project.sock hello:app
```
