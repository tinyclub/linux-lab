---
title: 'Oscilloscope: 用软件示波器实时渲染数据流'
author: Wu Zhangjin
layout: post
permalink: /oscilloscope-realtime-rendering-software-oscilloscope-data-streams/
tags:
  - cpu调频
  - cpufreq
  - Linux
  - performance tuning
  - rt-tests
  - Software Digital Oscilloscope
  - tuna
  - 功耗优化
categories:
  - 功耗优化
  - Oscilloscope
  - TinyDraw
---

> by falcon of [TinyLab.org][2]
> 2014/03/16


## 前言

人的左脑和右脑分别负责逻辑思维和形象思维。很早以前我们就在不断地训练这两种思维能力，它们各自有自己擅长的方向，是互补的。

还记得初中时候刚开始学习方程求解，比如说要求一个“圆”和一条“直线”的切点，如果要直接去计算方程式，演算过程会比较枯燥乏味，甚至是浪费时间，如果把这个方程转换为圆和直线绘制在纸上，那个切点一眼就能看出来。也就是说，在类似这种情况下，形象思维很凑效。

类似地，在现实生活和工作中，我们会非常多这样的例子，比如说我们要找出某些统计数据背后的逻辑关系，可以单纯地统计数字排序，也可以把这些数字转变为诸如直方图之类的展示出来，这些数字的差异和关系就很容易呈现出来。我们在 [Measure and Draw the Boot-up Time of Linux Kernel][3] 一文举了个非常经典的例子，那就是把一些事件的时间属性呈现出来，找出最费时间的部分，这样就可以用来做性能优化，在这篇文章中主要是介绍如何优化 Linux 系统的开机启动时间，并介绍了如何用我们的 [histogram.sh][4] 工具用直方图的形式把所有内核 initcalls 的时间开销直观地展示出来，进而辅助工程师高效地优化 Linux 启动速度。

上面的例子里头的数据统计结果是静态的，是在事后展现出来。如果关心事件的实时进展，甚至想获取事件发生时的后台详细场景，那么实时渲染数据流就很重要。比如说，我们的硬件示波器，可以抓取一些电流、电压的波形（实际上就是数据流，即不断变化的数据），并且允许在某些波形或者数据点发生时触发背景数据的采集。类似地，我们有软件示波器，软件示波器可以用来渲染各种类型的数据，不受硬件因素制约，有的软件示波器还提供类似硬件示波器的 trigger 功能。

## Oscilloscope 简介

我们这里介绍一款非常轻量级的软件示波器：Oscilloscope。

这款示波器源自 [Linux 实时抢占项目][5] ，具体地，它来自 [Tuna][6] 。这个工具可以用来渲染 [rt-tests][7] 测量的系统延迟 (Latency) 数据，并在达到预设的最大延迟 (Latency) 时 dump 出后台的 [Ftrace][8] 跟踪结果，从而辅助定位引起系统延迟的原因，引导开发人员进行实时系统优化。

## oscilloscope 改造

实际上 oscilloscope 可以用来渲染其他的数据流，比如说温度、湿度、电流、电压、 cpu 频率、系统负载、空闲内存，诸如此类，并且很容易通过它扩展到：在某些关键数据点采集系统后台的其他信息，所以我把它从 tuna 项目源码中独立出来，抽象出了一个简单的 [oscope/oscilloscope.py][9] 命令，放在我们的 [tinydraw][10] 项目中，无需安装，可以直接使用。

具体的改造细节请参考：[oscope/oscilloscope.change.log.txt][11]。

## oscilloscope 用法

先 clone 项目源码：

<pre>$ git clone https://github.com/tinyclub/tinydraw.git
</pre>

接着安装它依赖的 python 绘图库：

<pre>$ sudo apt-get install python-matplotlib
</pre>

然后阅读 [oscope/README.md][12] 获取详细用法。

这里简单举几个例子：

  * 实时渲染系统延迟

<pre>$ sudo apt-get install rt-tests
$ sudo cyclictest -p99 -v | oscope/oscilloscope.py
</pre>

【注】oscilloscope.py 默认处理数据的分割符是“:”，默认处理的数据是第 3 列，这是因为 cyclictest 默认输出结果就是这样的，如果数据格式不同，可以用`-d`指定分割符，用`-f`指定需要处理的数据列。

  * 实时渲染空闲内存情况

可以直接类似上面用 `|` 管道，也可以创建一个 fifo 文件：

<pre>$ mkfifo /tmp/free_mem_size
$ while :; do cat /proc/meminfo \
        | sed -n -s '/MemFree/s/[^0-9]*\([0-9]*\).*/\1/p'; sleep 0.1; done \
        > /tmp/free_mem_size &#038;
</pre>

然后，实时绘制：

<pre>$ cat /tmp/free_mem_size | ./oscope/oscilloscope.py -f0
</pre>

  * 实时渲染 cpu 频率变化

 Ubuntu 系统默认的 cpufreq governor 是 ondemand ，为了更好地看到效果，我们先替换成 conservative governor 。

<pre>$ sudo -s
$ echo conservative > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
</pre>

接着，用 oscilloscope 来实时观察 cpu 频率的变化，因为不清楚 cpufreq 调频的频率，我们暂且估计是 50ms ，也就是说 50ms 采样一次：

<pre>$ while :; do cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq; sleep 0.05; done | ./oscope/oscilloscope.py -f0 -M 0.001 -t r-o -m 2500
</pre>

【注】上面的 `-M 0.001` 表示对所有输入的数据乘以 0.001 然后进行绘制，这里是为了去掉冗余的 0 ，把 cpu 频率数据单位变成 M 。而 `-t r-o` 是为了把采样点更醒目地用圆点区分开来。 `-m 2500` 用来表示允许最大频率到 2500M 。

## oscilloscope 演示截图

这里是上面的 cpu 频率数据流的绘制结果：

![image][13]

## 小结

oscilloscope 给我们提供了一种自由渲染数据的方式，它可以很友好地把一些问题转化为直观的图形和图像，并能够对数据做一个初步的分析，比如说自动计算最大值、最小值还有平均值。

这个具体到嵌入式系统里头，则可以很好地用于辅助系统功耗、温度、性能等的优化。

 [2]: http://tinylab.org
 [3]: /measure-and-draw-the-boot-up-time-of-linux-kernel/
 [4]: https://github.com/tinyclub/tinydraw/raw/master/histogram/histogram.sh
 [5]: https://rt.wiki.kernel.org/
 [6]: https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_MRG/1.3/html/Tuna_User_Guide/
 [7]: https://rt.wiki.kernel.org/index.php/Cyclictest
 [8]: http://elinux.org/Ftrace
 [9]: https://github.com/tinyclub/tinydraw/raw/master/oscope/oscilloscope.py
 [10]: /tinydraw/
 [11]: https://github.com/tinyclub/tinydraw/raw/master/oscope/oscilloscope.change.log.txt
 [12]: https://github.com/tinyclub/tinydraw/raw/master/oscope/README.md
 [13]: /wp-content/uploads/2014/03/oscolloscope-cpufreq-conservative-governor.png
