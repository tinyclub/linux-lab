---
title: 'Linux 数据渲染套件'
tagline: 含数字示波器 Oscilloscope 等工具，可辅助系统优化
author: Wu Zhangjin
layout: page
permalink: /tinydraw/
recommend: false
description: 收集/开发各类 Linux 下的数据渲染工具。
update: 2015-10-1
categories:
  - 开源项目
tags:
  - TinyDraw
  - Linux
  - 数据渲染
  - Oscilloscope
---

## Introduction

This project aims to collects tools for drawing The Data.

Data is often organized in strings, which is not that Intuitively.

To show the data more friendly, we often need to draw the data in a graph.

Different data need different tools, this project aims to collect or develop  
such tools.

  * Git Repository: [https://github.com/tinyclub/tinydraw.git][1]

## Tools developed by TinyLab.org

  * [oscope][2] A digital oscilloscope, dramatize the data flow real time

> This is based on the oscilloscope and tuna: <http://git.kernel.org/?p=utils/tuna/tuna.git;a=summary>

  * [histogram.sh][3] draws the &#8220;two row data&#8221; in SVG with histogram

> This tool derives from [(Linux)/scripts/bootgraph.pl][4] and [FlameGraph][5].

See an example output, you can [open it][6] to get an interactive view.

![linux-boot-histogram.svg][6]

## Tools Collected From Internet

  * [gnuplot][7] can convert the data to a static graph.

> Gnuplot is a portable command-line driven graphing utility for Linux, OS/2,  
> MS Windows, OSX, VMS, and many other platforms. The source code is  
> copyrighted but freely distributed (i.e., you don&#8217;t have to pay for it). It  
> was originally created to allow scientists and students to visualize  
> mathematical functions and data interactively, but has grown to support many  
> non-interactive uses such as web scripting. It is also used as a plotting  
> engine by third-party applications like Octave. Gnuplot has been supported  
> and under active development since 1986.

  * [systrace][8] exports [Ftrace][9] output to an interactive HTML report with AJAX feature.

> The Systrace tool helps analyze the performance of your application by  
> capturing and displaying execution times of your applications processes and  
> other Android system processes. The tool combines data from the Android  
> kernel such as the CPU scheduler, disk activity, and application threads to  
> generate an HTML report that shows an overall picture of an Android device’s  
> system processes for a given period of time.

  * [FlameGraph][10] is able to draw a large number of the function call trees and the profiling data in a single SVG.

> Flame graphs are a visualization of profiled software, allowing the most  
> frequent code-paths to be identified quickly and accurately. They can be  
> generated using my Perl programs on  
> <https://github.com/brendangregg/FlameGraph>, which create interactive SVGs.

  * [Gprof2Dot][11] converts the output from many profilers into a dot graph.

> It supports many profilers: prof, gprof, VTune Amplifier XE, linux perf,  
> oprofile, Valgrind&#8217;s callgrind tool, sysprof, xperf, Very Sleepy, AQtime,  
> python profilers, Java&#8217;s HPROF; prunes nodes and edges below a certain  
> threshold; uses an heuristic to propagate time inside mutually recursive  
> functions; uses color efficiently to draw attention to hot-spots; works on  
> any platform where Python and graphviz is available, i.e, virtually anywhere.

  * [VnstatSVG][12] converts the vnStat output (network traffic data) to AJAX output.

> vnStatSVG is a lightweight AJAX based web front-end for network traffic  
> monitoring; To use it, its backend [vnStat][13] must be  
> installed at first; It only requires a CGI-supported http server but also  
> generates a graphic report with SVG output, vnStatSVG is friendly to generic  
> Linux hosts, servers, embedded Linux systems and even Linux clusters.

  * [AnalyzeSuspend][14] a tool for system developers to visualize the activity between suspend and resume

> The Suspend/Resume project provides a tool for system developers to visualize the activity between suspend and resume, allowing them to identify inefficiencies and bottlenecks. The use of Suspend/Resume is an excellent way to save power in Linux platforms, whether in Intel® based mobile devices or large-scale server farms. Optimizing the performance of suspend/resume has become extremely important because the more time spent entering and exiting low power modes, the less the system can be in use.




 [1]: https://github.com/tinyclub/tinydraw
 [2]: https://github.com/tinyclub/tinydraw/raw/master/oscope/oscilloscope.py
 [3]: https://github.com/tinyclub/tinydraw/raw/master/histogram/histogram.sh
 [4]: http://stuff.mit.edu/afs/sipb/contrib/linux/scripts/bootgraph.pl
 [5]: https://github.com/brendangregg/FlameGraph
 [6]: /wp-content/uploads/2014/01/boot-initcall.svg
 [7]: http://www.gnuplot.info/
 [8]: http://developer.android.com/tools/help/systrace.html
 [9]: http://lwn.net/Articles/365835/
 [10]: http://www.brendangregg.com/flamegraphs.html
 [11]: https://code.google.com/p/jrfonseca/wiki/Gprof2Dot
 [12]: /vnstatsvg/
 [13]: http://humdi.net/vnstat/
 [14]: https://01.org/suspendresume/
