title: Begin Arch Linux
date: 2015-09-26 18:02:05
categories:
- Linux
tags:
- Linux
- Arch
---
iPhone 6S都发布，仍然用着刚上大学那会买的笔记本，cry...

最近这块被我拆拆装装的本越发像犯了老年痴呆一样，对于一个不折腾不痛快星人而言，这不啻一个新的玩点。

在[V2EX](https://www.v2ex.com/)上混的时候，被多次安利[Arch Linux](https://www.archlinux.org)，传闻中的K.I.S.S风格，滚动升级，业界良心的Wiki，强大的社区支持，让常在Linux下搬砖的我心生向往。于是就在别人轻抚刚发货的iPhone 6S的夜晚，开始第N+1次折腾。

故事就在这样一个夜晚发生了...

### 准备工作

Arch的镜像很小，仅不到700M，由于光驱已经退役，因此就用了U盘做启动。在Linux下用`dd`命令就可以将iso镜像烧写进U盘：
```sh
$ dd bs=4M if=/path_archlinux.iso of=/dev/sdx && sync
```
其中`sdx`为`/dev`下挂载的U盘文件符。几页书的时间，烧写完毕，准备工作就绪！

### 躁起来吧，骚年

重启选择U盘启动，U盘里的镜像文件释放展开，屏幕上显现启动列表，选择第一个x86-64进入Arch配置安装。前方没有任何图形，黑白两色的屏幕像极了窗外的夜。

#### 联网
相比Debian、CentOS这些动辄3,4G的安装镜像，Arch有着诱人的小而美，也意味这很多包都需要联网下载。所以安装过程中，必须要联网。
```sh
$ wifi-mune
```
输入wifi密码，ping测试。

#### 磁盘
执行`lsblk`查看当前磁盘挂载情况，本地磁盘的话都是`sdx`。我准备删掉Win7+ubuntu的双系统全新安装Arch，对磁盘来一次彻底的革命。
```sh
$ parted /dev/sda
(parted) mklabel msdos
(parted) mkpart primary ext4 1M 300M
(parted) set 1 boot on
(parted) mkpart primary ext4 300M 50G
(parted) mkpart primary linux-swap 50G 54G
(parted) mkpart primary ext4 54G 100%
```
上面的操作是对本地磁盘进行分区，分别为`/boot`分区、`/`分区、`swap`交换分区和`/home`分区。分区完成后，exit退出parted状态返回安装界面。

再次`lsblk`查看磁盘情况，可以看到`sda`生成了`sda1`～`sda4`4个分区，接下来就是对这些分区进行格式化和挂载。
```sh
$ mkfs.ext4 /dev/sda1
$ mkfs.ext4 /dev/sda2
$ mkswap    /dev/sda3
$ mkfs.ext4 /dev/sda4
$
$ mount /dev/sda2 /mnt
$ mkdir -p /mnt/boot
$ mkdir -p /mnt/home
$ mount /dev/sda1 /mnt/boot
$ mount /dev/sda4 /mnt/home
$ mkswap /dev/sda3
$ swapon /dev/sda3
```
这是我的操作，每个人分区不同操作也各异，注意每个分区应该挂载到对应的位置上，否则后果可想而知。

#### 安装进行时

修改安装源，中科大的mirror很靠谱，修改`/etc/pacman.d/mirrorlist`，找到中科大mirror地址，粘贴到第一行即为最高下载优先级。

下面就是安装进行时：
```sh
$ pacstrap -i /mnt base base-devel
```
几分钟的胡思乱想之后，Arch成功安装到挂载空间中。`arch-chroot`进入挂载空间中的Arch，进行必要的初始配置：
```sh
$ genfstab -U /mnt > /mnt/etc/fstab
$ arch-chroot /mnt /bin/bash
$ vi /etc/locale.gen
...
en_US.UTF-8 UTF-8
zh_CN.UTF-8 UTF-8

$ locale-gen
$ echo LANG=en_US.UTF-8 > /etc/locale.conf
$ ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
$ hwclock --systohc --utc
```

安装grub引导并生成配置文件
```sh
$ pacman -S grub os-prober
$ grub-install --recheck /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
```

给自己的第一台Arch起个响亮的名字吧，`echo hello-world > /etc/hostname`。exit退出chroot环境，`mount -R /mnt`结束挂载，`reboot`进入Arch的世界。

### Done!

哈哈，真真是个大道至简的黑屏白字世界，Arch于此开始，一如混沌之初。

![](https://i.imgur.com/BBzfW3H.png)

TODO: 后续再把图形化过程记下来,包括 xorg -> xfce -> lightdm -> video-driver, etc.

> K.I.S.S: Keep It Simple, Stupid.   
> 大道至简，大智若愚。   
