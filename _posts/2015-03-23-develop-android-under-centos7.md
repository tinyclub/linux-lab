---
title: 在 CentOS 7 下配置 Android 开发环境
author: bigz.zhang
layout: post
permalink: /develop-android-under-centos7/
views:
  - 104
tags:
  - Android
  - CentOS
  - Chrome
  - EPEL
  - Github
  - goagent
  - hoststool
  - JDK7
  - PyCharm
  - SciTools
  - thunderbird
  - Ubuntu
  - VirtualBox
  - VMware
  - VPN
  - 开发环境
categories:
  - Android
  - Linux
---

> by bigz of [TinyLab.org][1]
> 2015/3/23


## 起因

作为一个 Android 驱动工程师，Linux 很自然的成为了我日常工作的主要操作系统环境。

目前比较流行的 Linux 发行版本已经很多了，流行度最高的应该还是 Ubuntu, 而且 Google 提供的 Android 编译环境配置文档中，也只提供了 Ubuntu 的配置方法，这也导致了大部分公司都把 Ubuntu 作为默认的开发系统。

对我而言：

  1. 极度不喜欢 Ubuntu 的 Unity 界面。
  2. Ubuntu 更新太频繁，而且某些功能不太稳定。

在各种 Linux 发行版本中，我比较喜欢 CentOS，借用陈道明的一句广告词来形容它：**“简约而不简单!”**

如果你也喜欢 CentOS，且希望在 CentOS 7 上配置 Android 开发编译环境，那么恭喜你，这篇文章非常适合你！

## 安装 CentOS 7

参考 [CentOS 7 USB 安装][2]

## 安装必要的软件

### 配置三方源 Extra Packages for Enterprise Linux(EPEL)

EPEL，即 Extra Packages for Enterprise Linux， 是由 Fedora 社区创建维护，为 RHEL 及衍生发行版如 CentOS、Scientific Linux 等提供高质量软件包的项目。[EPEL][3] 中含有大量的软件，对官方标准源是一个很好的补充。

    sudo yum install epel-release


### 安装 Google Chrome

自从使用了 Chrome 浏览器后，每次装系统后第一个安装的软件必定是它，原因很简单: **好用!!**

如果你喜欢使用自带的 Firefox，可以跳过这一步！

  * 配置 Chrome 源

    进入 /etc/yum.repos.d 目录下，新建 google.repo 文件，或者直接修改目录下的 CentOS-Base.repo，在文件内追加如下参数：

        [google64]
        name=Chrome-x86_64
        baseurl=http://dl.google.com/linux/rpm/stable/x86_64
        enabled=1
        gpgcheck=1
        
        gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub


  * 安装 Chrome

    打开终端，按需求安装不同版本的 Chrome 即可。

      * 安装稳定版本：`sudo yum install google-chrome-stable`
      * 安装测试版本：`sudo yum install google-chrome-beta`
      * 安装不稳定版本：`sudo yum install google-chrome-beta`

### 配置 Android 编译环境

官方参考文档: [Android Build Environment][4]

Android 官方文档只提供了 Ubuntu 系统上的编译环境配置，这让不太喜欢使用 Ubuntu 的用户很蛋疼！

不过没关系，官方不提供，我们自己想办法解决。

    sudo yum install autoconf213 bison bzip2 ccache curl flex gawk gcc-c++ git glibc-devel glibc-static libstdc++-static libX11-devel make mesa-libGL-devel ncurses-devel patch zlib-devel ncurses-devel.i686 readline-devel.i686 zlib-devel.i686 libX11-devel.i686 mesa-libGL-devel.i686 glibc-devel.i686 libstdc++.i686 libXrandr.i686 zip perl-Digest-SHA wget


### 下载安装 JDK6 or JDK7

1. 下载对应版本的 [JDK][5]
2. 例如，解压至：`/usr/java/jdk1.6.0_45` 目录
3. 修改 ~/.bashrc，配置环境变量

        # JAVA Home
        export JAVA_HOME=/usr/java/jdk1.6.0_45
        export JRE_HOME=${JAVA_HOME}/jre
        export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
        export PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH


4. 使用 `java －version` 来确定是否安装成功

### MTK Android 编译环境支持（可选）

鉴于国内很多公司都有做 MTK 平台，而且 MTK 平台 Android L 版本以前都是使用自己的一套编译系统，所以还需要安装一些额外软件才行：

    sudo yum install unix2dos gperf mawk perl-Switch mingw32-gcc
    sudo ln -s i686-w64-mingw32-gcc i586-mingw32msvc-gcc


### 配置 Github 和 Ssh

Github 基本上已经成为程序猿的标配工具，所以，自然不能少了它。

1. [Github Linux配置][6]
2. 如果不想每次去 ssh-add Key, 在 ~/.bashrc 中添加

        ssh-add ～/.ssh/id_rsa


想更深入的了解 git 原理，请参考：[常用 Git 开发模型]()

### 配置 ADB

1. 在 51-android.rules 中只写一句：

        *SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", MODE="0666"*


2. 在 .android/adb_usb.ini 加入PID:

    *PID 可以通过 lsusb 来获取,如果没有该文件，创建之.*

### 配置 Vim

Linux 下不能使用 Source Insight，没有问题！！！

Vim＋Ctags＋Sscope 是一个不错的替代品，对于程序猿来说，甚至更加棒！！！且看：

  * [把 Vim 打造成源代码编辑器][7]
  * [在 Vim 中如何规范自己的代码][8]
  * [在 Linux 终端和 Vim 下复制粘贴][9]

### 安装 SciTools Understand（可选）

不能使用 Source Insight，这对于我们这类经常需要在 Android 这样的大型项目下分析代码的工程师来说，确实是一件很痛苦的事情。

如果一定需要一个类似 Source Insight 的工具，可以尝试 SciTools Understand。

个人感觉 Understand 相对于 Source Insight 在代码查找方面稍逊，但某些方面确比 Source Insight 强大，具体的功能可以参考官方网站的 [Feature介绍][10]

  1. 下载 Linux 版本，解压即可。
  2. 将 Scitools 的直接路径添加到 ~/.bashrc 中的环境变量中去。
  3. 如果想创建快捷菜单，可以在 /usr/local/share/applications/ 下创建一个新的 scitools.desktop 文件。

【编者注：实际上 Google 新推出的 Android Studio 更强大，甩出早期的 Eclipse + ADT 几条街，且看 [Android Studio 官方首页][11]】

### 安装 VMware Player/VirtualBox (可选)

对于需要使用 Windows 或需要安装另一个 Linux 系统用来测试的朋友非常需要虚拟机。

  * VMware 的安装非常简单，到官方网站下载安装包，一步步安装下去就可以了。
  * VirtualBox 可直接通过包管理工具安装。

### 安装 Mail 客户端 (可选)

Linux 的邮件客户端选择比较多，但是我个人比较喜欢 Thunderbird。

    $ sudo yum install thunderbird


### 安装 PyCharm (可选)

如果是你一个 Python 爱好者，那么一定不要错过PyCharm。

PyCharm 为爱好者们提供了一个免费的[Community版本][12]，尽情想用吧！

### 翻墙

对于工程师来说如果不能 Google，那将是一件痛苦无比的事情，大家都懂的。

*如果需要先安装 Chrome 或者访问 Android 官方网站，这一步骤需要提前。*

这里提供两个解决方案：

1. 如果有 VPN 帐号

    首先安装 CentOS 7 下图形方式配置 pptp 客户端：

    到 [这里][13] 查找和下载 NetworkManager-pptp-xxxxxxxx.nux.x86\_64.rpm、NetworkManager-pptp-gnome-xxxxxxxxxxx.x86\_64.rpm*

    进入下载目录后：

        yum install NetworkManager-pptp-xxxxxxxx.nux.x86_64.rpm NetworkManager-pptp-gnome-xxxxxxxxxxx.x86_64.rpm


    然后配置完成 VPN 即可。

2. 如果你没有 VPN 账号也没有关系，我们还可以使用 hoststool 和 goagent。

    相对 goagent，hoststool 更加稳定，不过似乎无法看 Youtube 视频；goagent 到 14 年末就不太稳定了，但是如果需要看 Youtube，却不可缺少；所以，我个人是两者都使用，弥补彼此的不足。

    可以到下面两个网址下载安装 hoststool：

  * [官方网站][14]
  * [Github][15]

    如果需要使用 GUI 版本，先安装 PyQt4 即可。

        sudo yum install PyQt4


    更多内容请参考：[Goagent图文教程][16]

## 遗留问题

  1. MTK flashtool 在 CentOS 7 上无法使用，应该是 USB 驱动问题。
  2. 如果你一定要在 CentOS 上使用 Source Insight，需要自己编译 Wine 32 位版本。

## 后记

前面只要是针对 Android 编译环境的大体配置方法进行了说明，还有一些细节并没有描述的非常清楚。如果大家有疑问，也可以在[泰晓科技][1]进一步交流！

另外，CentOS 搭建 Docker 环境也是非常轻松容易的，或许我们可以尝试使用 Docker 在 CentOS 上搭建起 Windows/Mac OS X/Linux 公用的 Android 编译环境。且看下回分解。





 [1]: http://tinylab.org
 [2]: http://wiki.centos.org/HowTos/InstallFromUSBkey
 [3]: http://fedoraproject.org/wiki/EPEL
 [4]: http://source.android.com/source/initializing.html
 [5]: http://www.oracle.com/technetwork/java/javase/downloads/index.html
 [6]: https://help.github.com/articles/set-up-git/#platform-linux
 [7]: /make-vim-source-code-editor/
 [8]: /faqs/how-to-regulate-their-own-code-in-vim/
 [9]: /linux-terminal-and-paste-copy-under-vim/
 [10]: https://scitools.com/features/
 [11]: http://developer.android.com/tools/studio/index.html
 [12]: https://www.jetbrains.com/pycharm/download/
 [13]: http://li.nux.ro/download/nux/dextop/el7/x86_64/
 [14]: https://hosts.huhamhire.com
 [15]: https://github.com/huhamhire/huhamhire-hosts/releases
 [16]: https://github.com/goagent/goagent/blob/wiki/InstallGuide.md
