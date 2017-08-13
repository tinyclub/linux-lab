---
layout: post
draft: false
author: 'Wu Zhangjin'
title: "《奔跑吧Linux内核》上市在即，抢鲜用Linux Lab做实验"
permalink: /learning-rlk4.0-in-linux-lab/
description: "《奔跑吧 Linux 内核》是全球首本Linux 4.x内核分析书籍，本文介绍如何通过Linux Lab来做书中的实验。"
category:
  - Linux 内核
  - Linux Lab
tags:
  - 奔跑吧Linux内核
---

> By Falcon of [TinyLab.org][1]
> 2017-08-14 23:42:48

盼望着，盼望着，《奔跑吧 Linux 内核》终于如期付梓，预计在 8 月 22 日上市，几大知名图书站点都可以[预订](http://www.epubit.com.cn/book/details/4835)了。

[![RLK4.0 Book](/wp-content/uploads/2017/08/rlk4.0.jpg)](http://www.epubit.com.cn/book/details/4835)

## 作者 Figo

首先，恭喜 Figo.Zhang，这样一本几百页的 IT 巨著着实是非常考验体力、智力和能力的。

笔者自己曾经编写过一本[几十页的小册子](http://www.packtpub.com/optimizing-embedded-systems-using-busybox/book)，都累到满脸痘痘，心力交瘁。而这样一本几百页的图书更是如此。IT 图书有个区别于其他图书的地方是，里头涉及到大量的实操性内容，必须是可重复的，就单纯这一项的反复校订就是巨大的工程。更何况，这些工作都是在兼职的情况下完成的。

另外，关于 Linux 内核的书在市面上其实有不少，如果要撰写一本全新的书，如何编排、如何挑选内容、甚至如何推广都是非常考验智力的。

而在做好初步准备以后，如何落地，如何运筹帷幄，如果掷地有声都是非常考验经验和技能的，需要对知识了如指掌，又或者信手拈来。这与 Figo 在业界十多年的深耕分不开，目前 Figo 就职于 Intel，长期的 FAE 经历和善于思考和总结的习惯为本书积攒了大量的知识和技能筹备。在工作之余，他还有诸多开源贡献，例如 [UKSM](http://kerneldedup.org/projects/uksm/)，这些都为本书的出版冥冥中做了很多铺垫。

另外一方面，Figo 还表现出了营销的天赋，他亲自运营微信公众号，建立微信推广群，参加 Linux 大会，撰写各类幽默风趣的文章，推广得非常成功。

就是这样一个聪慧、敏捷、经验老到的实力派 Linux 玩家，他却谦称 “笨叔叔”；就是这样一个专业技能爆表的同学，他却一直践行“奔叔叔”，在学习和健身的路上一直奔跑。所以，Figo 就是这样一个榜样。

## 奔跑吧 Linux 内核

接下来，我们来看看这本书的编排：

* 处理器体系结构
* 内存管理
* 进程管理
* 并发与同步
* 中断管理
* 内核调试

相比于传统的内核书籍，该书做了很好的内容挑选，这些内容的实用性很高，很贴合工作实战，也是 Figo 十多年内核与驱动工作经验的心得与分享。

另外，本书显著的特点还有：

* 基于 ARM32/ARM64 体系架构
* 基于 Linux 4.x 内核和 Android 7.x
* 以实际问题为导向，给读者提供一个以解决实际问题为引导的阅读方式
* 内容详实，讲解深入透彻，反映内核社区技术发展，比如 EAS调度器、MCS锁、QSpinlock、DirtyCOW

作为一个安卓手机系统研发的从业者，这本书犹如及时雨，从 ARM64 处理器架构、内核版本 4.0 到为节能引入的 [EAS 调度](http://www.linaro.org/blog/core-dump/energy-aware-scheduling-eas-project/)，甚至更强大的内存检测工具 [Kasan](https://www.ibm.com/developerworks/cn/linux/1608_tengr_kasan/index.html) ，这些都是安卓 Linux 内核开发者所迫切需要的内容。而源自工作经验的启发式问题，能让相关的从业者产生共鸣，相关的解法可以用到实际工作中去，阅读效果预计会提高不少。

## 实操性

本书还有一个很重要的特点，就是它的实操性很强。

作者花了整整一章来介绍内核调试，不仅介绍了诸如 printk、RAM Console、Oops分析，还用大量篇幅介绍了 Ftrace、Systemtap、Kasan 内存检测、Lockdep 死锁检测等当前很流行也很贴合实际开发需要的内容。

更重要地是，这些内容都可以通过软件模拟器 Qemu 来做实验，作者也很及时地把所有实验代码开放到了 Github 上：<https://github.com/figozhang/runninglinuxkernel_4.0>。

在 Figo 撰写本书的过程中，笔者刚好正在开发一个开放源代码的 Linux 内核学习和实验环境：[Linux Lab](http://tinylab.org/linux-lab)，这个环境通过 Docker 容器化技术大大地简化了实验环境的构建过程，并结合笔者早年的社区工作经验设计了一个 Qemu 虚拟化实验框架，可以大大简化内核编译、文件系统制作、内核调试和内核测试等工作。Figo 很果断地在书中给读者们做了推荐。

为了更加地便利各位读者，笔者通过两天的努力，为本书的实验环境制作了一套独立的 Linux Lab 插件：<https://github.com/tinyclub/rlk4.0>，这个插件可以直接放置到 Linux Lab 的 `boards/` 目录下使用。

除了撰写使用文档外，笔者又另外挤了点时间录制了该实验环境的使用视频，完整的使用文档和实验演示视频如下：

* 使用文档
    * [Linux Lab 使用文档](http://tinylab.org/linux-lab)
    * [RLK4.0 插件 for Linux Lab 使用文档](https://github.com/tinyclub/rlk4.0)
* 《奔跑吧Linux内核》实验演示视频
    * [桌面视频（用showdesk.io录制）](http://showdesk.io/2017-08-20-15-15-09-using-rlk4.0-in-linux-lab-00-15-58/)
    * [命令行视频（用showterm.io录制）](http://showterm.io/e786d08e0ea0964f3efb1)

## 实验演示视频

备注：点击视频右上角的`+`加号放大观看，效果更佳！单击可暂停/继续，本视频用 [showdesk.io](http://showdesk.io) 录制，用 [vplayer.io](http://vplayer.io) 播放。

<iframe src="http://showdesk.io/71ebfa3a31094daf1cc4b2ff5f2ea0f1/?f=1" width="100%" marginheight="0" marginwidth="0" frameborder="0" scrolling="no" border="0" allowfullscreen></iframe>

[1]: http://tinylab.org
