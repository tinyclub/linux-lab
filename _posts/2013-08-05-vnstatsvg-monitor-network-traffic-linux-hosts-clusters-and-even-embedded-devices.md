---
title: '用 vnStatSVG 监控 Linux 系统的网络流量'
author: Wu Zhangjin
layout: post
permalink: /vnstatsvg-monitor-network-traffic-linux-hosts-clusters-and-even-embedded-devices/
tags:
  - AJAX
  - 网络流量
  - MVC
  - Network Traffic
  - SVG
  - vnStat
  - 分布式系统监控
  - 嵌入式系统监控
categories:
  - Linux
  - Networking
---

> by falcon of [TinyLab.org][1]
> 2013/08/05 23:09

vnStatSVG 是一款开放源代码的、轻量级的、网络流量监控工具 vnStat 的 Web  前端， 2008 年首次发布， 2009 年发布完 1.0.7 版本后停止维护，现在重新启动，即将发布 2.0 版本。

不同于 vnStat 的其他 Web 前端， vnStatSVG 的开发初衷主要是面向嵌入式与分布式平台，但是它同样适应普通的网络平台。它不需要复杂的 Web 服务器，所以大到 Apache ，小到 Busybox 的 httpd 都支持。另外，它基于 AJAX 、 SVG 、 CGI 等技术实现了 MVC 结构，使得数据获取（ Javascript+CGI ）、传输（ XML ）与显示（ SVG+CSS+XSL ）得到很好的分离，不仅代码结构清晰易维护，传输数据小占用带宽小，而且配置性和可扩展性都很好，通过简单的配置，可以用于在同一个 Web 前端监控一个简单的 Linux 主机、小型的嵌入式设备、甚至是一个大型集群中各个节点的网络流量状态。

  * 项目首页：[vnstatsvg][2]
  * 代码仓库：[vnstatsvg.git][3]
  * 演示站点：[vnstatsvg-demo][4]
  * 使用文档：同项目首页，pdf 版本，可在线阅读或者直接下载，如下：[vnstat.pdf](https://github.com/tinyclub/vnstatsvg/raw/master/doc/vnstatsvg.pdf)

下面介绍下项目相关背景：

vnStat 本身基于控制台，它支持 Linux 和 BSD ，基于内核提供的网络流量统计接口，可以定时采样各个网络接口的数据存储到其作者设计的特定数据库中，并提供数据统计和分析接口。在 Linux 平台上，通过 `/proc/net/dev` 来获取系统中各个网络接口的流量信息。其官方网站为： <http://humdi.net/vnstat/> 

由于 vnStat 的轻量级特性，它本身并不支持 Web 的访问方式（有比较简单的 CGI demo ），所以在其官方网站上有列出第三方的 vpsinfo, jsvnstat, vnStat PHP frontend 以及我们这里的 vnSat SVG frontend 。除了 vnStatSVG ，其他所有前端都依赖比较复杂的 web 服务器支持，都需要 PHP 模块，只有 vnStatSVG 的需求最小，它只要一个简单的支持 CGI 的 Web 服务器即可，所以特别适合嵌入式平台，能够完美运行于 Busybox 构建的嵌入式系统；另外，由于 vnStatSVG 基于 AJAX 、 SVG 、 CGI 实现了 MVC 结构，所以，可配制性和可扩展性都特别好，适合分布式平台，能够通过一个浏览器窗口同时透明地监控大量不同主机的不同网络接口。

vnStatSVG 最早发布于 2008 年，那时候作者还在上学，所以时间比较充裕，项目托管于 <http://sourceforge.net/projects/vnstatsvg/> ，于 2009 年发布最后一个 1.0.7 版本后，由于实习工作繁重，逐步停止了该项目的维护。作者从上大学开始到现在，一直在学习和研究嵌入式 Linux 方向，目前主要专注于 Linux kernel features 方面的研究与工作。目前正在建立一个平台： http://tinylab.org ，用于深入分享和交流嵌入式 Linux 系统相关的技术。所以重新梳理了早期发起或者参与的项目，发现 vnStatSVG 有其现实的应用场景和需求，但是需要很好的改进和完善，所以最近重启了 vnStatSVG 项目，完成了 2.0 的 rc1 版本，并把项目仓库管理工具转成了 git ，放到了 Tinylab.org 的代码仓库中： [vnstatsvg.git][3] ，并编写了基本的使用文档： [vnstatsvg][2] 。希望该项目能够使更多用户受益。

目前只在 Ubuntu 和添加有 Busybox 工具的 Android emulator 中测试过，希望正式的 2.0 版本能够很好地支持更多的 Linux 和 BSD 发行版，所以如果其他朋友正好有环境并且有监控网络流量监控的需求，欢迎帮忙一起测试并提交 Bug Fixup 。当然，有兴趣的同学也欢迎参与一起维护和改进。

 [1]: http://TinyLab.org
 [2]: /vnstatsvg
 [3]: https://github.com/tinyclub/vnstatsvg.git
 [4]: /vnstatsvg-demo/
