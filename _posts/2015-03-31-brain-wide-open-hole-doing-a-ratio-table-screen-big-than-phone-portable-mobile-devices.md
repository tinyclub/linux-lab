---
title: 大开脑洞，做一个比表屏大，比 phone 便携的移动设备
author: Chen Jie
layout: post
permalink: /brain-wide-open-hole-doing-a-ratio-table-screen-big-than-phone-portable-mobile-devices/
tags:
  - Adam
  - Clutter
  - ipod touch 4
  - Swift
  - 小屏幕
categories:
  - Life
  - Mobile
---

<!-- title: 大开脑洞，做一个比表屏大，比 phone 便携的移动设备 -->

<!-- %s/!\[image\](/&#038;\/wp-content\/uploads\/2015\/03\// -->

> by Chen Jie of [TinyLab.org][1]
> 2015/3/28

![image][2]


## 比表屏大，比 phone 便携

月初，某表终于发布，除了没有微型麻醉枪外，功能还挺丰盛的。只是要用上这许多功能，需对着若小的一屏指指点点。这感想，大概和儿时吮吸冻得严严实实的 双响棒（现在叫做碎碎冰了）是一样的吧 —— 享用一点，费半天劲。更别说表不过是绕着 phone 转的卫星 —— 离了 phone 啥都干不了。

至于 phone 嘛，宽 4 寸的 [Nokia Lumia 525][3] 放在口袋，坐下尚嫌硌腿，更别提目下这些大屏手机了。

于是，发扬 YY 精神，大开脑洞，臆想个移动设备，它应该看起来像，咳咳，带电话功能的 4 代 ipod touch。 嗯，这其实就是个小屏手机，尺寸在 3.5 &#8211; 4 寸之间。

## ipod touch 4 的颜值

某次出差，当周围人第一次见到 4 代 ipod touch 时，一个大大的“哇”：这手机&#8230;不错。

额，这个像手机，但不能打电话&#8230;

![image][4]

以时下的技术，可以做窄边框，可以更轻和更薄，以及加长的电池续航。

## 小屏用来做什么

小屏可以完成一些中等程度的交互，同时有着不错的便携性，更好贴合线下的活动 —— 融入你的生活，而不是让你融入手机的生活：

  * **基于场景的交互汇聚**：知晓此刻的场景，并据此合理呈现交互内容。屏幕虽小，但呈现的是用户此时此刻最需要的。对场景学习，大概是需要云来支撑的。

    信息汇聚是一个很重要的环节：君不见，打车吃饭 App，推广扫码挨个装，满屏图标该选谁；君不见，公司流程电子化，漫天邮件每天飞，哪些重要哪些急？

  * 既然是小屏手机了，也不指望盯着这个玩游戏，或是装一堆 App 了吧。这时，终于可以用有限的硬件资源，来完成有限的任务，结果就是操作**响应更快**，**能耗更低**。

    某时见到过一篇文章，言 DOS 时代软件的启动速度，能甩开现在软件好几条街。一直以来塞进太多的期望和要求，渐成拖泥带水，不痛快！

  * 摄影，支付。既然贴近线下，这些功能必须强化。

    说说指纹识别功能，可以在下缘配置一个划擦式指纹识别装置，与按压式相比，更省空间，增加屏占比，提升整体颜值。

<div style="text-align:center">
  <img src="/wp-content/uploads/2015/03/sp-fingerprint-pay.jpg" />
</div>

## 合身 OS

一个合身 OS，对于产品初衷能否最终完美表达，至关重要。

然而，拉扯大一个新 OS，真心不易。大概是 OS 本身需要承载和肩负太多，需要各方面均衡发展，好比从小就被培养做大人物的孩子：

  * 别家孩子学围棋，也得学！
  * 别家孩子学音乐，学！
  * 别家孩子报了跆拳道班，报！
  * &#8230;

其实吧，每个成长，只是在巧合的机遇，集中精力于微小个别，牛刀杀鸡，获得突破，进而撕开壁垒，更上一层楼。小屏手机本身是一个减法的过程，合身 OS 打造会更加容易些，并可进而数次迭代，至通至用。

具体过程大概首先找到一个原型（例如 Mer，Ubuntu Touch，GNOME/Linux 等等），然后替换/注入一些核心元素。这个过程有点像大片中，特工去某地执行任务，首先会找自己的 Local contact。对于有经历的工程师也是一样。

下面是我的（理想）Local contact：

<div style="text-align:center">
  <img src="/wp-content/uploads/2015/03/sp-building-blocks.jpg" />
</div>

  * [Adam][5]，来自 Adobe，是一种描述属性模型的语言。 在 CMV（Controller-Model-View，或者叫做 MVC ，但前者更严谨些），Adam 用于描述 Model 部分，从而替代掉许多维护 Model 的函数回调。举个形似的例子：

    // 缩放图像：原始尺寸（original width），当前尺寸（current width）以及缩放比（current percent）

    `printf("Original width is %d, current width is %d - about %f % length of the Original", original_width, current_with, current_percent);`

    把格式化符串视作 View 的一部分；而 Adam 则描述了 original\_width，current\_width 和 current_percent 三者关系：`current_width = original_width * current_percent`。

    Adam 确保了交互界面 传给 程序核心 的参数集总是有效的，即排除了许多无效组合 —— 换言之，是不连续的。这就好像量子力学中，能量传递是以不连续的、量子的形式。因此，我给 Adam 支撑下的交互界面 取了个名，唤做 “量子界面” 技术。

  * [Clutter][6]，来自 GNOME 社区，之前由 Intel 维护，并应用于 MeeGo。Clutter 名义上用于支撑 UI 的动画效果，但其结构分离得非常好，成为进一步实现 Widget 的基石，例如 mx。另外，Clutter 一直被努力用于拯救破旧的 gtk+ 库（所谓的 4.0 版本），但最终，维护者决定另起一个 [GSK][7]，GSK 将会继承 Clutter 全部优雅，且让我们期待其进展。

  * [Libdispatch][8]，来自 Apple。头次见到能把异步多线程封装得如此简洁统一，吓了一跳。感兴趣的童鞋可移步看俺早年草制的两幻灯：[libdispatch][9]，[libdispatch-event][10]

  * [Swift][11]，来自 Apple。一种内存安全的编译型（编译至机器码）语言。

    对于 OS 而言，上层统一的开发环境至关重要，直接关系到未来的应用生态。而编程语言则更是重中之重。传统的编译型语言，例如 C/C++ 固然效率较高，但内存安全问题突出。兴起的内存安全的编译型语言中，Swift 似乎居首。

    Swift 目前没有开源支持。考虑添加开源实现，编译支持也许容易，但各种 Swift 可用库的接入，似显艰巨。

当然，对于一个新 OS 的开发，还有许多具体组件，例如安全框架，调试和剖析框架，包，系统级和会话级服务，数据甚至是会话的同步等等，不一一赘述。

## 即时通讯风格的交互界面

即时通讯风格交互界面，自然呈现基于上下文的交互；便于自然语言命令的交互方式；由于形式简单固定，便于 App 的快速开发。

下图为其的一个设想示意：

![image][12]

注意图中：

  1. 输入法依据上下文，给予用户交互提示；
  2. 用户仿佛[输入命令][13]，而不是目光游走于 UI 各元素，一边思考是否感兴趣，然后选定 UI 元素，交互填入数据&#8230;





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/03/sp-head-pic.jpg
 [3]: http://www.microsoft.com/en/mobile/phone/lumia525/specifications/
 [4]: http://www.blogcdn.com/www.engadget.com/media/2010/09/ipodtouch2010hands3.jpg
 [5]: http://stlab.adobe.com/group__asl__overview.html
 [6]: https://blogs.gnome.org/clutter/
 [7]: https://www.bassi.io/articles/2014/07/29/guadec-2014-gsk/
 [8]: https://libdispatch.macosforge.org/
 [9]: https://github.com/cee1/cee1.archive/raw/master/documents/libdispatch.pdf
 [10]: https://github.com/cee1/cee1.archive/raw/master/documents/libdispatch-event.pdf
 [11]: https://developer.apple.com/swift/
 [12]: /wp-content/uploads/2015/03/sp-imstyle-HI.jpg
 [13]: /new-ui-design-im-style-cellphone-ui-intro/
