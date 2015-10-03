---
title: 'Git 用法详解'
author: Wu Zhangjin
layout: post
permalink: /git-usage-hello-the-git-world/
tags:
  - Git用法详解
  - Lemote
  - Loongson Debian
categories:
  - Git
---

> by falcon of TinyLab.org
> 2013/06/01 16:58

2011 年下，在即将离开北京去珠海工作的时候，好友 [Longson Debian](http://www.bjlx.org.cn/) 的维护者 世伟 兄邀请我到他们公司分享 Git 的用法。

大概花了一个礼拜左右的时间细心地整理和总结几年来使用 GIT 的点滴积累，然后在一个阳光明媚的下午去他们位于中关村的办公楼里一起交流。

好像听众只有两个，不过氛围得以足够轻松，是纯粹技术性的交流，现场还开了终端演示，而且世伟兄还录了像，不知当时的录像记录是否还在？

印象中，我们还探讨了 CVS 和 GIT 各自的优势，世伟兄提到的 CVS 因为小巧和 C/S 的结构特别适合小型嵌入式系统中的在线代码实时维护，这个观点让我惊诧不已：GIT 确实非常适合常规的开发，非常强大，不过诸如存储空间非常受限的嵌入式系统中的代码即时修改和管理，CVS 却还有如此的生命力和竞争力。

早在 2009 年于 [Lemote](http://www.lemote.com/) 实习的时候了，就有结识世伟兄，在我的印象当中，他是 Loongson 社区很早的支持者，是北京 龙芯&Debian 用户俱乐部的创始人，多年以来，一直维护龙芯上的 Debian。如果没有记错的话，他维护的 Debian 应该是龙芯上最容易上手，最稳定好用的 Linux 发行版了，我抽屉里采用龙芯 2F 处理器的 [逸珑8101迷你笔记本](http://www.lemote.com/products/computer/yilong/) 至今还安装着他维护的 Debian。

大概在 2009 年中下，我开始不停地往社区提交龙芯 2F 序列的 Linux 补丁，后来基本的支持添加到 Linux 主线以后，为了持续后续的维护，我发起了一个 [Linux/Loongson Community](/linux-loongson-community) 项目。随着该项目维护的龙芯 Linux 的不断成熟，世伟兄维护的 Loongson Debian 发行版逐渐开始直接使用该项目维护的 Linux 版本，并且经常会提交一些 Patch，积极参与 [Loogson Linux Developer Google Group](http://groups.google.com/group/loongson-dev) 的讨论，所以，渐渐地，就非常熟悉了。不过，第一次见面却是在 2010 年到北京工作以后，这次 GIT 的分享应该大概是第三次见面吧。

好了，回归正题。这个幻灯后来几经修改和完善，有应深圳两个同学的邀请，去他们的公司做过分享，也有在公司内部做过交流，现在发出来分享给大家。

我想，GIT 如今如此流行，无处不在，真地应该感谢 Linus 大神当年的努力以及后续维护人员的深耕。GIT 的功能无法一一罗列，所以，幻灯只是选取了最常用的一些内容做了介绍。如果有其他 GIT 方面的问题，欢迎直接回复进行交流。

下载该幻灯片，请点击：[hello-the-git-world.pdf](/wp-content/uploads/2013/05/hello-the-git-world.pdf)。
