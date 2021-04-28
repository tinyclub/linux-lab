---
title: '开源之夏 - Summer 2021'
tagline: '“开源软件供应链点亮计划——暑期2021”项目提案'
author: Wu Zhangjin
draft: false
layout: page
permalink: /summer2021/
description: 国内第2届开源之夏，泰晓科技技术社区踊跃报名，将携 5 个 Linux Lab 子项目参加，欢迎大家报名。
update: 2021-04-28
categories:
  - 开源项目
  - Linux Lab
tags:
  - 暑期2021
  - 点亮计划
  - openEuler
  - 打包
  - GuiLite
  - Rust
---

## 项目简介

中科院软件所与华为 openEuler 社区去年共同举办了 [“开源软件供应链点亮计划——暑期2020”](https://summer.iscas.ac.cn/) 活动，今年为第二届。该活动旨在鼓励大家关注开源软件和开源社区，致力于培养和发掘更多优秀的开发者。

泰晓科技作为 Linux 与开源技术社区去年提报了 4 个项目，有 1 个因为报名的学生需要出国留学而在中期停止了，另外 3 个都过了中期节点，最终有 2 个完成了预期目标。

去年报名的几个学生的基础都非常不错，也很投入，不过因为疫情影响，很多学校的课程和作业被延期到了暑期，学生们实际能投入项目的时间非常有限，所以也部分影响了最后的实施效果，尽管如此，有 2 个项目还是争分夺秒努力达成了预期。

今年我们又准备了 5 个小项目，详情见文后的 “项目列表”。

## 去年回顾

![Summer2020](/wp-content/uploads/2021/03/29/summer2020.png)

有意向报名的同学可以提前了解一下去年的情况，相关文章链接如下：

* [Summer2021预告：暑期来做开源项目吧，有社区老师指导，还有Bonus领取](http://tinylab.org/summer2021-intro/)
* [“开源软件供应链点亮计划——暑期2020”项目提案](http://tinylab.org/summer2020)
* [暑期2020：泰晓科技项目简介](http://tinylab.org/tinylab-summer2020)

## 活动概览

Summer2021 项目开发周期为 3 个月，从 7 月 1 日到 10 月 22 日，期间：

* Mentor 负责指导报名的 Student 完成并达成预期的目标
    * 为确保活动开展质量，所有项目准备、调研、开发、测试、总结等过程需及时记录并公开发表在社区网站或公众号

* 达成目标后，活动主办方会给与 Mentor 和 Student 一定的奖励和资助
    * 数额因项目难度和完成情况而略有差异，Student 可以获得从 ￥6000 到 ￥12000 不等的 Bonus，具体情况以[开源之夏](https://summer.iscas.ac.cn/)活动官网为准，解释权归活动主办方所有

* 社区这边主要是义务遴选合适的项目参加并组织和协调 Mentor 与 Student 的项目实施过程
    * 设立 Summer2021 微信交流群，方便学员和 Mentor 的交流
    * 组织必要的项目会议，跟进项目进度，发现项目瓶颈，协调解决项目困难，确保各个项目顺利推进
    * 开展必要的项目培训与演练

完整日程：

| 日期	                    | 阶段
|---------------------------|----------------------------------
| 01 月 29 日	            | 社区报名启动
| 04 月 02 日	            | 第一批社区名单公示，学生开始与社区沟通项目意向
| 05 月 20 日	            | 社区报名截止
| 05 月 21 日	            | 第二批社区名单公示
| 05 月 24 日 - 06 月 13 日 | 学生提交项目申请阶段
| 06 月 30 日	            | 项目申请审核结果公示
| 07 月 01 日 - 08 月 15 日 | 项目研发第一阶段
| 08 月 30 日	            | 项目中期考核结果公示
| 08 月 16 日 - 09 月 30 日 | 项目研发第二阶段
| 10 月 22 日	            | 项目结项考核结果公示
| 11 月上旬	            | 年度优秀项目公示

## Linux Lab 简介

![Linux Lab](/wp-content/uploads/2020/08/linux-lab-loongson.jpg)

本次提报的项目均围绕 Linux Lab 开源项目展开，这里对 Linux Lab 做一个简单介绍：

[Linux Lab](http://tinylab.org) 是一款知名国产开源项目，由 [泰晓科技技术社区](http://tinylab.org) 创建于 2016 年，旨在提供一套开箱即用的 Linux 内核与嵌入式 Linux 系统开发环境，安装以后，可以在数分钟内开展 Linux 内核与嵌入式 Linux 系统开发。

当前 Linux Lab 已经支持包括 X86、ARM、RISC-V、Loongson 在内的 7 大国内外主流处理器架构，增加了 18 款流行虚拟或真实嵌入式开发板，支持从 v0.11, v2.6.x 到 v5.x 的各种新老 Linux 内核版本，可以同时在 Linux、Windows 和 macOS 三大主流操作系统上安装与使用，另外也制作了免安装、即插即用的 Linux Lab Disk。

* 项目首页：<http://tinylab.org>
* 当前文档：<http://tinylab.org/pdfs/linux-lab-v0.6-manual-zh.pdf>
* 代码仓库：<https://gitee.com/tinylab/linux-lab>
* 视频课程：<https://www.cctalk.com/m/group/88948325>

## 报名准备

为了最大程度地确保活动效果，社区需要遴选出准备最充分、能力最合适的学生参与相应项目，报名前请事先做好如下准备：

* 访问 [项目首页](http://tinylab.org/linux-lab) 了解项目详情
* 下载 [项目文档](http://tinylab.org/pdfs/linux-lab-v0.6-manual-zh.pdf) 并浏览主要章节
* 参考文档安装好 Linux Lab，并在如下页面登记安装信息，证明确实安装成功
    * [成功运行过的操作系统和Docker版本列表](https://gitee.com/tinylab/linux-lab/issues/I1FZBJ)
* 参考文档学习并使用 Linux Lab，撰写使用文档
    * 使用过程需公开发表在知乎、CSDN、泰晓科技等任何公开渠道
* 浏览后文的 “项目列表”，选中自己感兴趣的项目
* 提前对相关技术做充分的调研并撰写一份技术调研报告
    * 为确保调研的质量，调研报告需正式发表到社区网站或公众号
    * 社区稿件投递地址为：<http://tinylab.org/post>

## 报名方式

5 月 24 日- 6 月 13 日是学生提交项目申请阶段，可提前了解 [学生指南](https://summer.iscas.ac.cn/help/student/)。

对社区提报的项目感兴趣的同学们，现在就可以提前联系我们，**联系微信**：tinylab，**暗号**：Summer2021。

后续学生报名入口：<https://summer.iscas.ac.cn/help/student>

## 预约福利

为鼓励同学们提前预约了解和准备，凡是在 6 月 13 日之前联系我们并加入社区 Summer2021 微信群的同学可以以 8 折优惠申请一枚 Linux Lab Disk，申请后可以提前熟悉 Linux Lab 开源项目，为后续开发工作做充分的准备。

![Linux Lab Disk](/wp-content/uploads/2021/04/linux-lab-disk-64g-ssd.jpg)

## 版权说明

本次活动中由参与的学生新开发的代码需遵循 GPL v2 协议开放源代码，该等协议不影响相关项目原有和后续的版权协议，新增成果归贡献者和泰晓科技技术社区所有。

## 项目列表

### 项目一

1. 项目标题：Linux Lab 打包实战
2. 项目描述：本项目计划为 Linux Lab 的 Cloud Lab 管理环境打包，确保可以在 Linux、Windows、MacOS 等操作系统上更易、更快安装，允许通过软件仓库就能完成 Linux Lab 及 Cloud Lab 的安装及依赖环境的处理。。
3. 项目难度：高
4. 项目社区导师：@taotieren
5. 导师联系方式：admin@taotieren.com
6. 合作导师联系方式：@Falcon, falcon@tinylab.org
7. 项目产出要求：
    - 为 Linux 发行版打包，优先支持 1-2 种主流格式，例如 deb, rpm, YaST, AUR
    - 为 macOS 打包，添加 macOS 安装包
    - 为 Windows 打包，添加 Windows `exe` 安装包
    - 撰写并发表详细开发与使用文档
8. 项目技术要求：
    - 基本的 Linux 命令
    - 熟悉 Linux Lab
    - 熟悉 Cloud Lab
    - 了解各大主流系统的软件包构成
    - 了解仓库中安装软件包时如何处理依赖关系
    - 有 obs, debreate, deb, rpm, YaST, AUR 等使用经验优先
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Linux Lab: <https://gitee.com/tinylab/linux-lab>
   - OBS: <https://openbuildservice.org/>

### 项目二

1. 项目标题：Linux Lab 嵌入式图形系统集成实战
2. 项目描述：本次项目计划把 Linux Lab 打造成一套迷你嵌入式 Linux 发行版，优先满足 AIoT 领域需求。Linux Lab 目前已支持 Linux、Buildroot、Uboot 和 Qemu 四大核心组件，本次项目将进一步模块化，新增至少一款嵌入式 GUI 支持，不依赖 Buildroot，能一键编译并启动嵌入式图形系统，并集成一些核心协议和软件，希望有 AIoT 厂家申请参与协作。
3. 项目难度：高
4. 项目社区导师：@jiaxianhua
5. 导师联系方式：iosdevlog@iosdevlog.com
6. 合作导师联系方式：@Falcon, falcon@tinylab.org
7. 项目产出要求：
    - 进一步模块化 Linux Lab，方便扩展更多组件
    - 集成 GuiLite 等嵌入式图形系统
    - 集成 BusyBox
    - 一键构建一个可以在虚拟开发板运行的 mini 图形系统
    - 加上一些小型的协议，比如 mqtt 之类的
    - 撰写并发表详细开发与使用文档
    - 选做：接入智能家居平台
8. 项目技术要求：
    - 基本的 Linux 命令
    - 熟悉 Makefile 和 Bash
    - 熟悉 Docker 的安装与使用
    - 熟练使用 Linux Lab
    - 有 LFS 等 Linux 发行版制作经验优先
    - 有 GuiLite 等嵌入式图形系统开发经验优先
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Linux Lab: <https://gitee.com/tinylab/linux-lab>
   - Busybox: <https://busybox.net/>
   - GuiLite: <https://gitee.com/idea4good/GuiLite>

### 项目三

1. 项目标题：Linux Lab openEuler 集成开发支持
2. 项目描述：作为一款国产开源项目，Linux Lab 已经并且在继续为国产芯片、开发板和系统提供大力支持。 2019 年，Linux Lab 为平头哥前身中天微 [CSKY](https://gitee.com/tinylab/csky) 添加了集成开发支持；2019-2020 年，Linux Lab 已经为龙芯 MIPS 架构的 3 大芯片系列的 4 款开发板提供了[即时开发支持](https://gitee.com/loongsonlab/loongson)；2020-2021 年，Linux Lab 集成了国产真实[嵌入式硬件开发板](https://gitee.com/tinylab/ebf-imx6ull)，这些工作让开发者“零门槛”真切用上国产芯片和开发板，也让国产芯片和开发板有更多的开发者生态。本次项目旨在 Linux Lab 现有 aarch64/virt 虚拟开发板的基础上，增加鲲鹏支持，并同时增加对知名开源国产操作系统 openEuler 的集成开发支持，旨在降低 openEuler 内核与系统的学习、实验与开发门槛，同时为 openEuler 开源项目吸引更多的爱好者与开发者。
3. 项目难度：高
4. 项目社区导师：@Falcon
5. 导师联系方式：falcon@tinylab.org
6. 合作导师联系方式：暂无
7. 项目产出要求：
    - 添加一款新的鲲鹏虚拟开发板
    - 集成 openEuler 开源内核
    - 集成 openEuler 文件系统
    - 撰写并发表详细开发与使用文档
8. 项目技术要求：
    - 基本的 Linux 命令
    - 熟悉 Linux Lab
    - Linux 内核开发基础
    - 嵌入式 Linux 系统开发基础
    - 熟悉 Qemu 用法
    - 有 openEuler 使用与开发经验优先
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Linux Lab: <https://gitee.com/tinylab/linux-lab>
   - openEuler: <https://openeuler.org/zh/>

### 项目四

1. 项目标题：Linux Lab 新增 Rust for Linux 开发支持
2. 项目描述：Rust for Linux 正在往 Linux 官方主线提交代码，目前有部分代码已经进入 Linux Next，这意味着下一个 Linux 内核版本将正式可以使用 Rust 来开发 Linux 模块。但是，Rust 作为一个新兴语言，对很多人来说都很陌生，第一步的环境搭建就能挡住很多人。本次项目旨在为 Linux Lab 做好 Rust for Linux 的环境准备工作，确保 Linux Lab 用户可以直接上手在 Linux Lab 中用 Rust 编写 Linux 内核模块，并提供必要的上手模块案例和中文文档。
3. 项目难度：高
4. 项目社区导师：@Falcon
5. 导师联系方式：falcon@tinylab.org
6. 合作导师联系方式：@Mike Tang, daogangtang@live.com
7. 项目产出要求：
    - 为 Linux Lab 新增 Rust 开发环境
    - 确保 Rust for Linux 中的模块可以编译与运行
    - 确保 make module 兼容 Rust 撰写的 Linux 内核模块
    - 撰写并发表详细开发与使用文档
    - 可选：使用 Rust 撰写1-2个新的 Linux 内核模块
8. 项目技术要求：
    - 基本的 Linux 命令
    - 熟悉 Makefile 和 Bash
    - 熟悉 Linux Lab
    - Linux 内核与驱动开发基础
    - 具有 Rust 语言使用经验优先
    - 用 Rust 撰写过 Linux 内核模块优先
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Markdown Lab: <https://gitee.com/tinylab/markdown-lab>
   - Rust for Linux: <https://github.com/Rust-for-Linux>
   - Rust: <https://www.rust-lang.org/>

### 项目五

1. 项目标题：Linux Lab Disk 跨平台运行管理软件
2. 项目描述：Linux Lab 开源项目目前正在开发 v0.7，该版本旨在开发一款免安装、即插即用的 Linux Lab Disk，进一步降低 Linux 内核与嵌入式 Linux 系统的学习与开发门槛，提升学习与开发效率。当前 Linux Lab Disk 采用超高速固态 U 盘，已经可以在 64 位 X86 主机、笔记本和 macBook 上做到开机上电即插即用，也可以在 Windows、Linux 和 macOS 三大主流操作系统上当双系统使用，目前正在开发一款当双系统使用时的跨平台管理软件，方便在作为双系统使用时也能做到 “即插即用”。
3. 项目难度：高
4. 项目社区导师：@Falcon
5. 导师联系方式：falcon@tinylab.org
6. 合作导师联系方式：@RXD, rxd@tinylab.org
7. 项目产出要求：
    - 可以在 Linux 系统下管理并快速启动 Linux Lab Disk
    - 可以在 Windows 系统下管理并快速启动 Linux Lab Disk
    - 可以在 macOS 系统下管理并快速启动 Linux Lab Disk
    - 需要支持 Virtualbox, Qemu 或 Vmware 中至少一种虚拟机
    - 撰写并发表详细开发与使用文档
8. 项目技术要求：
    - 有 Python、Qt 或 Delphi 等某一种图形化软件开发经验
    - 了解 Virtualbox，Qemu 或 Vmware 中某一种虚拟机的深度命令行工具用法
    - 有 Windows、Linux 或 macOS 等系统跨平台相关开发经验
    - 熟练使用 Linux Lab
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Markdown Lab: <https://gitee.com/tinylab/markdown-lab>
   - VMUB: <https://github.com/DavidBrenner3/VMUB>

[1]: https://gitee.com/tinylab/cloud-lab/issues/I1H8Q3
[2]: https://gitee.com/tinylab/cloud-lab/issues/I1HAN4
[3]: https://gitee.com/tinylab/cloud-lab/issues/I1HAU0
[4]: https://gitee.com/tinylab/cloud-lab/issues/I1HAV2
