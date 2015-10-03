---
title: Clutter：UI 得瑟起来～～
author: Chen Jie
layout: post
permalink: /clutter-let-ui-be-higher/
tags:
  - GNOME
  - GSK
  - GTK+
  - meego
categories:
  - 技术动态
  - Clutter
---

<!-- title: Clutter：UI 得瑟起来～～ -->

<!-- %s/!\[image\](/&#038;\/wp-content\/uploads\/2015\/04\// -->

> by Chen Jie of [TinyLab.org][1]
> 2015/4/6


## 简介

Meego 大概拥有最酷炫移动系统界面，其背后实现基础便是 Clutter。下图展示了 Clutter 的一个大概：

![image][2]

  * 舞台（Stage）（用 widget toolkit 的思维，相当于 Top-level Window）
  * 以及舞台上的各个演员（Actors）。图中 (1)、(2) 和 (3) 就处在 **不同景深** 的 Actors。Actor 还能内含若干个 Actors，如（1）含有许多个 Actors。
  * 通过 Transition，Actors 在 Stage 上动起来，如 Actor (2) 从左往右平移；Actor (3) 则从台内至台前，再退回。

言及 UI，可从 MVC（Model-View-Controller 或者更确切的 CMV）来分析。下面先从 View（视图），再从 Controller（控制器）来看 Clutter。

## View

对于一个图形界面基础库而言，在 View 层面提供的功能不外乎：

  * Layout（布局）：例如横向平铺，纵向平铺，表格，流式（铺完一行，铺下一行），指定固定坐标，以及叠堆等等。
  * Drawing（绘制）：分别调用子 Actor(s) 的绘制方法。除此之外，还可提供滤镜特效，例如光晕，烟雾等等 —— 就好比各个子 Actor(s) 提供了各自素颜照，再经过 *特效滤镜* 来自动美颜，最终成了舞台照。

从 Layout 角度而言，Clutter 把 Actor(s) 都看作矩形块，然后应用指定的 Layout 算法。Layout (Manager) 本身仅是 Actor 属性，这意味着 Actor 可以设定任意需要的 Layout 方式。

从绘制的角度，Clutter 采用了类似油画的技法，后画的图层盖在先前的图层上。以一个视频播放器的为例：

![image][3]

它实际上是许多图层混合的（Clutter 按照遍历 “render graph” 来依次调用各 Actor(s) 的绘制方法）：

![image][4]

按照从后到前，分别是：

  1. 背景图层：视频回放
  2. 操作面板图层
  3. “进度条控制”、“暂停播放”按钮 和 “退出全屏播放”按钮 图层

## Controller

Controller 的实现，其实就是将窗口系统中的事件，分发到内部子元素上（Actor(s)）。有趣的是，对于坐标类的事件，Clutter 借用了类似绘制的过程，来决定分发给哪个 Actor，如下图所示：

![image][5]

即任意为每个 Actor 选定一个颜色，并用该颜色绘制。然后取事件坐标处的颜色，依据颜色找到对应 Actor，该过程被称为 Pick。此类方式的好处在于，很直观地将坐标事件分发到 *任意形状* 的 Actor(s) 上，且过程本身是显卡加速的。

## 动画 和 其他

动画是一组状态间的过渡。分解来看，相邻两状态，从 状态 A 到状态 B，就是在既定 **时间间隔** 内，选择合适的 **插值算法**，由 A 状态的 **属性集** “渐变” 到 B 状态的 **属性集**。

Clutter 还有与 物理引擎（box2d、bullet）的结合，推测起来，大概是由状态 A 属性集，结合输入参数，依据设定物理模型来渐变到状态 B。

由于 Meego 项目的停滞，Clutter 开发热度降低，许多周边的项目，例如 MX（用 Clutter 来构建一套 toolkit）、物理引擎结合 等都已停止。不过其良好的设计，仍然发挥着余热，例如 GNOME 社区一直努力用 Clutter 来拯救陈旧的 GTK+（成功了就可能是 GTK+ 4.0）。最新的努力动向是由 Clutter 代码中孵化出 GSK（[GTK+ Scene Graph Kit][6]），来提供 “舞台场景图” 支持。





 [1]: http://tinylab.org
 [2]: /wp-content/uploads/2015/04/clutter-overview.jpg
 [3]: /wp-content/uploads/2015/04/clutter-video-player-example.jpg
 [4]: /wp-content/uploads/2015/04/clutter-video-player-example-render-graph.jpg
 [5]: /wp-content/uploads/2015/04/clutter-video-player-example-event-dispatch.jpg
 [6]: https://www.bassi.io/articles/2014/07/29/guadec-2014-gsk/
