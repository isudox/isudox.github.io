---
title: 通过代理安装 AUR 软件包
date: 2016-05-09 23:27:07
tags: [Arch,Proxy]
categories: [Linux]
---

Arch 最迷人的地方莫过于完善的 Wiki 和强大的 [AUR](https://wiki.archlinux.org/index.php/Arch_User_Repository)(Arch User Repository)。然而由于某些{不可说}的人为原因，在 Arch 里安装 AUR 包时不时就会遇到连接失败导致无法安装的问题。比如之前我试图安装 Atom，但屡试屡败，其中的苦你一定懂。

<!-- more -->

这种问题当然不会难到我，解决的办法就是让安装 AUR 的程序能通过一把梯子翻过高墙，毕竟梯子是掌握正确上网姿势的必备条件。

就以上面提到的 [atom-editor](https://aur.archlinux.org/packages/atom-editor/) 的安装为例，通常 AUR 维护的包都会包含一个记录安装信息和安装命令的脚本文件 PKGBUILD，比如 atom-editor 包的 PKGBUILD 文件内容为

```
# Maintainer: Sebastian Jug <seb@stianj.ug>
# Contributor: John Reese <jreese@noswap.com>
# Upstream URL: https://github.com/atom/atom
#
# For improvements/fixes to this package, please send a pull request:
# https://github.com/sjug/atom-editor

pkgname=atom-editor
pkgver=1.7.3
pkgrel=1
pkgdesc='Chrome-based text editor from Github'
arch=('x86_64' 'i686')
url='https://github.com/atom/atom'
license=('MIT')
depends=('alsa-lib' 'desktop-file-utils' 'gconf' 'gtk2' 'libgnome-keyring' 'libnotify' 'libxtst' 'nodejs' 'nss' 'python2')
optdepends=('gvfs: file deletion support')
makedepends=('git' 'npm')
conflicts=('atom-editor-bin' 'atom-editor-git')
install=atom.install
source=("https://github.com/atom/atom/archive/v${pkgver}.tar.gz"
        'package.patch')
sha256sums=('5074b59ddaca5525eb48098dee6fe63013799cbc77749add314b9e1bc894b8f4'
            'ab27ab817f67043e98298d525efb6a417dea07f4012b6dfb7cf6a538f9b50bab')

prepare() {
  cd "atom-$pkgver"

  patch -Np0 -i "$srcdir/package.patch"

  sed -i -e "/exception-reporting/d" \
      -e "/metrics/d" package.json

  sed -e "s/<%= description %>/$pkgdesc/" \
    -e "s|<%= appName %>|Atom|"\
    -e "s|<%= installDir %>/share/<%= appFileName %>|/usr/bin|"\
    -e "s|<%= iconPath %>|atom|"\
    resources/linux/atom.desktop.in > resources/linux/Atom.desktop
}

build() {
  cd "$srcdir/atom-$pkgver"

  export PYTHON=python2
  script/build --build-dir "$srcdir/atom-build"
}

package() {
  cd "$srcdir/atom-$pkgver"

  script/grunt install --build-dir "$srcdir/atom-build" --install-dir "$pkgdir/usr"

  install -Dm644 resources/linux/Atom.desktop "$pkgdir/usr/share/applications/atom.desktop"
  install -Dm644 resources/app-icons/stable/png/1024.png "$pkgdir/usr/share/pixmaps/atom.png"
  install -Dm644 LICENSE.md "$pkgdir/usr/share/licenses/$pkgname/LICENSE.md"
}
```

脚本内容很清晰，注明了软件包的说明，下载路径，依赖/冲突关系和安装命令。很显然，安装失败的原因就是因为国内网络无法连接上 atom 的安装包下载地址 https://github.com/atom/atom/archive/v1.7.3.tar.gz。
AUR 包的安装需要在包目录下执行
```bash
makepkg -sri
```
因此得修改 makepkg 的配置，使得 makepkg 在调用下载程序时能通过 Proxy 翻过防火墙的阻碍。makepkg 的配置文件位于 `/etc/makepkg.conf`，找到 DLAGENT 字段

```
#-- The download utilities that makepkg should use to acquire sources
#  Format: 'protocol::agent'
DLAGENTS=('ftp::/usr/bin/curl -fC - --ftp-pasv --retry 3 --retry-delay 3 -o %o %u'
          'http::/usr/bin/curl -fLC - --retry 3 --retry-delay 3 -o %o %u'
          'https::/usr/bin/curl -fLC - --retry 3 --retry-delay 3 -o %o %u'
          'rsync::/usr/bin/rsync --no-motd -z %u %o'
          'scp::/usr/bin/scp -C %u %o')
```

DLAGENT 顾名思义就是 Download Agent 的意思，这个字段指定了不同网络协议的下载工具和下载参数，默认是调用 curl 下载。现在只需要让 curl 通过 Proxy 而非直连的方式去下载 PKGBUILD 里设置的软件包即可。查看 curl 命令的参数用法

```bash
curl -h | grep socks
     --socks4 HOST[:PORT]  SOCKS4 proxy on given host + port
     --socks4a HOST[:PORT]  SOCKS4a proxy on given host + port
     --socks5 HOST[:PORT]  SOCKS5 proxy on given host + port
     --socks5-hostname HOST[:PORT]  SOCKS5 proxy, pass host name to proxy
     --socks5-gssapi-service NAME  SOCKS5 proxy service name for GSS-API
     --socks5-gssapi-nec  Compatibility with NEC SOCKS5 server
```

因为我搭的 Proxy 是通过 socks5，所以在 makepkg.conf 配置文件里的 DLAGENT 字段中加上 `--socks5 127.0.0.1:1080` 参数就行了。最后测试一把：

![Imgur](https://i.imgur.com/lnnrhqt.png)

![Imgur](https://i.imgur.com/1tI4gsX.png)

大功告成，喜大普奔！

另外，也可以自定义下载工具，比如 axel 就是很好的替代选择，可以设置多线程下载，速度非常快。

没有自由，何谈快乐！
