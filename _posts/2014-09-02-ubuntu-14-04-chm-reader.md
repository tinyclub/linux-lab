---
title: Ubuntu 14.04 CHM 文档最佳阅读器
author: Wu Zhangjin
layout: post
permalink: /faqs/ubuntu-14-04-chm-reader/
tags:
  - chm
  - chm2pdf
  - chmsee
  - 阅读器
  - kchmviewer
  - xchm
categories:
  - Ubuntu
---
  * 问题描述

    最近拿到了一份 chm 文档，尝试了几个阅读器，发现都不管用？要不就是根本没法正常工作，要不就是中文乱码。特别是之前很喜欢的 chmsee，竟然在 Ubuntu 14.04 找不到了。

  * 问题分析

    找到 chmsee 的[官网][1]，发现作者已经停止维护了。

    > Stop maintain
    >
    > ChmSee is not being developed anymore. I haven&#8217;t read CHM documents more than a year, new and update IT books are pdfs or epubs, so it&#8217;s right time to end this chm viewer.

    根据作者的描述，原因很简单，作者不读 chm 的文档了 ;-P

  * 解决方案

    竟然没得 chmsee 用，那就找个别的吧，后面尝试了一下 kchmviwer 也不错，乱码没了，很爽：

        $ sudo apt-get install kchmviewer


    不过 kchmviewer 是基于Qt的，没有 GTK+ 那么好看，而且字体锯齿很多，整个交互设计上美观度也不够 chmsee 优雅。

    如果不妥协，那么自己从 [chmsee官网][2] 下载自行编译安装一个，或者参考这里的[诸多方法][3]下一个。后续咱们有时间可以再来一个介绍 chmsee 安装的FAQ。

    下面来看两张图，第一张是 `kchmviewer` 的预览效果：

    ![kchmviewer overview][4]

    然后是 `chmsee`，效果对比非常明显：

    ![chmsee overview][5]




 [1]: https://code.google.com/p/chmsee/
 [2]: https://code.google.com/p/chmsee/downloads/list
 [3]: http://askubuntu.com/questions/471877/what-happened-to-chmsee-in-14-04
 [4]: /wp-content/uploads/2014/09/kchmviwer-overview.jpg
 [5]: /wp-content/uploads/2014/09/chmsee-overview.jpg
