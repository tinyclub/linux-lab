---
title: 使用 JDB 调试 Android 应用程序
author: Huang Tao
album: "Debugging+Tracing"
layout: post
permalink: /use-jdb-to-debug-android-application/
tags:
  - ADB
  - ADT
  - Android
  - Android Studio
  - JDB
  - JDWP
categories:
  - JDB
  - 调试技巧
---

> By Huang Tao of [TinyLab.org][1]
> 2015/04/13


## 前言

自从有了各种 IDE 工具，程序猿调试工作轻松了不少，只要在 IDE 上面点击两下按钮，各种程序运行时的信息全部都显示在屏幕上面，很美好的一件事情，我们都要感谢开发这些 IDE 工具的前辈，是他们让我们的工作变得这么“轻松简单”，但是对于我个人来说，不是很喜欢这些 IDE 工具：

  * 第一是因为这类 IDE 工具实在是变化太快，我们要花费很大的时间成本来学习这一类工具，然而当你好不容易熟悉了一种工具之后，别人又出了一种更牛 B 的工具，谷歌从 ADT 切换到 Android Studio 就是如此。

  * 第二是因为使用这类工具过程中一旦遇到问题，或者想要增加一种功能往往会使人们不知所措，给人的感觉不够灵活。

所以相比使用 IDE 工具来说，我比较倾向于使用命令行工具，虽然原始了一点，但是从里面我们可以学到很多东西，使用起来也更加灵活，今天我们要讲的 JDB 就是一种这样的命令行工具，目前大多数程序员在调试 Android 应用程序的时候，大多选择的是 ADT 和 Android Studio，这两个 IDE 已经为我们集成了很多调试的功能，像打断点、单步调试、dump 虚拟机的堆栈信息等，这些工具很强大，是我们开发过程中不可缺少的，但是有没有想过他们是怎么做到的呢？其实他们也是利用了类似 JDB 的功能，然后以可视化界面显示在人们面前。

## JDWP 协议介绍

首先让我们认识一下什么是 JDWP（Java调试线协议），说白了就是 JVM 或者类 JVM 的虚拟机都支持一种协议，通过该协议，Debugger 端可以和目标 VM 通信，可以获取目标 VM 的包括类、对象、线程等信息，在调试 Android 应用程序这一场景中 Debugger 一般是指你的 develop machine 的某一支持 JDWP 协议的工具例如 Android Studio 或者 JDB，而 Target JVM 是指运行在你 mobile 设备当中的各个 App（因为它们都是一个个虚拟机 Dalvik 或者 ART），JDWP Agent一般负责监听某一个端口，当有 Debugger 向这一个端口发起请求的时候，Agent 就转发该请求给 Target JVM 并最终由该 JVM 来处理请求，并把 reply 信息返回给 Debugger 端。

![JDWP-1][2]

上面这个图是借用别人说明 JVM 的，针对 Android 来说可能不是特别准确，我们来看一下 Android 上面是什么情况，调试的时候我们一般通过 ADB 来连接移动设备，所以上面的 JDWP Agent 在 Android 手机上应该是指 adbd 进程，接着上图：

![JDWP-2][3]

上图说明了使用 DDMS 来跟 App VMs 通信的流程，关于 adb 的使用说明，这里就不详细展开了，可以参见 Google 官方文档。

再来唠叨一下 JDWP 协议的报文格式，JDWP 协议中主要有两种报文：Command packet 和 Reply packet，command packet 就是我们上面所说的请求报文，reply 自然就是对 command 的回答。

JDWP Packet 分为包头（header）和数据（data）两部分组成。包头部分的结构和长度是固定，而数据部分的长度是可变的，具体内容视 packet 的内容而定。Command packet 和 reply packet 的包头长度相同，都是 11 个 bytes.

  1. Command packet 的 header 的结构

    ![JDWP-Command-Packet-Header][4]

  * Length 是整个 packet 的长度，包括 length 部分。因为包头的长度是固定的 11 bytes，所以如果一个 command packet 没有数据部分，则 length 的值就是 11。

      * Id 是一个唯一值，用来标记和识别 reply 所属的 command。Reply packet 与它所回复的 command packet 具有相同的 Id，异步的消息就是通过 Id 来配对识别的。

      * Flags 目前对于 command packet 值始终是 0。

      * Command Set

    相当于一个 command 的分组，一些功能相近的 command 被分在同一个 Command Set 中。Command Set 的值被划分为 3 个部分：

      * 0-63: 从 debugger 发往 target Java 虚拟机的命令
      * 64 – 127： 从 target Java 虚拟机发往 debugger 的命令
      * 128 – 256： 预留的自定义和扩展命令

  1. Reply packet 的 header 的结构

    ![JDWP-Reply-Packet-Header][5]

  * Length、Id 作用与 command packet 中的一样。
  * Flags 目前对于 reply packet 值始终是 0&#215;80。我们可以通过 Flags 的值来判断接收到的 packet 是 command 还是 reply。
  * Error Code 用来表示被回复的命令是否被正确执行了。零表示正确，非零表示执行错误。

Data 的内容和结构依据不同的 command 和 reply 都有所不同。比如请求一个对象成员变量值的 command，它的 data 中就包含该对象的 id 和成员变量的 id。而 reply 中则包含该成员变量的值。

## JDB 的使用方式

上面说了这么多，其实都是为了讲 JDB 的使用原理做的铺垫，JDB 其实是 JDWP 协议中所讲的 Debugger，它运行在 develop machine 上面，它和移动设备上面的 App VMs 通过 JDWP 协议来通信，JDB 一般位于你的 JDK 安装目录下面，可以直接运行，因为 JDB 和移动设备必须通过 ADB 来沟通，所以在 Android 上面使用 JDB 之前必须做一些配置：

  1. 通过 `adb jdwp` 列出移动设备上面可以执行 JDWP 协议的进程 ID。
  2. 通过 `adb forward tcp:123456 jdwp:pid` (第一步所得到的 PID )设置使用 123456 端口来和移动设备上面的App VMs（其实是 adbd）来通信。
  3. 执行 `jdb -attach localhost:123456` 将 jdb attach 到本机的 123456 端口。

这样一个 JDB 到移动设备 App VMs 的连接就成了，可以使用 JDB 提供的各种命令来和 App VMs 交互。

## JDB 的使用示例

  1. 使用 `adb shell ps | grep com.android.settings` 来得到 settings 进程的 pid 号为 3107
  2. 执行 `adb forward tcp:12345 jdwp:3107`
  3. 执行 `jdb -attach localhost:12345` 执行完上面三步之后，jdb 与设置 App 之间的连接就建立好了。
  4. 执行 `jdb` 命令 `classes`，得到设置 App 当中所有的类列表。

    ![JDB Classes][6]

  5. 我们感兴趣的是 com.android.setting.Settings 这个类，所以我们继续使用 `jdb` 命令 `methods` 来查看这个类拥有哪一些方法。

    ![JDB Methods][7]

  6. 假设我们想在 com.android.setting.Settings 这个类的 onCreate 这个方法中添加断点，那么我们执行 `stop in com.android.setting.Settings.onCreate(android.os.Bundle)` 在这个方法中设置断点，然后我们打开设置 app，jdb 会提示我们断点命中，同时告知我们哪个线程，具体的方法、哪一行等信息。

  7. 执行 `next` 命令，使代码执行到下一行。
  8. 执行 `step` 命令，使代码单步执行。
  9. 执行 `run` 命令，使程序跳过断点继续执行。

    ![JDB Run][8]

## JDB 的命令列表

\*\* 命令列表 \*\*

> connectors &#8212; 列出此 VM 中可用的连接器和传输
>
> run [class [args]] &#8212; 开始执行应用程序的主类
>
> threads [threadgroup] &#8212; 列出线程
>
> thread <thread id> &#8212; 设置默认线程
>
> suspend [thread id(s)] &#8212; 挂起线程 (默认值: all)
>
> resume [thread id(s)] &#8212; 恢复线程 (默认值: all)
>
> where [<thread id> | all] &#8212; 转储线程的堆栈
>
> wherei [<thread id> | all]&#8211; 转储线程的堆栈, 以及 pc 信息
>
> up [n frames] &#8212; 上移线程的堆栈
>
> down [n frames] &#8212; 下移线程的堆栈
>
> kill <thread id> <expr> &#8212; 终止具有给定的异常错误对象的线程
>
> interrupt <thread id> &#8212; 中断线程
>
> print <expr> &#8212; 输出表达式的值
>
> dump <expr> &#8212; 输出所有对象信息
>
> eval <expr> &#8212; 对表达式求值 (与 print 相同)
>
> set <lvalue> = <expr> &#8212; 向字段/变量/数组元素分配新值
>
> locals &#8212; 输出当前堆栈帧中的所有本地变量
>
> classes &#8212; 列出当前已知的类
>
> class <class id> &#8212; 显示已命名类的详细资料
>
> methods <class id> &#8212; 列出类的方法
>
> fields <class id> &#8212; 列出类的字段
>
> threadgroups &#8212; 列出线程组
>
> threadgroup <name> &#8212; 设置当前线程组
>
> stop in <class id>.<method>[(argument_type,...)] &#8212; 在方法中设置断点
>
> stop at <class id>:<line> &#8212; 在行中设置断点
>
> clear <class id>.<method>[(argument_type,...)] &#8212; 清除方法中的断点
>
> clear <class id>:<line> &#8212; 清除行中的断点
>
> clear &#8212; 列出断点
>
> catch [uncaught|caught|all] <class id>|<class pattern> &#8212; 出现指定的异常错误时中断
>
> ignore [uncaught|caught|all] <class id>|<class pattern> &#8212; 对于指定的异常错误, 取消 &#8216;catch&#8217;
>
> watch [access|all] <class id>.<field name> &#8212; 监视对字段的访问/修改
>
> unwatch [access|all] <class id>.<field name> &#8212; 停止监视对字段的访问/修改
>
> trace [go] methods [thread] &#8212; 跟踪方法进入和退出。 &#8212; 除非指定 &#8216;go&#8217;, 否则挂起所有线程
>
> trace [go] method exit | exits [thread] &#8212; 跟踪当前方法的退出, 或者所有方法的退出 &#8212; 除非指定 &#8216;go&#8217;, 否则挂起所有线程
>
> untrace [methods] &#8212; 停止跟踪方法进入和/或退出
>
> step &#8212; 执行当前行
>
> step up &#8212; 一直执行, 直到当前方法返回到其调用方
>
> stepi &#8212; 执行当前指令
>
> 下一步 &#8212; 步进一行 (步过调用)
>
> cont &#8212; 从断点处继续执行
>
> list [line number|method] &#8212; 输出源代码
>
> use (或 sourcepath) [source file path] &#8212; 显示或更改源路径
>
> exclude [<class pattern>, ... | "none"] &#8212; 对于指定的类, 不报告步骤或方法事件
>
> classpath &#8212; 从目标 VM 输出类路径信息
>
> monitor <command> &#8212; 每次程序停止时执行命令
>
> monitor &#8212; 列出监视器
>
> unmonitor <monitor#> &#8212; 删除监视器
>
> read <filename> &#8212; 读取并执行命令文件
>
> lock <expr> &#8212; 输出对象的锁信息
>
> threadlocks [thread id] &#8212; 输出线程的锁信息
>
> pop &#8212; 通过当前帧出栈, 且包含当前帧
>
> reenter &#8212; 与 pop 相同, 但重新进入当前帧
>
> redefine <class id> <class file name> &#8212; 重新定义类的代码
>
> disablegc <expr> &#8212; 禁止对象的垃圾收集
>
> enablegc <expr> &#8212; 允许对象的垃圾收集
>
> !! &#8212; 重复执行最后一个命令
>
> <n> <command> &#8212; 将命令重复执行 n 次
>
> `# <command>` &#8212; 放弃 (无操作)
>
> help (或 ?) &#8212; 列出命令
>
> version &#8212; 输出版本信息
>
> exit (或 quit) &#8212; 退出调试器
>
> <class id>: 带有程序包限定符的完整类名
>
> <class pattern>: 带有前导或尾随通配符 (&#8216;*&#8217;) 的类名
>
> <thread id>: &#8216;threads&#8217; 命令中报告的线程编号
>
> <expr>: Java(TM) 编程语言表达式。
>
> 支持大多数常见语法。

可以将启动命令置于 &#8220;jdb.ini&#8221; 或 &#8220;.jdbrc&#8221; 中 ，位于 user.home 或 user.dir 目录下。

## 参考资料

  * <http://www.ibm.com/developerworks/cn/java/j-lo-jpda3/index.html>
  * <http://codeseekah.com/2012/02/16/command-line-android-development-debugging/>
  * <http://resources.infosecinstitute.com/android-hacking-security-part-6-exploiting-debuggable-android-applications/#article>
  * <http://developer.android.com/tools/debugging/index.html>





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/04/jdb-image001.jpg
 [3]: /wp-content/uploads/2015/04/jdb-debugging.png
 [4]: /wp-content/uploads/2015/04/jdb-image003.jpg
 [5]: /wp-content/uploads/2015/04/jdb-image004.jpg
 [6]: /wp-content/uploads/2015/04/jdb-classes.png
 [7]: /wp-content/uploads/2015/04/jdb-methods.png
 [8]: /wp-content/uploads/2015/04/jdb-run.png
