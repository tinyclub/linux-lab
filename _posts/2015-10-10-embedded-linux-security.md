---
layout: post
author: 'Wu Zhangjin'
title: "嵌入式 Linux 系统安全"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-security/
description: "介绍了嵌入式 Linux 有关的安全方面的技术"
category:
  - 系统安全
  - 安全管理
tags:
  - Security
  - Linux
---

> By Falcon of TinyLab.org
> 2015-10-10

> 书籍：[嵌入式 Linux 知识库](http://tinylab.gitbooks.io/elinux)
> 原文：[eLinux.org](http://eLinux.org/Security)
> 翻译：[@lzz5235](https://github.com/lzz5235)
> 校订：[@lzufalcon](https://github.com/lzufalcon)


## 简介

本文主要包含与嵌入式 Linux 有关的安全方面的技术。

## 技术/项目主页

-   [硬件安全](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/Security_Hardware_Resources/Security_Hardware_Resources.html "Security Hardware Resources")
-   [引导程序安全](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/Bootloader_Security_Resources/Bootloader_Security_Resources.html "Bootloader Security Resources")
-   [强制访问控制方案比较](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/Mandatory_Access_Control_Comparison/Mandatory_Access_Control_Comparison.html "Mandatory Access Control Comparison")

## Linux Kernel 中的安全子系统

### SELinux

-   [SELinux](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/SELinux/SELinux.html "SELinux") - 这个组件主要用来实现一种 Linux 安全架构：[FLASK（The Flux Advanced Security Kernel）](http://www.cs.utah.edu/flux/fluke/html/flask.html)。
    SELinux 主要起始于 NSA 在 2001 年内核峰会上演示给内核开发人员的一个内核补丁，来自这次报告的反馈促成了 LSM 这个项目。SELinux 项目已经帮助内核定义了大部分的 LSM 接口。
    -   OLS 2008 paper: [消费电子设备下的 SELinux](http://eLinux.org/images/8/88/Nakamura-reprint.pdf "Nakamura-reprint.pdf")
        Nakamura & Sameshima, 日立软件工程师.
    -   ELC 2008 presentation: [嵌入式 SELinux](http://eLinux.org/images/a/a3/ELC2008_nakamura.pdf "ELC2008 nakamura.pdf")

### Tomoyo

-   [TOMOYO Linux](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/TomoyoLinux/TomoyoLinux.md "TomoyoLinux") 主要用来提升 Linux 自身的安全性，这个特性最初由[ NTT DATA CORPORATION, Japan](http://www.nttdata.co.jp/en/index.html)开发。 [TOMOYO Linux](../.././dev_portals/Security/TomoyoLinux/TomoyoLinux.md "TomoyoLinux") 是在 2005 年 11 月 11 日，以 GPL 许可证的形式开源的。 [TOMOYO Linux](../.././dev_portals/Security/TomoyoLinux/TomoyoLinux.html "TomoyoLinux") 是一种可以被称为安全操作系统的机制，与 SELinux 非常类似，这个机制可以把各类访问权限化整为零，从而做到更加细粒度的访问控制。
    -   [ELC 2007 presentation](http://eLinux.org/images/b/b5/Elc2007-presentation-20070418-for_linux.pdf "Elc2007-presentation-20070418-for linux.pdf")
    -   [OLS 2007 BoF slides](http://eLinux.org/images/e/eb/Ols2007-tomoyo-20070629.pdf "Ols2007-tomoyo-20070629.pdf")

Tomoyo 在 2.6.28 时被合并到 Linux 内核主线中。

### SMACK

-   SMACK - 即 Simple Mandatory Access Control Kernel （简单强制访问控制内核），这是一个非常轻量级的 Linux 内核 MAC 实现。
    -   官方主页 (非常简单):
        [http://schaufler-ca.com/](http://schaufler-ca.com/)
    -   LWN.net 文章:
        [http://lwn.net/Articles/244531/](http://lwn.net/Articles/244531/)
    -   CELF-commissioned 白皮书: [SMACK for Digital
        TV](http://www.embeddedalley.com/pdfs/Smack_for_DigitalTV.pdf)
        by Embedded Alley (now Mentor Graphics)

SMACK 在 2.6.25 时被合并到 Linux 内核主线中。

## 陈旧的信息 ( 2005 年，CELF 调查的相关信息)

### 文档

-   CELF 1.0 安全规范: [安全规范\_R2](http://www.celinuxforum.org/CelfPubWiki/SecuritySpec_R2)

### 关键需求与相关技术点

下面是与安全相关的技术点，这些会在后面的表格中引用到。

1.  Umbrella
2.  Linux Security Module (LSM) framework
3.  PAX patch – ( x86 架构独有)
4.  LOMAC
5.  LIDS
6.  Netfilter
7.  digsig/bsign/elfsig
8.  可信计算机集群 (TCG)
9.  TPE (包括 LIDS )
10. PRAMFS
11. ACL 文件系统拓展
12. Posix 中与文件相关的功能

<table>
<thead>
<tr class="header">
<th align="left">需求</th>
<th align="left">相关技术</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left">可靠性</td>
<td align="left">10</td>
</tr>
<tr class="even">
<td align="left">安全/信任的引导</td>
<td align="left">8</td>
</tr>
<tr class="odd">
<td align="left">访问控制</td>
<td align="left">1, 4, 5, 11, 12</td>
</tr>
<tr class="even">
<td align="left">缓冲区/栈的保护</td>
<td align="left">3</td>
</tr>
<tr class="odd">
<td align="left">入侵检测</td>
<td align="left">5, 8</td>
</tr>
<tr class="even">
<td align="left">可配置的安全选项</td>
<td align="left">1, 2, 4, 5, 7, 9(?), 11, 12</td>
</tr>
<tr class="odd">
<td align="left">用户认证</td>
<td align="left">1, 7</td>
</tr>
<tr class="even">
<td align="left">Signed binaries</td>
<td align="left">1, 7</td>
</tr>
<tr class="odd">
<td align="left">可靠的连接</td>
<td align="left">IPSec, SSL already supported</td>
</tr>
<tr class="even">
<td align="left">安全服务</td>
<td align="left">1, 4, 5, 7, 8</td>
</tr>
<tr class="odd">
<td align="left">防火墙</td>
<td align="left">6</td>
</tr>
<tr class="even">
<td align="left">用于支持安全硬件的 API</td>
<td align="left">8</td>
</tr>
<tr class="odd">
<td align="left">安全固件的可升级性</td>
<td align="left">9</td>
</tr>
<tr class="even">
<td align="left">认证</td>
<td align="left">8</td>
</tr>
</tbody>
</table>

对于清单中的相关技术，CELF 安全组织正在研究或者已经支持以下的技术：

-   Umbrella
-   PAX - 目前仅仅是监控（monitor）
-   LIDS
-   Signed Binaries
    -   Dig Sig（DSI 项目的一部分：[http://disec.sourceforge.net/](http://disec.sourceforge.net/)）
    -   Bsign（一个 Debian 项目：[http://packages.debian.org/squeeze/bsign](http://packages.debian.org/squeeze/bsign)）
    -   [ELFSign](http://www.hick.org/code/skape/papers/elfsign.txt)
-   Linux API for TCG - 仍然处在 NPO 状态，并进行讨论
-   TPE - LIDS 的一部分
-   ACL 文件拓展 - 为 CELF 所需（PRAMFS，JFFS2）。也关注 LKLM 讨论，然后进行实现
-   POSIX 中与文件相关的功能

### 资源

#### 安全框架

-   [The Linux Security Modules (LSM)](http://lsm.immunix.org) 项目提供一个轻量级而且通用的访问权限控制框架。
    当前的计算环境变得越来越不利，往内核中导入增强的访问控制模型改善了主机安全性也能帮助服务器免于被恶意攻击。
    安全研究已经提供了许多不同类型的权限访问控制，它们针对不同类型的操作环境有效。而 LSM 框架允许权限访问控制被实现为可加载的内核模块。

-   [Medusa DS9 Security Project](http://medusa.terminus.sk/) 是另外一个提高 Linux 内核安全性的项目，它实现了 ZP 安全框架。
    该项目目标就是实现一个安全框架，该框架可用于实现任意安全模型（不同于其他安全 Linux 内核项目）。

Medusa DS9 主要用来提高 Linux 的安全性，它由两部分组成：Linux 内核变更和用户空间守护进程。
内核变更主要来监控系统调用、文件系统动作和进程，它们实现了通信协议部分。而安全守护进程通过字符设备收发
数据包来与内核进行通讯。守护进程包含了整个业务逻辑并实现了具体的安全策略，这就意味着 Medusa 可以实现任何类型的
数据保护模型；而它仅仅有赖于配置文件，该配置文件实际上是用内置编程语言写的一个程序，该语言非常类似于 C 。

-   [Rule Set Based Access Control (RSBAC)](http://www.rsbac.org) 是当今 Linux 内核中一个灵活、强大与快速的开源访问控制框架，
    从 2000 年 1 月开始，就已经实现产品级稳定使用。所有开发独立于政府与大企业并且没有重用任何其他访问控制代码。

标准的安装包包括一系列的访问控制模块，比如 MAC、RC、ACL 等，而且运行时注册机制（Runtime Registration Facility, REG）使得我们更加容易
以内核模块的方式实现自己的访问控制模型，并且将它在运行时注册就可以了。

RSBAC 框架建立在通用权限访问控制框架 (GFAC) 之上，该框架是由 Abrams 与 La Padula 设计。
所有安全相关系统调用都由安全实施代码拓展，这种代码调用中央决策组件，进而调用所有的主动决策模块并产生一组决策。
这些决策最终由系统调用扩展来实施。

决策建立在几个方面之上，包括访问请求类型、访问目标和附着于主题呼叫（The Subject Calling）和访问目标之上的属性值。
另外，独立属性被运用在独立的模块中，比如：the privacy module (PM) 。所有的属性被存储在受保护的文件夹内，一个文件夹
对应一个挂载设备，因此改变这些属性需要提供特殊的系统调用。

-   [TrustedBSD MAC 框架](http://www.trustedbsd.org/mac.html) -
    强制访问控制拓展了任意访问控制，它允许管理员为系统中所有主体（例如进程和套接字）和对象（如套接字、文件系统对象以及 sysctl 节点）实施额外的安全加固。
    该框架的灵活性为新的访问控制模型的开发提供了极大便利。该框架也允许新的访问控制模型作为内核模块载入。

-   [可信计算集群 (TCG)](https://www.trustedcomputinggroup.org/) - TCG 定义了一种基于硬件的安全架构
    （硬件为 Trust 的根基），这是在多种平台创建可信计算的一种经济有效的方案。更多的介绍信息请查看 Seiji
    Munetoh 与 Nicholas Szeto 的演示, TCGOverviewPDF, 这个演示是在
     [Tech Conference 2005 Docs](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/Tech_Conference_2005Docs/Tech_Conference_2005Docs.html "Tech Conference 2005Docs")
    页面上。可信平台模块（[TPM](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/Security_Hardware_Resources/Security_Hardware_Resources.html)）是绑定到平台的安全芯片和该架构的关键组件。
    TCG 拥有一个移动电话工作组，该工作组发布了一个用户用例文档，该文档可应用于许多通用消费电子设备（包括移动电话）-- [MPWG User Cases](https://www.trustedcomputinggroup.org/groups/mobile/MPWG_Use_Cases.pdf)

#### 安全组件

-   [SELinux](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/SELinux/SELinux.html "SELinux") - 主要实现了 [FLASK](http://www.cs.utah.edu/flux/fluke/html/flask.html) 安全架构。
    SELinux 主要起始于 NSA 在 2001 年内核峰会期间演示给内核开发者的一个内核补丁，来自该报告的反馈促成了 LSM 项目。
    SELinux 项目已经定义了大量的 LSM 接口。

-   [Apparmor](http://en.opensuse.org/Apparmor) - Apparmor 是一个应用安全工具，主要是针对应用程序设计的一个简单易用的安全框架。

-   [Linux 入侵防护系统 (LIDS)](http://www.lids.org/) 由一个内核补丁和一套管理工具组成，它通过实现 MAC 增加了内核的安全性。
    当它生效时，文件访问，所有系统网络管理操作，任意权能使用，裸设备、内存和 I/O 访问都能被选择性地禁用（即使针对 Root）。
    我们可以配置只允许特定的应用程序访问某些特定文件。它使用和扩展系统能力边界集来控制整个系统，并且为了增强安全性，它为
    内核增加了一些网络和文件系统安全特性。我们能够细粒度地在线微调安全保护，隐藏敏感的进程，通过网络接收安全警报，等等。
    LIDS 有两个版本，1.2 和 2.2。LIDS 2.2 支持 2.6 内核，LIDS 1.2 支持 2.4 内核，并且它提供了新的功能，可信路径执行（Trusted PATH Execution，TPE）
    和可信域实施（Trusted Domain Enforcement，TDE）。这些对于创建沙盒非常有用。LIDS 以 GPL 方式发布。

-   [TOMOYO Linux](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/TomoyoLinux/TomoyoLinux.html "TomoyoLinux") 主要用来提高 Linux 自身的安全性，
    该特性最初由 [NTT DATA CORPORATION, Japan](http://www.nttdata.co.jp/en/index.html) 开发。
    [TOMOYO Linux](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/TomoyoLinux/TomoyoLinux.html "TomoyoLinux") 是在 2005 年 11 月 11 日，
    以 GPL 许可证的形式开源的。[TOMOYO Linux](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/TomoyoLinux/TomoyoLinux.html "TomoyoLinux") 是一个被称为安全操作系统的机制，
    它与 SELinux 非常类似，通过把现有的访问权限化整为零，从而可以做到更细粒度的访问控制。
    -   [ELC2007 presentation](http://sourceforge.jp/projects/tomoyo/document/elc2007-presentation-20070418-for_linux.pdf/en/4/elc2007-presentation-20070418-for_linux.pdf)
    -   [OLS2007 BoF slides](http://sourceforge.jp/projects/tomoyo/document/ols2007-tomoyo-20070629.pdf/en/4/ols2007-tomoyo-20070629.pdf)
    -   [CELF Wiki](http://tree.celinuxforum.org/CelfPubWiki/TomoyoLinux)

Tomoyo 在 2.6.28 时被合并到 Linux 内核 主线中。

-   SMACK - 即 Simple Mandatory Access Control Kernel，是 Linux 内核 MAC 的一种轻量级实现。
    -   官方主页 (非常简单):
        [http://schaufler-ca.com/](http://schaufler-ca.com/)
    -   LWN.net 文章:
        [http://lwn.net/Articles/244531/](http://lwn.net/Articles/244531/)
    -   CELF-commissioned 白皮书: [SMACK for Digital
        TV](http://www.embeddedalley.com/pdfs/Smack_for_DigitalTV.pdf)
        by Embedded Alley (now Mentor Graphics)

SMACK 在 2.6.25 时被合并到 Linux 内核主线中。

-   [Umbrella](http://sourceforge.net/projects/umbrella)
    基于 Linux 安全模块框架，为手持设备实现了基于进程的 MAC 与文件认证的功能组合。
    其中 MAC 方案由每个进程的一系列限制来实施。
    -   针对资源的限制
    -   针对访问网络接口的限制
    -   针对进程创建与信号处理的限制
    -   文件签名

-   [LOMAC](http://opensource.nailabs.com/lomac/) 是面向 UNIX 内核的一种可动态加载的安全模块，
    其中它使用了 Low Water-Mark 的 MAC，用于保护进程和数据的完整性，免于受病毒、特洛伊木马和
    远程恶意用户以及缺乏免疫力（易被入侵）的网络服务守护进程的破坏。LOMAC 设计的目标就是兼容性与易用性，
    这也是典型用户能够接受的一种 MAC 实现方式。


LOMAC 致力于创建典型用户可接受的一种 MAC 完整性保护方式。LOMAC 实现了一种简单的 MAC 完整性保护方式，
它基于 Biba 的 Low Water-Mark 模型并且被实现为了一个可加载的内核模块（LSM）。它可提供有效的完整性保护，
从而免受病毒、特洛伊木马、远程恶意用户和被成功入侵的网络服务器的损害，并且它无须修改内核、应用或者他们已有的配置。
LOMAC 设计的目标就是易用性，它默认的配置主要用来提供有效的保护，避免为特定的用户、服务器和系统中的其他软件做专门的调整。
LOMAC 可以在系统启动以后通过简单地加载内核模块来加固当前部署的系统。

-   [The Enforcer](http://sourceforge.net/projects/enforcer/) 是一个 Linux 安全模块，
    它通过保证文件系统不被恶意篡改，从而提高运行有 Linux 的计算机的完整性。它能通过与 TCPA 硬件进行交互
    来提供更高级别的针对软件与敏感数据的防护。

-   [Janus](http://www.cs.berkeley.edu/~daw/janus) 是一个安全工具，用于把不受信的应用关在一个受限的
    安全环境（即所谓沙盒）中，它可用于限制被成功入侵的应用造成的危害。在一个受限的沙盒环境中，无须干扰应用的行为，
    我们已经成功地运用 Janus 来 “监禁”（Jail）了 Apache，bind 和其他程序。而且我们还在继续寻求在实际产品环境中实验该方案。

-   [Domain and Type Enforcement(DTE) ](http://www.cs.wm.edu/~hallyn/dte/) 是一个 MAC 系统，
    可以赋予不同文件不同类型，赋予不同进程不同域。来自域间和域到文件的访问都依据 DTE 策略实施。
    该项目的首次实现紧紧贴合来自名为《A Domain and Type Enforcement Prototype and
    Confining Root Programs with Domain and Type Enforcement》的论文的 TIS 描述。

-   [实时 Linux 安全模块(LSM)](http://sourceforge.net/projects/realtime-lsm/)
    是 Linux 2.6 内核中可加载的拓展，它可以选择性地赋予实时权限给特定的用户组和应用。

-   [Linux 内核 ACL 支持](http://sourceforge.net/projects/linux-acl/) - 该 Linux 内核补丁和用户代码组合允许支持 Linux 内核 ACLS。

-   [http://www.hu.grsecurity.net/
    grsecurity](http://grsecurity.urc.bl.ac.yu/) (镜像原始站点在[这里](http://www.grsecurity.net/)) - 这是一种创新的方式，能安全利用多层次的监测、防护和容器模型。
    该项目以 GPL 方式发布。

此外提供了大量其他的特性：

-   一种智能又健壮的基于角色的访问控制系统（RBAC），它可以不经配置为整个系统产生最少的权限策略。
-   chroot 加固
-   避免 /tmp 竞争条件
-   广泛审计
-   预防与地址空间错误有关的所有类型漏洞利用（来自于 Pax 项目）
-   针对 TCP/IP 栈追加的的随机性
-   限制当前用户只能查看自身的进程
-   每个安全警报或者是安全审计包含每个引起该错误事件用户的 IP 地址

#### 安全特性

-   NX 补丁 - 最近提交到主线的补丁，用来阻止执行栈段的恶意代码 [ LKML 上关于 NX 补丁的讨论](http://groups.google.com/groups?hl=en&lr=&ie=UTF-8&threadm=232Xj-3bC-13%40gated-at.bofh.it&rnum=1&prev=/groups%3Fq%3DNX%2Bsecurity%2Blkml%26hl%3Den%26lr%3D%26ie%3DUTF-8%26selm%3D232Xj-3bC-13%2540gated-at.bofh.it%26rnum%3D1)

#### 其他资源

-   启动设备的安全性
    -   [安全硬件相关资源](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/Security_Hardware_Resources/Security_Hardware_Resources.html "Security Hardware Resources")
    -   Bootloader 安全相关的资源 -- [Bootloader 安全相关的资源](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Security/Bootloader_Security_Resources/Bootloader_Security_Resources.html "Bootloader Security Resources")

##### 安全活动

-   [可信计算小组](https://www.trustedcomputinggroup.org/)
-   [Linux 安全模块](http://lsm.immunix.org)

##### 邮件列表

-   [Linux 安全模块（LSM）邮件列表](http://vger.kernel.org/vger-lists.html#linux-security-module)

##### 会议

-   Linux Conf Au [Linux Security 2009 (miniconf)](http://linux.conf.au/schedule/32/view_miniconf?day=tuesday)
    - January 21, 2009
-   Usenix Security Symposium July 31 - August 4, 2006
    -   [proceedings](http://www.usenix.org/events/sec06/tech/)
-   Ottawa Linux Symposium (OLS) July 19 - 22, 2006
    [http://www.linuxsymposium.org/2006](http://www.linuxsymposium.org/2006)
    -   [OLS Proceedings](http://www.linuxsymposium.org/2006/proceedings.php)

##### 安全相关的文章

-   [TOMOYO Linux 和基于路径名的安全](http://lwn.net/Articles/277833/) [LWN.net] Apr 2008
-   [The Linux Journal Aug 2003](http://www.linuxjournal.com/article.php?sid=6633)
-   [ARM 上针对安全的 Trust Zone](http://www.arm.com/miscPDFs/4136.pdf)
-   [基于 TPM 的 Linux 运行时认证](http://domino.research.ibm.com/comm/research_projects.nsf/pages/ssd_ima.index.html)

##### 论文

-   [用 TCPA/TCG 硬件做实验](http://www.cs.dartmouth.edu/~sws/pubs/TR2003-476.pdf)
-   [用来阻止动态缓冲区溢出的开放工具对比](http://www.ida.liu.se/~johwi/research_publications/paper_ndss2003_john_wilander.pdf)
-   [SMACK for Digital
    TV](http://www.embeddedalley.com/pdfs/Smack_for_DigitalTV.pdf)

##### 实例和开源代码

-   Redhat 8 上的 [GPL TCPA Linux 驱动实例](http://www.research.ibm.com/gsal/tcpa/)
-   [Linux TPM 设备驱动](http://sourceforge.net/projects/tpmdd)
-   [TCG 软件栈 (TSS) for Linux](http://sourceforge.net/projects/trousers)
-   一些有用的链接和 NetBSD 驱动可以在 Rick Wash 的[可信计算](http://www.citi.umich.edu/u/rwash/projects/trusted) 主页中看到。


[目录](http://eLinux.org/Special:Categories "Special:Categories"):

-   [安全](http://eLinux.org/Category:Security "Category:Security")
