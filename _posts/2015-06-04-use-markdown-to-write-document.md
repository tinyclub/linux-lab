---
title: 用 Markdown 写文档
author: Wu Zhangjin
layout: post
album: Markdown 用法详解
permalink: /use-markdown-to-write-document/
tags:
  - Article
  - 文档
categories:
  - Markdown
---

> by Falcon of [TinyLab.org][1]
> 2015/05/11


## 背景

Markdown 让人回归内容创作本身，本站第四篇关于 Markdown 的文章，这次介绍如何用 Markdown 写中文文档。

## 下载仓库

    git clone https://github.com/tinyclub/markdown-lab.git
    cd markdown-lab/article/


## 安装环境

    sudo apt-get install pandoc
    sudo apt-get install texlive-xetex texlive-latex-recommended texlive-latex-extra

    sudo apt-get install ttf-arphic-gbsn00lp ttf-arphic-ukai # from arphic
    sudo apt-get install ttf-wqy-microhei ttf-wqy-zenhei     # from WenQuanYi


## 编辑文档

请参照如下两篇使用 Markdown 语法编写文档。

  * [Markdown基本语法][2]
  * [Pandoc&#8217;s Markdown语法][3]

## 编译并查看

    make && make read


编译完会生成一份 doc.pdf 文档。





 [1]: http://tinylab.org
 [2]: https://www.markdownguide.org/basic-syntax
 [3]: http://pandoc.org/demo/example19/Pandoc_0027s-Markdown.html
