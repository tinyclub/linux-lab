---
title: 'unifdef: 批量清除条件编译代码'
author: Wen Pingbo
layout: post
permalink: /faqs/remove-condition-code-in-kernel/
tags:
  - kernel
  - unifdef
  - 条件编译
categories:
  - C
---
  * 问题描述

    这几天在工作中，需要在一个大仓库中，清除所有 C 代码里的某个条件编译。就像这样的代码：

        static struct xxx xxx_name {
        #ifdef CONFIG_XXX
          .is_XXX = 1;
        #else
          .is_XXX = 0;
        #endif
        };


    这就相当于把代码预处理一般，但是又不能修改其他地方。

  * 问题分析

    解决这个问题，手动清除当然是可以的。但这肯定不是这篇 FAQ 要表达的东西。重复的工作得交给机器来完成，那就要借助工具啦。我想到的第一个工具就是 `sed` 。通过匹配条件编译指令，然后做删除动作。我用的命令如下：

        find . -type f | xargs sed -i '/^#ifdef\ CONFIG_XXXX$/,/^#endif$/{d}'


    这个方法可以处理一般的条件编译指令，但是并不能处理带 `#ifndef` ， `#else` 和 条件编译指令嵌套的情况。就像这样：



        #ifndef CONFIG_XXXX
        // there are some codes
        #ifdef CONFIG_XXX1
        // code...
        #endif
        #else
        // code...
        #end


    我想写一个比较复杂的 `sed` 脚本，应该可以解决这个问题，但是这里我更倾向于一个更简单的工具：`unifdef`。以 Ubuntu 为例，安装如下：

        apt-get install unifdef


    你可以把它理解为了一个 C/C++ 的预编译器。它能够非常简洁的处理上面提到的情况。对于单个文件，可以这样用：

        unifdef -K -U CONFIG_XXXX /path/to/file


    这里，-K 是防止 unifdef 处理一些带常数的条件编译，比如 `#if 0`。-U 就是指定某个宏是 undefined。

  * 解决方案

    OK，现在我们知道用什么工具来做这件事了。那对于一个 Linux Kernel 源码仓库来说，我们需要扫描所有的代码，并找到我们要处理的宏，然后传递给 unifdef 来处理。我用的脚本如下：

        #!/bin/bash
        
        filelist=`find . -name *.c -o -name *.h`
        tmpfile=`mktemp`
        
        for file in $filelist
        do
          unifdef -K -U CONFIG_RECOVERY_KERNEL $file > $tmpfile
          cmp --silent $file $tmpfile || cp $tmpfile $file
        done
        
        rm -f tmpfile


    赶快尝试一下吧 :)



