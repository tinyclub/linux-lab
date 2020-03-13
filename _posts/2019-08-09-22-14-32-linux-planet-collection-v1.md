---
layout: post
author: 'Wu Zhangjin'
title: "『Linux 知识星球』发布第 1 个合集，106 篇, 529 页, 5.8 M"
draft: false
album: Linux 知识星球
license: "cc-by-nc-nd-4.0"
permalink: /linux-planet-v1/
description: "『Linux 知识星球』为感谢第一批订阅会员们的关注和支持，也方便大家查询和阅读，前几天完成了梳理和编撰，已经发布了第 1 个合集。未来，我们将每隔 3 个月发一个合集。"
category:
  - Linux 知识星球
tags:
  - Linux
  - 内核开发
  - 嵌入式 Linux
  - elinux.org
  - C 语言
  - Linux Lab
  - LWN 翻译
---

> By Falcon of [TinyLab.org][1]
> Aug 08, 2019

一转眼，[『Linux 知识星球』][2]建立了快 **4** 个月，前前后后的文章分享也已经突破了 **100** 篇，为了感谢第一批订阅会员们的关注和支持，也方便大家查询和阅读，前几天完成了梳理和编撰，已经发布了第 1 个合集。未来，我们将每隔 3 个月发一个合集，敬请期待！

这个合集**共 106 篇，合计 529 页，5.8M**。内容横跨项目实录、内核开发、效率工具、程序开发、泰晓资讯、LWN 翻译，社区与文化、思维碰撞等几个大的类别。

![Linux 知识星球海报](http://tinylab.org/images/xingqiu/planet-collection.jpg)

**扫描上述二维码订阅，即可获得该合集**，也能持续获得后续全年所有星球原创内容，还能受邀加入专属微信群，与数十位 Linux 一线工程师和技术专家们面对面交流。

借这个时间点，跟大家分享一下笔者*为什么要建立[『Linux 知识星球』][2]*以及未来*我们将怎样去建设它*。

## 关于『Linux 知识星球』

### 泰晓科技简介

首先 [Linux 知识星球][2] 是 [泰晓科技][1] VIP 版，只面向付费订阅的读者开放。

而 泰晓科技 创建于 2010 年，是国内知名高质量 Linux 内容原创社区，旨在 “聚焦 Linux，追本溯源，见微知著“，致力于促进行业打造更极致的 Linux 产品，目前已经聚拢了数百位 Linux 产品一线工程师和技术专家。

九年来如一日，泰晓科技坚持公益性，并且一直坚持原创，坚持不断分享产品实战经验和技术观察：

- 撰写了*数百篇技术文章*，主要聚焦 Linux，涉及程序开发、源码分析、内核开发、系统优化、调试跟踪、嵌入式 Linux、行业资讯等。

- 组织了 *3 个翻译计划*，包括 [嵌入式 Linux 知识库翻译计划](http://tinylab.org/elinux)，[Linux 内核文档翻译计划](http://tinylab/linux-doc)，[LWN 翻译计划](http://tinylab.lwn)，第 3 个翻译计划目前最活跃。

- 发起了*数个开源项目*，包括 [Linux Lab: 内核实验室](http://tinylab.org/linux-lab)，[Linux 0.11 Lab: 0.11 内核实验室](http://tinylab.org/linux-0.11-lab)，[X86 Linux AT&T 汇编语言实验室](http://tinylab.org/cs630-qemu-lab), [轻量级流量检测前端 vnstatSVG](http://tinylab.org/vnstatsvg) 等。部分项目已经收获数百 Stars 和 Forks，Linux Lab 已经发布 [v0.2 rc1](https://www.cnbeta.com/articles/soft/870475.htm)。

- 编撰了*多本开源书籍*，包括 [C 语言编程透视](http://tinylab.org/open-c-book)，[Shell 编程范例](http://tinylab.org/open-shell-book)，已经被各大在线课堂、免费编程书目录等收录。笔者还以第一作者撰写了一本英文版书籍《Instant optimizing embedded systems using BusyBox》。

- 建立了 *4 个技术讨论群*，一个是『泰晓原创团队』，一个是『校企 Linux 团队直通车』，前者面向所有一线 Linux 工程师、学生、老师开放，后者面向高校 Linux 社团和企业 Linux 团队负责人开放。还有一个 『LWN 翻译团队』，主要面向所有译者们。最后还有一个只面向会员的 [『Linux 知识星球』][2]讨论组。

- 组织了*多次线下沙龙*。在珠海地区组织了多次线下沙龙，未来也规划在其他城市组织类似沙龙。

### 重启公众号

泰晓科技早先只有 2 个发布渠道，一个是 Web 网站：<http://tinylab.org>，一个是公众号：泰晓科技 / TinyLab-Org。公众号在今年重启，*坚持在工作日每天推送一篇文章*，从周一到周五分别推送读者原创、LWN 翻译、专辑连载、产品实践、业界资讯。

![泰晓科技 微信公众号：TinyLab-Org](http://tinylab.org/images/wechat/tinylab-org.jpg)
<p style="text-align: center;">（扫码关注『泰晓科技』公众号）</p>

上述工作得到了读者们广泛的支持和好评。今年 4 月份，笔者经过审慎地考虑，为了让这些工作能够更持久高质量地做下去，在坚持公益的同时，我们做了两件事。

### 开通 [『付费征稿』](http://tinylab.org/post)，扩大技术原创来源

一方面，开通了『付费征稿』，以便更多的一线工程师们能够踊跃投稿，不仅给予大家展示才华的机会，也给予大家必要的小激励（*现在的稿费预设是每篇 200 块大洋*^_^），算是给熬夜写稿的作者们一点贴心的犒劳，或加几个鸡腿，或买几罐可乐。

自从开通『付费征稿』以来，我们已经收获了若干篇精彩的原创文章，并且已经发表了数篇。期待更多的同学加入进来。所有的稿件都是最简洁的 Markdown 格式，投稿只要发个 Github PR，非常便利。除了稿费，还可以接收网站和公众号两个渠道的打赏，有鸡腿加，不亦乐乎 ;-)

为了持续鼓励读者们踊跃撰稿，即日起，**凡是在泰晓科技独家发表了原创技术文章的作者们都可以获赠[『Linux 知识星球』][2]一年的会员**。

### 开通 [『Linux 知识星球』][2]，创造高品质内容

另外一方面，由于笔者 4 月份从原公司离职，暂时还赋闲在家，没有多余的资金来补充稿费，所以就开通了[『Linux 知识星球』][2]，以便泰晓科技将近十年来的热心读者们能够有一个参与和支持这个平台的机会。

大家通过 [订阅『Linux 知识星球』][2] 一方面能够获得更多专属的原创内容，包括技术开发、产品思考和行业观察等，也能够有机会与我们邀请到的 Linux 行业专家和 CTO 级嘉宾们进行面对面的沟通；与此同时，能够让我们有机会一起给作者们加鸡腿，加可乐，让大家快乐幸福地写好的内容，分享好的经验，从而让这个轮子可以转起来，大家也能够在学习和讨论中汲取经验教训，少走弯路，不断进步，成长。

目前，*[『Linux 知识星球』][2]的订阅费是 199 块大洋，只相当于赞助了一篇原创文章的稿费*，而您收获的是每年数十甚至数百篇技术原创文章。

所以，简而言之，『Linux 知识星球』是泰晓科技专门开辟的 VIP 版，是一个更专属的技术圈子，订阅以后，除了泰晓科技网站和公众号的文章，还可以阅读仅发表在星球内的原创内容，向邀请到的嘉宾们和原创作者们直接提问，也可以发表自己的感想或技术思考，还可以加入会员们的专属微信讨论群。


## 我们已经做了什么

『Linux 知识星球』是泰晓科技的一个 VIP 版块，上面我们介绍了『泰晓科技』过去九年来的所有主要公益性工作与贡献，为了让这些公益事业能够持续，我们开辟了这样一个会员制的版块。那这个版块过去 4 个月主要做了哪些工作呢？

### 27 个标签

先来看看我们的标签：

> Linux Lab, Shell, LWN, 泰晓资讯, Linux, TIPS, GIT, Makefile, 佳作共赏, 若有所思, Debugging+Tracing, Real Time, C 语言, Docker, ML, Risc-V, 源码分析, Android, Linux 人物, Linux Toolchains, Linux 文化, Linux 0.11 Lab, 星球合集, 5G, 芯片, 周边生活, 龙芯

总结下来，内容横跨项目实录、内核开发、效率工具、程序开发、泰晓资讯、LWN 翻译，社区与文化、思维碰撞等几个大的类别。

### 第一个合集

整理完的第一个合集大纲如下（由于篇幅太长，仅摘录部分内容）：

* 简介

* 版本变更记录

* 项目实录
  * Linux Lab：Linux 内核实验室
    * 最新版本：v0.2 rc1
    * 全面支持 v5.0 内核
    * 全功能文件系统支持
    * 为 Linux Lab 加新板子

* 内核开发
  * 通过命令行工具修改内核配置
  * 实时 Linux 资料汇总
  * Linux v5.1 内核详解
  * 各大处理器交叉编译工具链大全
  * 七张图看懂 profiling 机制
  * ARM Linux v5.0 死机案例
  * 用 git bisect 定位 Regression
  * backtrace 分析方法与工具

* 效率工具
  * Makefile 高级用法 11 条
  * Git 实用技巧 6 则
  * 记录和分享命令行的 n 重境界
  * 记录和分享桌面的 n 重境界

* 程序开发
  * C 语言编程
    * 如何绕过编译器优化
    * 那些经典的 LD_PRELOAD 用法
    * 多任务调试: libvirt 分析

  * 汇编语言
    * 如何生成干净可阅读的汇编代码

  * Shell 编程
    * 语法之外的那些事儿

  * Android 开发
    * Android DispSync 详解

* 泰晓资讯
  * Risc-V 正是关注好时机
  * 2019 LSFMM 大会专题报导
  * 2019 MOOC 大会与会心得
  * 08月 / 第一期
  * 07月 / 第四期
  * 07月 / 第二期
  * 07月 / 第三期
  * 07月 / 第一期

* LWN 翻译
  * LWN 106010: 实现 “实时（realtime）” Linux 的多种方法
  * LWN 146861: 实时抢占补丁综述
  * LWN 452884: 实时 Linux 中的 Per-CPU 变量处理
  * LWN 520076: 软中断对实时性的影响
  * LWN 178253: 内核中的 “优先级继承（Priority Inheritance）”
  * LWN 230574: 内核调度器替换方案的激烈竞争
  * LWN 271817: 实时自适应锁
  * LWN 296419: SCHED_FIFO 和实时任务抑制（throttling）
  * LWN 302043: 中断线程化

* 社区与文化
  * 分享两部 Linux 纪录片：The Code, Revolution OS

* 更多内容
  * Linux Lab 开发实录
    * 支持直接体验最新 v5.2 的 Preempt RT 特性
    * 新增龙芯 ls232 教学开发板支持
    * Linux Lab v0.2 rc1发布，新增龙芯全系支持
    * 新增 kvm 加速支持
    * 一条命令配置、编译和测试内核模块
    * 一条命令快速体验和测试一个新的内核特性
    * 新增 riscv32/virt & riscv64/virt boards

  * 实时 Linux 开发
    * 分享两篇 Linux Preempt RT 的理论和实践论文
    * 龙芯 2F 在欧洲 OSADL 实验室跑了 5+ 年实时测试
    * Preempt RT 特性有望完全进入 Linux v5.3

  * Linux 开发
    * 国内 Linux 镜像，加速 Linux 内核下载
    * 新增 Riscv32/64 汇编语言实例: Hello World
    * 新增了一个 Debugging+Tracing 专辑

  * 若有所思
    * 好记性不如烂笔头，写作与分享受益终身
    * 坚持意味着什么
    * Why 996: 编程本身具有不确定性

  * 开放讨论
    * 开普勒是如何得出开普勒三大定律的？（好文推荐，外部链接）
    * 阻止文明倒塌：Jonathan Blow 在莫斯科 DevGAMM 上的演讲（好文推荐，外部链接）

  * 行业资源
    * 国内芯片 60 个细分领域重要代表企业（好文推荐，外部链接）
    * 全国 5G 最新进展和规划情况汇总（好文推荐，外部链接）

## 未来计划做哪些工作

### 现有的不足

回顾上面的合集，虽然内容比较丰富：

- 有很多提升效率的实用技巧
- 有不少解决实际问题的思路和方案
- 有最新的行业动态跟踪
- 有核心原理的解读与翻译
- 有实际开源项目的开发过程实录
- 有编程语言的深度案例分析
- 还有对开源社区与文化的观察与宣导
- 以及关于生活其他方面的思考

但是，通过跟读者们的反复沟通后，还需要完善，主要在以下几个方面：

- 技术方面，内容需要更聚焦，更有深度和连贯性
- 技术之余，需要关注个人成长、就业择业、产品思考、团队管理、流程规范等内容

### TODO plan

所以，接下来有几个工作正在做或者计划去做：

- 继续强化 [LWN 翻译计划](http://tinylab.org/lwn)，加强新发布内容的跟踪与翻译，目前已经实质上是 [LWN](http://lwn.net) 的独家中文翻译平台

- 加强 Linux Lab 项目的实际使用案例，确保大家能够真正把 Linux Lab 用到实际学习和开发中，大大提升学习效率

- 梳理出几个主题，跟会员们和读者们讨论，选出大家感兴趣的主题连载，目前计划连载的内容包括
  - 基于 Linux 0.11 Lab 的 Linux 0.11 阅读与实战，甚至可能往 Risc-V Porting？
  - 基于 CS630 Qemu Lab 的 X86 Linux AT&T 汇编语言开发实践，甚至可能往 ARM Porting?
  - 基于 Linux Lab 的嵌入式 Linux 系统开发，选一个开发板，比较系统地介绍如何从 0 ~ 1 ~ n 做嵌入式 Linux 开发
  - Linux 手机驱动开发，介绍现代嵌入式平台上重要设备的驱动开发
  - Linux 各大子系统深度解读，基于 Linux Lab，一方面解读 Linux 新版本的功能，另外一方面分析各个核心子系统
  - 系统优化、测试、调试等系列，进阶类
    - Linux 稳定性优化
    - 嵌入式 Linux 性能优化
    - Linux 温控优化
    - Linux 系统裁剪
    - Linux 续航优化
    - Linux Debugging/Tracing/Profiling 专题
    - Linux Automated testing 专题

- 继续开放邀请更多的行业专家加入，包括跨行业的专家，比如说云计算、存储、AIoT、芯片设计、知识产权，ID 设计、UI/UE 设计，GUI 系统开发、团队运营，配置管理，领导力培养等

- 系统性地总结自己读书、工作多年来的一些心得，比如说：
  - 如何熟练地使用 git 代码版本管理工具
  - 如何创建和管理一个校园开源社团
  - 如何规划校园学习生涯
  - 如何择业就业
  - 如何参加国际开源社区
  - 如何发起和管理一个开源项目
  - 如何从一个工程师逐步提升为一个技术专家
  - 如何从一个工程师转变为一个技术管理者
  - 如何管理一个技术团队
  - 如何应对企业快速的成长
  - 如何应对数百万上千万规模 Linux 产品的系统质量保障
  - 如何应对快到 1 个多月的 Linux 产品软件交付周期压力

### 哪些已经动工了

上面的部分主题已经发表在泰晓科技、知乎等平台上，未来计划比较系统地整理和归纳，持续发表在『Linux 知识星球』。比如：

- [为什么计算机专业的学生要学习 Linux 开源技术？](http://tinylab.org/why-computer-students-learn-linux-open-source-technologies/)
  - [知乎](https://www.zhihu.com/question/19934684/answer/43155800)，347 赞

- [从事嵌入式行业的你，现在年薪多少，有什么经历想和大家分享？](https://www.zhihu.com/question/55453399/answer/144885919)，432 赞

- [为什么手机核心数目提升得比计算机快?](https://www.zhihu.com/question/31022653/answer/51307328)，707 赞

- [Android 手机是否会越用越卡？](https://www.zhihu.com/question/31212416/answer/51024984)，799 赞

- [智能手机系统优化的演进与实践](http://tinylab.org/smartphone-sys-opt-evolution-and-practice/)，2015

- [嵌入式系统优化](http://tinylab.org/embedded-linux-optimization/), 2011

- [Android Linux 可靠性（RAS）研究与实践](http://tinylab.org/android-linux-ras-research-and-practice/), 2013

也欢迎各位读者提出自己感兴趣的问题和主题，我们整理后，一方面基于自己经验解答，另外一方面邀请更多专业嘉宾加入。可以通过扫描文末二维码添加笔者微信号。

## 您怎么参与进来

首先再次感谢大家一直以来的支持，除了阅读、评论、反馈外，您还可以通过下列方式更踊跃的参与进来。

### 撰写原创稿件

好记性不如烂笔头，通过撰写原创稿件，不断记录工作日志，分享产品研发经验，获得其他同学反馈，不断探讨，完善思路，加深理解，提升技能。请参考[付费征稿流程](http://tinylab.org/post)。

### 参与翻译项目

通过参与 [LWN 翻译计划](http://tinylab.org/lwn) 等翻译项目，一方面跟踪 Linux 技术演进轨迹和前沿动态，另一方面，提升英文的读写能力。

### 关注 泰晓科技: Tinylab-Org 微信公众号

扫描下方二维码，设为星标，更及时获得原创文章推送，通过留言发表自己的看法，对好看的文章点击 “在看” 并通过朋友圈分享给周边的同学。

![泰晓科技 微信公众号：TinyLab-Org](http://tinylab.org/images/wechat/tinylab-org.jpg)
<p style="text-align:center">（扫码关注『泰晓科技』公众号）</p>

### 订阅『Linux 知识星球』

以实际行动支持作者们的原创工作，因此收获大家分享的技术干货和各类思考，结识来自各个企业的一线工程师与技术专家，让整个圈子能够更良性的运转起来。

![Linux 知识星球](http://tinylab.org/images/xingqiu/tinylaborg.jpg)
<p style="text-align:center">（扫码关注『Linux 知识星球』）</p>


## 星主与 Linux 的那些故事

大学毕业的时候总想着要 “轰轰烈烈地” 写一写  “我的大学”，工作了以后慢慢地觉得好像也没什么好写的，工作八、九年后，现在离职了，接触了知乎、泰晓原创团队微信群等各个渠道大家提出的问题后，觉得似乎可以简单回顾一下。

所以，下面简单回顾一下 “我的大学” 以及 “我的工作”，这些基本都围绕 Linux，希望可以打发一下大家的碎片时间。

由于内容篇幅过长，这部分请阅读 [细数我与 Linux 这十三年](http://tinylab.org/falcon-and-linux)。

## 送您一张免费体验卡

非常感谢您能耐心读到这里，下面奉上一张免费体验卡，可以多人使用，也欢迎转赠给周边的朋友。

![『Linux 知识星球』免费体验卡](http://tinylab.org/images/xingqiu/planet-free-card.jpg)

## 寄语

在手机这波浪潮逐渐退却之后，汽车、物联网、AI 这些大潮接踵而至，但是都离不开它们的基石，即我们正在学习和研究的 Linux 平台，无论是作为设备（汽车大屏、充电桩、语音终端、摄像终端）系统存在，还是作为云（AI 计算、数据存储、虚拟化）平台系统存在，Linux 在未来都将继续呈现勃勃生机。

笔者希望，能够藉由[『Linux 知识星球』][2]这个载体，系统地总结过去十多年的 Linux 系统使用、研究和开源社区组织参与经验，以及过去八年来数千万规模的手机终端产品 Linux 系统研发、团队管理和质量保障经验，然后逐步回归 Linux 官方社区，密切关注和参与行业发展趋势。

与此同时，笔者将不断邀请更多专业嘉宾朋友加入。然后希望这些成果能够切实降低当下其他行业应用 Linux 技术的门槛，切实提升 Linux 一线工程师们解决问题的效率，切实提升汽车、物联网和 AI 产品中 Linux 系统的用户体验，为行业做一些微薄的贡献。

此致！感谢所有为 Linux 和其他开源技术产品做出过诸多贡献的同学们！

也特别邀请您转发这篇文章，让更多的同学了解[『Linux 知识星球』][2]，让我们一起 “聚焦 Linux，追本溯源，见微知著！”。

然后一起学习和研究 Linux，一起成长。Let's go together, no longer alone。


[1]: http://tinylab.org
[2]: https://wx.zsxq.com/dweb/#/index/455128114458