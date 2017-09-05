---
title: 为什么计算机的学生要学习 Linux 开源技术
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
---

> by falcon of [TinyLab.org][1]
> 2013/08/25

Linux 开源相关技术对于学生来说，特别是计算机专业的学生来说，非常重要，下面就几个方面进行讨论：

## 研究平台

因为开源的优势，有非常多的开放的文案可以参考，有很多有趣的点子可以拿来做深入的研究。任何一个点挖进去都是一片天地。

## 专业视野

通过那些开放的项目，可以通过邮件列表、[Linkedin][2]、Google Group 接触到来自全球各地的天才，不仅可以提升英文读写能力，认识国际友人，还可以把握领域前沿，甚至还有机会得到大佬们的指点迷津。

## 工作机会

就像 2004 年左右，自己在学校毅然而然地选择转到 Linux 平台一样，现在有同样的预感， Linux 以及相关的开源技术因为它包含人类共赢 (Open, Free, Share) 的 **大同** 理念，融合了全球众多企业和天才的智慧，以及它不断更新换代地自我革新，她将持续繁荣下去。

目前的 Linux 人才看似很多，刚从学校毕业没什么编码经验的学生也可以很快写个小驱动，看似门槛很低，但是真正能够从系统层面解决问题，做了工作不用别人搽屁股的高端人才很少。如果从大学开始抓取，毕业的时候就比其他同学多了四年的使用经验和思维培养。对于后续的研究和工作来说，都会是非常重要的竞争力。

## 课程实践

几乎从硬件到软件， Linux 平台能够提供从下而上的所有触及“灵魂”的学习案例，让所有课程从纸上谈兵转变成沙场实战，会极大地提升工程实践的效率和技能。

### 硬件方面

硬件模拟已经是趋势，不可阻挡。包括处理器模拟、系统模拟，大名鼎鼎的 Qemu ，以及它的伟大的派生者： Android Emulator 提供了易用的案例，支持四大，不是律师事务所，是 ARM, X86, PPC 以及 MIPS 。这东西不仅能够模拟处理器指令，还支持系统级（各种外设）的模拟，还支持直接在一个架构上执行另一个架构的可执行文件（通过 qemu-user-static 翻译）。有了它，不用花钱买开发板，有了它，可以研究如何模拟设计和实现一个硬件系统，一套处理器指令，还可以研究虚拟化技术，虚拟化集群。

跟 GNU 序列工具的开创者 Stallman 以及 Linux 的开创者 Linus 一样， Qemu 的开创者也是一个伟大的先驱，看看他的简介和个人主页吧： <http://bellard.org/> ，以及那个用 Javascript 写的可以直接通过浏览器跑 Linux 的模拟器吧： <http://bellard.org/jslinux/> 

>  法布里斯·贝拉   是一位法国著名的计算机程序员，因 FFmpeg 、 QEMU 等项目而闻名业内。他也是最快圆周率算法贝拉公式、 TCCBOOT 和 TCC 等项目的作者。 1972 年生于法国 Grenoble 。在高中就读期间开发了著名的可执行压缩程序 LZEXE ，这是当年 DOS 上第一个广泛使用的文件压缩程序。

接触开源，有机会了解和认识这些疯狂的前辈，这无疑是一件非常励志和让人血脉贲张的趣事。

### 引导程序/BIOS

大学时学习了 BIOS ，基本输入输出系统，是个啥玩意，感觉得到，看得到面纱，看不到她真实的样子。但是有了 [Uboot](http://www.denx.de/wiki/U-Boot) ，可以。

可以直接在 Qemu 里头做 Uboot 的实验 [Using QEMU for Embedded Systems Development, Part 3][3]  或者 [利用 qemu 模拟嵌入式系统制作全过程][4] 

### 操作系统

Linux 本身绝大部分都是 Open 的，操作系统课程如果在上课的同时能够读一读 Linux 0.11 的源代码： <http://oldlinux.org/> ，会发现操作系统不是干巴巴的电梯调度算法之类算法描述。可以看到实实在在的活生生的场景，可以说话的场景。

什么调度算法，什么同步机制，什么中断管理，什么文件系统，什么各类外设的驱动等等，通通可以看到源代码实现并允许亲自去修改，调试和完善，甚至可以通过 [ 邮件列表 ][5] 提交 Patch 到官方 Linux 社区，然后有机会接触 Linux 社区的那些印象中“神一般”现实里“平易近人”的大佬们。

还可以自己制作一个完整的操作系统。看看 Building Embedded Linux System 这本书 ,  从 Linux 官方社区 : <http://www.kernel.org> 下载一份源代码，编译一下，然后用 [Busybox][6] ， [Buildroot][7] 、 LFS 或者 Openembedded 制作自己的文件系统，然后就是一个完整的操作系统。然后会知道什么是一个完整的操作系统，什么仅仅是一个操作系统 Kernel 。然后会了解，用户交互的界面，除了 GUI ，其实它最最本质的东西还是 Shell Terminator ， GUI 只是换上了一袭花衣裳。会真正地理解，当按下一个键盘上的按键的时候，这个背后发生了什么样的故事和演变。作为计算机的学生，不应该被这些蒙在鼓里，应该掀开那袭花衣裳，打探背后的细枝末节，然后，等到哪一天，闭上眼睛，当整个故事情节在脑海里像放电影一样清晰不再模糊的时候，就如偿所愿了，那种美妙的滋味在出现 Bug 需要解决的时候会得到印证。

做这些实验，根本不需要买开发板，Qemu就绰绰有余了，可以参考：

  * [Using QEMU for Embedded Systems Development, Part 1][8]
  * [Using QEMU for Embedded Systems Development, Part 2][9]

如果想看 Linux 0.11 的源代码，可以到 <http://oldlinux.org/> 下载开放的书籍和源代码，在 Ubuntu 下用 Qemu 做实验就好了。记得下载可以在 Ubuntu 下用最新编译器编译的 Linux 0.11 代码： [https://github.com/tinyclub/linux-0.11-lab.git][10] 以及这里的 [五分钟 Linux 0.11 实验环境使用指南][11] 。

如果想研究最新的 Linux 内核，则可以使用 [Linux Lab](http://tinylab.org/linux-lab)。利用它可以通过 Docker 一键搭建一个集成的 Linux 内核的实验环境，通过 Qemu 支持上百款免费的开发板，集成了交叉编译环境、Buildroot，Uboot 等嵌入式 Linux 开发的必备工具，支持串口和图形启动，支持在线调试，可通过 Web 远程访问。

### 汇编语言

估计学校还在用王老师的书吧，这个是大二时写的[《汇编语言 王爽著》课后实验参考答案][12]。

Share 在这里是非常想强调实践的重要性，不知道有几个同学认真地做完了所有或者绝大部分大学计算机课程课后的实验，实验真地非常重要。另外一个原因是，真地希望大家能够在 Linux 平台下学 X86 的汇编，用 gas 汇编器，用 AT&T 的语法，用 gcc 看 C 语言写的东西是怎么用汇编语言实现的。非常美妙的事情。当然，还可以用 qemu-user-static 跑一个 debootstrap 制作的 Debian for ARM, MIPS or PPC ，学习 ARM ， MIPS 和 PPC 汇编。特别推荐学习 MIPS 汇编，精简指令集，最优美的纯天然的汇编语言。

结合上面的操作系统课程，特别推荐一个国外的貌似是旧金山大学的课程，叫 [CS630][13] ，本来这个老师 (Allan B. Cruse) 是在 I386 真机上做实验的，鄙人完善了他的 Makefile ，然后直接在 Qemu 上做实验。分享一个趣事：鄙人给那个老师分享了在 Qemu 上做实验的方法，人家说这个学生不错，可以直接给个 A 了，呵呵。具体用法和源代码请参考： [Learn CS630 on Qemu in Ubuntu][14] 。

BTW：上面 Linux 0.11 的课程，为了可以直接用现在流行的标准 gas 和 gcc ，那个 boot 引导的 16bit 汇编代码有用 AT&T 重写。

如果想学 ARM 汇编：推荐《ARM System Developers Guide: Designing and Optimizing System Software 》，如果想学 MIPS 汇编 :  推荐《See MIPS Run Linux》

如果想学 X86 汇编，不要错过那个 [CS630 课程][13] 以及 Allan B. Cruse 的 [个人主页][15] ，有蛮多相关的资料。

如果要在 Linux 下快速上手四大架构的汇编语言，在下载 [Linux Lab](http://tinylab.org/linux-lab) 后，可以从 [examples/assembly](https://github.com/tinyclub/linux-lab/tree/master/examples/assembly) 找到 32 位和 64 位的汇编语言例子。这篇文章：[Linux 汇编语言快速上手：4大架构一块学](http://tinylab.org/linux-assembly-language-quick-start/) 对此进行了详细的介绍。

### C 语言

就语言本身来说，她太有生命力了，而且现在以及可以预知的未来，她还会保持她独有的生命力。

语言本身是不是还在学谭老师的课程呢？建议还是要自学 C 语言作者的书：

The C programming Language

然后，不要忘记把基础打扎实一下，下面几个内容基本可以作为日后学习和工作的持久参考书，最好是在大学阶段系统地全部阅读和实践一遍，会受益匪浅的：

C Traps and Pitfalls

C FAQ: [http://c-faq.com/][16]

Advanced Unix Programming

特别推荐 Jserv 黄的大作[《深入淺出 Hello World》][17]，它揭示了“Linux 背後的層層布幕”，他在博客里面提到：

> 許多充斥於開放資源的 Linux programming 文件常只敘及概念或技術細節，往往以照單全收卻沒有充分消化的結局作收。我們何嘗不能以「實驗」的心態去思考 "Hello World" 這種小規模應用程式在執行時期的微妙變化，此時再佐以網路上豐富的資料，不是更能享受醍醐灌頂的美妙嗎？

整个系列的 slides 的原始存放位置已经无法访问，大家也可以从这里下载：[Part-I](http://www.kernelchina.org/files/HackingHelloWorld-PartI-2007-03-25.pdf)，[Part-II](http://www.kernelchina.org/files/HackingHelloWorld-PartII-2007-03-25.pdf)，[Part-III](http://www.kernelchina.org/files/HackingHelloWorld-PartIII-2007-03-25.pdf)。

巧合地是，在 2008 年左右也有过类似的心路历程，虽然跟前辈 Jserv 比起来只是咿呀学步，不过有兴趣的朋友也可以一同分享，目前已经整理成开源书籍：[《C 语言编程透视（开源书籍）》][19]，目前只是 0.2 版，正在持续校订中。

忘记提 gcc ， gdb 之类了。在 Linux 下面学习 C ，离不开他们，当然还有编辑器 vim+cscope+ctags ，还有 gprof, gcov 等。

### 脚本语言

学一两样脚本语言，对于平时的学习和工作会起到事半功倍的效果。

比如说要处理一些数据，可以用 sed, awk 加 gnuplot ，这个时候 Shell 程序设计就非常重要。关于 Shell ，有写过一个 [《 Shell 编程范例》][20] 。

又比如，要做一些比较复杂的甚至带有图形的交互，这个时候可以用 Python ，可以高效地实现一些案子，而且可以学习面向对象的思路。

### 编译原理

编译原理太重要了，了解 turob c, virtual studio C++ 背后的故事吗？很难吧，但是 gnu toolchains 可以。

从源代码编辑 (vim) 、预处理 (Gcc -E, cpp) 、汇编（as）、编译 (gcc -c) 、链接（gcc, ld）的整个过程可以看得一清二楚。可以用 binutils 提供的一序列工具 readelf, objdump, objcopy, nm, ld, as 理解什么是可执行文件，可执行文件的结构是什么样的，它包含了哪些东西，那些所谓的代码段、数据段是如何组织的。通过 objdump ，可以反汇编一个有趣的可执行文件，看看它背后的实现思路。还可以看看为了支持动态链接，可执行文件该怎么组织。还可以了解，一个程序执行时的细节，它怎么能够在屏幕上打印出来一个 "Hello, World!"，这需要什么样的支持，这个背后的硬件、操作系统以及应用程序做了什么样的工作？

另外，还可以去看 gnu toolchains 的源代码。如果觉得这个东西太庞大。也可以去阅读刚才提到的那个天才：法布里斯·贝拉，他写的 [TCC ： Tiny C Compiler][22] ，可以看到一个完整的小巧的 C 编译器是如何实现的。

对了，相关的方面，有写一个序列的 Blog： Linux 下 C 语言程序开发过的程视图，后面整理成了开源书籍，即上面提到的： [《 C 语言编程透视（开源书籍）》 ][19] 。

### 数据库

Mysql, PostgreSQL, SQLite?  在上学时，这些东西就很火，这么多年了，还是那么火。特别是那个小巧的 SQLite， Android 都在用了。而且她小巧，可以学习那些 SQL 语言背后具体是怎么实现的。

也许说企业级的 Oracle, SQLServer 很好用啊，是的，她们是浓妆艳抹的贵妇，高高在上，在有钱人的圈子里打转，不会投怀送抱的，永远没有机会摸透她们的心思。

### 计算机网络

回到虚拟化，用 Qemu （当然，还有 VirtualBox 之类），理论上可以创建任意多台虚拟的计算机，搭建任意多种不同的网络服务，创建一个复杂的集群，想做网桥，还是想做 NAT 可以选……

### 文档撰写

各种学习总结过程中，离不开文档撰写，包括幻灯片、文章甚至图书出版，毕业后还可能涉及到简历制作。这些统统可以用目前最流程也是最简约的 Markdown 来完成，它允许彻底摒弃繁杂的格式限制，更多地沉浸到内容的创作中。学会 Markdown 对于学习效率和专注力培养来说都会有好处。推荐大家使用 [Markdown Lab][24] 来快速搭建文档撰写环境，已经内置精美的幻灯、文章、图书和简历模板，都可转为 pdf。

### 其他

几乎所有的课程，都可以找到开放的实践项目，看: [20 Source Code Hosting Sites You Should Know][23]

## 在线实验和演示视频

为了更快更高效地做相关实验，泰晓科技开发了一套实验云台，这套平台已逐步添加了包括汇编、C、Linux 0.11、Linux等在内的实验环境，更多实验环境正在陆续开发中。欢迎添加微信（lzufalcon）进行讨论和交流。

* 实验云台：<http://tinylab.cloud:6080>
* 演示视频：<http://showdesk.io>
* 购买帐号：<http://weidian.com/?userid=335178200>

购买帐号后通过浏览器登陆[实验云台](http://tinylab.cloud:6080)即可进行相应的实验，以往要花几周才能搭建的实验环境，现在几分钟就可以获得，实验环境从此不再成为我们学习计算机这类实操课程的阻力。

[![泰晓实验云台](/wp-content/uploads/2017/09/tinylab.cloud.png)](http://tinylab.cloud:6080)

## 小结

以上从多个方面分析了学习 Linux 开源技术的诸多益处。潮流一点叫“社区化学习”，国际一点叫“Open, Free, Share”，国内一点叫“共赢”，传统一点叫“三人行，必有我师”。

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
 [18]: https://github.com/shuopensourcecommunity/Information/tree/master/Resources/201203HackingHelloWold-%E6%B4%BB%E5%8A%A8/HackingHelloWorld
 [19]: https://gitbook.com/book/tinylab/cbook
 [20]: https://gitbook.com/book/tinylab/shellbook
 [22]: http://bellard.org/tcc/
 [23]: http://www.brenelz.com/blog/20-source-code-hosting-sites-you-should-know/
 [24]: http://tinylab.org/markdown-lab
