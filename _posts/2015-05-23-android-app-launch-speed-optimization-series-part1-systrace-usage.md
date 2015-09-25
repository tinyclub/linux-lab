---
title: Android 应用启动速度优化之 Systrace 的使用
author: Gao JianWu
layout: post
permalink: /android-app-launch-speed-optimization-series-part1-systrace-usage/
tags:
  - Android
  - SysTrace
  - 应用启动速度优化
categories:
  - Android
---

> By Gracker of [TinyLab.org][1]
> 2015/05/22


## Systrace 简介

Android 应用启动速度优化方式有很多方法，不过在优化之前，需要找到应用启动速度的瓶颈，找到关键点之后，再去优化，则可以达到事半功倍的效果。 Google 提供了很多 Debug 工具来帮助我们优化应用，这其中就包括 Systrace 工具。

Systrace 是 Android 4.1 中新增的性能数据采样和分析工具。它可帮助开发者收集 Android 关键子系统（如 surfaceflinger、WindowManagerService 等 Framework 部分关键模块、服务，View 系统等）的运行信息，从而帮助开发者更直观的分析系统瓶颈，改进性能。

Systrace 的功能包括跟踪系统的 I/O 操作、内核工作队列、CPU 负载以及 Android 各个子系统的运行状况等。在 Android 平台中，它主要由三部分组成：

  * 内核部分

    Systrace 利用了Linux Kernel 中的 ftrace 功能。所以，如果要使用 Systrace 的话，必须开启 kernel 中和 ftrace 相关的模块。

  * 数据采集部分

    Android 定义了一个 Trace 类。应用程序可利用该类把统计信息输出给 ftrace。同时，Android 还有一个 atrace 程序，它可以从 ftrace 中读取统计信息然后交给数据分析工具来处理。

  * 数据分析工具

    Android 提供一个 systrace.py（python脚本文件，位于Android SDK 目录 /tools/systrace 中，其内部将调用 atrace 程序）用来配置数据采集的方式（如采集数据的标签、输出文件名等）和收集 ftrace 统计数据并生成一个结果网页文件供用户查看。

从本质上说，Systrace 是对 Linux Kernel 中 ftrace 的封装。应用进程需要利用 Android 提供的 Trace 类来使用 Systrace。

关于 Systrace 的官方介绍和使用可以看这里：[Systrace 官方文档][2]。

## Systrace 用法

使用 Systrace前，要先了解一下 Systrace 在各个平台上的使用方法，鉴于大家使用 Eclipse 和 Android Studio 的居多，所以直接摘抄官网关于这个的使用方法，不过不管是什么工具，流程是一样的：

  * 手机准备好你要进行抓取的界面
  * 点击开始抓取（命令行的话就是开始执行命令）
  * 手机上开始操作
  * 设定好的时间到了之后，会将生成 Trace 文件，使用 Chrome 将这个文件打开进行分析

下面介绍了四种使用工具抓取 Systrace 的方法：

### <span id="_Eclipse">使用 <strong>Eclipse</strong></span>

  1. In Eclipse, open an Android application project.
  2. Switch to the DDMS perspective, by selecting Window &#62; Perspectives &#62; DDMS.
  3. In the Devices tab, select the device on which to run a trace. If no devices are listed, make sure your device is connected via USB cable and that debugging is enabled on the device.
  4. Click the Systrace icon at the top of the Devices panel to configure tracing.
  5. Set the tracing options and click OK to start the trace.

### <span id="_Android_Studio">使用 <strong>Android Studio</strong></span>

  1. In Android Studio, open an Android application project.
  2. Open the Device Monitor by selecting Tools &#62; Android &#62; Monitor.
  3. In the Devices tab, select the device on which to run a trace. If no devices are listed, make sure your device is connected via USB cable and that debugging is enabled on the device.
  4. Click the Systrace icon at the top of the Devices panel to configure tracing.
  5. Set the tracing options and click OK to start the trace.

### <span id="_Device_Monitor">使用 <strong>Device Monitor</strong></span>

  1. Navigate to your SDK tools/ directory.
  2. Run the monitor program.
  3. In the Devices tab, select the device on which to run a trace. If no devices are listed, make sure your device is connected via USB cable and that debugging is enabled on the device.
  4. Click the Systrace icon at the top of the Devices panel to configure tracing.
  5. Set the tracing options and click OK to start the trace.

### <span id="i">使用命令行工具(<strong>强烈推荐</strong>)</span>

命令行形式比较灵活，速度也比较快，一次性配置好之后，以后再使用的时候就会很快就出结果.

<pre>$ cd android-sdk/platform-tools/systrace
$ python systrace.py --time=10 -o mynewtrace.trace sched gfx view wm
</pre>

从上面的命令可以看到 Systrace 工具的位置，只需要在 Bash 中配置好对应的路径和 Alias，使用起来还是很快速的。另外需要注意的是: **User版本是不可以抓 Trace 的，只有 ENG 版本或者 Userdebug 版本才可以**，是不是又多了一个买 Nexus5 的理由 ^_^。

抓取结束后，会生成对应的 Trace 文件，注意这个文件只能被 Chrome 打开。关于如何分析 Trace 文件，我们下面的章节会讲。

## Systrace 命令参数

不论使用那种工具，在抓取之前都会让选择参数，下面说一下这些参数的意思：

  * -h, &#8211;help Show the help message.（帮助）
  * -o \<FILE&#62; Write the HTML trace report to the specified file.（即输出文件名，）
  * -t N, &#8211;time=N Trace activity for N seconds. The default value is 5 seconds. （Trace抓取的时间，一般是 ： -t 8）
  * -b N, &#8211;buf-size=N Use a trace buffer size of N kilobytes. This option lets you limit the total size of the data collected during a trace.
  * -k \<KFUNCS&#62;
  * —ktrace=\<KFUNCS&#62; Trace the activity of specific kernel functions, specified in a comma-separated list.
  * -l, &#8211;list-categories List the available tracing category tags. The available tags are(下面的参数不用翻译了估计大家也看得懂，贴官方的解释也会比较权威，后面分析的时候我们会看到这些参数的作用的):

      * **gfx** &#8211; Graphics
      * **input** &#8211; Input
      * **view** &#8211; View
      * webview &#8211; WebView
      * **wm** &#8211; Window Manager
      * **am** &#8211; Activity Manager
      * audio &#8211; Audio
      * video &#8211; Video
      * camera &#8211; Camera
      * hal &#8211; Hardware Modules
      * res &#8211; Resource Loading
      * **dalvik** &#8211; Dalvik VM
      * rs &#8211; RenderScript
      * **sched** &#8211; CPU Scheduling
      * **freq** &#8211; CPU Frequency
      * **membus** &#8211; Memory Bus Utilization
      * **idle** &#8211; CPU Idle
      * **disk** &#8211; Disk input and output
      * **load** &#8211; CPU Load
      * **sync** &#8211; Synchronization Manager
      * **workq** &#8211; Kernel Workqueues Note: Some trace categories are not supported on all devices. Tip: If you want to see the names of tasks in the trace output, you must include the sched category in your command parameters.

  * -a  \<APP_NAME&#62;

  * —app=\<APP_NAME&#62; Enable tracing for applications, specified as a comma-separated list of package names. The apps must contain tracing instrumentation calls from the Trace class. For more information, see Analyzing Display and Performance.
  * —link-assets Link to the original CSS or JavaScript resources instead of embedding them in the HTML trace report.
  * —from-file=\<FROM_FILE&#62; Create the interactive Systrace report from a file, instead of running a live trace.
  * —asset-dir=\<ASSET_DIR&#62; Specify a directory for the trace report assets. This option is useful for maintaining a single set of assets for multiple Systrace reports.
  * -e \<DEVICE_SERIAL&#62;
  * —serial=\<DEVICE_SERIAL&#62; Conduct the trace on a specific connected device, identified by its device serial number.

上面的参数虽然比较多，但使用工具的时候不需考虑这么多，在对应的项目前打钩即可，命令行的时候才会去手动加参数：

我们一般会把这个命令配置成Alias，配置如下：

<pre>alias st-start='python /path/to/android-studio/sdk/platform-tools/systrace/systrace.py'
alias st-start-gfx = 'st-start -t 8 gfx input view sched freq wm am hwui workq res dalvik sync disk load perf hal rs idle mmc'
</pre>

这样在使用的时候，可以直接敲 **st-start-gfx** 即可，当然为了区分和保持各个文件，还需要加上 **-o xxx.Trace**。上面的命令和参数不必一次就理解，只需要记住如何简单使用即可，在分析的过程中，这些东西都会慢慢熟悉的。

## Systrace 结果截图

Systrace 抓取结束后，会生成一个文件，这个文件必须使用 Chrome 打开。下面的图是一张典型的应用启动时候的 Systrace 图：

![Systrace][3]





 [1]: http://tinylab.org
 [2]: http://developer.android.com/tools/help/systrace.html "SysTrace 官方介绍"
 [3]: https://wt-prj.oss.aliyuncs.com/d1b5415c872549dcb9f47d0af7295722/9ddcff92-b98e-4a51-a2bf-844dd9bbc05a.png
