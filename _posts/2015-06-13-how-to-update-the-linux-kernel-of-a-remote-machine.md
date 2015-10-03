---
title: 如何更新远程主机上的 Linux 内核
author: Wu Zhangjin
layout: post
permalink: /how-to-update-the-linux-kernel-of-a-remote-machine/
tags:
  - 系统维护
  - Linux
  - 在线更新
  - 服务器
categories:
  - 稳定性
---

> By Falcon of [TinyLab.org][1]
> 2008/06/27

**注**：最近在 linuxsir.org 看到有一篇《能否不重新起動而使用新遍譯好的內核》的帖子，最近楼主自己发了一个解决办法的帖子，叫《用 kexec 迅速切换内核》，即参考[资料][2]，另外，也请参考一下[资料][3]。这种方法启动更快，但是要求内核高于2.6.23。


## 问题背景

先来讨论这样一个问题：

假设我们有一台服务器放在网络中心，网络中心却离我们呆的地方比较远，如果想更新这台服务器上的 Linux 内核，那该怎么办呢？类似的问题是：即使网络中心就在我们隔壁，那里头嘈杂的环境确实不应该是人呆的地方，所以还是有必要试图远程更新这台主机上的内核。

也许答案很简单：直接在服务器上安装一个远程 Shell 服务，比如 ssh，在本地登录上去，通过发行版提供的方式或者是自己手动配置和编译一个内核，然后在启动引导管理器 grub 或者 lilo 中修改相关配置，启动新内核就 ok。

如果新编译的内核没有问题，这肯定就是最简单的方式了，但是：如果新编译的内核无法启动，比如 kernel panic，那该怎么办？系统挂在那里，所以这个时候别指望那个 ssh 服务器开着，等你连上解决问题，因为内核都没有起来，这个 ssh 服务就没有办法起来了，这个时候你得给网络中心的老大打个电话或者自己驱车过去跑一趟，而且还得忍受那嘈杂的机房环境，真是够倒霉的 :-(

## 解决办法

不要灰心，也许这个内核的启动参数会有帮助：

    panic=10


上述参数告诉内核，在它出现 panic 的10秒后，自动重启（请参考`man bootparam`）。

如果内核重启解决不了问题呢？你还得重复上面的工作，叫网络中心老大……所以我们还得找其他的解决办法，比如：

在那台服务器之上安装一个虚拟机（比如 Linux+xen, UML, qemu 等，更多请参考[资料][4]），在虚拟机之上再安装提供服务的 Linux 操作系统，因此更新内核的操作可以通过虚拟机来完成了，就不存在重启硬件的问题了。

这个基本上是可以解决问题的，但是如果你嫌弃虚拟机可能带来的效率问题，而不想这么干，那该怎么办呢？

还是有办法，因为有专门的工具来引导 Linux 的启动，所以如果启动失败，启动管理器应该可以作一些力所能及的工作。

[资料][5]提到 grub 0.95 及以后的版本提供了这样的功能：通过一定的配置，可以告诉 grub，如果它引导的内核启动失败，那么可以让它启动其他的内核。

这里头存在两个比较重要的问题，我们需要告诉 grub：

  * 你想启动哪个内核
  * 你想启动的内核启动失败后应该启动哪个内核

它们可以分别通过 default,fallback 在 grub 配置文件(例如 Ubuntu 中 0.97 版的 Grub 的配置文件为 /boot/grub/menu.lst)中指定：

<pre>#
# Sample boot menu configuration file
#

# Boot automatically after 30 secs.
timeout 10

# By default, boot the first entry.
default 0

# Fallback to the second entry.
fallback 1

# For booting GNU (also known as GNU/Hurd)
title  Ubuntu/Hardy
root   (hd0,0)
kernel /boot/vmlinuz-2.6.24-16-generic root=/dev/sda1 ro quiet splash
initrd /boot/initrd.img-2.6.24-16-generic
boot

title  Ubuntu/Hardy (recover mode)
root   (hd0,0)
kernel /boot/vmlinuz-2.6.24-16-generic root=/dev/sda1 ro single
initrd /boot/initrd.img-2.6.24-16-generic
</pre>

default 和 fallback 后面跟上内核入口“编号”，即它们的配置信息在上述配置文件中所处的位置，上面的配置文件通过&#8221;default 0&#8243;把Ubuntu/Hardy 设置为你想启动的内核，通过&#8221;fallback 1&#8243;把 Ubuntu/Hardy (recover mode) 设置为&#8221;你想启动的内核&#8221;启动失败后 grub 自动进入的内核。因此，当无法正常进入 Ubuntu/Hardy 内核时，grub 会自动切换到 Ubuntu/Hardy (recover mode)。

这样的话，只要我们的服务器上有一个能够正常启动的内核，并通过&#8221;fallback 该内核的入口编号&#8221;进行设置，那么我们就可以非常方便地编译新内核，通过&#8221;default 新内核的入口编号&#8221;设置为默认启动的内核（也可以直接通过&#8221;grub-set-deafult 新内核入口编号&#8221;命令来配置），并尝试远程启动进入新内核了。即使新内核启动失败，我们也不用担心系统一直挂在那里，因为 grub 会帮我们启动到正常的内核。

关于重启远程服务器的更多办法，建议阅读一下[资料][5]；关于虚拟机的更多信息，建议阅读[资料][4]；关于 Grub 的详细用法可以参考一下下面的 Grub 相关资料。

## 参考资料

  * [HOWTO Remote Kernel Upgrade][5]

  * [Virtual Machine][4]

  * [Grub Manual][6]

  * [用 kexec 迅速切换内核][2]

  * [Reboot Linux faster using kexec][3]





 [1]: http://tinylab.org
 [2]: http://www.linuxsir.org/bbs/thread335331.html
 [3]: http://www.ibm.com/developerworks/cn/linux/l-kexec/
 [4]: http://en.wikipedia.org/wiki/Virtual_machine
 [5]: http://www.gentoo-wiki.info/HOWTO_Remote_Kernel_Upgrade
 [6]: http://www.gnu.org/software/grub/manual/grub.html
