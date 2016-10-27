---
layout: post
author: 'Wu Zhangjin'
title: "泰晓携手青云向高校开放在线实验环境"
group: original
permalink: /free-online-linux-labs/
description: "为便利嵌入式 Linux 系统学习，泰晓科技不仅撰写了一系列原创技术文章和一些开源书籍，而且基于 Docker 开发了一系列辅助学习的易构实验环境，如今更是携手青云，让这些环境可以直接通过网络访问，大大降低了学习的门槛。"
category:
  - 开发环境
tags:
  - 青云
  - QingCloud
  - Online Lab
  - 在线实验环境
  - Linux 0.11
  - Linux Lab
  - Linux
---

> By Falcon of [TinyLab.org][1]
> 2016-10-28 02:31:18

## 背景简介

为便利嵌入式 Linux 系统学习，泰晓科技不仅撰写了一系列原创技术文章和一些[开源书籍][10]，而且基于 Docker 开发了一系列辅助学习的[易构实验环境][11]，如今更是携手 青云QingCloud，让这些环境可以直接通过网络访问，大大降低了学习的门槛。

根据自己以往的学习经验，作为工程类的课程，课外实践非常重要：“纸上得来终觉浅，绝知此事要躬行”。

非常可惜地是，很多课程的配套实验环境非常难以搭建，门槛很高，搭建一个环境都可能要个把礼拜甚至几个礼拜，有的还需要采购一些额外的硬件设备，这也缺那也缺，到最后往往浪费精力而且可能不了了之，因此这些实验环境往往成为了拦路虎。

鉴于此，泰晓科技开发了一系列实验环境。

## 实验环境介绍

下面是泰晓科技截止到现在开发的实验环境中的其中 4 个：

|-----------------------------------|----------------------------------------------------------|
| 实验环境                          | 简介                                                     |
|-----------------------------------|----------------------------------------------------------|
| [CS630 Qemu Lab](/cs630-qemu-lab) | 为旧金山大学的一门在线 X86 Linux [汇编课程][12]开发的实验环境。适合学习 Linux 汇编语言。|
| [Linux 0.11 Lab](/linux-0.11-lab) | 为赵老师[Linux 0.11 内核完全注释][2]一书开发的实验环境。适合学习操作系统课程。|
| [Linux Lab](/linux-lab)           | 为 Linux 内核以及嵌入式 Linux 准备的一款实验/开发环境。适合学习 C 语言、汇编、嵌入式 Linux、Shell、并深入研究 Linux 内核。内置十几个处理器架构和几十款免费开发板。|
| [Markdown Lab ](/markdown-lab)    | 为 Markdown 开发的一款编辑环境，支持幻灯、书籍、文章和简历，可导出 pdf 和 html。|
|-----------------------------------|-------------------------------------------------------------|

更多实验环境正在开发和集成中，后续计划尽快导入 Android、IoT 等开发环境。

这些实验环境支持 Docker，已经构建了相应镜像并推送到了 Docker Hub。大家可自行下载并参照各个项目文档进行使用。

|-----------------------------------|------------------------|-----------------------------
| 实验环境                          | Docker 镜像名          | 在线演示效果               |
|-----------------------------------|------------------------|----------------------------|
| [CS630 Qemu Lab](/cs630-qemu-lab) | tinylab/cs630-qemu-lab | [showterm.io][3]           |
| [Linux 0.11 Lab](/linux-0.11-lab) | tinylab/linux-0.11-lab | [showterm.io][4]           |
| [Linux Lab](/linux-lab)           | tinylab/linux-lab      | [showterm.io][5]           |
| [Markdown Lab ](/markdown-lab)    | tinylab/markdown-lab   | [showterm.io][6]           |
|-----------------------------------|------------------------|----------------------------|

所有实验环境可以通过 [Cloud-Lab][7] 管理，用法如下：


    // 下载 cloud-lab，主要是一系列管理实验环境的脚本
    $ git clone https://github.com/tinyclub/cloud-lab.git
    $ cd cloud-lab/

    // 查看现在已经支持的实验环境
    $ ls configs/
    cs630-qemu-lab  linux-0.11-lab  linux-lab  linux-talents  markdown-lab  qing-lab  tinylab.org

    // Download lab source code
    $ tools/docker/choose linux-0.11-lab

    // Pull the docker image from docker hub
    $ tools/docker/pull
    OR
    // Build the docker image from Dockfile
    $ tools/docker/build

    // 运行 Docker image 并自动加载浏览器访问实验环境，可通过控制台打印的密码登陆
    $ tools/docker/run

需要提到的是，`qing-lab` 集成了上述所有其他的实验环境，可同时满足不同课程的学习。而 `qing-lab` 一名一方面是为了感谢 青云QingCloud 的赞助，另外一方面也有 **轻** 的意思，即轻巧、轻量。

## 免费申请在线环境

考虑到上述环境还要求安装 Docker 的工作环境，为了进一步便利化，我们得到 青云QingCloud 的赞助，申请到了一台云服务器，并在上面部署了这些实验环境。

这些实验环境优先向高校 Linux 相关社团免费开放，但是由于服务器资源有限，我们暂时做如下要求：

* 每个高校 Linux 社团必须撰写一篇团队介绍文章并提交到 [Linux Talents][8]，这是一个连接高校和企业 Linux 团队的平台，目前已经有几十所高校，十几家知名企业加入。该平台主要目标是让高校人才和企业用人单位负责人能够面对面，直接打通校园和企业的人才交流通道，并籍此促进更具质量的人才培养。

* 提交完团队介绍文章后，社团负责人可申请加入“校企 Linux 团队直通车” 专属微信群。

* 之后按需申请上述实验环境的访问帐号，并说明用途。暂时限定每个团队最多可申请 3 个访问帐号。

* 为了提高这些环境的利用率和产出，我们同时要求每个帐号每个月需要输出一篇原创学习文章到本站。如果无法按时达成就需要收回帐号使用权限。

上述限制条件会随着服务器资源的使用情况适当调整，敬请关注这篇文章的后续更新。

也欢迎企业的 Linux 社团负责人加入上述“校企 Linux 团队直通车” 专属微信群，为了支持高校 Linux 社团的建设以及相关服务器的开支，请到 [泰晓开源小店][9] 赞助后，再申请加入。已经加入但是还没有赞助的同学，可以酌情支持。

即日起，各高校 Linux 相关社团可遵照上述规则开始免费申请。

其他个人或者企业如果需要短时间体验上述环境，也可以到 [泰晓开源小店][9] 选择对应的实验环境进行赞助。


[1]: http://tinylab.org
[2]: http://oldlinux.org/download/clk011c-1.9.5.pdf
[3]: http://showterm.io/547ccaae139df14c3deec
[4]: http://showterm.io/ffb67385a07fd3fcec182
[5]: http://showterm.io/6fb264246580281d372c6
[6]: http://showterm.io/1809186b57f904d51aeff
[7]: http://github.com/tinyclub/cloud-lab.git
[8]: http://linux-talents.tinylab.org
[9]: http://weidian.com/?userid=335178200
[10]: /books
[11]: /projects
[12]: http://www.cs.usfca.edu/~cruse/cs630f06/
