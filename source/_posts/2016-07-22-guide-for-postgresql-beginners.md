---
title: 开始使用 PostgreSQL
date: 2016-07-22 10:49:49
tags:
  - PostgreSQL
categories:
  - Database
---

最近开始做的一个课余项目用 Flask + PostgreSQL + Bootstrap 快速开发。之前本地开发和生产部署都用 [MySQL](https://www.mysql.com/)，而 [PostgreSQL](https://www.postgresql.org/) 是关系型数据库阵营中的另一大高手。这俩的口号放在一起看相当好玩。

<!-- more -->

![](https://o70e8d1kb.qnssl.com/mysql-vs-postgresql.png)

一个自称 "The world's most popular open source database"，另一个自称 "The world's most advanced open source database"。论针锋相对，我就服这俩。→_→

至于 MySQL 和 PostgreSQL 之间的比较，可以参考 Digital Ocean 社区里的一篇文章，写的很详细，顺便还拉上了 SQLite。
[SQLite vs MySQL vs PostgreSQL: A Comparison Of Relational Database Management Systems](https://www.digitalocean.com/community/tutorials/sqlite-vs-mysql-vs-postgresql-a-comparison-of-relational-database-management-systems)

菜鸟入门三板斧，安装、配置和使用——

### 安装

服务器端我习惯用 Debian 系统。Debian/Ubuntu 内置的 APT 源已经包含了 PostgreSQL，但版本上会稍滞后于 PostgreSQL 最新版本。如果像我一样激进的，可以把 PostgreSQL 官方维护的 APT 源加进 Debian/Ubuntu 的 APT 列表中。比如在 Debian 系统下，新建文件 `/etc/apt/sources.list.d/pgdg.list`，添加源地址和版本，再导入该源的签名。

```text
deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main
```
```bash
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update && sudo apt install postgresql postgresql-client postgresql-contrib postgresql-server-dev
```

安装 PostgreSQL 会安装多个核心包和扩展包，常用和重要的包有：

* postgresql-client: 客户端库和二进制文件
* postgresql: 核心数据库服务器
* postgresql-contrib: 额外的支持模块
* libpq-dev: C 语言的头文件和库（前端）
* postgresql-server-dev: C 语言的头文件和库（后端）
* pgadmin3: 图形化工具集（服务器端无需安装）

安装后查看服务运行状况 `sudo service postgresql status`，查看守护进程运行状况 `ps -ef | grep postgres`。PostgreSQL 默认监听 5432 端口。

### 配置

#### 创建用户/角色

PostgreSQL 会自动创建名为 `postgres` 的 Linux 用户，用来操作 PostgreSQL 数据库。先修改 `postgres` 的用户密码，`sudo passwd postgres`；再切换至 `postgres` 用户，`su - postgres`，输入刚才设置的用户密码，成功切换后可以看到 `postgres` 的用户目录为 `/var/lib/postgresql`；
执行 `psql` 命令进入 PostgreSQL 命令控制台：

```
psql (9.5.3)
Type "help" for help.

postgres=# 
```

PostgreSQL 除了创建新的 Linux 用户 `postgres`，还创建了同样名为 `postgres` 数据库用户和同名数据库。在 PostgreSQL 控制台里为数据库用户 `postgres` 创建密码，`\password postgres`。
当然也可以为单独创建一个数据库用户，通过 `postgres` Linux 用户新建和 Linux 用户名相同的数据库用户，并设定该用户为 superuser，使其具备数据库的读写权限。

```bash
postgres@Dev:~$ createuser --interactive
```

反之，如果要删除数据库用户，执行 `dropuser`。

同上，再为新建的数据库用户设置密码。这样，在使用 PostgreSQL 数据库 shell 时就无需切换到 `postgres` 用户了，可以直接在当前 Linux 用户下执行一系列 PostgreSQL 的操作，如新建数据库 `createdb` 命令等。

上面提到的各种用户名都快要绕晕了。梳理一遍，Linux 用户 `postgres` 和数据库用户 `postgres` 是完全同的两个概念。Linux 用户是用来连接数据库的，而数据库用户是用来完成数据库的管理任务。对 PostgreSQL 而言，数据库用户和 Linux 用户是彼此对应的，Linux 用户默认连接与其同名的数据库。例如，Linux 用户 `postgres` 执行 `psql` 默认会连接到 `postgres` 数据库用户下的 `postgres` 数据库；同样的，如果已经创建和当前 Linux 用户同名的数据库用户 `${USER}`，那么执行 `psql` 会尝试连接名为 `${USER}` 的数据库。

#### 创建数据库

创建 PostgreSQL 数据库的操作很简单，`createdb mytestdb`；连接到指定数据库，`psql mytestdb`，就进入到 PostgreSQL 客户端控制台
```bash
psql (9.5.3)
Type "help" for help.

mytestdb=#
```

将数据库的所有权限赋予给数据库用户

```sql
GRANT ALL ON mytestdb.* TO dbuser;
```

在控制台里输入 `\h` 查看所有可使用命令的帮助文档，或者指定要查询的命令 `\h command`。

#### 配置本地访问

默认设置下，PostgreSQL 的数据库连接会在当前系统用户拥有该数据库权限的情况下被被认证通过。当特定系统用户在系统本地运行程序时会很实用，但如果需要更安全的配置，就要通过验证密码来访问数据库。

先切换到 Linux 用户 `postgres`，修改配置文件 `/etc/postgresql/9.x/main/pg_hba.conf`，在 `# "local" is for Unix domain socket connections only` 这行可以见到如下配置：

```text
# "local" is for Unix domain socket connections only
local    all        all             peer
```

将认证方式 `peer` 替换为 `md5`。切换回自己的系统用户，重启 PostgreSQL 服务。现在，如果想在 `postgres` 用户下，尝试用数据库用户 `${USER}` 连接测试数据库 `testdb`，就需要输入密码了。
```bash
postgres@Dev:~$ psql -U sudoz -W testdb 
Password for user sudoz:
```

#### 配置远程访问

默认配置的 PostgreSQL 会监听来自 `localhost` 的访问连接，但它不建议修改配置去监听来自公网 IP 的连接。如果需要同图形化的工具来远程访问服务器上的 PostgreSQL 数据库，就得修改配置文件 `/etc/postgresql/9.x/main/postgresql.conf`，当然，也需要切换到 `postgres` 系统用户去操作，因为这些配置文件的所属用户和组都是 `postgres` 的。修改 `listen_addresses = 'localhost'` 行，默认设置是只监听本地，把 `localhost` 替换为 `*`，或者添加指定 IP 地址，`localhost,my_remote_server_ip_address`，就可以将远程访问加入白名单中。

```python
listen_addresses = '*'    # what IP address(es) to listen on;
                          # comma-separated list of addresses;
                          # defaults to 'localhost'; use '*' for all
                          # (change requires restart)
```

### 使用

#### 常用控制台命令

由 `psql` 进入到 PostgreSQL 客户端控制台，大致罗列几个常用命令：
- `\?` 查看全部 psql 命令
- `\h` 查看全部 SQL 命令或指定的 SQL 命令
- `\q` 退出 psql 控制台，退回到 Linux shell（Ctrl + d 作用相同）
- `\l` 列出全部数据库 
- `\c` 连接到其他数据库，命令后跟数据库名
- `\d` 列出当前数据库下所有数据表
- `\dp` 列出所有访问权限
- `\du` 列出所有用户以及他们的权限
- `\dt` 展示当前数据库中所有表相关的汇总信息
- `\password` 修改指定数据库用户的密码
- `\conninfo` 查看当前数据库和连接信息

#### 数据库操作

和 MySQL 支持扩展的 SQL 标准不同，PostgreSQL 严格遵循完备的 ANSI-SQL 标准，因此 PostgreSQL 的数据库操作规范且通用。下面就写几条常用的 SQL 语句。

```sql
# 创建新表 
CREATE TABLE playground (
    equip_id serial PRIMARY KEY,
    type varchar (50) NOT NULL,
    color varchar (25) NOT NULL,
    location varchar(25) check (location in ('north', 'south', 'west', 'east', 'northeast', 'southeast', 'southwest', 'northwest')),
    install_date date
);
# 插入数据 
INSERT INTO playground (type, color, location, install_date) VALUES ('slide', 'blue', 'south', '2014-04-28');
# 选择记录 
SELECT * FROM playground;
# 更新数据 
UPDATE playground set color = 'blue' WHERE equip_id = 1;
# 删除记录 
DELETE FROM playground WHERE type = 'slide';
# 添加栏位 
ALTER TABLE playground ADD email VARCHAR(40);
# 更新结构 
ALTER TABLE playground ALTER COLUMN email SET NOT NULL;
# 更名栏位 
ALTER TABLE playground RENAME COLUMN email TO mail;
# 删除栏位 
ALTER TABLE playground DROP COLUMN email;
# 表格更名 
ALTER TABLE playground RENAME TO ground;
# 删除表格 
DROP TABLE IF EXISTS ground;
```

好啦，PostgreSQL 初级入门就写到这，后续开发过程中会总结更多使用经验，持续更新。