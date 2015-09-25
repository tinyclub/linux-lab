---
title: 在 Android init.rc 脚本中创建文件
author: Wu Zhangjin
layout: post
permalink: /faqs/how-to-create-files-in-android-init-rc-script/
tags:
  - Android
  - create file
  - init.rc
  - 创建文件
categories:
  - Android
---
* 问题描述

  某些应用场景要求在init.rc中创建一些目录和文件，目录可以通过`mkdir`创建，但是文件呢？

* 问题分析

  如果是Linux用户，很容易联想到`touch`, `cp`等命令，但是非常抱歉，Android特立独行，把`cp`实现为`copy`，而且为了让toolbox尽量小，没有提供`touch`命令，而是提供了`write`命令：<http://androidxref.com/4.4.3_r1.1/xref/system/core/init/keywords.h>:

      94    KEYWORD(write,       COMMAND, 2, do_write)
      95    KEYWORD(copy,        COMMAND, 2, do_copy)

* 解决方案

  下面咱们举例介绍`write`和`copy`创建文件的用法：

      # init.rc
        
      on post-fs-data
          ...
          write /data/non-empty-file 1
          copy /dev/null /data/empty-file
