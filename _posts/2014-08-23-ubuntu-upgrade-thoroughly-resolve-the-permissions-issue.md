---
title: 升级 Ubuntu 14.04 后彻底解决权限问题
author: Wu Zhangjin
layout: post
permalink: /ubuntu-upgrade-thoroughly-resolve-the-permissions-issue/
tags:
  - 13.10
  - 14.04
  - PAM
  - PolicyKit
  - Ubuntu升级
  - 无法设置网络
  - 无法安装软件
  - 权限问题
categories:
  - Ubuntu
---

  * 问题描述

    从Ubuntu 12.10平滑升级到Ubuntu 14.04 (LTS)后发现在图形界面所有需要root权限的操作都无法工作，包括网络设置、软件安装等等，非常烦恼。

    例如，在安装软件时会有该问题：

        (org.freedesktop.PolicyKit.Error.Failed: (‘system-bus-name’, {‘name’: ‘:1.104′}): org.debian.apt.install-or-remove-packages


  * 问题分析

    查找资料后发现是PolicyKit的问题，可以临时通过gksu授权，不过这个并不是所有情况下都有用，比如说网络设置的NetworkManager服务，杀掉后通过gksu授权也不管用。

    另外，也发现从 13.10 开始就已经有该问题。

  * 解决方案

    通过苦苦搜寻，终于发现有一个彻底的解决办法，那就是修改登录管理器的 PAM 认证配置文件，例如 lxde 用了 lxdm 登录管理器，其对应配置为： `/etc/pam.d/lxdm`。

    在该文件开头的 `#%PAM-1.0` 后面加入如下两行后，重启 X 即可：

        session required pam_loginuid.so
        session required pam_systemd.so`


    类似地，如果用了其他登录管理器，比如 gdm 和 lightdm，可以同样修改，例如：`/etc/pam.d/gdm`, `/etc/pam.d/lightdm`。

    修改以后一切权限问题都OK了。

    从修改来看，可能是 Ubuntu 13.10 之后的登录认证方式有所变化，用到了 `pam_loginuid` 和 `pam_systemd`：

        pam_loginuid - Record user's login uid to the process attribute
        
        The pam_loginuid module sets the loginuid process attribute for the
        process that was authenticated. This is necessary for applications to
        be correctly audited. This PAM module should only be used for entry
        point applications like: login, sshd, gdm, vsftpd, crond and atd. There
        are probably other entry point applications besides these.


        pam_systemd registers user sessions in the systemd login manager
        systemd-logind.service(8), and hence the systemd control group
        hierarchy.


    注：我们在 [Ubuntu升级：从12.10到14.04 LTS][1] 一文也对此进行了说明。

    相关参考资料：

      * [Not authorized to perform operation][2]
      * [This operation cannot continue since proper authorization was not provided][3]





 [1]: /upgrade-to-ubuntu-lts-14-04-from-the-dead-12-10/
 [2]: https://bugs.launchpad.net/ubuntu/+source/policykit-desktop-privileges/+bug/1240336/comments/33
 [3]: http://ubuntugenius.wordpress.com/2013/11/29/ubuntu-13-10-permissions-fix-this-operation-cannot-continue-since-proper-authorization-was-not-provided-halts-software-updater-shutdown-drive-mounting-dvd-playback-etc/
