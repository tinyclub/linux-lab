---
title: 泰晓沙龙 第二期：Linux 虚拟化技术
author: Wu Zhangjin
layout: post
group: activity
album: 泰晓沙龙
permalink: /tiny-salon-phase-ii-virtualization-technology/
tags:
  - Cgroup
  - Docker
  - Namespace
categories:
  - 虚拟化
  - 泰晓沙龙
---

> by [泰晓科技][1]
> [泰晓沙龙第二期][2] @ 2015/04/26


## 活动小结

2015年04月26日2：30～5：30，即上上周末，来自金山、魅族、北理工等公司和高校的 11 号同学如期组织了第二期泰晓沙龙活动。活动地点定在海怡湾畔，珠海地区一个环境优美的小区，这里是泰晓科技的临时活动场所。这次活动的主持人为本站的 [Falcon][3] 同学。

随着 Docker 等各类虚拟化技术的火热，上期沙龙的末尾确定了本期讨论的主题为虚拟化技术。

这次主题预定了四个演示环节，分别是：

  1. Docker 简介
  2. Docker 的基础技术：NameSpace
  3. Docker 的基础技术：Cgroup
  4. Docker 的企业级应用

由于来自 YY 的同学临时有事，第 4 个演示环节未能如期进行，其他三个分别为：

  * [Docker 快速入门：用 Docker + GitBook 写书][4]
  * [An Intro to Linux Kernel NS (NameSpace)][5]

  * [Cgroup on Phone][6]

本次沙龙从用 Docker 构建 GitBook 写作环境开始，结合当前最火热的 Markdown 开源书籍创作环境 GitBook 对 Docker 的基本用法做了简单介绍。转而深入底层技术 Cgroup 与 Namespace，最后讨论了不同虚拟化技术的区别和应用场景。现场交流顺畅，气氛热烈。

通过本次沙龙活动，大家对各类 Linux 虚拟化技术有了初步的认识，也通过这次交流加强了企业间、校企间和不同开放团队间的互动。

本次活动有来自珠海 Google GDG 的同学，他们希望加强 GDG 和 [泰晓][1] 之间的合作，期望后续可以一起举办一些活动。也有来自北理工的同学，他们期望通过这个平台找到一些合适的实习机会。

而来自不同企业的同学则非常感兴趣这些虚拟化技术到底在各自企业的应用情况如何？有的企业有用 Docker 来部署游戏引擎的后台服务器，有的已经在部署一些开发和测试环境，也有类似这次演示的 Docker + GitBook 书籍创作环境。更多的其他虚拟化技术的应用很广泛，比如说 qemu-user-static，有用来作为汇编语言实验环境，而 XtratuM 则有用在工控领域，而 OpenStack / Hadoop / Spark 等则用在云计算和大数据等领域。

## 相关资料

由于时间有限，很难在这么短的时间内深入地讨论完这么一个宏大的题目，所以沙龙活动之后本站收集了一些数据用作更多的线上讨论。

### 推荐书籍

  * [虚拟化与云计算][7]

    7.0 (164评价) 《虚拟化与云计算》小组 / 电子工业出版社 / 2009

    本书系统阐述了当今信息产业界最受关注的两项新技术——虚拟化与云计算。云计算的目标是将各种IT资源以服务的方式通过互 联网交付给用户。计算资源、存储资源、软件开发&#8230;

  * [系统虚拟化][8]

    7.6 (60评价) Intel corporatio / 清华大学出版社 / 2009

    系统虚拟化：原理与实现，ISBN：9787302193722，作者：英特尔开源软件技术中心，复旦大学并行处理研究所 著

  * [KVM 虚拟化技术][9]

    6.5 (23评价) 任永杰 / 机械工业出版社 / 2013

    首本Linux KVM虚拟化技术专著，由Intel虚拟化技术部门资深虚拟化技术专家和国内KVM技术的先驱者撰写，权威性毋庸置疑>。在具体内容上，本书不仅系统介绍了KVM虚拟机的功&#8230;

  * [Xen 虚拟化技术][10]

    6.6 (28评价) 石磊 / 华中科技大学出版社 / 2009

    《Xen虚拟化技术》主要讲述了：目前，无论是学术界还是工业界，虚拟化技术的研究和应用都是热点。在不断涌现出的虚拟>化解决方案中，开源解决方案Xen以其独特的虚拟化设&#8230;

    更多：[豆瓣书籍频道][11]

### 在线资料

  * 虚拟化技术综述

      * [理解全虚拟、半虚拟以及硬件辅助的虚拟化][12]
      * [虚拟技术综述][13]
      * [桌面虚拟化技术综述][14]
      * [桌面虚拟化技术发展综述][15]
      * [服务器虚拟化技术综述][16]
      * [虚拟化技术概览][17]
      * [虚拟化技术大观][18]
      * [Linux 虚拟化技术方案比较][19]
      * [Wiki百科 虚拟化][20]
      * [Linux 虚拟化技术][21]
      * [虚拟化安全综述][22]

  * 虚拟化技术原理与实现

      * [如何实现自己的linux container？][23]
      * [Docker基础技术：Linux CGroup][24]
      * [Namespace Part1][25]
      * [Namespace Part2][26]
      * [Introduction to Linux namespaces][27]
      * [Virtio：针对 Linux 的 I/O 虚拟化框架][28]
      * [虚拟化的理论-内存和IO虚拟化][29]
      * [让KVM飞——初识][30]
      * [KVM虚拟机管理配置——libvirt][31]
      * [KVM，QEMU，libvirt入门学习笔记 ][32]
      * [【Docker技术入门与实战】虚拟化与Docker ][33]
      * [利用Docker构建开发环境][34]
      * [docker详细的基础用法][35]
      * [淺談 Linux Container (aka lxc)][36]
      * [对比Hadoop Spark受多方追捧的原因][37]
      * [Spark和Hadoop作业之间的区别][38]
      * [技术小白：Hadoop 到底是啥？][39]
      * [OpenStack][40]
      * [openstack 和hadoop的区别是什么？ ][41]
      * [基于openstack上的hadoop平台搭建][42]
      * [OpenStack、Xen、lxc 、kvm、qemu与Hadoop（Yarn）,Mesos 与Spark，Hadoop][43]
      * [如何使用OpenStack、Docker和Spark打造一个云服务][44]
      * [用Docker之后还需要OpenStack吗？][45]

  * 其他

      * [云上的虚拟计算推动了节能技术][46]
      * [5分钟在超能云（SuperVessel）上免费创建属于自己的大数据环境][47]

## 活动缩影

下面是本次活动的一些照片记录：

  1. Falcon 演示 Docker 基本用法

![Presentation about Docker + GitBook][48]

  2. 平波 介绍 NameSpace

![Pingbo][49] ![Mount NameSpace][50]

  3. 文军 介绍 Cgroup

![WenJun][51] ![VM v.s. Container][52]

  4. Falcon 主持讨论各种虚拟化技术以及它们的应用场景

![VM discussion][53]





 [1]: http://tinylab.org
 [2]: /tinysalon/
 [3]: /author/falcon/
 [4]: /docker-quick-start-docker-gitbook-writing-a-book/
 [5]: http://share.csdn.net/slides/14643
 [6]: http://share.csdn.net/slides/14644
 [7]: http://book.douban.com/subject/4114150/
 [8]: http://book.douban.com/subject/3619896/
 [9]: http://book.douban.com/subject/25743939/
 [10]: http://book.douban.com/subject/3768550/
 [11]: http://book.douban.com/subject_search?search_text=%E8%99%9A%E6%8B%9F%E5%8C%96&cat=1001
 [12]: http://blog.csdn.net/flyforfreedom2008/article/details/45113635
 [13]: http://www.dlf.net.cn/manager/manage/photo/admin2009724104552%CA%F6.pdf
 [14]: http://datoucan.blog.51cto.com/656829/284629
 [15]: http://articles.e-works.net.cn/It_overview/article109377.htm
 [16]: http://wenku.baidu.com/view/f653d888a0116c175f0e488b.html
 [17]: http://www.open-open.com/lib/view/open1390723158367.html
 [18]: https://ring0.me/2014/12/virtualization-overview/
 [19]: http://yp.oss.org.cn/blog/show_resource.php?resource_id=331
 [20]: http://zh.wikipedia.org/wiki/%E8%99%9B%E6%93%AC%E5%8C%96
 [21]: https://www.ibm.com/developerworks/cn/linux/theme/virtualization/
 [22]: http://www.searchsecurity.com.cn/guide/virtualizationsec.htm
 [23]: http://weibo.com/p/1001603824282965777334
 [24]: http://coolshell.cn/articles/17049.html
 [25]: http://coolshell.cn/articles/17010.html
 [26]: http://coolshell.cn/articles/17029.html
 [27]: https://blog.jtlebi.fr/2013/12/22/introduction-to-linux-namespaces-part-1-uts/
 [28]: http://blog.chinaunix.net/uid-29056899-id-4395232.html
 [29]: http://forlinux.blog.51cto.com/8001278/1408853/
 [30]: http://bbs.linuxtone.org/thread-24347-1-1.html
 [31]: http://www.iyunv.com/thread-42981-1-1.html
 [32]: http://blog.csdn.net/julykobe/article/details/27571387
 [33]: http://dockerone.com/article/74
 [34]: http://tech.uc.cn/?p=2726
 [35]: http://www.open-open.com/lib/view/open1410568733492.html
 [36]: https://fourdollars.hackpad.com/ep/pad/static/rZ8cgA4Y8Kf
 [37]: http://cloud.yesky.com/301/35894301.shtml
 [38]: http://zhidao.baidu.com/question/1703470834520525580.html?qbl=relate_question_4&word=openstack%20spark%20hadoop
 [39]: http://os.51cto.com/art/201305/396145.htm
 [40]: http://baike.baidu.com/link?url=e6LQfFrO-BMna0OW1sZMt_m3c5QodbpfAJeX0bYf6C1sk9ecqdjNiRjQ6EEimnsGs-N8iwPY4QCgvVA_mcTqX_
 [41]: http://www.zhihu.com/question/20475470
 [42]: http://blog.itpub.net/21937342/viewspace-1120289/
 [43]: http://m.blog.csdn.net/blog/shenlin2011/24668979
 [44]: http://www.csdn.net/article/2015-03-31/2824362
 [45]: http://www.csdn.net/article/2014-12-15/2823129
 [46]: http://www.intel.com/content/dam/www/public/cn/zh/pdfs/teamsun-casestudy-cn.pdf
 [47]: http://my.oschina.net/u/1431433/blog/384964
 [48]: /wp-content/uploads/2015/06/salon/005wLCQdjw1erk2tx5s3ij30p018gtbd.jpg
 [49]: /wp-content/uploads/2015/06/salon/005wLCQdjw1erk2u4tyttj318g0wwdow.jpg
 [50]: /wp-content/uploads/2015/06/salon/005wLCQdjw1erk2u6k3bnj316616idn7.jpg
 [51]: /wp-content/uploads/2015/06/salon/005wLCQdjw1erk2u1s61gj318g0wwwjy.jpg
 [52]: /wp-content/uploads/2015/06/salon/005wLCQdjw1erk2u2ztqsj318g0wwgqt.jpg
 [53]: /wp-content/uploads/2015/06/salon/005wLCQdjw1erk2tytnhwj318g0wwk0b.jpg
