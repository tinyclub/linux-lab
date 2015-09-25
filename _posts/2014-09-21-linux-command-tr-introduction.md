---
title: Linux 命令 tr 介绍
author: Wen Pingbo
layout: post
permalink: /linux-command-tr-introduction/
tags:
  - 非打印字符
  - Linux
  - non-printable characters
  - tr
categories:
  - Linux
---

> by WEN Pingbo of [TinyLab.org][1]
> 2014/09/21

最近在用 `gedit` 打开一个 log 文件时，提示说有不能显示的字符，导致整个文件都乱码。用 `file` 命令去查看这个文件的类型，居然显示为二进制文件。明明是一个纯文本文件，怎么会显示为二进制文件呢？估计文件中存在奇特的字节，导致整个文件解析不正常。既然一堆沙子里混入了几颗石头，那么就要把这些石头剔除掉。有很多命令可以处理这个问题，这里我推荐 `tr`。

`tr` 命令是一个很传统的 Unix 命令。本意就是 translate。也就是用来做字符替换、删除和去重的工作。其基本格式如下：

<pre>tr OPTION SET1 [SET2]
</pre>

其中两个 SET 就是用户指定的字符集。其中 SET1 是指定 `tr` 要处理的字符范围，SET2 是用来指定去重和替换时的目标字符范围。具体字符集的指定格式可以看 `tr` 的 man 文档。这里我们演示一下具体的操作：

<pre>echo "thIs iSS aa Test" | tr "[:lower:]" "[:upper:]"   # out: THIS ISS AA TEST           (1)
echo "thIs iSS aa Test" | tr "a-z" "A-Z"   # out: THIS ISS AA TEST               (2)
echo "thIs iSS aa Test" | tr -s "a-zA-Z"   # out: thIs iS a Test               (3)
echo "thIs iSS aa Test" | tr -s "a-zA-Z" "a-za-z"   # out: this is a test               (4)
echo "thIs iSS aa Test" | tr -d "a-z"   # out: I SS  T                    (5)
echo "thIs iSS aa Test" | tr -cd "a-z\n\40"   # out: ths i aa est               (6)
</pre>

每个命令后面的注释是该命令的输出。这里我们可以看到第一个和第二个命令是做字符替换工作，把 SET1 字符集替换成 SET2 字符集。而第三个命令是做字符去重，`-s` 的意思就是 squeeze-repeats。而第四个命令添加了 SET2 字符集，目的是让 `tr` 在去重的同时，做字符替换工作。这里要注意的是，SET1 和 SET2 的长度必须保持一致，不然， `tr` 就会把 SET2 最后一个字符重复填充，多余字符会抛弃； 且`tr` 默认是先做字符替换，然后再用 SET2 做去重。第五和第六个命令是做字符删除操作。这里 `-c` 是用 SET1 的补集。在第六个命令中可以看出，我们保留了换行符和空格。

好了，对 `tr` 命令有一番了解后，我们再回过头来看看，怎么剔除一个纯文本文件中的非字符字节。我使用的命令如下：

<pre>tr -cd "\t\n\40-\176" &gt; /path/to/filename_new.log &lt; /path/to/filename.og
</pre>

怎么样，这条命令，你看懂了么？





 [1]: http://tinylab.org
