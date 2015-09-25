---
title: Ubuntu 升级：从 12.10 到 14.04(LTS)
author: Wu Zhangjin
layout: post
permalink: /upgrade-to-ubuntu-lts-14-04-from-the-dead-12-10/
tags:
  - 12.10
  - 14.04
  - gksu
  - LTS
  - LXDM
  - NetworkManager
  - not authorized to
  - PolicyKit
  - Quantal
  - Trusty
  - Ubuntu
  - 升级
  - 无法设置网络
  - 无法安装软件
  - 权限问题
categories:
  - Linux
---

> by falcon of [TinyLab.org][2]
> 2014/07/24


## 前言

最近发现Ubuntu 12.10(Quantal)已经停止维护，所有源都无法更新，所有软件都无法升级，因为官方源已经把12.10移除了。

解决该问题的办法是尽快升级到更新的版本，但是升级到什么版本更合适呢？LTS版。

## Ubuntu LTS简介

下面先来介绍下什么是[Ubuntu LTS][3]？

  * LTS是“Long Term Support”的缩写，即长期支持版本。
  * 每6个月发布新的桌面和服务器版本。这意味着总能拥有开源世界提供的最新最好的软件。
  * Ubuntu在设计时就考虑了安全因素，至少可以免费提供9个月的安全更新，包括桌面和服务器版。
  * LTS版每2年发布一次，在早期发布中，LTS版的桌面只有3年支持，而LTS版的服务器有5年支持，但是从12.04 LTS开始，包括桌面和服务器都拥有5年支持。
  * LTS没有额外的收费。
  * LTS版本只适应Ubuntu的某些特定子集，并不是Ubuntu的所有版本和衍生，例如8.04 LTS，Kubuntu选择迁移到KDE 4.0并且没有发行LTS版本。在10.04，Netbook版本没有LTS。Ubuntu项目会在LTS开发周期的前期决定哪个版本会成为LTS。

历史上的LTS版本有，10.04, 12.04, 14.04，每隔一个04版本会发布一个LTS版，所以下一个LTS可能会是16.04，而最新的LTS版是14.04。

关于所有发布过的版本，可以通过[这里][4]查看。

## 升级Ubuntu 12.10到LTS 14.04

升级过程其实很简单，

  * 先更新源到14.04

可以把源里头的版本名字进行替换，比如12.10叫Quantal，最新的14.04叫Trusty：

<pre>$ sudo sed -i -e "s/quantal/trusty/g" /etc/apt/sources.list.d/*.list
$ sudo sed -i -e "s/quantal/trusty/g" /etc/apt/sources.list
</pre>

也可以通过一些网站（例如：[Ubuntu Sources List Generator][5]）生成。

  * 接着更新源数据库

<pre>$ sudo apt-get update
</pre>

  * 然后更新软件并智能删除不再需要的包

<pre>$ sudo apt-get upgrade
$ sudo apt-get dist-upgrade
</pre>

## 试用并除错

重启后基本妥当，但是发现中文输入法无法调出，于是通过`Menu -> Preferences -> Language Support`安装中文包，但是出现如下错误：

> (org.freedesktop.PolicyKit.Error.Failed: (&#8216;system-bus-name&#8217;, {&#8216;name&#8217;: &#8216;:1.104&#8242;}): org.debian.apt.install-or-remove-packages

但是成功通过命令行安装了中文支持：

<pre>$ sudo apt-get install language-pack-zh-hans*
</pre>

然后确保安装了sunpinyin和pinyin输入法：

<pre>$ sudo apt-get install ibus-sunpinyin ibus-pinyin
</pre>

安装完中文包以后，还需要通过右键调出桌面右下角的Ibus输入法配置框，选择`Preferences -> Input Method -> Select Input Method -> Chinese -> Pinyin/SunPinyin`。

之后就可以通过`CTRL+Space`调出拼音输入法或者是SunPinyin输入法了。

另外，参考[Software center cannot install or remove software][6]通过如下命令启动Language Support安装界面，也可以正常获得安装权限：

<pre>$ gksu /usr/bin/python3 /usr/bin/gnome-language-selector
</pre>

类似地，如果有其他权限问题，也可以通过gksu启动来预先授权。但是要彻底解决该问题，请看下面。

## 彻底解决权限问题

通过千辛万苦地搜索后，发现在 `/etc/pam.d/lxdm` 到 `#%PAM-10` 第一行后面加入该配置即可解决问题：

<pre>session required pam_loginuid.so
session required pam_systemd.so
</pre>

如果gdm，lightdm也有问题，那么可以针对相应配置文件做类似修改，`/etc/pam.d/gdm`, `/etc/pam.d/lightdm`。

如果想切换不同到登录管理器，例如切到gdm，可以这么做：

<pre>$ sudo dpkg-reconfigure gdm
</pre>

相关参考资料：

  * [LXDM: On Login produces No Session for PID (lxde pid) error][7]
  * [Not authorized to perform operation&#8230;.][8]





 [2]: http://tinylab.org
 [3]: https://wiki.ubuntu.com/LTS
 [4]: http://releases.ubuntu.com/
 [5]: http://repogen.simplylinux.ch/
 [6]: http://askubuntu.com/questions/215712/software-center-cannot-install-or-remove-software
 [7]: http://ubuntuforums.org/showthread.php?t=2178645&p=13045560#post13045560
 [8]: https://bugs.launchpad.net/ubuntu/+source/policykit-desktop-privileges/+bug/1240336/comments/33
