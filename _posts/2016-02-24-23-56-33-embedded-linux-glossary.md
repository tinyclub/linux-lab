---
layout: post
author: 'Lin Jinhui'
title: "嵌入式 Linux 词汇表"
album: "嵌入式 Linux 知识库"
group: translation
permalink: /embedded-linux-glossary/
description: "本文介绍嵌入式 Linux 中使用的术语表，并列出本书中其它的术语表章节"
category:
  - Linux 综合知识
tags:
  - Linux
  - 术语
---

> 书籍：[嵌入式 Linux 知识库](https://tinylab.gitbooks.io/elinux)
> 原文: [eLinux.org](http://eLinux.org/Glossary "http://eLinux.org/Glossary")
> 翻译：[@mintisan](https://github.com/mintisan)
> 校订：[@lzufalcon](https://github.com/lzufalcon)

## 高频主题术语表

以下是特定技术领域的一些术语表：

-   [启动时间](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Boot_Time/Boot-up_Time_Definition_Of_Terms/Boot-up_Time_Definition_Of_Terms.html "Boot-up Time Definition Of Terms")
    - Linux 启动过程涉及的相关术语
-   [电源管理](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Glossary/Power_Management_Definition_Of_Terms/Power_Management_Definition_Of_Terms.html "Power Management Definition Of Terms")
    - CELF 电源管理工作组术语定义
-   [实时性](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Glossary/Real_Time_Terms/Real_Time_Terms.html "Real Time Terms") - 系统实时性能相关术语
-   [安全](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Glossary/Security_Terms/Security_Terms.html "Security Terms") - Linux 安全及安全架构相关术语

<table>
<thead>
<tr class="header">
<th align="left"> 目录 </th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td align="left"><a href="#A">A</a> <a href="#B">B</a> <a href="#C">C</a> <a href="#D">D</a> <a href="#E">E</a> <a href="#F">F</a> <a href="#G">G</a> <a href="#H">H</a> <a href="#I">I</a> <a href="#J">J</a> <a href="#K">K</a> <a href="#L">L</a> <a href="#M">M</a> <a href="#N">N</a> <a href="#O">O</a> <a href="#P">P</a> <a href="#Q">Q</a> <a href="#R">R</a> <a href="#S">S</a> <a href="#T">T</a> <a href="#U">U</a> <a href="#V">V</a> <a href="#W">W</a> <a href="#X">X</a> <a href="#Y">Y</a> <a href="#Z">Z</a> <br /></td>
</tr>
</tbody>
</table>

## A

**Abatron **
[Abatron](http://www.abatron.ch/) 是一家瑞士厂商，他们生产市场流行的 JTAG 调试器，这些调试器常用于调试嵌入式 Linux 系统。他们的主要产品是 `BDIx000` 系列的 JTAG 调试器。


**异步 I/O （Asynchronous I/O）**
在启动 I/O 之后即回到主程序中，而非等到功能 I/O 完成。此时，I/O 传输和处理器同时并行工作，在 I/O 操作的同时也在执行主程序流程，而非阻塞等待其完成。

## B

**板子（Board）**
当我们在说开发板，一般是在说带有嵌入式 Linux 操作系统的硬件设备，它其实是一块印刷电路板。我们有时也叫它开发板或者评估板。

**阻塞 I/O（Blocked I/O）**
直到 I/O 所有的数据请求完成之后才返回程序控制权的方式。这种方式下，I/O 传输与处理器串行执行。

**板级支持包（BSP）**
其实就是用于支持特定硬件板的代码，这个术语一般用于指代代码，而不能见名知义地当作一个具体的“包”。它通常指适用于某块特定板子的所有特定软件，包括内核代码、用户代码等等。

## C

**交叉编译器（Cross-compiler）**
交叉编译器是指，一个运行在某个平台上的编译器，它通过配置后有能力为另外一个平台或者多个其他平台生成代码。

**交叉编译过程（Cross-compilation）**
交叉编译是指，通过交叉编译器编译代码，代码针对另外一个平台，而不是执行编译的平台本身。

## D

## E

**嵌入式 Linux 会议（ELC）**
这是每年为嵌入式 Linux 开发者准备的主要技术会议之一。参考[事件](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Events/Events.html "Events") 一节可以看到历年事件的资料。

**嵌入式（Embedded）**
“嵌入式”设备通常意味着该设备独立于其他附带的软硬件特性，具有固定的功能。该术语多少有些含糊不清，它是相对于通用功能而言的，意味着专用。需要提到的是，移动手机虽然现在支持各种通用程序和功能，但是也被当作嵌入式设备。典型的嵌入式 Linux 产品包括数字相机、路由器、电视机与机顶盒以及非消费类的嵌入式设备，像传感器、工控设备以及除桌面和服务器市场外所有运行 Linux的设备。详情请看[维基百科嵌入式入门指南](http://en.wikipedia.org/wiki/Embedded_system)。

## F

**文件系统（File system）**
操作系统用来管理磁盘分区的一套方法和数据结构，也就是磁盘组织文件的方式。有时也指用于存储文件或者文件系统类型的分区或者磁盘。

## G

## H

**主机（Host）**
主机或者宿主机是指软件开发者具体为他们的产品编写和编译软件时所用的机器。在主机－目标机环境中，主机用来开发软件，目标机用来运行主机开发出来的软件。

## I

**知识产权模块（IP 核）**
IP 核是指芯片上某个执行不同功能的集成电路的一部分，IP 核代表“知识产权”，它被开发或者授权，然后才能集成到系统的 SOC 或者某些其他芯片中。这个核作为一个单元被授权和操作，这个单元需要用诸如 Verilog 这样的硬件描述语言来表达出一个准确定义的线路。因为相同的 IP 核可能用在多种芯片上（并且通常是来自不同公司的芯片），所以为系统上某个 IP 核所写的驱动也常能够（添加少许修改就可以）在其他使用了相同 IP 核的系统上工作。在当代处理器上常见的 IP 块有视频控制器、 UART (串行端口)、 总线控制器和网络接口 (有线和无线)，而这些只是冰山一角。

## J

[**JTAG**](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Glossary/JTAG/JTAG.html "JTAG")
"Joint Test Action Group" 的缩写, JTAG 是一种调试接口，用于在嵌入式开发板上验证硬件和调试软件。 详见 [JTAG](http://tinylab.gitbooks.io/elinux/content/zh/dev_portals/Glossary/JTAG/JTAG.html "JTAG")

## K

**内核（Kernel）**

Linux 内核是 Linux 系统的核心软件，它负责与硬件打交道，代表进程管理资源，也负责协调进程与硬件之间以及不同进程间的交互。

## L

## M

## N

**非阻塞 I/O （Non-blocking I/O）**
在启动 I/O 进程之后即返回控制权到调用程序，而且是在 I/O 完成之前。I/O 传输与处理器工作可并行执行，也就是说，I/O 操作执行之时，用户程序可不受影响地持续运行。即异步 I/O。

**非易失性存储（Non-volatile storage）**
(NVS, 非易失性存储，也称持久性储存) ，此术语描述的是这样一个存储设备，即使掉了电它的内容也会保留。存储器使用磁介质（例如磁盘，磁带或者泡沫内存）通常是天然具有非易失性，然后半导体内存（静态内存，特别是动态内存）通常是易失的但是在永久地接上一个（可反复充电的）电池后，就可以作成非易失性的存储器了。

## O

## P

**物理层（PHY）**
物理层（Physical Layer）的缩写。物理层通常指代在一个芯片或者主板上实现了网络功能的硬件电路。有时候，物理层是单独的芯片实现的，但是更一般的是指 SoC 上的网络设备或者接口模块。详见 [http://en.wikipedia.org/wiki/PHY\_(chip)](http://en.wikipedia.org/wiki/PHY_(chip))

## Q

## R

**基于内存的文件系统（RAM-based file system）**
作为存储介质，在易失性 RAM 上构建的文件系统。

## S

**片上系统（SOC）**
片上系统是指单一集成电路上包含一个几乎完整系统的芯片，它可能会有多种 IP 核，这些 IP 核实现不同的硬件功能，除了系统主 CPU 以外，如串口、网口、总线和视频控制器。一般读作 "ess-oh-see"  或者  "sock"。详见 [http://en.wikipedia.org/wiki/System\_on\_a\_chip](http://en.wikipedia.org/wiki/System_on_a_chip)



**同步 I/O （Synchronous I/O）**
直到所有的数据请求传输后才返回控制权到调用程序本身，I/O 传输与处理器工作串行执行。即阻塞 I/O 。

## T

**目标板（Target）**
目标板是执行所开发软件的设备或者环境。它可能是开发板，真实的产品或者仿真器。一般而言，开发者在主机上开发完软件之后需要到目标板上测试，调试和部署。

**工具链（Toolchain）**
工具链是一整套为嵌入式设备构建软件的程序，具体来说，它指代编译器和连接器。但是它也可能是其他特定于某个特别架构或者 CPU 的其他程序，例如调试器，分析器和与目标软件配合使用的其他工具。

## U

## V

## W

## X

## Y

## Z
