---
title: 用 Markdown 制作简历
author: Wu Zhangjin
layout: post
album: Markdown 用法详解
permalink: /write-resume-with-markdown/
tags:
  - 简历
  - Latex
  - Markdown
  - Resume
categories:
  - Markdown
---

> by Falcon of [TinyLab.org][1]
> 2015/05/10


## 背景

Markdown 彻底地让人回归内容创作本身，本站已经连续写了两篇文章，介绍如何用 Markdown 写书和演示文稿：

  * [Docker 快速上手：用 Docker + GitBook 写书][2]
  * [用 Markdown 高效地写幻灯片][3]

本文继续第三篇：如何用 Markdown 写简历。

简历 —— 简单介绍自己的阅历，所以用 Markdown 好好写阅历，没必要搞得各种华丽，简约清新即可。

这次咱们直接重用网上的项目：

  * [mwhite/resume][4]
  * [there4/markdown-resume][5]

两者都允许直接用 Markdown 写简历，并提供工具转化为 pdf 或者 html 格式，输出的风格稍有差异。

作为对比，我们同时介绍了一款 Latex 模板，大家可以参照对比 Latex 和 Markdown 谁更简易。

## <span id="mwhiteresume">方案一：<a href="https://github.com/mwhite/resume">mwhite/resume</a></span>

由于原项目的 pandoc/default.latex 有一处错误，导致中文支持编译失败，本站修复后创建了一个独立仓库，用法如下。

### 下载仓库

    git clone https://github.com/tinyclub/markdown-resume.git


### 安装环境

    apt-get install texlive texlive-latex-extra tex-gyre texlive-xetex ttf-wqy-zenhei pandoc


### 编辑简历

参照 resume.md 编写即可。原文格式为英文，可直接用中文混合改写。语法格式为 Markdown。

### 编译

  * 输出为 pdf

        make pdf


  * 输出为 html

        make html


## <span id="there4markdown-resume">方案二：<a href="https://github.com/there4/markdown-resume">there4/markdown-resume</a></span>

### 下载仓库

    git clone https://github.com/there4/markdown-resume.git


### 安装环境

    sudo apt-get install wkhtmltopdf


### 编辑简历

examples/source/ 下有几份样稿可参照，其中 zhsample.md 为中文样稿，语法格式为 Markdown。

### 编译

  * 输出为 pdf

        ./bin/md2resume pdf examples/source/zhsample.md examples/output/


  * 输出为 html

        ./bin/md2resume pdf examples/source/zhsample.md examples/output/


## <span id="tinylablatex-resume">方案三：<a href="https://github.com/tinyclub/latex-resume">tinylab/latex-resume</a></span>

### 下载仓库

    git clone https://github.com/tinyclub/latex-resume.git


### 安装环境

    sudo apt-get install latex-cjk-common latex-cjk-chinese latex-cjk-chinese-arphic-bkai00mp latex-cjk-chinese-arphic-bsmi00lp latex-cjk-chinese-arphic-gbsn00lp latex-cjk-chinese-arphic-gkai00mp texlive-fonts-recommended imagemagick


### 编辑简历

这里的简历用 Latex 编写，中文和英文分别放在 zh/ 与 en/ 目录下，默认简历文本都是 resume.tex，打开可利用 Latex 语法编辑。

其中，中文模板有用到一个头像，图片是 photo.jpg。

### 编译

  * 中文

        cd zh && make


  * 英文

        cd en && make


## 对比

方案一和二都可用 Markdown 编写，只是输出方式有异，大家可根据自身爱好选择。

方案三用 Latex 编写，主要差异在 Latex 语法相比 Markdown 复杂很多，嵌入了过多的格式控制字符，所以简历还是比较推荐用 Markdown 编写，节约时间和生命。

## 参考资料

  * [Markdown基本语法][6]
  * [Pandoc Markdown 语法][7]





 [1]: http://tinylab.org
 [2]: /docker-quick-start-docker-gitbook-writing-a-book/
 [3]: /use-markdown-to-write-slides/
 [4]: https://github.com/mwhite/resume
 [5]: https://github.com/there4/markdown-resume
 [6]: http://wowubuntu.com/markdown/
 [7]: http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html
