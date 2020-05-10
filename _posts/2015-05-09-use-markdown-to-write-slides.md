---
title: 用 Markdown 高效地写幻灯片
author: Wu Zhangjin
layout: post
album: Markdown 用法详解
permalink: /use-markdown-to-write-slides/
tags:
  - Slides
  - 幻灯
categories:
  - Markdown
---

> By Falcon of [TinyLab.org][1]
> 2015/05/08

【**背景**：笔者用 M$ PowerPoint, Libreoffice Draw, LaTeX 等写过幻灯，没有一个是令人省心的工具，没有一个能让人专注于内容创作本身。繁杂的格式、字体、以及所谓特效调节让人困惑烦恼，自从有了 Markdown，让思绪自由流畅不受阻，让创作回归内容本身，把那些繁杂的演示效果交给其他专业的人士打理就好。】


# 准备环境

## 安装pandoc

  * 以Ubuntu为例

        sudo apt-get install pandoc


  * 其他平台

    请参考[pandoc首页][2]

## 安装LaTeX以及中文支持

  * 以Ubuntu为例

        $ sudo apt-get install texlive-xetex \
            texlive-latex-recommended \
            texlive-latex-extra \
            latex-cjk-common latex-cjk-chinese \
            latex-cjk-chinese-arphic-bkai00mp \
            latex-cjk-chinese-arphic-bsmi00lp \
            latex-cjk-chinese-arphic-gbsn00lp \
            latex-cjk-chinese-arphic-gkai00mp \


## 安装Beamer

  * 以Ubuntu为例

        sudo apt-get install latex-beamer


  * 相关用法与实例

        $ ls /usr/share/doc/latex-beamer/
        beameruserguide.pdf.gz
        examples
        solutions


## 安装字体

        $ sudo apt-get install \
            fonts-arphic-bkai00mp \
            fonts-arphic-bsmi00lp \
            fonts-arphic-gbsn00lp \
            fonts-arphic-gkai00mp \
            ttf-wqy-microhei \
            ttf-wqy-zenhei


## 配置字体

  * 列出可选字体

        $ fc-list | egrep "wqy|AR"


  * 实例配置：需配置zh_template.tex如下：

        \setCJKmainfont{AR PL KaitiM GB} % 中文字体


# 编写幻灯

## 幻灯首页

  * 前三行分别对应

      * 标题
      * 作者
      * 日期

  * 例如：

        % Markdown+Beamer+Pandoc幻灯片模板
        % 吴章金 @ 泰晓科技 | TinyLab.org
        % \today


## 幻灯正文

  * 支持如下语法

      * [Markdown基本语法][3]
      * [Pandoc Markdown语法][4]
      * LaTeX语法：[1][5],[2][6]

  * 实例

        # In the morning

        ## Getting up

        - Turn off alarm
        - Get out of bed


# 格式转换

## 生成pdf

  * 利用该模板

        $ make pdf & make read


  * 原生命令

        $ pandoc -t beamer --toc \
            -V theme:Darmstadt \
            -V fontsize:9pt \
            slides.md -o slides.pdf \
            --latex-engine=xelatex \
            --template=./templates/zh_template.tex


## 生成html

  * 利用该模板

    $ make html & make read-html

  * 原始命令

        $ pandoc -t dzslides -s --mathjax \
            slides.md -o slides.html


# 实例

## 以本文稿为例

  * 下载 Markdown 幻灯模板

        $ git clone https://github.com/tinyclub/markdown-lab.git
        $ cd markdown-lab/slides/


  * 编译成 pdf & html

        $ make


  * 浏览

        $ make read & make read-html


# 参考资料


  * [Write Beamer or Html slide using Markdown and Pandoc][7]
  * [Producing slide shows with pandoc][8]





 [1]: http://tinylab.org
 [2]: http://johnmacfarlane.net/pandoc/installing.html
 [3]: https://www.markdownguide.org/basic-syntax
 [4]: http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html
 [5]: http://www.maths.tcd.ie/~dwilkins/LaTeXPrimer/
 [6]: http://latex-project.org/guides/
 [7]: https://github.com/herrkaefer/herrkaefer.github.io/blob/master/_posts/2013-12-17-write-beamer-or-html-slide-using-markown-and-pandoc.markdown
 [8]: http://johnmacfarlane.net/pandoc/README.html#producing-slide-shows-with-pandoc
