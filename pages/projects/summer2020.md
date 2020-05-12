---
title: 'Open Source Promotion Plan - Summer 2020'
tagline: '“开源软件供应链点亮计划——暑期2020”项目提案'
author: Wu Zhangjin
draft: true
layout: page
permalink: /summer2020/
description: 国内第一次组织类似 Google Summer of Code 的开源活动，泰晓科技技术社区踊跃报名，将携 Cloud Lab、Linux Lab、Markdown Lab 等项目参加，欢迎大家报名。
update: 2020-05-13
categories:
  - 开源项目
  - Linux Lab
  - Cloud Lab
  - Markdown Lab
tags:
  - 暑期2020
  - 点亮计划
---

## 项目简介

2020 年，中科院软件所与华为 openEuler 项目共同举办了 [“开源软件供应链点亮计划——暑期2020”](https://isrc.iscas.ac.cn/summer2020/) 项目。

该项目与 GSoC 形式类似：

* 开源社区提供项目需求并提供导师（mentor）
* 在校学生利用暑期时间进行开发
* 主办方为顺利完成的项目提供一定额度的奖金

这类项目是连接高校和社区，连接学生和企业工程师，连接理论和实践的非常棒的纽带。

泰晓科技作为 Linux 技术社区加入这一计划，带来了多个具有挑战性的项目需求，欢迎同学们踊跃报名。

这里是需求梗概，方便速览：

| 需求                   |  描述                                                                   | 关联项目
|------------------------|-------------------------------------------------------------------------|-------------
| Perf Lab  性能实验室   | 基于 Cloud Lab 的易用性和可扩展性，开发一款便利系统性能优化的环境       | [Cloud Lab](http://tinylab.org/cloud-lab)
| Linux Lab 镜像升级     | 把当前镜像从 Ubuntu 14.04 升级到 Ubuntu 20.04，满足各类软件开发需要     | [Linux Lab](http://tinylab.org/linux-lab)
| Linux Lab 模块化支持   | 为 Linux Lab 添加模块化支持，增加可扩展性，进一步提升对各类新软件的支持 | [Linux Lab](http://tinylab.org/linux-lab)
| Markdown Lab 功能增强  | 为 Markdown Lab 完善中文支持、美化 PDF 输出格式、增加加密和水印功能等   | [Markdown Lab](http://tinylab.org/markdown-lab)

详细需求如下。

## 需求列表

### 项目一

1. 项目标题：Perf Lab 性能实验室
2. 项目描述：性能优化是提升产品用户体验的关键，也是所有产品走向高端的必由之路。Linux 系统上的性能优化工具日新月异，从早年的 Oprofile，Ftrace，Systemtap 到如今的 Perf, eBPF，日渐完善，不断强大。但是对于初学者，这些新工具的使用门槛很高，本项需求的目标是基于 [Cloud Lab](http://tinylab.org/cloud-lab) 构建一个开箱即可上手的系统性能优化工具箱，囊括各种常见的系统性能优化工具，并提供配套的实际开发案例。
3. 项目难度：高
4. 项目社区导师：@rxd
5. 导师联系方式：rxd@tinylab.org
6. 合作导师联系方式：lzufalcon, falcon@tinylab.org
7. 项目产出要求：
   - 在 Cloud Lab 中新增 perf-lab，需兼容 [Cloud Lab 现有接口](http://tinylab.org/how-to-deploy-cloud-labs/)
   - 构建并发布基于 Ubuntu 20.04 或同时期 Linux 发行版的 Docker 镜像
   - 集成 ftrace, trace-cmd, kernelshark, perf, ebpf 等性能优化工具
   - 上线 perf-lab 项目首页、中英文用户手册和代码仓库
8. 项目技术要求：
   - 基本的 Linux 命令
   - 熟悉 Makefile 和 Bash
   - Docker 安装、使用与镜像制作
   - 使用过 Cloud Lab 下面的某个现有 Lab
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Linux Lab: <https://gitee.com/tinylab/linux-lab>


### 项目二

1. 项目标题：Linux Lab 镜像升级
2. 项目描述：[Linux Lab](http://tinylab.org/linux-lab) 是一个 Linux 内核实验环境，当前已经支持国内外的 7 大主流处理器架构和 16 款开发版。当前环境基于 Ubuntu 14.04，难以适应各类软件新版本的开发需要，本项需求旨在升级当前环境到最新的 Ubuntu 20.04 或者其他更为合适的同时期 Linux 发行版。
3. 项目难度：高
4. 项目社区导师：@lzufalcon
5. 导师联系方式：falcon@tinylab.org
6. 合作导师联系方式：
7. 项目产出要求：
   - 构建并发布基于 Ubuntu 20.04 或同时期 Linux 发行版的 Docker 镜像
   - 确保镜像大小不超过 5G
   - 兼容现有 Linux Lab 功能
   - 确保内置工具链能够编译历史版本（比如 v2.4, v2.6）的 Linux 内核
   - 新增更多开发与调试工具
8. 项目技术要求：
   - 基本的 Linux 命令
   - 熟悉 Makefile 和 Bash
   - 熟悉 Docker 的安装、使用与镜像制作
   - 熟练使用 Linux Lab
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Linux Lab: <https://gitee.com/tinylab/linux-lab>

### 项目三

1. 项目标题：Linux Lab 模块化支持
2. 项目描述：[Linux Lab](http://tinylab.org/linux-lab) 是一个 Linux 内核实验环境，当前已支持 Linux、Buildroot、Uboot 和 Qemu 四大核心软件，但是当前软件支持的耦合度非常高。本项需求旨在解耦，把各个软件的支持拆解到独立的软件支持文件中，增加可扩展性，从而方便进一步导入其他软件实验功能。
3. 项目难度：高
4. 项目社区导师：@lzufalcon
5. 导师联系方式：falcon@tinylab.org
6. 合作导师联系方式：
7. 项目产出要求：
   - 拆解核心 Makefile 为多个文件，方便单独维护
   - 新增 core 目录，导入函数库、Init、Boot、Test、Debug、Fini 等公共模块文件
   - 把对软件的支持拆解到 packages 目录下，每个软件有独立支持文件
   - 兼容现有 Linux Lab 功能
8. 项目技术要求：
   - 基本的 Linux 命令
   - 熟悉 Makefile 和 Bash
   - 熟悉 Docker 的安装与使用
   - 熟练使用 Linux Lab
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Linux Lab: <https://gitee.com/tinylab/linux-lab>

### 项目四

1. 项目标题：Markdown Lab 功能增强
2. 项目描述：[Markdown Lab](http://tinylab.org/markdown-lab) 是一个 Markdown 编辑环境，当前内置简历、文档、幻灯和书籍的 Markdown 模板，可导出为 html 和 pdf，本项需求旨在进一步完善中文支持、美化 PDF 输出格式、增加加密和水印功能等。
3. 项目难度：中
4. 项目社区导师：@lzufalcon
5. 导师联系方式：falcon@tinylab.org
6. 合作导师联系方式：
7. 项目产出要求：
   - 完善中文支持，新增更多字体库、简化字体配置、完善加粗和等宽等支持。
   - 增加文档加密和水印功能。
   - 美化输出格式，包括代码、目录、表格等
8. 项目技术要求：
   - 基本的 Linux 命令
   - 熟悉 Makefile、Latex 和 Markdown
   - 熟悉 Markdown Lab
9. 相关的开源软件仓库列表：
   - Cloud Lab: <https://gitee.com/tinylab/cloud-lab>
   - Markdown Lab: <https://gitee.com/tinylab/markdown-lab>
