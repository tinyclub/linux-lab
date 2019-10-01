---
title: 为什么计算机的学生要学习Linux开源技术
author: Wu Zhangjin
layout: post
permalink: /why-computer-students-learn-linux-open-source-technologies/
transposh_can_translate:
  - 'true'
tags:
  - CS630
  - 计算机学生
  - Linux
  - Linux 0.11
  - Linux Lab
  - Qemu
  - Uboot
  - 开源
categories:
  - 开源社区
  - Linux 系统
---

> by Falcon of [TinyLab.org][1]
> 2013/08/25

Linux 相关的开源技术对于学生来说，特别是计算机专业的学生来说，非常重要，下面就几个方面进行讨论：

## 研究平台

因为开源的优势，有很多开放文案可以参考，有很多有趣的点子可以拿来做深入的研究。任何一个点挖进去都是一片天地。

## 专业视野

藉由那些开源项目，可以通过[邮件列表][30]、[Patchwork][31]、[Github][32]、[Linkedin][2]、Google Group 接触到来自全球各地的天才，不仅可以提升英文读写能力，认识国际友人，还可以把握领域前沿，甚至还有机会得到大佬们的指点迷津。

## 工作机会

就像 2004 年左右，笔者在学校毅然而然地选择转到 Linux 平台一样，现在有同样的预感，Linux 以及相关的开源技术因为它包含了人类的共赢理念（Open, Free, Share），融合了全球众多企业和天才的智慧，以及它不断更新换代地自我革新，她将持续繁荣下去。

目前的 Linux 人才看似很多，刚从学校毕业没什么编码经验的学生也可以很快写个小驱动，看似门槛很低，但是真正能够从系统层面解决问题，做了工作不用别人搽屁股的高端人才很少。如果从大学开始抓取，毕业时就多了四年的使用经验和思维培养。对于后续的研究和工作来说，都会是非常重要的竞争力。

## 课程实践

几乎从硬件到软件，Linux 平台能够自下而上提供各类触及“灵魂”的学习案例，让所有课程从纸上谈兵转变成沙场实战，会极大地提升工程实践的效率和技能。

### 硬件方面

硬件模拟已经是趋势，不可阻挡。包括处理器模拟、系统模拟，大名鼎鼎的 Qemu，以及它的派生者 Android Emulator 提供了易用的案例，支持四大，不是律师事务所，是 ARM、X86、PPC 以及 MIPS。

这东西不仅能够模拟处理器指令，支持系统级（各种外设）的模拟，还支持直接在一个架构上执行另一个架构的可执行文件（通过 qemu-user 翻译）。有了它，不必花钱买开发板，有了它，可以研究如何模拟设计和实现一个硬件系统，一套处理器指令，还可以研究虚拟化技术，虚拟化集群。

跟 GNU 序列工具的开创者 Stallman 以及 Linux 的开创者 Linus 一样，Qemu 的开创者也是一个伟大的先驱，他的个人主页在：<http://bellard.org/> 。

> 法布里斯·贝拉 是一位法国著名的计算机程序员，因 FFmpeg 、Qemu 等项目而闻名业内。他也是最快圆周率算法贝拉公式、TCCBOOT 和 TCC 等项目的作者。1972 年生于法国 Grenoble。在高中就读期间开发了著名的可执行压缩程序 LZEXE ，这是当年 DOS 上第一个广泛使用的文件压缩程序。

接触开源，有机会了解和认识这些疯狂的前辈，这无疑是一件非常励志和让人血脉贲张的趣事。

关于纯 CPU 模拟，这里补充一个 [Unicorn](https://github.com/unicorn-engine/unicorn)，同样源自 Qemu。

再补充一个，如果要研究处理器，可以考虑 [RISC-V](https://riscv.org)，它采用 BSP 协议授权，完全开源。

* [The RISC-V Analysis (in Chinese)](https://medium.com/@yuxing.tang/the-risc-v-analysis-in-chinese-a26abaac03f3)
* [Risc-V 开放源码首页](https://github.com/riscv)
* [Risc-V 发展迅猛，正是关注好时机](http://tinylab.org/riscv-overview/)

### 引导程序

大学时学习了 BIOS，基本输入输出系统，是个啥玩意，感觉得到，看得到面纱，看不到她真实的样子。但是有了 [Uboot](http://www.denx.de/wiki/U-Boot) ，可以。

可以直接通过 Qemu 做 Uboot 实验：

* [Using QEMU for Embedded Systems Development, Part 3][3]
* [利用 Qemu 模拟嵌入式系统制作全过程][4]

而最近，更是可以通过 [Linux Lab](http://tinylab.org/linux-lab) 更便捷地做 Uboot 实验：

* [命令行演示](http://showterm.io/11f5ae44b211b56a5d267)
* [视频演示](https://v.qq.com/x/page/l0549rgi54e.html)

也可以通过 [固件和引导程序介绍](http://tinylab.org/firmware-and-bootloaders/) 获取更多引导程序相关的信息。

### 操作系统

Linux 本身绝大部分都是 Open 的，在学习操作系统课程的同时如果能够读一读 Linux 0.11 的源代码，会发现操作系统不是干巴巴的电梯调度算法之类算法描述。可以看到实实在在的活生生的场景，可以说话的场景。

什么调度算法，什么同步机制，什么中断管理，什么文件系统，什么各类外设的驱动等等，通通可以看到源代码实现并允许亲自去修改、调试和完善，甚至可以通过 [邮件列表][5] 提交 Patch 到官方 Linux 社区，然后有机会接触 Linux 社区的那些印象中“神一般”现实里“平易近人”的大佬们。而且开源社区很喜欢初生牛犊不怕虎、善于思考、勇于探索的同学们。

还可以自己制作一个完整的操作系统。看看 Building Embedded Linux System 这本书，从 [Linux 官方社区](http://www.kernel.org) 下载一份源代码，编译一下，然后用 [Busybox][6]、[Buildroot][7]、LFS、Openembedded 甚至 Yocto 制作文件系统，然后就是一个完整的操作系统。

然后会知道什么是一个完整的操作系统，什么仅仅是一个操作系统 Kernel。然后会了解，用户交互的界面，除了 GUI ，其实它最最本质的东西还是 Shell Terminator，GUI 只是换上了一袭花衣裳。会真正地理解，当按下键盘上的一个按键时，这背后发生了什么样的故事和演变。作为计算机的学生，不应该被这些蒙在鼓里，应该掀开那袭花衣裳，打探背后的细枝末节，然后，等到哪一天，闭上眼睛，当整个故事情节在脑海里像放电影一样清晰不再模糊时，就如偿所愿了，那种美妙的滋味在出现 Bug 需要解决时会得到印证。

做这些实验，不必买开发板，Qemu 就绰绰有余了（懂得节省的“穷学生”是好学生 ^-^），可以参考：

* [Using QEMU for Embedded Systems Development, Part 1][8]
* [Using QEMU for Embedded Systems Development, Part 2][9]

如果想学习 Linux 0.11 内核，可以到 <http://oldlinux.org/> 下载开放的书籍和源代码，用 Qemu 做实验就好：

* 赵博士的[《Linux 内核完全注释》](http://www.oldlinux.org/download/clk011c-3.0.pdf)
* [Linux 0.11 实验环境和源代码](https://github.com/tinyclub/linux-0.11-lab.git)
* [五分钟 Linux 0.11 实验环境使用指南][11] 。

如果想研究最新的 Linux 内核，则可以使用 [Linux Lab](http://tinylab.org/linux-lab)。利用它可以通过 Docker 一键搭建 Linux 内核实验环境，通过 Qemu 支持上百款免费的开发板，集成了交叉编译环境、Buildroot、Uboot 等嵌入式 Linux 开发的必备工具，支持串口和图形启动，支持在线调试和测试，也可通过 Web 远程访问。

* [Linux Lab 源代码](https://github.com/tinyclub/linux-lab)
* [利用 Linux Lab 完成嵌入式系统软件开发全过程](http://tinylab.org/using-linux-lab-to-do-embedded-linux-development/)

关于 Linux 0.11 Lab 和 Linux Lab 的用法详见：

* Linux 0.11 Lab 用法演示
    * [基本用法](http://showdesk.io/50bc346f53a19b4d1f813b428b0b7b49)
    * [添加一个新的系统调用](http://showterm.io/4b628301d2d45936a7f8a)
    * [获取即时在线实验帐号](https://weidian.com/i/1487448443)

* Linux Lab 用法演示
    * [基本用法](http://showdesk.io/7977891c1d24e38dffbea1b8550ffbb8)
    * [进阶用法（请切到高清观看）](https://v.qq.com/x/page/y0543o6zlh5.html)
    * [获取即时在线实验帐号](https://weidian.com/i/1937753839)

### 汇编语言

估计学校还在用王老师的书吧，这个是笔者大二时写的[《汇编语言 王爽著》课后实验参考答案][12]。

分享在这里是非常想强调实践的重要性，不知道有几个同学认真地做完了所有或者绝大部分大学计算机课程课后的实验，实验真地非常重要。

另外，真地希望大家能够在 Linux 平台下学汇编语言，用 gas 汇编器，用 AT&T 的语法，用 gcc 看 C 语言写的东西是怎么用汇编语言实现的。非常美妙的事情。当然，还可以用 qemu-user 学习 ARM、MIPS 和 PPC 汇编。特别推荐学习 MIPS 汇编，精简指令集，最优美的汇编语言。

结合上面的操作系统课程，特别推荐一门旧金山大学的课程：[CS630][13]，本来这个老师 (Allan B. Cruse) 是在 I386 真机上做实验的，笔者完善了 Makefile，然后就可以在 Qemu 上做实验：

* [CS630 汇编语言课程实验环境][14]。
* [Linux 下通过 Qemu 学习 X86 AT&T 汇编语言](http://tinylab.org/learn-x86-language-courses-on-the-ubuntu-qemu-cs630/)

分享一个趣事：笔者给 Cruse 老师分享了通过 Qemu 做实验的方法，他说这个 Online 学生不错，可以直接拿个 A ^-^。

> Hello, Falcon
>
> I'm amazed to receive your cs630-experiment-on-VM.  I think, as an online "student", you have earned an 'A' for this course!  I will let some Ubuntu-savvy students here know about what you've created, and we'll see if they find it to be a timesaver, as it ought to be.  Thanks for contributing these efforts to the class.
>

推荐两本书：

* ARM 汇编
    * 《ARM System Developers Guide: Designing and Optimizing System Software 》
* MIPS 汇编
    * 《See MIPS Run Linux》

而 X86 汇编，则不要错过刚介绍的 [CS630 课程][13] 以及 Allan B. Cruse 的 [个人主页][15]。再来两则资料：

* [Linux 汇编语言快速上手：4大架构一块学，包括32位和64位](http://tinylab.org/linux-assembly-language-quick-start/)
* [MIPS / Linux 汇编语言编程实例](http://tinylab.org/practical-mips-assembly-language-programming-in-linux/)

关于 CS630 Qemu Lab 以及 Linux Lab 中汇编语言例子的用法请参考：

* CS630 Qemu Lab 用法演示
    * [命令行演示](http://showterm.io/547ccaae139df14c3deec)
    * [视频演示](http://showdesk.io/1f06d49dfff081e9b54792436590d9f9/)
    * [获取即时在线实验帐号](https://weidian.com/i/1978159029)

* Linux Lab 各架构汇编例子用法演示
    * [命令行演示](http://showterm.io/0f0c2a6e754702a429269)
    * [获取即时在线实验帐号](https://weidian.com/i/1937753839)

### C 语言

就语言本身来说，她太有生命力了，而且现在以及可预知的将来，她还会保持独有的生命力。

语言本身是不是还在学谭老师的课程呢？建议还是要自学 C 语言作者的书：

* The C programming Language

然后，不要忘记把基础打扎实一些，下面几则内容可以作为日后学习和工作的持久参考书，最好是在大学阶段系统地阅读和实践一遍，会受益匪浅的：

* C Traps and Pitfalls
* C FAQ: [http://c-faq.com/][16]
* Advanced Unix Programming

特别推荐 Jserv 的大作[《深入淺出 Hello World》][17]，它揭示了“Linux 背後的層層布幕”，有一段这么写到：

> 許多充斥於開放資源的 Linux programming 文件常只敘及概念或技術細節，往往以照單全收卻沒有充分消化的結局作收。我們何嘗不能以「實驗」的心態去思考 "Hello World" 這種小規模應用程式在執行時期的微妙變化，此時再佐以網路上豐富的資料，不是更能享受醍醐灌頂的美妙嗎？

整个系列的 Slides 的原始存放位置已经无法访问，这里提供了备份：[Part-I][26]，[Part-II][27]，[Part-III][28]。

巧合地是，2008 年左右笔者也有过类似的心路历程，虽然跟前辈 Jserv 比起来只是咿呀学步，不过有兴趣的朋友也可以一同分享，目前已经整理成开源书籍：[《C 语言编程透视》][19]，正在持续校订和完善中。Jserv 前辈也参与了该书的修订并已经把该书作为大学补充教材：

> hi,
>
> 首先感謝將《C语言编程透视》一書開源，本人任教於台灣的大學，很希望拿這本好書當作補充教材，於是著手調整，很希望能夠符合 Linux x86_64 環境。我做了一點調整，請見: <https://github.com/jserv/open-c-book/tree/x86_64>
>
> 但涉及到 dynamic linking 的部分，實在有太多地方得修改。請問最近有改版的計畫嗎？
>
> Thanks,
> -jserv

再来一本 Jserv 老师引荐的书：[Computer Science from the Bottom Up](https://www.bottomupcs.com/)

上面忘记提 Gcc，Gdb 之类了。在 Linux 下面学习 C，离不开他们，当然还有编辑器 Vim + Cscope + Ctags，还有 Gprof, Gcov 等。

由于 [Linux Lab](http://tinylab.org/linux-lab) 提供了非常丰富的开发工具，因此也可以用 Linux Lab 来做 C 语言实验。

* [Linux 下 C 语言演示](http://showterm.io/a98435fb1b79b83954775)

### 脚本语言

学一两样脚本语言，对于平时的学习和工作会起到事半功倍的效果。

比如说要处理一些数据，可以用 Sed, Awk 加 Gnuplot ，这时 Shell 程序设计就非常重要。

关于 Shell，笔者有写过一本开源书籍 [《 Shell 编程范例》][20]，这本书以“面向对象”的方式系统地介绍了日常工作中需要操作的各类数值、逻辑值、字符串、文件、进程、文件系统等，很适合随时检索。

又比如，要做一些比较复杂的甚至带有图形的交互，这时可以用 Python，可以用一门非常漂亮的语言高效地实现一些案子，而且可以学习面向对象的思路。

* [Linux 下 Shell 语言演示](http://showterm.io/445cbf5541c926b19d4af)

### 编译原理

编译原理太重要了，了解 Turob c, Virtual studio C++ 背后的故事吗？很难吧，但是 Gnu Toolchains 可以。

从源代码编辑 (vim) 、预处理 (gcc -E, cpp) 、编译 (gcc -S)、汇编（gcc -c, as）、链接（gcc, ld）的整个过程可以看得一清二楚。

可以用 binutils 提供的一序列工具 readelf, objdump, objcopy, nm, ld, as 理解什么是可执行文件，可执行文件的结构是什么样的，它包含了哪些东西，那些所谓的代码段、数据段是如何组织的。

通过 objdump ，可以反汇编一个有趣的可执行文件，看看它背后的实现思路。还可以看看为了支持动态链接，可执行文件该怎么组织。

还可以进一步研究，一个程序执行时的细节，它怎么能够在屏幕上打印出来一个 "Hello, World!"，这需要什么样的支持，这个背后的硬件、操作系统以及应用程序做了什么样的工作？

另外，还可以去看这些 Gnu Toolchains 的源代码。如果觉得这个东西太庞大。也可以去阅读刚才提到的那个天才：法布里斯·贝拉，他写的 [TCC：Tiny C Compiler][22]，可以看到一个完整又小巧的 C 编译器是如何实现的。

对了，笔者同样有写一个相关的博客系列，即 [Linux 下 C 语言程序开发过程的视图](http://tinylab.org/the-c-programming-language-insight-publishing-version-0-01/)，后面有整理成开源书籍，即上面提到的[《C 语言编程透视》 ][19] 。

* [Linux 下 C 语言编译过程演示](http://showterm.io/887b5ee77e3f377035d01)

### 数据库

Mysql, PostgreSQL, SQLite? 在上学时，这些东西就很火，这么多年了，还是那么火。特别是那个小巧的 SQLite，Android 都在用了。而且她小巧，可以学习那些 SQL 语言背后具体是怎么实现的。

也许说企业级的 Oracle, SQLServer 很好用啊，是的，她们是浓妆艳抹的贵妇，高高在上，在有钱人的圈子里打转，不会投怀送抱的，永远没有机会摸透她们的心思。

* [Linux 下 SQL 演示](http://showterm.io/7766b67876c0b7615850e)

### 计算机网络

回到虚拟化，用 Qemu （当然，还有 VirtualBox 之类），理论上可以创建任意多台虚拟的计算机，搭建任意多种不同的网络服务，创建一个复杂的集群，想做网桥，还是想做 NAT，可以根据需要选……

### 文档撰写

各种学习总结过程中，离不开文档撰写，包括幻灯片、文章甚至图书出版，毕业后还可能涉及到简历制作。

这些统统可以用目前最流程也是最简约的 Markdown 来完成，它允许彻底摒弃繁杂的格式限制，更多地沉浸到内容的创作中。学会 Markdown 对于学习效率和专注力培养来说都会有好处。

推荐大家使用 [Markdown Lab][24] 来快速搭建文档撰写环境，已经内置精美的幻灯、文章、图书和简历模板，都可转为 pdf。

### 其他

几乎所有的课程，都可以找到开放的实践项目，下面有存放各类开放源代码的站点: 

* [Comparison of source code hosting facilities][23]

## 在线实验

实验环节往往是继续深入计算机课程的拦路虎。为了更快更高效地做实验，泰晓科技开发了一套开源的在线[实验云台](/cloud-lab)。

这套平台已逐步添加了包括汇编、C、Linux 0.11、Linux 等在内的实验环境，更多环境正在陆续开发中。欢迎提出更多想法、需求和建议。

* 项目首页：<http://tinylab.org/cloud-lab>
* 代码仓库：<https://github.com/tinyclub/cloud-lab>

有了 Cloud Lab，以往要花几周才能搭建的实验环境，现在几分钟就可以获得，实验环境从此不再成为我们学习计算机这类实操课程的阻力。

![泰晓实验云台](/wp-content/uploads/2017/09/tinylab.cloud.png)

## 演示视频

我们录制了几份课程的实验演示视频，欢迎自由观看：

* [CS630 Qemu Lab](http://tinylab.org/cs630-qemu-lab)：X86 Linux 汇编语言实验环境
    * [CS630 Qemu Lab 基本用法](http://showdesk.io/2017-03-18-15-21-20-cs630-qemu-lab-usage-00-03-33/)
    * [获取即时在线实验帐号](https://weidian.com/i/1978159029)

* [Linux 0.11 Lab](http://tinylab.org/linux-0.11-lab)： Linux 0.11 内核实验环境
    * [Linux 0.11 Lab 基本用法](http://showdesk.io/2017-03-18-17-54-23-linux-0.11-lab-usage-00-06-42/)
    * [为 Linux 0.11 添加系统调用](http://showterm.io/4b628301d2d45936a7f8a)
    * [获取即时在线实验帐号](https://weidian.com/i/1487448443)

* [Linux Lab](http://tinylab.org/linux-lab)：Linux 内核和嵌入式 Linux 实验环境
    * [Linux Lab 基本用法](http://showdesk.io/2017-03-11-14-16-15-linux-lab-usage-00-01-02/)
    * [通过 Linux Lab 做《奔跑吧 Linux 内核》实验](https://v.qq.com/x/page/y0543o6zlh5.html)
    * [通过 Linux Lab 做 Uboot 实验](https://v.qq.com/x/page/l0549rgi54e.html)
    * [获取即时在线实验帐号](https://weidian.com/i/1937753839)

* 其他
    * [C 语言](http://showterm.io/a98435fb1b79b83954775)
    * [C 编译过程](http://showterm.io/887b5ee77e3f377035d01)
    * [Shell 语言](http://showterm.io/445cbf5541c926b19d4af)
    * [SQL 语言](http://showterm.io/7766b67876c0b7615850e)
    * [获取即时在线实验帐号](https://weidian.com/i/1937753839)

## 小结

以上从多个方面分析了学习 Linux 相关开源技术的诸多益处。

潮流一点叫“社区化学习”，国际一点叫“Open, Free, Share”，国内一点叫“共赢”，传统一点叫“三人行，必有我师”。

欢迎添加微信（lzufalcon）进一步交流，添加时请务必注明准确原因。

如果觉得文章有帮助，也欢迎扫描如下二维码鼓励和支持我们。

 [1]: http://tinylab.org
 [2]: http://www.linkedin.com/
 [3]: http://www.linuxforu.com/2011/08/qemu-for-embedded-systems-development-part-3/
 [4]: /using-qemu-simulation-inserts-the-type-system-to-produce-the-whole-process/
 [5]: http://vger.kernel.org/vger-lists.html
 [6]: http://www.busybox.net/
 [7]: http://www.buildroot.org/
 [8]: http://www.linuxforu.com/2011/06/qemu-for-embedded-systems-development-part-1/
 [9]: http://www.linuxforu.com/2011/07/qemu-for-embedded-systems-development-part-2/
 [10]: https://github.com/tinyclub/linux-0.11-lab
 [11]: /take-5-minutes-to-build-linux-0-11-experiment-envrionment/
 [12]: http://tinylab.org/assembly/
 [13]: http://www.cs.usfca.edu/~cruse/cs630f06/
 [14]: /cs630-qemu-lab/
 [15]: http://www.cs.usfca.edu/~cruse/
 [16]: http://c-faq.com/
 [17]: http://blog.linux.org.tw/~jserv/archives/001844.html
 [19]: https://tinylab.gitbooks.io/cbook
 [20]: https://tinylab.gitbooks.io/shellbook
 [22]: http://bellard.org/tcc/
 [23]: https://en.wikipedia.org/wiki/Comparison_of_source_code_hosting_facilities
 [24]: http://tinylab.org/markdown-lab
 [26]: /wp-content/uploads/hacking-helloworld/HackingHelloWorld-PartI-2007-03-25.pdf
 [27]: /wp-content/uploads/hacking-helloworld/HackingHelloWorld-PartII-2007-03-25.pdf
 [28]: /wp-content/uploads/hacking-helloworld/HackingHelloWorld-PartIII-2007-03-25.pdf
 [30]: http://vger.kernel.org/vger-lists.html
 [31]: https://patchwork.kernel.org/
 [32]: https://github.com/
