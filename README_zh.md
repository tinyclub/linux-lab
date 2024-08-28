<!-- metadata start --><!--
% Linux Lab v1.4 中文手册
% [泰晓科技 | Tinylab.org][077]
% \today
--><!-- metadata end -->

![Linux Lab Logo](doc/images/linux-lab-logo.jpg)

**订阅公众号，关注项目状态：**

![扫码订阅“泰晓科技”公众号](doc/images/tinylab-wechat.jpg)

<!-- toc start -->

# 目录

- [1. Linux Lab 概览](#1-linux-lab-概览)
  - [1.1 项目简介](#11-项目简介)
  - [1.2 项目主页](#12-项目主页)
  - [1.3 演示视频](#13-演示视频)
    - [1.3.1 开放教程](#131-开放教程)
    - [1.3.2 付费课程](#132-付费课程)
  - [1.4 项目功能](#14-项目功能)
  - [1.5 项目历史](#15-项目历史)
    - [1.5.1 项目起源](#151-项目起源)
    - [1.5.2 项目缘由](#152-项目缘由)
    - [1.5.3 项目诞生](#153-项目诞生)
  - [1.6 项目变更](#16-项目变更)
    - [1.6.1 v0.1 @ 2019.06.28](#161-v01--20190628)
    - [1.6.2 v0.2 @ 2019.10.30](#162-v02--20191030)
    - [1.6.3 v0.3 @ 2020.03.12](#163-v03--20200312)
    - [1.6.4 v0.4 @ 2020.06.01](#164-v04--20200601)
    - [1.6.5 v0.5 @ 2020.09.12](#165-v05--20200912)
    - [1.6.6 v0.6 @ 2021.02.06](#166-v06--20210206)
    - [1.6.7 v0.7 @ 2021.06.03](#167-v07--20210603)
    - [1.6.8 v0.8 @ 2021.10.13](#168-v08--20211013)
    - [1.6.9 v0.9 @ 2022.01.13](#169-v09--20220113)
    - [1.6.10 v1.0 @ 2022.06.16](#1610-v10--20220616)
    - [1.6.11 v1.1 @ 2022.11.09](#1611-v11--20221109)
    - [1.6.12 v1.2 @ 2023.07.09](#1612-v12--20230709)
    - [1.6.13 v1.3 @ 2024.03.17](#1613-v13--20240317)
    - [1.6.14 v1.4 @ 2024.08.25](#1614-v14--20240825)
- [2. Linux Lab 安装](#2-linux-lab-安装)
  - [2.1 软硬件要求](#21-软硬件要求)
  - [2.2 安装 Docker](#22-安装-docker)
  - [2.3 选择工作目录](#23-选择工作目录)
  - [2.4 切换到普通用户帐号](#24-切换到普通用户帐号)
  - [2.5 下载实验环境](#25-下载实验环境)
  - [2.6 运行并登录 Linux Lab](#26-运行并登录-linux-lab)
  - [2.7 更新实验环境并重新运行](#27-更新实验环境并重新运行)
  - [2.8 快速上手：启动一个开发板](#28-快速上手：启动一个开发板)
- [3. Linux Lab 入门](#3-linux-lab-入门)
  - [3.1 使用开发板](#31-使用开发板)
    - [3.1.1 列出支持的开发板](#311-列出支持的开发板)
    - [3.1.2 选择一个开发板](#312-选择一个开发板)
      - [3.1.2.1 真实开发板](#3121-真实开发板)
      - [3.1.2.2 虚拟开发板](#3122-虚拟开发板)
      - [3.1.2.3 如何选购](#3123-如何选购)
    - [3.1.3 以插件方式使用](#313-以插件方式使用)
    - [3.1.4 配置开发板](#314-配置开发板)
  - [3.2 一键自动编译](#32-一键自动编译)
  - [3.3 详细步骤分解](#33-详细步骤分解)
    - [3.3.1 下载](#331-下载)
    - [3.3.2 检出](#332-检出)
    - [3.3.3 打补丁](#333-打补丁)
    - [3.3.4 配置](#334-配置)
      - [3.3.4.1 缺省配置](#3341-缺省配置)
      - [3.3.4.2 手动配置](#3342-手动配置)
      - [3.3.4.3 使用旧的缺省配置](#3343-使用旧的缺省配置)
    - [3.3.5 编译](#335-编译)
    - [3.3.6 保存](#336-保存)
    - [3.3.7 启动](#337-启动)
- [4. Linux Lab 进阶](#4-linux-lab-进阶)
  - [4.1 Linux 内核](#41-linux-内核)
    - [4.1.1 非交互方式配置](#411-非交互方式配置)
    - [4.1.2 使用内核模块](#412-使用内核模块)
    - [4.1.3 使用内核特性](#413-使用内核特性)
      - [4.1.3.1 列出当前支持的 feature](#4131-列出当前支持的-feature)
      - [4.1.3.2 启用内核模块支持](#4132-启用内核模块支持)
      - [4.1.3.3 启用 rust feature](#4133-启用-rust-feature)
      - [4.1.3.4 启用 kft feature](#4134-启用-kft-feature)
      - [4.1.3.5 启用 rt feature](#4135-启用-rt-feature)
      - [4.1.3.6 持久化与清理 feature 设定](#4136-持久化与清理-feature-设定)
    - [4.1.4 新建开发分支](#414-新建开发分支)
    - [4.1.5 启用独立内核仓库](#415-启用独立内核仓库)
  - [4.2 U-Boot 引导程序](#42-u-boot-引导程序)
  - [4.3 QEMU 模拟器](#43-qemu-模拟器)
  - [4.4 Toolchain 工具链](#44-toolchain-工具链)
  - [4.5 Rootfs 文件系统](#45-rootfs-文件系统)
  - [4.6 Linux 与 U-Boot 调试](#46-linux-与-u-boot-调试)
    - [4.6.1 调试 Linux](#461-调试-linux)
    - [4.6.2 调试 U-Boot](#462-调试-u-boot)
  - [4.7 自动化测试](#47-自动化测试)
  - [4.8 文件共享](#48-文件共享)
    - [4.8.1 在 rootfs 中安装文件](#481-在-rootfs-中安装文件)
    - [4.8.2 采用 NFS 共享文件](#482-采用-nfs-共享文件)
    - [4.8.3 通过 tftp 传输文件](#483-通过-tftp-传输文件)
    - [4.8.4 通过 9p virtio 共享文件](#484-通过-9p-virtio-共享文件)
  - [4.9 学习汇编](#49-学习汇编)
  - [4.10 学习 C 语言](#410-学习-c-语言)
    - [4.10.1 本地编译和运行](#4101-本地编译和运行)
    - [4.10.2 交叉编译和运行](#4102-交叉编译和运行)
  - [4.11 运行任意的 make 目标](#411-运行任意的-make-目标)
  - [4.12 提升内核开发效率](#412-提升内核开发效率)
    - [4.12.1 编译加速并减少磁盘损耗](#4121-编译加速并减少磁盘损耗)
    - [4.12.2 ONESHOT 模式](#4122-oneshot-模式)
    - [4.12.3 Nolibc 模式](#4123-nolibc-模式)
    - [4.12.4 Tiny 模式](#4124-tiny-模式)
  - [4.13 更多用法](#413-更多用法)
- [5. Linux Lab 开发](#5-linux-lab-开发)
  - [5.1 选择一个 QEMU 支持的开发板](#51-选择一个-qemu-支持的开发板)
  - [5.2 创建开发板的目录](#52-创建开发板的目录)
  - [5.3 从一个已经支持的开发板中复制一份 Makefile](#53-从一个已经支持的开发板中复制一份-makefile)
  - [5.4 从头开始配置变量](#54-从头开始配置变量)
  - [5.5 同时准备 configs 文件](#55-同时准备-configs-文件)
  - [5.6 选择 kernel，rootfs 和 U-Boot 的版本](#56-选择-kernelrootfs-和-u-boot-的版本)
  - [5.7 配置，编译和启动](#57-配置编译和启动)
  - [5.8 保存生成的镜像文件和配置文件](#58-保存生成的镜像文件和配置文件)
  - [5.9 上传所有工作](#59-上传所有工作)
- [6. 常见问题](#6-常见问题)
  - [6.1 Docker 相关](#61-docker-相关)
    - [6.1.1 docker 下载速度慢](#611-docker-下载速度慢)
    - [6.1.2 Docker 网络与 LAN 冲突](#612-docker-网络与-lan-冲突)
    - [6.1.3 本地主机不能运行 Linux Lab](#613-本地主机不能运行-linux-lab)
    - [6.1.4 非 root 无法运行 tools 命令](#614-非-root-无法运行-tools-命令)
    - [6.1.5 网络不通](#615-网络不通)
    - [6.1.6 Client.Timeout exceeded while waiting headers](#616-clienttimeout-exceeded-while-waiting-headers)
    - [6.1.7 关机或重启主机后如何恢复运行 Linux Lab](#617-关机或重启主机后如何恢复运行-linux-lab)
    - [6.1.8 the following directives are specified both as a flag and in the configuration file](#618-the-following-directives-are-specified-both-as-a-flag-and-in-the-configuration-file)
    - [6.1.9 pathspec FETCH_HEAD did not match any file known to git](#619-pathspec-fetch_head-did-not-match-any-file-known-to-git)
    - [6.1.10 Docker not work in Ubuntu 20.04](#6110-docker-not-work-in-ubuntu-2004)
    - [6.1.11 Error creating aufs mount](#6111-error-creating-aufs-mount)
  - [6.2 QEMU 相关](#62-qemu-相关)
    - [6.2.1 缺少 KVM 加速](#621-缺少-kvm-加速)
    - [6.2.2 Guest 关机或重启后挂住](#622-guest-关机或重启后挂住)
    - [6.2.3 如何退出 QEMU](#623-如何退出-qemu)
    - [6.2.4 Boot 时报缺少 sdl2 库](#624-boot-时报缺少-sdl2-库)
  - [6.3 环境相关](#63-环境相关)
    - [6.3.1 NFS 与 tftpboot 不工作](#631-nfs-与-tftpboot-不工作)
    - [6.3.2 在 VIM 中无法切换窗口](#632-在-vim-中无法切换窗口)
    - [6.3.3 长按 Backspace 不工作](#633-长按-backspace-不工作)
    - [6.3.4 如何快速切换中英文输入](#634-如何快速切换中英文输入)
    - [6.3.5 如何调节 Web 界面窗口的大小](#635-如何调节-web-界面窗口的大小)
    - [6.3.6 如何进入全屏模式](#636-如何进入全屏模式)
    - [6.3.7 如何录屏](#637-如何录屏)
    - [6.3.8 Web 界面无响应](#638-web-界面无响应)
    - [6.3.9 登录 WEB 界面时超时或报错](#639-登录-web-界面时超时或报错)
    - [6.3.10 Ubuntu Snap 问题](#6310-ubuntu-snap-问题)
    - [6.3.11 如何退出 VNC 客户端全屏模式](#6311-如何退出-vnc-客户端全屏模式)
  - [6.4 Linux Lab 相关](#64-linux-lab-相关)
    - [6.4.1 No working init found](#641-no-working-init-found)
    - [6.4.2 linux/compiler-gcc7.h: No such file or directory](#642-linuxcompiler-gcc7h-no-such-file-or-directory)
    - [6.4.3 linux-lab/configs: Permission denied](#643-linux-labconfigs-permission-denied)
    - [6.4.4 scripts/Makefile.headersinst: Missing UAPI file](#644-scriptsmakefileheadersinst-missing-uapi-file)
    - [6.4.5 unable to create file: net/netfilter/xt_dscp.c](#645-unable-to-create-file-netnetfilterxt_dscpc)
    - [6.4.6 如何切到 root 用户](#646-如何切到-root-用户)
    - [6.4.7 提示指定的版本或者配置不存在](#647-提示指定的版本或者配置不存在)
    - [6.4.8 is not a valid rootfs directory](#648-is-not-a-valid-rootfs-directory)
- [7. 联系并赞助我们](#7-联系并赞助我们)
  - [7.1 联系方式](#71-联系方式)
  - [7.2 关注并参与](#72-关注并参与)
  - [7.3 付费支持我们](#73-付费支持我们)
  - [7.4 扫码提供赞助](#74-扫码提供赞助)
    - [7.4.1 赞助我们](#741-赞助我们)
    - [7.4.2 赞助列表](#742-赞助列表)

<!-- toc end -->

# 1. Linux Lab 概览

## 1.1 项目简介

本项目致力于创建一个基于 Docker + QEMU 的 Linux 实验环境，方便大家学习、开发和测试 [Linux 内核][075]。

Linux Lab 是一个开源软件，不提供任何保证，请自行承担使用过程中的任何风险。

[![Linux Lab 项目启动示意图](doc/images/linux-lab.png)][076]

**温馨提示**：泰晓社区研发了**免安装**的 [Linux Lab Disk][028]（也叫 “泰晓 Linux 实验盘”），可以从 [泰晓开源小店][023] 或 [泰晓 B 站工房](https://space.bilibili.com/687228362) 选购，也可以在淘宝手机 APP 内搜索 “泰晓 Linux” 后购买。

## 1.2 项目主页

* 主页
    * <https://tinylab.org/linux-lab/>
    * <https://oschina.net/p/linux-lab>

* 仓库
    * <https://gitee.com/tinylab/linux-lab>
    * <https://github.com/tinyclub/linux-lab>

关联项目：

* Cloud Lab
    * Linux Lab 运行环境管理工具，自带图形和命令行界面，支持本地和远程登陆
    * <https://tinylab.org/cloud-lab>

* Linux 0.11 Lab
    * 用于 Linux 0.11 学习，今后仅集成到 [Linux Lab Disk][028]，即泰晓 Linux 实验盘
    * 下载到 `labs/linux-0.11-lab` 后，可直接在 Linux Lab 内使用
    * <https://tinylab.org/linux-0.11-lab>

* CS630 QEMU Lab
    * 用于 X86 Linux 汇编学习，今后仅集成到 [Linux Lab Disk][028]，即泰晓 Linux 实验盘
    * 下载到 `labs/cs630-qemu-lab` 后，可直接在 Linux Lab 内使用
    * <https://tinylab.org/cs630-qemu-lab>

* RVOS Lab
    * 用于 RISC-V OS 在线课程学习，已集成到 [Linux Lab Disk][028]，即泰晓 Linux 实验盘
    * 下载到 `src/examples` 后，可直接在 Linux Lab 内做实验
    * <https://gitee.com/tinylab/rvos-lab>

* GUI Lab
    * 用于学习嵌入式图形系统，如 Guilite，已集成到 [Linux Lab Disk][028]，即泰晓 Linux 实验盘
    * 下载到 `src/examples` 后，可直接在 Linux Lab 内做实验
    * <https://gitee.com/tinylab/gui-lab>

* RISC-V Linux
    * 用于研究 RISC-V 架构的 Linux 内核以及周边技术，已集成到 [Linux Lab Disk][028]，即泰晓 Linux 实验盘
    * 下载到 `src/examples` 后，可直接在 Linux Lab 内做实验
    * <https://gitee.com/tinylab/riscv-linux>

* RISC-V Lab
    * 用于学习嵌入式 RISC-V 软件开发，已集成到 [Linux Lab Disk][028]，即泰晓 RISC-V 实验盘
    * <https://gitee.com/tinylab/riscv-lab>

* ARM Lab
    * 用于学习嵌入式 ARM 软件开发，已集成到 [Linux Lab Disk][028]，即泰晓 ARM 实验盘
    * <https://gitee.com/tinylab/arm-lab>

## 1.3 演示视频

### 1.3.1 开放教程

* [Linux Lab 公开课][071]
    * Linux Lab 简介
    * 龙芯 Linux 内核开发
    * Linux Lab Disk 使用演示
    * Linux Lab 发布会视频回放
    * Rust For Linux 简介

* [Linux 内核观察][087]
    * 在新的 Linux 内核版本发布后，通过视频讲解其中的关键变更

* [RISC-V Linux 内核剖析][088]
    * RISC-V Linux 内核技术调研在线视频分享

* RISC-V Linux 系统开发公开课
    * [第 1 期：嵌入式入门][https://space.bilibili.com/687228362/channel/collectiondetail?sid=1750690]，配套 [泰晓 RISC-V 实验盘][028]
    * [第 2 期：嵌入式实战][https://space.bilibili.com/687228362/channel/collectiondetail?sid=2021659]，配套 [泰晓 RISC-V 实验箱][090]
    * [第 3 期：嵌入式进阶][https://space.bilibili.com/687228362/channel/collectiondetail?sid=3128538]，配套 [泰晓 RISC-V 实验箱][090]

### 1.3.2 付费课程

* [《360° 剖析 Linux ELF》][070]
    * 提供了上百个实验案例，全部通过 Linux Lab 验证

* [《Rust 语言快速上手》][006]
    * 初步了解 Rust 语言、历史、特性、适应领域以及与嵌入式、Linux、GCC、GPU、C/C++ 语言的关系并快速上手，所有实验全部通过 Linux Lab 验证

* [《软件逆向工程初探》][072]
    * 了解软件逆向工程的基本概念，掌握开展软件逆向相关技术、流程和方法，通过实验实操，最终独立完成简单 C 程序逆向分析，所有实验全部通过 Linux Lab 验证

* [《Linux 内核热补丁技术介绍与实战》][073]
    * 学习 Linux 内核热补丁核心工作原理，跟随老师动手实现 AArch64 架构 Linux 内核热补丁核心功能，所有实验全部通过 Linux Lab 验证

## 1.4 项目功能

现在，Linux Lab 已经发展为一个学习、开发和测试 Linux 的集成环境，它支持以下功能：

|编号| 特性       |  描述                                                                                |
|----|------------|--------------------------------------------------------------------------------------|
|1   | 开发板     | 基于 QEMU，支持 7+ 主流体系架构，20+ 款流行虚拟开发板；支持多款真实开发板            |
|2   | 组件       | 支持 U-Boot，Linux, Buildroot，QEMU。支持 Linux v0.11, v2.6.10 ~ v5.x                |
|3   | 预置组件   | 提供上述组件的预先编译版本，并按开发板分类存放，可即时下载使用                       |
|4   | 根文件系统 | 支持 initrd，harddisk，mmc 和 nfs; ARM 架构提供 Debian 系统                          |
|5   | Docker     | 包括 gcc-4.3 在内的交叉工具链已预先安装，还可灵活配置并下载外部交叉工具链            |
|6   | 灵活访问   | 支持本地或网络访问，支持命令行和图形界面，支持 bash, ssh, vnc, web ssh, web vnc      |
|7   | 网络       | 内置桥接网络支持，每个开发板都支持网络（Raspi3 是唯一例外）                          |
|8   | 启动       | 支持串口、Curses（用于 `bash/ssh` 访问）和图形化方式启动                             |
|9   | 测试       | 支持通过 `make test` 命令对目标板进行自动化测试                                      |
|10  | 调试       | 可通过 `make debug` 命令对目标板进行调试                                             |

更多特性和使用方法请看下文介绍。

## 1.5 项目历史

### 1.5.1 项目起源

大约十年前，我向 elinux.org 发起了一个 tinylinux 提案：[Work on Tiny Linux Kernel][010]。该提案最终被采纳，因此我在这个项目上工作了几个月。

### 1.5.2 项目缘由

在项目开发过程中，编写了几个脚本用于验证一些新的小特性（譬如：[gc-sections][021]）是否破坏了几个主要的处理器架构上的内核功能。

这些脚本使用 `qemu-system-ARCH` 作为处理器/开发板的模拟器，在模拟器上针对 Ftrace + Perf 运行了基本的启动测试和功能测试，并为之相应准备了内核配置文件（defconfig）、根文件系统（rootfs）以及一些测试脚本。但在当时的条件下，所有的工作只是简单地归档在一个目录下，并没有从整体上将它们组织起来。

### 1.5.3 项目诞生

这些工作成果在我的硬盘里闲置了好多年，直到我遇到了 noVNC 和 Docker，并基于这些新技术开发了第一个 [Linux 0.11 Lab][004]，此后，为了将此前开发的那些零散的脚本、内核配置文件、根文件系统和测试脚本整合起来，我开发了 Linux Lab 这个系统。

## 1.6 项目变更

### 1.6.1 v0.1 @ 2019.06.28

从 2016 年发起，经过数年的开发与迭代，Linux Lab 于 2019 年 6 月 28 日迎来了第 1 个正式版本 [v0.1][029]。

* [v0.1 rc3][032]
    * 按需加载 prebuilt 并迁移代码仓库到国内，大幅优化了下载体验

* [v0.1 rc2][031]
    * 修复了几处基础体验 Bugs

* [v0.1 rc1][030]
    * 历史上发布的第 1 个版本，在历史功能上进一步添加了 raspi3 和 RISC-V 支持

### 1.6.2 v0.2 @ 2019.10.30

[v0.2][033] 新增原生 Windows 支持、新增龙芯早期全系 MIPS 架构处理器支持、新增多个平台外置交叉编译器支持、新增实时 RT 支持、新增 host 侧免 root 支持等，并首次被某线上课程全程采用。

* [v0.2 rc3][036]
    * 新增原生 Windows 支持，基于 Docker Toolbox，无需通过 Virtualbox 或 Vmware 额外安装系统

* [v0.2 rc2][035]
    * 龙芯插件新增龙芯教育开发板支持
    * 在 docker 镜像中新增 gdb-multiarch 调试支持，避免为每个平台安装一个 gdb

* [v0.2 rc1][034]
    * 携手龙芯实验室，以 [独立插件][012] 的方式新增龙芯全面支持
    * 携手码云，在国内新增 QEMU、U-Boot 和 Buildroot 的每日镜像

### 1.6.3 v0.3 @ 2020.03.12

[v0.3][037] 统一了所有组件的公共操作接口更方便记忆，进一步优化了大型仓库的下载体验，通过添加自动依赖关系简化了命令执行并大幅度提升实验效率，为多本知名 Linux 图书新增了 v2.6.10, v2.6.11, v2.6.12, v2.6.14, v2.6.21, v2.6.24 等多个历史版本内核，并发布了首份中文版用户手册。

* [v0.3 rc3][040]
    * 首次新增中文文档

* [v0.3 rc2][039]
    * 提升 git 仓库下载体验：所有仓库下载切换为 git init+fetch，更为健壮
    * 提升自动化：常规动作都新增了依赖关系，一键自动下载、检出、打补丁、配置、编译、启动

* [v0.3 rc1][038]
    * 添加多本知名 Linux 图书所用内核支持

### 1.6.4 v0.4 @ 2020.06.01

[v0.4][041] 通过提升镜像下载速度、优化 make 性能、完善登陆方式等进一步完善使用体验，同时首次为 64 位 ARM 架构的 aarch64/virt 新增 U-Boot 支持并升级 arm/vexpress-a9 的 U-Boot 到当前最新版本，另外，修复了一处新内核下在容器内插入 NFSD 模块导致的系统卡死问题。

* [v0.4 rc3][044]
    * 新增 aarch64/virt U-Boot 支持
    * 临时修复新版本内核上容器内插入 NFSD 模块引起的 Sync 卡死问题

* [v0.4 rc2][043]
    * 新增第 16 块开发板
    * 新增 vnc 客户端登陆方法

* [v0.4 rc1][042]
    * 切换内核镜像到更快的 codeaurora
    * 添加本地开发板配置和编辑接口

### 1.6.5 v0.5 @ 2020.09.12

[v0.5][045] 提前升级到新镜像 Ubuntu 20.04，全面导入龙芯系列处理器支持，并进一步完善各种细微体验。

* [v0.5 rc3][048]
    * 修复 arm/vexpress-a9 因编译器配置问题引起的 U-Boot 编译失败
    * 进一步完善文档中对普通用户的使用要求，避免使用 root 带来的诸多问题

* [v0.5 rc2][047]
    * 进一步改善 QEMU 编译体验，在 Gitee 新增 submodules 镜像，不再有挫折感
    * 新增 Arch/Manjaro docker 安装文档
    * 修复 macOS 大小写敏感的文件系统镜像制作步骤

* [v0.5 rc1][046]
    * 全面完善并合并早期对龙芯全系处理器的支持
    * 全面升级开发环境基础镜像到 Ubuntu 20.04

### 1.6.6 v0.6 @ 2021.02.06

[v0.6][049] 完善开发镜像，新增首块真实硬件开发板支持。

* v0.6 rc3
    * 进一步完善真实硬件板的支持

* [v0.6 rc2][051]
    * 新增首块真实硬件开发板 `arm/ebf-imx6ull` 支持
    * 新增命令行自动补全脚本，允许直接在命令行补全板子信息，提升使用效率

* [v0.6 rc1][050]
    * 修复插件中的 BSP 包下载功能
    * 修复 x86 架构的内核编译问题
    * 修复 aarch64/virt 开发板 U-Boot 引导问题

### 1.6.7 v0.7 @ 2021.06.03

[v0.7][052] 开发并发布首个 Linux Lab 实验盘，支持智能启动、运行时切换、透明倍容和内存编译。

* v0.7 rc3
    * 增加 v0.8 开发计划
    * 新增 Linux Lab Disk 使用说明
    * 简化内存编译使用接口

* v0.7 rc2
    * 修复 sd boot，增补缺失的 dosfstools
    * 使用 truncate 取代 dd 创建磁盘镜像文件，提升创建速度
    * 为 source, checkout, patch 等目标新增 make 错误处理

* [v0.7 rc1][053]
    * 启动 Linux Lab Disk 开发
    * 新增内存编译功能和使用文档
    * 新增桌面快捷方式对 Ubuntu 20.04 的支持
    * 修复 Windows 和 macOS 系统上的 webvnc 连接异常
    * 容器内新增音视频播放支持

### 1.6.8 v0.8 @ 2021.10.13

[v0.8][054] 新增 LLVM/Clang, Rust 和 openEuler 支持。

* [v0.8 rc3][055]
    * 新增 Rust for Kernel 开发支持
    * 新增 openEuler Kernel 开发支持
    * 新增 LLVM/Clang 编译支持，make kernel LLVM=1
    * 新增 rust 环境安装脚本
    * Pocket Linux Disk 和 Linux Lab Disk 相继支持 Fedora
* [v0.8 rc2][061]
    * Pocket Linux Disk 和 Linux Lab Disk 相继支持 Manjaro
    * 早期文档中描述的更新步骤较重，替换为更为轻量级的更新步骤
    * 修复 macOS 上的 i386/pc 支持
    * 进一步清理 rootfs 各种格式的依赖关系
    * 进一步优化 make debug，确保 debug 基于最新的改动
    * 清理不必要的 1234 端口映射，该部分可以让用户按需开启
* [v0.8 rc1][066]
    * 发布了首支 Pocket Linux Disk
    * Pocket Linux Disk 和 Linux Lab Disk 相继支持 Deepin

### 1.6.9 v0.9 @ 2022.01.13

[v0.9][056] 完善 Linux Lab for Windows，升级默认内核版本到 v5.13，大幅提升交互性能，Linux Lab Disk 同步支持运行时免关机切换系统并新增 Kali、Mint 等发行版支持。

* [v0.9 rc3][059]
    * 新增 FAST FETCH 功能，支持单独快速下载指定内核版本
    * 新增 ONESHOT 内存编译功能，在原有内存编译的基础上增加代码内存缓存支持
    * 大幅优化 Linux Lab 的启动速度和交互性能，提升 10 到 20 倍
    * 完善 Linux Lab for Windows 支持，同时兼容 Docker Toolbox 和 Docker Desktop with wsl2
    * 升级镜像，导入 mipsel, arm 和 powerpc 的 gcc 4.3 支持并修复相关的兼容性问题

* [v0.9 rc2][058]
    * 为 v2.6.29 及之前版本的内核导入 make 3.81
    * 为 Rust for Linux 新增 riscv64/virt 和 aarch64/virt 支持
    * 新增 lxterminal 和 qterminal 支持
    * Linux Lab Disk 新增 Kali 和 Mint 支持，并首次支持免关机切换系统

* [v0.9 rc1][057]
    * 升级 LLVM 工具链到 13
    * 升级内核版本到 v5.13
    * 新增 cleanall，可同时清理 source 和 build

### 1.6.10 v1.0 @ 2022.06.16

[v1.0][060] 升级部分内核到 v5.17，修复内存编译功能，优化 make 自动补全功能，完善并新增 examples，更新文档。

* v1.0 rc3
    * 全面整理 Assembly 实验案例
    * 删除多余的 do target，由其他更简洁的用法替代
    * 允许更简单编译内核目标文件，例如：`make kernel arch/riscv/kernel/sbi.o`
    * 修复 make 自动命令补全，允许通过 tab 按键快速补全常用命令
    * 完善 make patch 命令
    * 更新文档和 License 信息

* v1.0 rc2
    * 升级 RISC-V 支持，QEMU 升级到 v6.0.0，内核升级到 v5.17
    * 升级 arm/vexpress-a9 的默认内核到 v5.17
    * 规范 build 输出路径，跟 `boards/` 下的路径保持一致，方便更快找到目标文件
    * 完善 docker 文件系统运行和导出支持
    * 新增 Python 实验案例
    * 完善 Assembly 和 Shell 实验案例

* v1.0 rc1
    * 增强 test 功能，允许在 testcase 中执行多个命令
    * 修复 test 中的内核参数传递问题，确保兼容 U-Boot 和 kernel
    * 允许灵活增加 App 的子 make 目标，例如 `make root busybox-menuconfig`
    * 修复两笔内存编译的问题

### 1.6.11 v1.1 @ 2022.11.09

[v1.1][079] 升级部分内核到 v6.0.7，升级 QEMU 编译到 v7.0，通过 [TinyCorrect][080] 修复文档并新增 RISC-V U-Boot 开发支持。

* v1.1 rc3
    * 新增 RISC-V U-Boot 开发支持
    * 新增 QEMU dumpdtb 支持
    * 修复新版内核上的 nfsd 模块检测
    * 修复文档中的 ROOTDEV 用法

* v1.1 rc2
    * 完善 QEMU 编译依赖安装
    * 用 TinyCorrect 修复所有文档排版错误
    * 修复 tools/toc.sh 脚本，对齐到 TinyCorrect 要求的格式

* [v1.1 rc1][078]
    * 新增 QEMU v7.0 编译支持
    * 新增龙芯虚拟开发板：`mips64el/loongson3-virt`，适配官方 v5.18 内核
    * 升级 RISC-V 内核版本到 v6.0.7

### 1.6.12 v1.2 @ 2023.07.09

v1.2 升级部分内核到 v6.3.6，升级部分 QEMU 版本到 v8.0.2，新增 nolibc 和 NOMMU 开发支持，另有新增 4 款虚拟开发板：`ppc/ppce500`, `arm/virt`, `loongarch/virt` 和 `s390x/s390-ccw-virtio`。

* v1.2 rc3
    * 新增 QEMU v8.0.x 开发支持
    * 新增 NOMMU 开发支持
    * 修复新版 Manjaro 下启动卡死的问题

* v1.2 rc2
    * 新增 nolibc 开发支持
    * 新增 syscall 裁减开发支持
    * 新增 oneshot 模式和 nolibc 模式的使用文档

* v1.2 rc1
    * 新增部分内核到 v6.1.1
    * 更新 rust-for-kernel 支持
    * 为 riscv64/virt 新增 openeuler 内核支持

### 1.6.13 v1.3 @ 2024.03.17

v1.3 升级部分内核到 v6.6，新增上游内核工具链支持，完善 riscv64 和 nolibc 开发支持，另有新增 2 款虚拟开发板：`ppc64le/pseries` 和 `ppc64le/powernv`。

* v1.3 rc3
    * riscv64: 默认工具链改为更轻量的上游内核工具链
    * toolchain: 新增内置工具链的自动解压支持
    * boot: Shell 从 `/bin/bash` 改为更为通用的 `/bin/sh`
    * examples: 修复 C 语言例子的编译参数，确保可以在 RISC-V Lab 下编译
    * README: 新增 RISC-V Linux 公开课视频链接，新增网络冲突说明

* v1.3 rc2
    * loongarch：新增 v6.5.4, v6.6 和 buildroot 支持
    * riscv64: 修复 riscv64-hello.s 的 `#ifdef` 错误
    * patch: 完善二进制补丁的检测与 Apply 支持
    * notice: 调整部分 errors 为 warnings，提高可用性

* v1.3 rc1
    * ppc64: 新增 `ppc64le/pseries` 和 `ppc64le/powernv` 等虚拟开发板支持
    * toolchain: 新增支持 <https://mirrors.edge.kernel.org/pub/tools/crosstool/>
    * riscv64: 新增图形显示支持
    * nolibc: 新增 `arm/versatilepb` 等多个板子的测试支持
    * test: 完善 timeout 机制

### 1.6.14 v1.4 @ 2024.08.25

v1.4 升级部分内核到 v6.10.6，新增支持基于真实硬件开发板的 “[泰晓 RISC-V 实验箱][090]”，新增最小化内核配置支持大幅提升内核编译速度，在单终端内新增多窗口调试功能，修复 defconfig, board-info, toolchains 等相关问题。

* v1.4 rc3
    * defconfig: 修复多处 `.config` 覆盖问题
    * boards: 升级 `arm/vexpress-a9` 默认内核版本到 v6.10.6

* v1.4 rc2
    * debug: 新增 `CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT=y`
    * debug: 用 tmux 实现单终端内的多窗口支持，调试更方便
    * defconfig: 支持 `KTAG=nolibc` 或 `KCFG=linux.nolibc.config`
    * defconfig: 新增 toolchains 依赖，部分配置动作需要准备好编译器
    * board-info: 修复并美化 make list
    * README: 新增 tiny 内核配置用法

* v1.4 rc1
    * boards: 新增 “泰晓实验箱” 支持，包括编译、烧录和运行
    * config: 修复老版本内核的 olddefconfig 和 defconfig 支持
    * tools: 完善基于 Python 的 helpers，包括 run, reboot 和 poweroff
    * examples: 修复 riscv 例子的编译参数
    * README: 更新网络和编译器相关用法

# 2. Linux Lab 安装

Linux Lab 基于 Docker，对于已经安装 Docker 并配置了国内加速镜像的用户来说，安装 Linux Lab 极其容易，通常三条命令即可，而各大主流桌面系统对 Docker 的支持也很成熟，安装过程很方便。

为了避免重复踩坑，建议先简单浏览以下安装过程，再来实际操作，不要上来就敲命令。

下述安装过程比较详尽，兼顾了各大桌面系统，实际上针对某个系统的用法非常简单。

如果确实是 Linux 新手或不喜欢无聊的安装过程，想**免安装**立马使用 Linux Lab，那么可以从 [泰晓开源小店][022] 选购一枚即插即跑的 [Linux Lab Disk][028]。它也叫“泰晓 Linux 实验盘”，可以在淘宝手机 App 内搜索 “泰晓 Linux” 后购买。

『Linux Lab Disk - 泰晓 Linux 实验盘』已经支持如下功能：

* 可选容量
    * 覆盖 32G, 64G, 128G, 256G, 512G, 1T, 2T, 4T 等，可按需定制任意容量
* 可选形态
    * 高速或固态 U 盘、Mini 移动硬盘、固态硬盘（含 NVME / SATA）
* 可选系统
    * 覆盖全球 Top6 发行版，可按需定制更多 Linux 发行版
    * Ubuntu 18.04-22.04, Deepin 20.08+, Fedora 37+, Mint 21.1+, Kali, Manjaro
* 主要特性
    * 随身携带：支持在 64 位 X86 台式机、笔记本和 macBook 上即插即跑
    * 智能启动：在 Windows, Linux 系统下自动检测后并行启动
    * 智能切换：在 Windows, Linux 系统下自动检测并免关机切换系统
    * 相互套娃：多支盘可相互启动或来回切换，可同时使用多个不同的 Linux 系统发行版
    * 时区兼容：自动兼容 Windows, MacOS 和 Linux 的时区设定，跟主系统来回任意切换后时间保持一致
    * 自动共享：在 Windows 或 Linux 主系统下并行运行时，自动提供多种与主系统的文件与粘贴板共享方式
    * 透明倍容：可用容量翻倍，128G 可以当 ~256G 左右使用
    * 零损编译：扩大可用容量，提升编译速度，节省擦写寿命
    * 出厂恢复：在主系统出现某些故障的情况下，允许恢复出厂系统，也支持按需配置备份和还原功能
    * 内存引导：支持内存模式启动，读写均在内存中，可提升使用速度，延长磁盘寿命
    * 即时实验，集成多套自研实验环境，可在 1 分钟内开展 Linux 内核、嵌入式 Linux、U-Boot、汇编、C、Python、数据库、网络等实验
* 购买地址
    * [泰晓开源小店][022]，该地址为目前泰晓社区官方唯一淘宝销售地址
    * 泰晓科技 B 站工房，关注 B 站的 [泰晓科技](https://space.bilibili.com/687228362) 账号，即可进工房选购
* 产品详情
    * <https://tinylab.org/linux-lab-disk>
    * 详细介绍了特性、功能与用法，配套了大量的演示视频

[![泰晓 Linux 实验盘 - Linux Lab Disk](doc/images/linux-lab-disk-demo.png)][022]

## 2.1 软硬件要求

Linux Lab 是一套完备的嵌入式 Linux 开发环境，需要预留足够的算力和存储空间，避免后续扩展麻烦，基本硬件配置建议如下：

| 硬件类型     |  要求                | 说明                                          |
|--------------|----------------------|-----------------------------------------------|
| 处理器       | X86_64, > 1.5GHz     | 创建虚拟机时也务必选择 64 位 X86 处理器       |
| 磁盘         | >= 50G               | 系统 (25G), Docker 镜像 (~5G), Linux Lab(20G) |
| 内存         | >= 4G                | 过低的内存可能会导致各种卡顿以及异常缓慢      |

如果平时用的几率比较高，建议把磁盘空间提高到 100G ~ 200G 以上，内存可以提升到 8G 以上，处理器核数提升到 4 个以上。

当前市面上所有支持 Docker 的 X86_64 系统都应该可以正常运行 Linux Lab，包括 Windows, Linux 和 macOS，市面上几乎所有的 Linux 发行版都有用户尝试过。

请查看其他同学 [成功运行过 Linux Lab 的系统][014]，并分享你的情况，例如：

    $ cd /path/to/cloud-lab/
    $ tools/docker/env
    System: Ubuntu 16.04.6 LTS
    Linux: 4.4.0-176-generic
    Docker: Docker version 18.09.4, build d14af54

## 2.2 安装 Docker

运行 Linux Lab 需要基于 Docker，所以请务必先安装 Docker：

  - Linux, Mac OSX, Windows 10

      使用 [Docker CE][025]

  - 更早的 Windows 版本（含大部分老版本 Windows 10）

      使用 [Docker Toolbox][011]；也可通过 Virtualbox 或 Vmware 安装 Ubuntu 等 Linux 发行版后使用

在运行 Linux Lab 之前，请参考 6.1.4 节确保无需 `sudo` 权限也可以正常运行以下命令：

    $ docker run hello-world

另外，在国内要正常使用 Docker，请**务必**配置好国内的 Docker 镜像加速服务：

* [阿里云 Docker 镜像使用文档][018]
    * 适合企业和家庭网络，需免费注册帐号并登陆后才能使用

* [USTC Docker 镜像使用文档][020]
    * 适合高校网络

使用 Linux Lab 过程中的常见 Docker 相关问题，请参考常见问题中的 6.1 节，镜像下载慢、下载超时、下载出错等问题都有详细解决方案。

其他问题，请参考 [官方 Docker 文档][007]。

**Ubuntu 用户安装手册**
  - [doc/install/ubuntu-docker.md][003]

**Arch 用户安装手册**
  - [doc/install/arch-docker.md][001]

**Manjaro 用户安装手册**
  - [doc/install/manjaro-docker.md][002]

**Windows 用户须知**：

  - 请参考 [Docker 官方文档][007] 确保所用 Windows 版本支持 Docker 并根据情况选择安装 Docker Desktop 还是 Docker Toolbox

  - Linux Lab 当前仅在 Git Bash 验证过，请务必配合 Git Bash 使用
      - 在安装完 [Git For Windows][017] 后，可通过鼠标右键使用 “Git Bash Here”

## 2.3 选择工作目录

可以简单地在 `~/Downloads` 或 `~/Documents` 下选择一个工作路径，也可以创建一个新的 `~/Develop` 文件夹：

    $ mkdir ~/Develop
    $ cd ~/Develop

对于 Windows 和 Mac OSX 用户，要正常编译 Linux，请参考 5.7.1 节开启 Build Cache。

对于 Windows 用户，在安装完 [Git For Windows][017] 后，可通过鼠标右键在选定的工作目录运行 “Git Bash Here”。

## 2.4 切换到普通用户帐号

下载代码前，请**务必**切到普通用户。Linux Lab 虽未禁用 `root` 帐号，但是不推荐使用 `root` 帐号，否则会有各种权限异常问题。

查看当前用户 ID，`0` 表示 `root`，非零表示普通用户：

    $ id -u `whoami`
    1000

如果当前为 `root`，需切到普通用户，请替换 `<USER>` 为自己的帐号名，下同：

    # id -u `whoami`
    0
    # sudo -su <USER>

如果目标机器上仅有 `root` 帐号，则**必须**新建一个普通用户帐号，假设取名为 `laber`：

    $ sudo useradd --create-home --shell /bin/bash --user-group --groups adm,sudo laber
    $ sudo passwd laber
    $ sudo -su laber
    $ whoami
    laber

## 2.5 下载实验环境

使用普通用户下载 Cloud Lab，然后再选择 linux-lab 仓库：

    $ git clone https://gitee.com/tinylab/cloud-lab.git
    $ cd cloud-lab/

如果错误使用了 `root` 帐号来 clone 代码，下载后请**务必**切换到普通用户，并把属主改为普通用户：

    $ sudo -su <USER>
    $ sudo chown -R <USER>:<USER> -R cloud-lab/{*,.git}

## 2.6 运行并登录 Linux Lab

启动 Linux Lab 并根据控制台上打印的用户名和密码登录实验环境：

    $ tools/docker/run linux-lab

通过 Bash 直接登陆：

    $ tools/docker/bash

通过 Web 浏览器直接登录实验环境：

    $ tools/docker/webvnc

其他登录方式：

    $ tools/docker/vnc
    $ tools/docker/ssh
    $ tools/docker/webssh

选择某种登陆方式：

    $ tools/docker/login list  # 列出并选择，并且记住
    $ tools/docker/login vnc    # 直接选择一种并记住

登录方式汇总：

|   登录方法     |   描述             |  缺省用户        |  登录所在地          |
|----------------|--------------------|------------------|----------------------|
|   bash         | docker bash        |  Ubuntu          | 本地主机             |
|   ssh          | 普通 ssh           |  Ubuntu          | 本地主机             |
|   vnc          | 普通 桌面          |  Ubuntu          | 本地主机+VNC client  |
|   webvnc       | web 桌面           |  Ubuntu          | 本地主机或互联网     |
|   webssh       | web ssh            |  Ubuntu          | 本地主机或互联网     |

由于普通的 vnc 客户端五花八门，所以当前建议采用 webvnc，确保可以在各个平台能自动登陆。

如果想使用本地的 vnc 客户端，请先提前安装好客户端，Linux Lab 推荐使用 vinagre。其他的客户端请通过如下方式指定：

    $ tools/docker/vnc vinagre

如果上述命令不能正常工作，请根据上述命令打印出来的 VNC 服务器信息，自行配置所用客户端。

**注意**：

* vinagre 有全屏模式，但是默认没有开启，可通过菜单中的 `View -> Fullscreen` 勾选，但是勾选前请务必事先勾选 `Keyboard shortcuts`，否则只能通过 `sudo pkill x11vnc` 退出全屏。
* 由于网络架构的差异，采用直连方式的 ssh 和 vnc 并不一定会工作，请优先使用 bash、webvnc 和 webssh 三种方式。

## 2.7 更新实验环境并重新运行

大部分时候，仅需要更新 Linux Lab，主要用于获取新的开发板支持或者相关功能修复：

    $ cd /path/to/cloud-lab/labs/linux-lab/
    $ git checkout master
    $ git pull

如果发现有运行故障或者发现社区有升级基础镜像，则可以更新 Cloud Lab：

    $ cd /path/to/cloud-lab
    $ git checkout master
    $ git pull

如果改动过 Linux Lab 的运行环境，并且相关改动在以后一定用得上，那么就需要备份所有的本地环境修改，也就是固化容器（通常很慢，不建议执行这一步）：

    $ tools/docker/save linux-lab
    $ git checkout -- configs/linux-lab/docker/name

之后重新运行 Linux Lab 即可，如果有新的镜像，会自动启用：

    $ tools/docker/rerun linux-lab

## 2.8 快速上手：启动一个开发板

进入实验环境，切换目录：

    $ cd /labs/linux-lab

输入如下命令，在缺省的 `vexpress-a9` 开发板上启动预置的内核和根文件系统：

    $ make boot

使用 `root` 帐号登录，不需要输入密码（密码为空），只需要输入 `root` 然后输入回车即可：

    Welcome to Linux Lab

    linux-lab login: root

    # uname -a
    Linux linux-lab 5.1.0 #3 SMP Thu May 30 08:44:37 UTC 2019 armv7l GNU/Linux
    #
    # poweroff
    #

键入 `poweroff` 即可关闭板子。

**注意**：部分开发板的关机功能不完善，可通过 `CTRL+a x`（依次按下 `CTRL` 和 `A`，同时释放，再单独按下 `x`）来退出 QEMU。当然，也可以另开一个控制台，通过 `kill` 或 `pkill` 退出 QEMU 进程。

# 3. Linux Lab 入门

## 3.1 使用开发板

### 3.1.1 列出支持的开发板

列出内置支持的开发板：

    $ make list
    [ aarch64/raspi3 ]:
          ARCH    = arm64
          CPU    ?= cortex-a53
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/mmcblk0 /dev/ram0
          ROOTDEV ?= /dev/mmcblk0
    [ aarch64/virt ]:
          ARCH    = arm64
          CPU    ?= cortex-a57
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/sda /dev/vda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/vda
    [ arm/mcimx6ul-evk ]:
          ARCH    = arm
          CPU    ?= cortex-a9
          LINUX  ?= v5.4
          ROOTDEV_LIST := /dev/mmcblk0 /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/mmcblk0
    [ arm/versatilepb ]:
          ARCH    = arm
          CPU    ?= arm926t
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/sda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ arm/vexpress-a9 ]:
          ARCH    = arm
          CPU    ?= cortex-a9
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/mmcblk0 /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ i386/pc ]:
          ARCH    = x86
          CPU    ?= qemu32
          LINUX  ?= v5.1
          ROOTDEV_LIST ?= /dev/hda /dev/ram0 /dev/nfs
          ROOTDEV_LIST[LINUX_v2.6.34.9] ?= /dev/sda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/hda
    [ mips64el/ls2k ]:
          ARCH    = mips
          CPU    ?= mips64r2
          LINUX  ?= loongnix-release-1903
          LINUX[LINUX_loongnix-release-1903] := 04b98684
          ROOTDEV_LIST := /dev/sda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ mips64el/ls3a7a ]:
          ARCH    = mips
          CPU    ?= mips64r2
          LINUX  ?= loongnix-release-1903
          LINUX[LINUX_loongnix-release-1903] := 04b98684
          ROOTDEV_LIST ?= /dev/sda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ mipsel/ls1b ]:
          ARCH    = mips
          CPU    ?= mips32r2
          LINUX  ?= v5.2
          ROOTDEV_LIST ?= /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ mipsel/ls232 ]:
          ARCH    = mips
          CPU    ?= mips32r2
          LINUX  ?= v2.6.32-r190726
          ROOTDEV_LIST := /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ mipsel/malta ]:
          ARCH    = mips
          CPU    ?= mips32r2
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ ppc/g3beige ]:
          ARCH    = powerpc
          CPU    ?= generic
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ riscv32/virt ]:
          ARCH    = riscv
          CPU    ?= any
          LINUX  ?= v5.0.13
          ROOTDEV_LIST := /dev/vda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/vda
    [ riscv64/virt ]:
          ARCH    = riscv
          CPU    ?= any
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/vda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/vda
    [ x86_64/pc ]:
          ARCH    = x86
          CPU    ?= qemu64
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
          ROOTDEV_LIST[LINUX_v3.2] := /dev/sda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0
    [ csky/virt ]:
          ARCH    = csky
          CPU    ?= ck810
          LINUX  ?= v4.9.56
          ROOTDEV ?= /dev/nfs

如果只想查看特定的架构，可以使用 `ARCH` 指定，也可以使用 `FILTER` 模糊匹配：

    $ make list ARCH=arm
    $ make list FILTER=virt

更多用法：

    $ make list-board         # 仅显示 ARCH
    $ make list-short         # ARCH 和 Linux
    $ make list-base          # 不包含插件
    $ make list-plugin        # 仅包含插件
    $ make list-full          # 所有板子信息
    $ make list-real          # 仅真实硬件
    $ make list-virt          # 仅虚拟开发板
    $ make list-local         # 已下载的开发板
    $ make list-remote        # 未下载的开发板

### 3.1.2 选择一个开发板

#### 3.1.2.1 真实开发板

从 v0.6 版以后，为了方便进一步开展外围设备驱动等实验，Linux Lab 开始支持真实的硬件开发板，选择这类开发板时请务必确保有购买开发板并正确连接到开发主机。

这类开发板可以用 `make list-real` 单独列出来：

    $ make list-real
    [ arm/ebf-imx6ull ]:
      ARCH    = arm
      CPU    ?= cortex-a9
      LINUX  ?= v4.19.35
      ROOTDEV_LIST := /dev/mmcblk0 /dev/ram0 /dev/nfs
      ROOTDEV ?= /dev/mmcblk0

由于不同的真实硬件开发板差异较大，所以在板级目录有提供专门的开发文档，例如：`boards/arm/ebf-imx6ull/README.md`。

[![Linux Lab 真板 - 野火 IMX6ULL](doc/images/ebf-imx6ull.png)][022]

#### 3.1.2.2 虚拟开发板

系统缺省使用的虚拟开发板型号为 `vexpress-a9`，我们也可以自己配置，制作和使用其他的虚拟开发板，具体使用 `BOARD` 选项，举例如下：

    $ make BOARD=malta
    $ make boot

如果存在同名的板子，必须指定架构以示区分，否则系统会默认匹配一个（不一定刚好是你想要的），所以建议明确设定：

    $ make BOARD=mipsel/malta

目前同名的有 `virt`, `pc` 等，可以这样查看同名的板子：

    $ make list FILTER=virt
    [ aarch64/virt ]:
          ARCH    = arm64
          CPU    ?= cortex-a57
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/sda /dev/vda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/vda
    [ riscv32/virt ]:
          ARCH    = riscv
          CPU    ?= any
          LINUX  ?= v5.0.13
          ROOTDEV_LIST := /dev/vda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/vda
    [ riscv64/virt ]:
          ARCH    = riscv
          CPU    ?= any
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/vda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/vda

    $ make list FILTER=/pc
    [ i386/pc ]:
          ARCH    = x86
          CPU    ?= qemu32
          LINUX  ?= v5.1
          ROOTDEV_LIST ?= /dev/hda /dev/ram0 /dev/nfs
          ROOTDEV_LIST[LINUX_v2.6.34.9] ?= /dev/sda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/hda
    [ x86_64/pc ]:
          ARCH    = x86
          CPU    ?= qemu64
          LINUX  ?= v5.1
          ROOTDEV_LIST := /dev/hda /dev/ram0 /dev/nfs
          ROOTDEV_LIST[LINUX_v3.2] := /dev/sda /dev/ram0 /dev/nfs
          ROOTDEV ?= /dev/ram0

选择时可以这样：

    $ make BOARD=x86_64/pc
    $ make BOARD=riscv64/virt

如果使用的命令选项是小写的 `board`，这表明创建的开发板的配置不会被保存，提供该选项的目的是为了方便用户同时运行多个开发板而不会相互冲突。

    $ make board=malta boot

使用该命令允许在多个不同的终端中或者以后台方式同时运行多个开发板。

检查开发板特定的配置：

    $ cat boards/arm/vexpress-a9/Makefile

**说明**：由于开发与维护的工作量巨大，目前仅开放了一款虚拟开发板，如需其他虚拟开发板，可通过下一小节的介绍进行购买。

#### 3.1.2.3 如何选购

所有适配过的开发板，包括真实开发板与虚拟开发板（即 Linux Lab BSP），都会统一放置在 [泰晓开源小店][023] 或 [泰晓 B 站工房](https://space.bilibili.com/687228362) 供大家选购，选购完毕后可以加微信号 `tinylab` 申请进入相应的技术群组。

也可以直接在淘宝手机 App 内搜索 “泰晓 Linux” 后购买，可搭配店内的 “Linux Lab Disk” 一起使用，用上 “Linux Lab Disk” 后就完全不需要安装独立的 Linux 开发环境。

为了便利大家开展不同架构处理器 Linux 内核与嵌入式 Linux 系统的学习，泰晓社区于近日推出了泰晓 RISC-V 实验盘、泰晓 ARM 实验盘、泰晓 X86 实验盘、泰晓 LoongArch 实验盘等特定架构实验盘，分别内置了特定架构的虚拟开发板。

### 3.1.3 以插件方式使用

Linux Lab 支持“插件”功能，允许在独立的 git 仓库中添加和维护开发板。采用独立的仓库维护可以确保 Linux Lab 在支持愈来愈多的开发板的同时，自身的代码体积不会变得太大。

该特性有助于支持基于 Linux Lab 学习一些书上的例子以及支持一些采用新的处理器体系架构的开发板，书籍中可能会涉及多个开发板或者是新的处理器架构，并可能会需要多个新的软件包（譬如交叉工具链和架构相关的 QEMU 系统模拟器）。

这里列出当前维护的插件：

  - [中天微/C-Sky Linux][013]
  - [龙芯/Loongson Linux][012]

其中，Loongson 已经在 v5.0 合并进主线。

### 3.1.4 配置开发板

每块开发板都有特定的配置，部分配置是可以根据需要进行修改的，比如说内存大小、内核版本、文件系统版本、QEMU 版本，以及其他外设配置，比如串口、网络等。

配置方法很简单，参考现有的板级配置（`boards/<BOARD>/Makefile`）修改即可，以下命令会通过 VIM 调出当前开发板的本地配置文件（`boards/<BOARD>/.labconfig`）：

    $ make edit

建议不要一次性做太大的调整，通常只建议修改内核版本，这样可直接用如下命令达到：

    $ make list-linux
    v4.12 v4.5.5 v5.0.10 [v5.1]
    $ make config LINUX=v5.0.10
    $ make list-linux
    v4.12 v4.5.5 [v5.0.10] v5.1

如果想把相关改动提交进上游代码仓库，请使用 `board-edit` 和 `board-config`，否则，建议使用 `edit` 和 `config`，这样可以方便同步上游的改动而不产生任何冲突。

## 3.2 一键自动编译

v0.3 以及之后的版本默认增加了目标依赖支持，所以，如果想编译内核，直接：

    $ make kernel-build

    或

    $ make build kernel

它将自动完成所有需要的工作，当然，依然可以跟以前一样手动指定某个目标运行。

更进一步地，通过给每个目标完成情况打上时间戳，完成的目标就不会再运行，从而可以节省时间。如果还想再次执行某个历史目标，可以删掉时间戳文件再运行：

    $ make cleanstamp kernel-build
    $ make kernel-build

    或

    $ make force-kernel-build

下面的命令则删掉所有内核目标的时间戳：

    $ make cleanstamp kernel

该功能同样适用于 Rootfs，U-Boot 和 QEMU。

## 3.3 详细步骤分解

### 3.3.1 下载

下载特定开发板的软件包、内核、buildroot 以及 U-boot 的源码：

    $ make source APP=bsp,kernel,root,uboot
    或
    $ make source APP=all
    或
    $ make source all

如果需要单独下载这些部分：

    $ make bsp-source
    $ make kernel-source
    $ make root-source
    $ make uboot-source

    或

    $ make source bsp
    $ make source kernel
    $ make source root
    $ make source uboot

从 v0.5 开始，所有源代码下载在 Linux Lab 的 `src/` 目录下，历史版本都直接放在 Linux Lab 根目录，请注意该区别。

**注意**：如果开启了 `CACHE_SRC` 或 `ONESHOT`（设置为 1），新下载的源码将被放置在 `build/src/` 目录下，里面的内容必须要手动保存和备份，否则在关机后会丢失。

### 3.3.2 检出

检出（checkout）您需要的 kernel 和 buildroot 版本：

    $ make checkout APP=kernel,root

单独检出相关部分：

    $ make kernel-checkout
    $ make root-checkout

    或

    $ make checkout kernel
    $ make checkout root

如果由于本地更改而导致检出不起作用，请保存更改并做清理以获取一个干净的环境：

    $ make kernel-cleanup
    $ make root-cleanup

    或

    $ make cleanup kernel
    $ make cleanup root

以上操作也适用于 QEMU 和 U-Boot。

### 3.3.3 打补丁

给开发板打补丁，补丁包的来源是存放在 `boards/<BOARD>/bsp/patch/linux` 和 `src/patch/linux/` 路径下：

    $ make kernel-patch

    或

    $ make patch kernel

### 3.3.4 配置

#### 3.3.4.1 缺省配置

使用缺省配置（defconfig）配置 kernel 和 buildroot：

    $ make defconfig APP=kernel,root

单独配置，缺省情况下使用 `boards/<BOARD>/bsp/` 下的 defconfig：

    $ make kernel-defconfig
    $ make root-defconfig

    或

    $ make defconfig kernel
    $ make defconfig root

使用特定的 defconfig 配置：

    $ make B=raspi3
    $ make kernel-defconfig bcmrpi3_defconfig
    $ make root-defconfig raspberrypi3_64_defconfig

如果仅提供 defconfig 的名字，则搜索所在目录的次序首先是 `boards/<BOARD>`，然后是 buildroot, u-boot 和 linux-stable 各自的缺省配置路径 `src/buildroot/configs`，`src/u-boot/configs` 和 `src/linux-stable/arch/<ARCH>/configs`。

#### 3.3.4.2 手动配置

    $ make kernel-menuconfig
    $ make root-menuconfig

    或

    $ make menuconfig kernel
    $ make menuconfig root

#### 3.3.4.3 使用旧的缺省配置

    $ make kernel-olddefconfig
    $ make root-olddefconfig
    $ make root-olddefconfig
    $ make uboot-olddefconfig

    或

    $ make olddefconfig kernel
    $ make olddefconfig root
    $ make olddefconfig uboot

### 3.3.5 编译

一起编译 kernel 和 buildroot：

    $ make build APP=kernel,root

单独编译 kernel 和 buildroot:

    $ make kernel-build  # make kernel
    $ make root-build    # make root

    或

    $ make build kernel
    $ make build root

从 v0.5 开始，所有构建结果存放在 Linux Lab 的 `build/` 目录下，历史版本都放在 `output/` 目录，请注意该区别。

### 3.3.6 保存

保存所有的配置以及 rootfs/kernel/dtb 的 image 文件：

    $ make saveconfig APP=kernel,root
    $ make save APP=kernel,root

保存配置和 image 文件到 `boards/<BOARD>/bsp/`：

    $ make kernel-saveconfig
    $ make root-saveconfig
    $ make root-save
    $ make kernel-save

    或

    $ make saveconfig kernel
    $ make saveconfig root
    $ make save kernel
    $ make save root

### 3.3.7 启动

缺省情况下采用非图形界面的串口方式启动，如果要退出可以使用 `CTRL+a x`, `poweroff`, `reboot` 或 `pkill qemu` 命令（具体参考 6.2.2 节）

    $ make boot

图形方式启动（如果要退出请使用 `CTRL+ALT+2 quit`）:

    $ make b=pc boot G=1 LINUX=v5.1 BUILDROOT=2019.11
    $ make b=versatilepb boot G=1 LINUX=v5.1 BUILDROOT=2016.05
    $ make b=g3beige boot G=1 LINUX=v5.1 BUILDROOT=2016.05
    $ make b=malta boot G=1 LINUX=v2.6.36 BUILDROOT=2016.05
    $ make b=vexpress-a9 boot G=1 LINUX=v4.6.7 BUILDROOT=2016.05 // LINUX=v3.18.39 works too

**注意**：

* 真正的图形化方式启动需要 LCD 和键盘驱动的支持，上述开发板可以完美支持 Linux 内核 5.1 版本的运行，`raspi3` 和 `malta` 两款开发板支持 tty0 终端但不支持键盘输入。
* 新版 `BUILDROOT` 配置文件目前设定了 tty 终端为串口（`BR2_TARGET_GENERIC_GETTY_PORT="ttyAMA0"`），如需启用图形控制台，请修改目标文件系统 `/etc/inittab` 中对应的 `getty` 代码行，例如，把 `ttyAMA0` 替换为 `console`；也可简单通过 QEMU 的 “View” 菜单切换到串口终端后使用。

`vexpress-a9` 和 `virt` 缺省情况下不支持 LCD，但对于最新的 QEMU，可以通过在启动时指定 `G=1` 参数然后通过选择 “View” 菜单切换到串口终端，但这么做无法用于测试 LCD 和键盘驱动。我们可以通过 `QOPTS` 选项指定额外的 QEMU 选项参数。

    $ make b=vexpress-a9 CONSOLE=ttyAMA0 boot G=1 LINUX=v5.1
    $ make b=raspi3 CONSOLE=ttyAMA0 QOPTS="-serial vc -serial vc" boot G=1 LINUX=v5.1

基于 curses 图形方式启动（这么做适合采用 bash/ssh 的登录方式，但不是对所有开发板都有效，退出时需要使用 `ESC+2 quit` 或 `ALT+2 quit`）

    $ make b=pc boot G=2 LINUX=v4.6.7

使用预编译的内核、dtb 和 Rootfs 启动：

    $ make boot kernel=old dtb=old root=old

使用新的内核、dtb 和 rootfs 启动：

    $ make boot kernel=new dtb=new root=new

如果目标内核和 U-Boot 不存在，重新编译一个之后再启动：

    $ make boot BUILD=kernel,uboot

启动时禁用 Uboot（目前仅测试并支持了 `versatilepb` 和 `vexpress-a9` 两款开发板）：

    $ make boot U=0

使用不同的 rootfs 启动（依赖于开发板的支持，启动后检查 `/dev/`）

    $ make boot ROOTDEV=ram0     // support by all boards, basic boot method
    $ make boot ROOTDEV=nfs      // depends on network driver, only raspi3 not work
    $ make boot ROOTDEV=sda
    $ make boot ROOTDEV=mmcblk0
    $ make boot ROOTDEV=vda      // virtio based block device

使用额外的内核命令行参数启动（格式：`KCLI = Additional Kernel Command LIne`）：

    $ make boot ROOTDEV=nfs KCLI="init=/bin/bash"

列出支持的选项：

    $ make list ROOTDEV
    $ make list BOOTDEV
    $ make list CCORI
    $ make list NETDEV
    $ make list linux
    $ make list uboot
    $ make list qemu

使用 `list <xxx>` 可以实现更多 `<xxx>-list`，例如：

    $ make list features
    $ make list modules
    $ make list gcc

# 4. Linux Lab 进阶

## 4.1 Linux 内核

### 4.1.1 非交互方式配置

Linux 内核提供了一个脚本 `scripts/config`，可用于非交互方式获取或设置内核的配置选项值。基于该脚本，实验环境增加了两个选项 `kernel-getconfig` 和 `kernel-setconfig`，可用于调整内核的选项。基于该功能我们可以方便地实现类似 "enable/disable/setstr/setval/getstate" 内核选项的操作。

获取一个内核模块的状态：

    $ make kernel-getconfig m=minix_fs
    Getting kernel config: MINIX_FS ...

    build/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

使能一个内核模块：

    $ make kernel-setconfig m=minix_fs
    Setting kernel config: m=minix_fs ...

    build/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

    Enable new kernel config: minix_fs ...

更多 `kernel-setconfig` 命令的控制选项：`y, n, c, o, s, v`：

|选项 | 说明                                                |
|-----|-----------------------------------------------------|
| `y` | 编译内核中的模块或者使能其他内核选项                |
| `c` | 以插件方式编译内核模块，类似 `m` 选项               |
| `o` | 以插件方式编译内核模块，类似 `m` 选项               |
| `n` | 关闭一个内核选项                                    |
| `s` | `RTC_SYSTOHC_DEVICE="rtc0"`，设置 rtc 设备为 rtc0   |
| `v` | `PANIC_TIMEOUT=5`, 设置内核 panic 超时为 5 秒       |

在一条命令中使用多个选项：

    $ make kernel-setconfig m=tun,minix_fs y=ikconfig v=panic_timeout=5 s=DEFAULT_HOSTNAME=linux-lab n=debug_info
    $ make kernel-getconfig o=tun,minix,ikconfig,panic_timeout,hostname

### 4.1.2 使用内核模块

编译所有的内部内核模块：

    $ make modules
    $ make modules-install
    $ make root-rebuild    // not need for nfs boot
    $ make boot

列出 `src/modules/` 和 `boards/<BOARD>/bsp/modules/` 路径下的所有模块：

    $ make modules-list

如果加上 `m` 参数，除了列出 `src/modules/` 和 `boards/<BOARD>/bsp/modules/` 路径下的所有模块外，还会列出 `src/linux-stable/` 下的所有模块：

    $ make modules-list m=hello
        1      m=hello ; M=$PWD/src/modules/hello
    $ make modules-list m=tun,minix
        1      c=TUN ; m=tun ; M=drivers/net
        2      c=MINIX_FS ; m=minix ; M=fs/minix

使能一个内核模块：

    $ make kernel-getconfig m=minix_fs
    Getting kernel config: MINIX_FS ...

    build/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

    $ make kernel-setconfig m=minix_fs
    Setting kernel config: m=minix_fs ...

    build/aarch64/linux-v5.1-virt/.config:CONFIG_MINIX_FS=m

    Enable new kernel config: minix_fs ...

编译一个内核模块（例如：minix.ko）

    $ make modules M=fs/minix/
    或
    $ make modules m=minix

安装和清理模块：

    $ make modules-install M=fs/minix/
    $ make modules-clean M=fs/minix/

其他用法：

    $ make kernel-setconfig m=tun
    $ make kernel tun.ko M=drivers/net
    $ make kernel drivers/net/tun.ko

编译外部内核模块（类似编译内部模块）：

    $ make modules m=hello
    或
    $ make kernel $PWD/src/modules/hello/hello.ko

### 4.1.3 使用内核特性

#### 4.1.3.1 列出当前支持的 feature

内核的众多特性都集中存放在 `src/feature/linux/`，其中包括了特性的配置补丁，可以用于管理已合入内核主线的特性和未合入的特性功能。

    $ make feature-list
    [ /labs/linux-lab/src/feature/linux ]:
      + 9pnet
      + core
        - debug
        - module
      + ftrace
        - v2.6.36
          * env.g3beige
          * env.malta
          * env.pc
          * env.versatilepb
        - v2.6.37
          * env.g3beige
      + gcs
        - v2.6.36
          * env.g3beige
          * env.malta
          * env.pc
          * env.versatilepb
      + kft
        - v2.6.36
          * env.malta
          * env.pc
      + uksm
        - v2.6.38

这里列出了针对某项特性验证时使用的内核版本，如果其他条件未改变的话该特性应该可以正常工作。

#### 4.1.3.2 启用内核模块支持

为了使能内核模块支持，可以执行如下简单的操作：

    // 设置大写的 FEATURE 将自动保存到配置文件中
    $ make feature FEATURE=module
    $ make kernel-olddefconfig
    $ make kernel

#### 4.1.3.3 启用 rust feature

以 `x86_64/pc` 开发板为例：

    $ make BOARD=x86_64/pc

切换到 v6.1.1 内核：

    $ make config LINUX=v6.1.1

编译内核，并使用 `rust_minimal` 模块进行测试：

    // 清理干净，方便启动一个全新的测试
    $ make kernel-cleanall

    // 开展测试，这里的小写是为了节省时间，并且该 feature 设定不会保存，仅当次测试有效
    $ make test f=rust m=rust_minimal

#### 4.1.3.4 启用 kft feature

为了在 malta 开发板上验证基于 2.6.36 版本的 `kft` 特性，可以执行如下操作：

    $ make cleanall b=malta
    $ make test b=malta f=kft LINUX=v2.6.36

#### 4.1.3.5 启用 rt feature

Linux 官方社区提供了 RT Preemption 的实时系统特性，但是还有很多 patchset 游离在外，这里可以简单启用：

    $ make feature-list f=rt
    $ make test b=i386/pc f=rt LINUX=v5.2

#### 4.1.3.6 持久化与清理 feature 设定

清理 feature 设定（清理 .labconfig 中保存的设定）：

    $ make feature FEATURE=rust
    $ make feature FEATURE=

上述功能与 `make config` 完全一致。

### 4.1.4 新建开发分支

如果希望新建一个分支来做开发，那么可以参考如下步骤。

首先在 `src/linux-stable` 或配置的其他 `KERNEL_SRC` 目录下基于某个内核版本新建一个 git 分支，假设历史版本是 v5.1：

    $ cd src/linux-stable
    $ git checkout -b linux-v5.1-dev v5.1

然后通过 `kernel-clone` 从 Linux Lab 的 v5.1 克隆一份配置和相应目录：

    $ make kernel-clone LINUX=v5.1 LINUX_NEW=linux-v5.1-dev

之后就可以跟往常一样开发。

如果基础版本不是 v5.1，那么可以从支持的版本中挑选一个比较接近的，以 `i386/pc` 为例：

    $ make b=i386/pc list linux
    v2.6.10 v2.6.11.12 v2.6.12.6 v2.6.21.5 v2.6.24.7 v2.6.34.9 v2.6.35.14 v2.6.36 v4.6.7 [v5.1] v5.2

例如，想进行 v2.6.38 开发，可以考虑从 v2.6.36 来克隆，就近的配置更接近，出问题可能更少。

    $ cd src/linux-stable
    $ git checkout -b linux-v2.6.38-dev v2.6.38

    $ make kernel-clone LINUX=v2.6.36 LINUX_NEW=linux-v2.6.38-dev

开发过程中，请及时 commit，另外，请慎重使用如下命令，避免清除重要变更：

* kernel-checkout, 检出某个指定版本，可能会覆盖掉当前修改
* kernel-cleanup, 清理 git 仓库，可能会清理掉当前修改
* kernel-clean, 清除历史编译记录
* kernel-cleanall, 同时清理编译结果和源码修改

### 4.1.5 启用独立内核仓库

v0.8 开始新增了 `KERNEL_FORK` 支持，可以配置独立的第三方 Linux 代码仓库，现在已适配 openEuler 和 wsl2，两个都支持 `x86_64/pc`，前者还支持 `aarch64/virt`。

例如，如果要编译 wsl2 内核，切换 `KERNEL_FORK` 即可：

    $ make BOARD=x86_64/pc
    $ make config KERNEL_FORK=wsl2
    $ make kernel

如果要配置 wsl2 的版本，参考如下配置修改即可：

    $ make edit
    LINUX[KERNEL_FORK_wsl2]  := linux-msft-wsl-5.10.74.3

后面的版本号为代码仓库中的任意 git tag。

## 4.2 U-Boot 引导程序

从当前支持 U-boot 的板子：`versatilepb` 和 `vexpress-a9` 中选择一款：

    $ make BOARD=vexpress-a9

下载 U-Boot：

    $ make uboot-source

检出一个特定的版本（版本号在 `boards/<BOARD>/Makefile` 中通过 U-Boot 指定）：

    $ make uboot-checkout

应用必要的补丁修改，可以指定 `BOOTDEV` 和 `ROOTDEV` 两个选项设置，如果不指定则缺省值使用 `flash`。

    $ make uboot-patch

如果要明确指定值为 `tftp`, `sdcard` 或 `flash`，则必须在输入 `uboot-patch` 之前运行 `make uboot-checkout`：

    $ make uboot-patch BOOTDEV=tftp
    $ make uboot-patch BOOTDEV=sdcard
    $ make uboot-patch BOOTDEV=flash

  `BOOTDEV` 用于设定 U-Boot 的存放设备以便从该设备引导，`ROOTDEV` 用于告诉内核从哪里加载 rootfs。

配置 U-boot：

    $ make uboot-defconfig
    $ make uboot-menuconfig

编译 U-boot：

    $ make uboot

使用 `BOOTDEV` 和 `ROOTDEV` 引导，缺省采用 `flash` 方式：

    $ make boot U=1

显式使用 `tftp`, `sdcard` 或 `flash` 方式：

    $ make boot U=1 BOOTDEV=tftp
    $ make boot U=1 BOOTDEV=sdcard
    $ make boot U=1 BOOTDEV=flash

我们也可以在启动引导阶段改变 `ROOTDEV` 选项，例如：

    $ make boot U=1 BOOTDEV=flash ROOTDEV=nfs

执行清理，更新 ramdisk, dtb 和 uImage：

    $ make uboot-images-clean
    $ make uboot-clean

保存 U-Boot 镜像和配置：

    $ make uboot-save
    $ make uboot-saveconfig

## 4.3 QEMU 模拟器

内置的 QEMU 或许不能和最新的 Linux 内核配套工作，为此我们有时不得不自己编译 QEMU，自行编译 QEMU 的方法在 vexpress-a9 和 virt 开发板上已经验证通过。

首先，编译 qemu-system-ARCH：

    $ make B=vexpress-a9
    $ make qemu
    $ make qemu-save

QEMU-ARCH-static 和 qemu-system-ARCH 是不能一起编译的，为了制作 qemu-ARCH-static，请在开发板的 Makefile 中首先使能 `QEMU_US=1` 然后再重新编译。

如果指定了 QEMU 和 QTOOL，那么实验环境会优先使用 bsp 子模块中的 QEMU 和 QTOOL，而不是已经安装在本地系统中的版本，但会优先使用最近编译的版本，如果最近有编译过的话。

在为新的内核实现移植时，如果使用 2.5 版本的 QEMU，Linux 5.0 在运行过程中会挂起，将 QEMU 升级到 2.12.0 后，问题消失。请在以后内核升级过程中注意相关的问题。

QEMU 每次编译都会检查子仓库是否较新，但是下载通常没那么顺利。如果下载过一次子仓库以后不想再更新，可以通过如下方式禁止更新：

    $ make qemu git_module_status=0

## 4.4 Toolchain 工具链

Linux 内核主线的升级非常迅速，内置的工具链可能无法与其保持同步，为了减少维护上的压力，环境支持添加外部工具链。譬如 ARM64/virt, CCVER 和 CCPATH。

列出支持的预编译工具链：

    $ make gcc-list

下载，解压缩和使能外部工具链：

    $ make gcc

切换编译器版本，例子如下：

    $ make gcc-switch CCORI=internal GCC=4.8

    $ make gcc-switch CCORI=linaro

如果未指定外部工具链，则缺省使用内置的工具链。

如果不存在内置的工具链，则必须指定外部工具链。当前对该特性已经支持 aarch64, arm, riscv, mipsel, ppc, i386, x86_64 多个体系架构。

GCC 的版本可以分别在开发板特定的 Makefile 中针对 Linux, Uboot, Qemu 和 Root 分别指定：

    GCC[LINUX_v2.6.11.12] = 4.4

采用以上配置方法，在编译 v2.6.11.12 版本的 Linux 内核时会在 defconfig 时自动切换为使用指定的 GCC 版本。

在编译主机（host）的软件时，也需要做相应配置（需要显式指定 `b=i386/pc`）：

    $ make gcc-list b=i386/pc
    $ make gcc-switch CCORI=internal GCC=4.8 b=i386/pc

## 4.5 Rootfs 文件系统

内置的 rootfs 很小，不足以应付复杂的应用开发，如果需要涉及高级的应用开发，需要使用现代的 Linux 发布包。

环境提供了针对 arm32v7 的 Ubuntu 18.04 的根文件系统，该文件系统已经制作成 Docker 镜像，以后有机会再提供更多更好的文件系统。

可以通过 Docker 直接使用：

    $ docker run -it tinylab/arm32v7-ubuntu

可以将文件系统提取出来在 Linux Lab 中使用：

    (host)$ sudo apt-get install -y qemu-user-static

  ARM32/vexpress-a9（用户名和密码均为 root）:

    (host)$ tools/root/docker/extract.sh tinylab/arm32v7-ubuntu arm
    (lab )$ make boot b=arm/vexpress-a9 U=0 V=1 MEM=1024M ROOTDEV=nfs ROOTFS=$PWD/prebuilt/fullroot/tmp/tinylab-arm32v7-ubuntu

  ARM64/raspi3（用户名和密码均为 root）:

    (host)$ tools/root/docker/extract.sh tinylab/arm64v8-ubuntu arm
    (lab )$ make boot b=aarch64/virt V=1 ROOTDEV=nfs ROOTFS=$PWD/prebuilt/fullroot/tmp/tinylab-arm64v8-ubuntu

其他 Docker 中更多的根文件系统：

    $ docker search arm64 | egrep "ubuntu|debian"
    arm64v8/ubuntu  Ubuntu is a Debian-based Linux operating system  25
    arm64v8/debian  Debian is a Linux distribution that's composed  20

## 4.6 Linux 与 U-Boot 调试

### 4.6.1 调试 Linux

使用调试选项编译内核：

    $ make feature FEATURE=debug
    $ make kernel-olddefconfig
    $ make kernel

编译时使用一个线程：

    $ make kernel JOBS=1

可运行如下命令调试：

    $ make debug

该命令将使用 tmux 分割出两个终端分别运行 QEMU 和 gdb，并从 `.gdb/kernel.default` 加载脚本。

可以使用 CTRL+b+方向键（例如←） 来切换 tmux 的窗格。

如果想修改调试脚本，可以拷贝一份到 `.gdb/kernel.user`，这样就可以无缝升级：

    $ cp .gdb/kernel.default .gdb/kernel.user

以上命令等价于运行如下命令：

    $ make debug linux

自动测试调试可以运行如下命令：

    $ make test-debug linux

找出内核崩溃出错地址所在的代码行：

    $ make kernel-calltrace func+offset/length

如果调试过程中提示端口 1234 被占用，可能是 QEMU 服务没有正常退出，手动清理即可：

    $ sudo netstat -tlp | grep 1234
    tcp        0      0 0.0.0.0:1234            0.0.0.0:*              LISTEN      3943/qemu-xxx
    $ sudo kill -9 3943

### 4.6.2 调试 U-Boot

如果想调试 Uboot（采用 `.gdb/uboot.default` 调试脚本）：

    $ make debug uboot

同样可以自动测试调试：

    $ make test-debug uboot

同样地，如果想修改调试脚本，可以拷贝一份到 `.gdb/uboot.user`，这样就可以无缝升级：

    $ cp .gdb/uboot.default .gdb/uboot.user

## 4.7 自动化测试

以 `aarch64/virt` 作为演示的开发板：

    $ make BOARD=virt

为测试做准备，在 `src/system/` 目录下安装必要的文件/脚本：

    $ make rootdir
    $ make root-rebuild

直接引导启动（参考 6.2.2 节）

    $ make test

测试完毕后不要关机：

    $ make test TEST_FINISH=echo

运行一下客户机的测试用例：

    $ make test TEST_CASE=/tools/ftrace/trace.sh

运行客户机的测试用例（`COMMAND_LINE_SIZE` 必须足够大，譬如，4096，查看下文的 `cmdline_size` 特性）

    $ make test TEST_BEGIN=date TEST_END=date TEST_CASE='ls /;echo hello world'

进行重启压力测试：

    $ make test TEST_REBOOT=2

  **注意**: reboot 可以有以下几种结果 1) 挂起，2) 继续；3) 超时后被杀死，`TEST_TIMEOUT=30`; 4) 超时终止后不报错继续其他测试，`TIMEOUT_CONTINUE=1`

在一个特定的开发板上测试一个特定 Linux 版本的某个功能（`cmdline_size` 特性用于增加 `COMMAND_LINE_SIZE` 为 4096）：

    $ make test f=kft LINUX=v2.6.36 b=malta TEST_PREPARE=board-init,kernel-cleanup

  **注意**：`board-init` 和 `kernel-cleanup` 用于确保测试自动运行，但是 `kernel-cleanup` 不安全，请在使用前保存代码！

测试一个内核模块：

    $ make test m=hello

测试多个内核模块：

    $ make test m=exception,hello

基于指定的 ROOTDEV 测试模块，缺省使用 nfs 引导方式，但注意有些开发板可能不支持网络：

    $ make test m=hello,exception TEST_RD=ram0

在测试内核模块时运行测试用例（在 insmod 和 rmmod 命令之间运行测试用例）：

    $ make test m=exception TEST_BEGIN=date TEST_END=date TEST_CASE='ls /root;echo hello world' TEST_PREPARE=board-init,kernel-cleanup f=cmdline_size

在测试内部内核模块时运行测试用例：

    $ make kernel-setconfig y=debug_fs
    $ make test m=lkdtm TEST_BEGIN='mount -t debugfs debugfs /mnt' TEST_CASE='echo EXCEPTION > /mnt/provoke-crash/DIRECT'

在测试内部内核模块时运行测试用例，传入内核参数：

    $ make test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION'

测试时不使用 feature-init（若非必须可以节省时间）

    $ make test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION' TEST_INIT=0
    或
    $ make raw-test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION'

测试模块以及模块的依赖（使用 `make kernel-menuconfig` 进行检查）：

    $ make test m=lkdtm y=runtime_testing_menu,debug_fs lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION' LINUX=v5.1 TEST_PREPARE=kernel-cleanup

测试时不使用 feature-init，boot-init，boot-finish 以及不带 `TEST_PREPARE`：

    $ make boot-test m=lkdtm lkdtm_args='cpoint_name=DIRECT cpoint_type=EXCEPTION'

测试一个内核模块并且在测试前执行某些 make 目标：

    $ make test m=exception TEST=kernel-checkout,kernel-patch,kernel-defconfig

使用一条命令测试所有功能（从下载到关机，如果关机后挂起，请参考 6.2.2）：

    $ make test TEST=kernel,root TEST_PREPARE=board-init,kernel-cleanup,root-cleanup

使用一条命令测试所有功能（带 U-Boot，如果支持的话，譬如：vexpress-a9）：

    $ make test TEST=kernel,root,uboot TEST_PREPARE=board-init,kernel-cleanup,root-cleanup,uboot-cleanup

测试引导过程中内核挂起，允许指定超时时间，系统挂起时将发生超时：

    $ make test TEST_TIMEOUT=30s

测试过程中如果超时，继续执行后续测试，而不是直接终止：

    $ make test TEST_TIMEOUT=30s TIMEOUT_CONTINUE=1

测试内核调试：

    $ make test DEBUG=1

**注意**: 上述测试在某些板子或者某些内核版本上可能会失败，如果有需要，请升级相应的内核版本。

## 4.8 文件共享

缺省支持如下方法在 QEMU 开发板和主机之间传输文件：

### 4.8.1 在 rootfs 中安装文件

将文件放在 `src/system/` 的相对路径中，安装和重新制作 rootfs：

    $ mkdir src/system/root/
    $ touch src/system/root/new_file
    $ make root-rebuild
    $ make boot

上述操作在 root 用户目录下新增 `new_file` 文件。

### 4.8.2 采用 NFS 共享文件

使用 `ROOTDEV=nfs` 选项启动开发板：

    $ make boot ROOTDEV=nfs

主机 NFS 目录如下：

    $ make env-dump VAR=ROOTDIR
    ROOTDIR="/labs/linux-lab/boards/<BOARD>/bsp/root/<BUILDROOT_VERSION>/rootfs"

### 4.8.3 通过 tftp 传输文件

在 QEMU 开发板上运行 `tftp` 命令访问主机的 tftp 服务器。

主机侧：

    $ ifconfig br0
    inet addr:172.17.0.3  Bcast:172.17.255.255  Mask:255.255.0.0
    $ cd tftpboot/
    $ ls tftpboot
    kft.patch kft.log

QEMU 开发板：

    $ ls
    kft_data.log
    $ tftp -g -r kft.patch 172.17.0.3
    $ tftp -p -r kft.log -l kft_data.log 172.17.0.3

**注意**：当把文件从 QEMU 开发板发送到主机侧时，必须先在主机上创建一个空的文件，这是一个 bug？！

### 4.8.4 通过 9p virtio 共享文件

有关如何为一个新的开发板启用 9p virtio，请参考 [qemu 9p setup][069]。编译 QEMU 时必须使用 `--enable-virtfs` 选项，同时内核必须打开必要的选项。

重新配置内核如下：

    CONFIG_NET_9P=y
    CONFIG_NET_9P_VIRTIO=y
    CONFIG_NET_9P_DEBUG=y (Optional)
    CONFIG_9P_FS=y
    CONFIG_9P_FS_POSIX_ACL=y
    CONFIG_PCI=y
    CONFIG_VIRTIO_PCI=y
    CONFIG_PCI_HOST_GENERIC=y (only needed for the QEMU Arm 'virt' board)

  如果需要使用 QEMU 的 `-virtfs` 或 `-device virtio-9p-pci` 选项，需要使能以上 PCI 相关的选项，否则无法工作：

    9pnet_virtio: no channels available for device hostshare
    mount: mounting hostshare on /hostshare failed: No such file or directory

`-device virtio-9p-device` 需要较少的内核选项。

  为了使能以上选项，请输入以下命令：

    $ make feature FEATURE=9pnet
    $ make kernel-olddefconfig

Docker 主机：

    $ modprobe 9pnet_virtio
    $ lsmod | grep 9p
    9pnet_virtio          17519  0
    9pnet                  72068  1 9pnet_virtio

主机：

    $ make BOARD=virt

    $ make root-rebuild

    $ touch hostshare/test    # Create a file in host

    $ make boot U=0 ROOTDEV=ram0 PBR=1 SHARE=1

    $ make boot SHARE=1 SHARE_DIR=src/modules  # for external modules development

    $ make boot SHARE=1 SHARE_DIR=build/aarch64/linux-v5.1-virt/  # for internal modules learning

    $ make boot SHARE=1 SHARE_DIR=src/examples  # for c/assembly learning

QEMU 开发板：

    $ ls /hostshare/      # Access the file in guest
    test
    $ touch /hostshare/guest-test  # Create a file in guest

使用 Linux v5.1 验证过的开发板：

| 开发板           | 支持状态                                                       |
|------------------|----------------------------------------------------------------|
|aarch64/virt      | virtio-9p-device（virtio-9p-pci 导致 nfsroot 不工作）          |
|arm/vexpress-a9   | 仅支持 virtio-9p-device                                        |
|arm/versatilepb   | 仅支持 virtio-9p-pci                                           |
|x86_64/pc         | 仅支持 virtio-9p-pci                                           |
|i386/pc           | 仅支持 virtio-9p-pci                                           |
|riscv64/virt      | 同时支持 virtio-9p-pci 和 virtio-9p-dev                        |
|riscv32/virt      | 同时支持 virtio-9p-pci 和 virtio-9p-dev                        |

## 4.9 学习汇编

Linux Lab 在 `src/examples/assembly` 目录下有许多汇编代码的例子：

    $ cd src/examples/assembly
    $ ls
    aarch64 arm mips64el mipsel powerpc powerpc64 riscv32 riscv64 x86 x86_64
    $ make -s -C aarch64/
    Hello, ARM64!

## 4.10 学习 C 语言

### 4.10.1 本地编译和运行

以 hello 为例：

    $ cd src/examples/c/hello
    $ make
    gcc -fno-stack-protector -fomit-frame-pointer -fno-asynchronous-unwind-tables -fno-pie -no-pie -m32 -Wall -Werror -g -o hello hello.c
    Hello, World!

### 4.10.2 交叉编译和运行

下面简单介绍如何在 Linux Lab 下交叉编译和并运行 C 程序，以 X32 (code for x86-64, int/long/pointer to 32bits), ARM, MIPS, PPC 和 RISC-V 为例：

    $ sudo apt-get update -y

    $ sudo apt-get install -y libc6-x32 libc6-dev-x32 libx32gcc-8-dev
    $ gcc -mx32 -o hello hello.c
    $ ./hello
    Hello, World!

    $ sudo apt-get install -y libc6-dev-armel-cross libc6-armel-cross
    $ arm-linux-gnueabi-gcc -o hello hello.c
    $ qemu-arm -L /usr/arm-linux-gnueabi/ ./hello
    Hello, World!

    $ sudo apt-get install -y libc6-dev-mipsel-cross libc6-mipsel-cross
    $ mipsel-linux-gnu-gcc -o hello hello.c
    $ qemu-mipsel -L /usr/mipsel-linux-gnu/ ./hello
    Hello, World!

    $ sudo apt-get install -y libc6-dev-powerpc-cross libc6-powerpc-cross
    // Linux Lab v0.6 中，必须加 -static，否则运行时会有段错误
    $ powerpc-linux-gnu-gcc -static -o hello hello.c
    $ qemu-ppc -L /usr/powerpc-linux-gnu/ ./hello
    Hello, World!

    $ sudo apt-get install -y libc6-riscv64-cross libc6-dev-riscv64-cross
    $ riscv64-linux-gnu-gcc -o hello hello.c
    $ qemu-riscv64 -L /usr/riscv64-linux-gnu/ ./hello
    Hello, World!

上面是通过 `qemu-user` 做指令翻译运行，如果要在目标板子上运行，参考 4.8.1 节复制到对应板子的文件系统即可。

主要的包是 `libc6-dev`, `libc6` 以及 `libgcc`，x32 是个例外，包名是 libx32gcc。可以通过 `apt-cache search` 检索更详细的列表。

## 4.11 运行任意的 make 目标

Linux Lab 支持访问所有 App 自身 Makefile 中定义的目标，譬如：

    $ make kernel help
    $ make kernel menuconfig

    $ make root help
    $ make root busybox-menuconfig

    $ make uboot help
    $ make uboot menuconfig

    Or

    $ make kernel-help
    $ make kernel-menuconfig

    $ make root-help
    $ make root-busybox-menuconfig

    $ make uboot-help
    $ make uboot-menuconfig

我们无需进入相关的构造目录就可以直接运行这些 make 目标来制作 kernel、rootfs 和 U-Boot。

## 4.12 提升内核开发效率

### 4.12.1 编译加速并减少磁盘损耗

**注意**：该动作有丢失数据风险，请确保数据安全！

该功能旨在创建一个驻留在内存的临时目录，并挂载为 `/labs/linux-lab/build`，用于存储编译过程中的数据，**如果不主动保存，关机以后，所有编译过程中的数据会全部丢失**。

启用临时缓存（创建一个驻留在内存的文件系统作为 build 目录）：

    $ make build cache

查看临时缓存的使用状态（如果已经启用则会显示状态）：

    $ make build status

用临时缓存做编译加速：

    $ time make kernel

备份临时缓存到永久的文件（如果觉得 build 目录的数据很重要）：

    $ make build backup

停止使用临时缓存（恢复默认的、存放在磁盘上的 build 目录）：

    $ make build uncache

恢复使用上次备份的缓存作为 build 目录：

    $ sudo mount /path/to/backup-file /labs/linux-lab/build/

### 4.12.2 ONESHOT 模式

v0.9 新增了一个 `ONESHOT` 控制开关，开启后，将启动如下功能：

- 自动缓存 `build/` 到内存
- 自动缓存 `src/` 到内存
- 自动启用 fast fetch，即 git shallow fetch

该模式适合的情况：

- 如 `ONESHOT` 所示，该模式适合一次性的开发需求
    - 用完需要主动执行 `kernel-saveconfig`, `kernel-save` 保存配置文件和编译结果

- 适合内存较大但是磁盘较小或者性能较弱的实验主机
    - `src/` 和 `build/` 都放在内存，而不是磁盘

- 方便临时下载和编译内核
    - 如实验主机未提前下载好内核，网速很慢，需临时下载和编译某个特定版本

其用法很简单，在每次实验之前，执行该命令即可：

    $ export ONESHOT=1

如果想一直使用该模式，可以直接配置 `.labinit` 文件：

    ONESHOT := 1

### 4.12.3 Nolibc 模式

v1.2-rc2 新增了 Nolibc 模式，允许极速编译内核和极小应用，并通过 initrd 把两者直接打包在一起，实现 “免 Rootfs” 内核部署。

Nolibc 模式新增了如下两组文件：

- 极小配置：`boards/<ARCH>/<BOARD>/bsp/configs/linux_v6.x_nolibc_defconfig`
- 极小应用：`src/examples/nolibc/hello.c`

类似上面的 `ONESHOT` 模式，在使用过程中开启 `NOLIBC` 即可：

    $ export NOLIBC=1

也可同样写入 `.labinit` 进而持久启用该模式：

    NOLIBC := 1

默认情况下，使用的应用是上面的 hello.c，如果想调整，可以类似地设定 `NOLIBC_SRC` 变量，调整前先做 clean：

    $ make nolibc-clean

然后在命令行传递：

    $ make kernel NOLIBC_SRC=$PWD/src/examples/nolibc/hello.c

该模式特别适合聚焦某个用户态依赖度不高的纯内核特性的开发。

### 4.12.4 Tiny 模式

在 Nolibc 模式的基础上，v1.4-rc2 新增了 Tiny 模式，允许极速编译内核，并引导 initrd。

用法如下：

    $ export KCFG=linux.tiny.config
    $ make kernel
    $ make boot ROOTDEV=ram0

相比默认配置，该模式仅开启部分配置选项，确保可以引导 initrd 并支持命令行交互，因此编译速度较默认配置提升 10 倍。

该模式特别适合测试、开发或预研一些内核新特性。

## 4.13 更多用法

欢迎阅读下述文档学习更多用法：

* 使用 Linux Lab 的好处
    * [Linux Lab：难以抗拒的十大理由 V1.0][067]
    * [Linux Lab：难以抗拒的十大理由 V2.0][068]

* 中文用户手册
    * [Linux Lab v1.4 中文手册][092]
    * [Linux Lab v1.3 中文手册][091]
    * [Linux Lab v1.2 中文手册][089]
    * [Linux Lab v1.1 中文手册][086]
    * [Linux Lab v1.0 中文手册][065]
    * [Linux Lab v0.9 中文手册][064]
    * [Linux Lab v0.8 中文手册][063]
    * [Linux Lab 龙芯实验手册 V0.2][062]

* Linux Lab 视频公开课：含用法介绍、使用案例分享、发布会视频回放、Linux Lab Disk 功能演示等
    * [CCTALK][071]
    * [B 站][024]

* 采用 Linux Lab 作为实验环境的视频课程
    * [《360° 剖析 Linux ELF》][070]
    * [《Rust 语言快速上手》][006]
    * [《软件逆向工程初探》][072]
    * [《Linux 内核热补丁技术介绍与实战》][073]

* 采用 Linux Lab 或者 Linux Lab 正在支持的图书、课程等
    * [成功适配过 Linux Lab 的国内外图书、线上课程列表][015]

* 采用 Linux Lab 或者 Linux Lab 正在支持的真实硬件开发板
    * [ARM IMX6ULL][023]，野火电子
    * RISCV-64 D1, 平头哥

* Linux Lab 社区正在开发的周边硬件
    * [Linux Lab Disk][023]，免安装、即插即用 Linux Lab 开发环境
        * 支持 Ubuntu 18.04-21.04, Deepin 20.2+, Fedora 34+, Mint 20.2+, Ezgo 14.04+, Kali, Manjaro
    * [Pocket Linux Disk][023]，免安装、即插即用 Linux 发行版
        * 支持 Ubuntu 18.04-21.04, Deepin 20.2+, Fedora 34+, Mint 20.2+, Ezgo 14.04+, Kali, Manjaro

# 5. Linux Lab 开发

本节介绍如何从头开始为 Linux Lab 添加一块新的开发板。

## 5.1 选择一个 QEMU 支持的开发板

列出支持的开发板，以 arm 架构为例：

    $ qemu-system-arm -M ?

## 5.2 创建开发板的目录

以 `vexpress-a9` 为例：

    $ mkdir boards/arm/vexpress-a9/

## 5.3 从一个已经支持的开发板中复制一份 Makefile

以 `versatilepb` 为例：

    $ cp boards/arm/versatilebp/Makefile boards/arm/vexpress-a9/Makefile

## 5.4 从头开始配置变量

先注释掉所有的配置项，然后逐个打开获得一个最小的可工作配置集，最后再添加其他配置。

具体参考 `doc/qemu/qemu-doc.html` 或在线说明 <https://www.qemu.org/docs/master/>。

## 5.5 同时准备 configs 文件

我们需要为 Linux，buildroot 甚至 U-Boot 准备 config 文件。

Buildroot 已经为 buildroot 和内核配置提供了许多例子：

    buildroot: src/buildroot/configs/qemu_ARCH_BOARD_defconfig
    kernel: src/buildroot/board/qemu/ARCH-BOARD/linux-VERSION.config

U-Boot 也提供了许多缺省的配置文件：

    uboot: src/u-boot/configs/vexpress_ca9x4_defconfig

内核本身也提供了缺省的配置：

    kernel: src/linux-stable/arch/arm/configs/vexpress_defconfig

Linux Lab 也提供许多有效的配置，`xxx-clone` 命令有助于利用现有的配置：

    $ make list kernel
    v4.12 v5.0.10 v5.1
    $ make kernel-clone LINUX=v5.1 LINUX_NEW=v5.4
    $ make kernel-menuconfig
    $ make kernel-saveconfig

    $ make list root
    2016.05 2019.02.2
    $ make root-clone BUILDROOT=2019.02.2 BUILDROOT_NEW=2019.11
    $ make root-menuconfig
    $ make root-saveconfig

编辑配置文件和 Makefile 直到它们满足我们的需要。

    $ make kernel-menuconfig
    $ make root-menuconfig
    $ make board-edit

配置文件必须放在 `boards/<BOARD>/` 目录下并且在命名上需要注明必要的版本信息，以 `raspi3` 为例：

    $ make kernel-saveconfig
    $ make root-saveconfig
    $ ls boards/aarch64/raspi3/bsp/configs/
    buildroot_2019.02.2_defconfig  linux_v5.1_defconfig

`2019.02.2` 是 buildroot 的版本，`v5.1` 是内核版本，这两个变量需要在 `boards/<BOARD>/Makefile` 中设置好。

更多 clone 命令的用法如下：

    $ make qemu-clone QEMU=<old_version> QEMU_NEW=<new_version>
    $ make uboot-clone UBOOT=<old_version> UBOOT_NEW=<new_version>
    $ make kernel-clone LINUX=<old_version> LINUX_NEW=<new_version>
    $ make root-clone BUILDROOT=<old_version> BUILDROOT_NEW=<new_version>

## 5.6 选择 kernel，rootfs 和 U-Boot 的版本

检出版本时请使用 `tag` 命令而非 `branch` 命令，以 kernel 为例：

    $ cd src/linux-stable
    $ git tag
    ...
    v5.0
    ...
    v5.1
    ..
    v5.1.1
    v5.1.5
    ...

如果我们需要的是 v5.1 的 kernel，那么可以在 `boards/<BOARD>/Makefile` 添加一行：`LINUX = v5.1`。

或者从旧的版本或者是官方的 defconfig 文件中复制一份内核的配置：

    $ make kernel-clone LINUX_NEW=v5.3 LINUX=v5.1

    或

    $ make B=i386/pc
    $ pushd src/linux-stable && git checkout v5.4 && popd
    $ make kernel-clone LINUX_NEW=v5.4 KCFG=i386_defconfig

如果不存在对应的 tag，可以直接使用 commit 号同时为它模拟一个 tag 名字，配置方法如下：

    LINUX = v2.6.11.12
    LINUX[LINUX_v2.6.11.12] = 8e63197f

可以配置和 Linux 版本对应的 `ROOTFS`：

    ROOTFS[LINUX_v2.6.12.6]  ?= $(BSP_ROOT)/$(BUILDROOT)/rootfs32.cpio.gz

## 5.7 配置，编译和启动

以 kernel 为例：

    $ make kernel-defconfig
    $ make kernel-menuconfig
    $ make kernel
    $ make boot

同样的方法适用于 rootfs，U-Boot，甚至 QEMU。

## 5.8 保存生成的镜像文件和配置文件

    $ make root-save
    $ make kernel-save
    $ make uboot-save

    $ make root-saveconfig
    $ make kernel-saveconfig
    $ make uboot-saveconfig

## 5.9 上传所有工作

最后，将 images、defconfigs、patchset 上传到开发板特定的 bsp 子模块仓库。

首先，获取远端 bsp 仓库的地址，方法如下：

    $ git remote show origin
    * remote origin
      Fetch URL: https://gitee.com/tinylab/qemu-aarch64-raspi3/
      Push  URL: https://gitee.com/tinylab/qemu-aarch64-raspi3/
      HEAD branch: master
      Remote branch:
        master tracked
      Local branch configured for 'git pull':
        master merges with remote master
      Local ref configured for 'git push':
        master pushes to master (local out of date)

然后，在 gitee.com 上 fork 这个仓库，上传您的修改，然后发送您的 pull request。

# 6. 常见问题

## 6.1 Docker 相关

### 6.1.1 docker 下载速度慢

为了优化 Docker 镜像的下载速度，请参考 6.1.6 节。

### 6.1.2 Docker 网络与 LAN 冲突

Cloud Lab 默认为 Docker 容器分配了一个 `172.20.0.0/16` 的网段，如果局域网内有其他服务在使用同样的网段，容器将无法正常联网，此时请通过修改 `configs/linux-lab/docker/subnet` 配置另外一个网段，例如：

    $ tools/docker/rm-all
    $ vim configs/linux-lab/docker/subnet
    $ cat configs/linux-lab/docker/subnet
    172.23.0.0/16
    $ tools/docker/run linux-lab

如果 Linux Lab 的网络仍然无法正常工作，请尝试使用另一个专用网络地址，并最终避免与 LAN 地址冲突。

### 6.1.3 本地主机不能运行 Linux Lab

Linux Lab 的完整功能依赖于 [Cloud Lab][027] 所管理的完整 docker 环境，因此，请切勿尝试脱离 [Cloud Lab][027] 在本地主机上直接运行 Linux Lab，否则系统会报告缺少很多依赖软件包以及其他奇怪的错误。

Linux Lab 的设计初衷是旨在通过利用 docker 技术使用预先安装好的环境来避免在不同系统中的软件包安装问题，从而加速我们上手的时间，因此 Linux Lab 暂无计划支持在本地主机环境下使用，也请不要提这样的需求。

### 6.1.4 非 root 无法运行 tools 命令

如果需要在不使用 `sudo` 的情况下执行 `tools` 目录下的命令，请确保将您的帐户添加到 docker 组并重新启动系统以使其生效：

    $ sudo usermod -aG docker <USER>
    $ newgrp docker

如果报：

    newgrp: group 'docker' does not exist

需要手动添加 `docker` 组，再执行以上步骤：

    $ sudo groupadd docker

**注意**: 当前不建议使用 root 而且默认是禁止通过 root 用户使用的，所以请务必把当前用户加入 docker 用户组。

### 6.1.5 网络不通

如果无法 ping 通，请根据下面列举的方法逐一排查：

* DNS 问题

    如果 `ping 8.8.8.8` 工作正常，请检查 `/etc/resolv.conf` 并确保其与主机配置相同。

* IP 问题

    如果 ping 不起作用，请参阅 6.1.2 并更改 docker 容器的 ip 地址范围。

### 6.1.6 Client.Timeout exceeded while waiting headers

解决方法是选择配置以下 Docker 镜像服务站点中的一个：

* [阿里云 Docker 镜像使用文档][018]
* [USTC Docker 镜像使用文档][020]

Ubuntu 系统下，请根据不同版本情况选择下述**某一种**方法进行 Mirror 站点配置：

`/etc/docker/daemon.json`:

    {
        "registry-mirrors": ["<your accelerate address>"]
    }

`/lib/systemd/system/docker.service`:

    ExecStart=/usr/bin/dockerd -H fd:// --registry-mirror=<your accelerate address>

`/etc/default/docker`:

    DOCKER_OPTS=\"\$DOCKER_OPTS --registry-mirror=<your accelerate address>\""

**注意**：以上三种方式不要同时配置，请选择适合 Docker 版本的方式选一种即可，新的 Linux 发行版一般都用 `/etc/docker/daemon.json`。

配置完需要重启 docker 服务才能生效：

    $ sudo service docker restart

对于其他 Linux 系统，Windows 和 macOS 系统，建议优先参考 [阿里云 Docker 镜像使用文档][018]。

如果添加镜像后速度依然很慢，请仔细检查是否配置成功或者是否打错了地址：

    $ docker info | grep -A1 -i Mirrors
    Registry Mirrors:
      https://XXXXX.mirror.aliyuncs.com/

### 6.1.7 关机或重启主机后如何恢复运行 Linux Lab

如果要恢复容器中已经安装的软件和添加的各类配置，请事先保存好容器：

    $ tools/docker/save linux-lab

在关机或者重启主机（或虚拟机）系统后，通常可以通过点击桌面的 “Linux Lab” 图标恢复运行，或者通过命令行像第一次运行那样：

    $ tools/docker/run linux-lab

当前实现不支持通过 `docker start` 恢复容器，请知悉！

如果上述方式无法恢复，请根据情况执行 6.3.9 节中的相应步骤。

如果是从休眠中的主机（或虚拟机）系统唤醒，那么 Linux Lab 也会自动恢复，可以直接使用，登陆方式请参考 2.4 节中提供的 4 种登陆方式。例如，直接开一个浏览器去使用：

    $ tools/docker/webvnc

### 6.1.8 the following directives are specified both as a flag and in the configuration file

如果运行 docker 时遇到如下错误：

    unable to configure the Docker daemon with file /etc/docker/daemon.json: the
    following directives are specified both as a flag and in the configuration
    file: registry-mirrors: (from flag: [https://docker.mirrors.ustc.edu.cn/], from
    file: [https://xxx.mirror.aliyuncs.com])

说明同时在 `/etc/docker/daemon.json` 和 `/etc/default/docker` 中配置了 `registry-mirrors`，请注释掉后面的配置后重启 Docker 服务即可。

    $ sudo service docker restart

### 6.1.9 pathspec FETCH_HEAD did not match any file known to git

如果在 `make boot` 时遇到如下错误，说明容器内网络可能不通，请参考 6.1.5 节。

    Could not resolve host: gitee.com
    error: pathspec 'FETCH_HEAD' dit not match any file(s) known to git

### 6.1.10 Docker not work in Ubuntu 20.04

如果在 Ubuntu 20.04 下 Docker 不工作，请尝试使用 `doc/install/daemon.json` 并清理 dockerd 的默认参数，更多内容请参考 [docker daemon][008]：

    $ sudo cat /etc/systemd/system/docker.service.d/docker.conf
    [Service]
    ExecStart=
    ExecStart=/usr/bin/dockerd

    $ sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    $ sudo cp doc/install/daemon.json /etc/docker/
    $ sudo service docker restart

**注意**：记得把 `registry-mirrors` 配置为你希望使用的加速器地址。

### 6.1.11 Error creating aufs mount

如果遇到类似错误："error creating aufs mount to ... invalid arguments", 那意味着当前配置的 docker 存储驱动不被支持，可以从 [Storage Driver][009] 选配一个，例如：

    $ sudo vim /etc/docker/daemon.json
    {
      "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"],
      "storage-driver": "devicemapper"
    }

这里主要是跟内核版本有关，同样的系统升级内核后，Storage Driver 类型可能得相应调整。

## 6.2 QEMU 相关

### 6.2.1 缺少 KVM 加速

KVM 当前仅支持 `qemu-system-i386` 和 `qemu-system-x86_64`，并且还需要 CPU 和 bios 支持，否则，您可能会看到以下错误日志：

    modprobe: ERROR: could not insert 'kvm_intel': Operation not supported

检查 CPU 的虚拟化支持能力，如果没有输出，则说明 CPU 不支持虚拟化：

    $ cat /proc/cpuinfo | egrep --color=always "vmx|svm"

如果 CPU 支持，我们还需要确保在 BIOS 中启用了该功能，只需重新启动计算机，按 “Delete” 键进入 BIOS，请确保 “Intel virtualization technology” 功能已启用。

### 6.2.2 Guest 关机或重启后挂住

当前对于以下开发板，基于内核版本 5.1（LINUX=v5.1），`poweroff` 和 `reboot` 命令无法正常工作：

* mipsel/malta (exclude `LINUX=v2.6.36`)
* mipsel/ls1b
* mipsel/ls232
* mips64el/ls2k
* mips64el/ls3a7a
* aarch64/raspi3
* arm/versatilepb

在运行 `poweroff` 或 `reboot` 时，系统会直接挂起，为了退出 QEMU，请使用 `CTRL+a x` 或执行 shell 命令 `pkill qemu`。

为了自动化测试这些开发板，请确保设置 `TEST_TIMEOUT`，例如：`make test TEST_TIMEOUT=50`。

欢迎提供修复意见。

### 6.2.3 如何退出 QEMU

| 停留界面               | 退出方式                              |
|------------------------|---------------------------------------|
| 串口控制台             | `CTRL+a x`                            |
| 基于 Curses 的图形终端 | `ESC+2 quit` 或 `ALT+2 quit`          |
| 基于 X 图形终端        | `CTRL+ALT+2 quit`                     |
| 通用方法               | `poweroff`, `reboot`, `kill`, `pkill` |

### 6.2.4 Boot 时报缺少 sdl2 库

这是由于 docker 的 image 没有更新导致，解决的方法是进入 cloud-lab 目录重新运行 lab：

    $ tools/docker/rerun linux-lab

## 6.3 环境相关

### 6.3.1 NFS 与 tftpboot 不工作

如果 NFS 或 tftpboot 不起作用，请在主机端运行 `modprobe nfsd` 并在 Guest 侧通过 `/configs/tools/restart-net-servers.sh` 重新启动网络服务，请确保不要使用 `tools/docker/trun`。

### 6.3.2 在 VIM 中无法切换窗口

浏览器和 VIM 中都提供了 `CTRL+w`，为了避免冲突，要从一个窗口切换到另一个窗口，请改用 `CTRL+Left` 或 `CTRL+Right` 键，Linux Lab 已将 `CTRL+Right` 映射为 `CTRL+w`，将 `CTRL+Left` 映射为 `CTRL+p`。

### 6.3.3 长按 Backspace 不工作

长按键目前在 Web 界面中不起作用，因此，长按 “Delete” 或 “Backspace” 键不起作用，请改用 `alt+delete` 或 `alt+backspace` 组合键，以下是更多有关组合键的小技巧：

|说明           | VIM           | Bash                       |
|---------------|---------------|----------------------------|
|行首/行尾      | `^/$`          | `Ctrl + a/e`              |
|前进/后退一个字| `w/b`          | `Ctrl + Home/end`         |
|向后剪切一个字 | `db`           | `Alt  + Delete/backspace` |
|向前剪切一个字 | `dw`           | `Alt  + d`                |
|剪切光标前所有 | `d^`           | `Ctrl + u`                |
|剪切光标后所有 | `d$`           | `Ctrl + k`                |
|粘帖剪切的内容 | `p`            | `Ctrl + y`                |

### 6.3.4 如何快速切换中英文输入

为了切换英文/中文输入法，请使用 `CTRL+s` 快捷键，而不是 `CTRL+space`，以避免与本地系统冲突。

### 6.3.5 如何调节 Web 界面窗口的大小

有两种方式可以调节 Web 界面窗口的大小，一种是通过 noVNC 左侧边栏设置 Scaling Mode，这样屏幕就可以自适应；另外一种是在启动时指定。

先来介绍第一种，也就是屏幕自适应，这种方法很方便，但是屏幕字体由于拉伸变形后略微有些发虚。

* 点击 noVNC Web 页面左侧的边栏（左侧有个小箭头）
* 断开连接
* 点击设置：'Settings -> Scaling Mode: -> Local Scaling -> Apply'
* 重新连接

接下来介绍第二种方法，即在启动 Lab 时指定一个合适的分辨率。

Linux Lab 的屏幕尺寸是由 `xrandr` 捕获的，如果不起作用，请检查并自行设置，例如：

获取可用的屏幕尺寸值：

    $ xrandr --current
    Screen 0: minimum 1 x 1, current 1916 x 891, maximum 16384 x 16384
    Virtual1 connected primary 1916x891+0+0 (normal left inverted right x axis y axis) 0mm x 0mm
      1916x891      60.00*+
      2560x1600    59.99
      1920x1440    60.00
      1856x1392    60.00
      1792x1344    60.00
      1920x1200    59.88
      1600x1200    60.00
      1680x1050    59.95
      1400x1050    59.98
      1280x1024    60.02
      1440x900      59.89
      1280x960      60.00
      1360x768      60.02
      1280x800      59.81
      1152x864      75.00
      1280x768      59.87
      1024x768      60.00
      800x600      60.32
      640x480      59.94

更新屏幕尺寸：

    $ cd /path/to/cloud-lab
    $ tools/docker/resize 1280x1024  # 指定任意一个尺寸
    $ tools/docker/resize            # 不带参数则设定为主系统同样的屏幕尺寸

如果需要做到全屏，可按如下步骤操作：

1. 如果用到虚拟机，先把虚拟机设置为全屏模式
2. 然后执行：`tools/docker/resize`，把 Lab 屏幕大小设定为主机系统屏幕大小
3. 进入到浏览器的 WebVNC 界面，点击左边栏的 FullScreen 按钮即可放大

### 6.3.6 如何进入全屏模式

打开左边的侧边栏，点击 “Fullscreen” 按钮。

### 6.3.7 如何录屏

1. 使能录制

    打开左侧边栏，按 “Settings” 按钮，配置 “File/Title/Author/Category/Tags/Description”，然后启用 “Record Screen” 选项。

2. 开始录制

    按下 “Connect” 按钮。

3. 停止录制

    按下 “Disconnect” 按钮。

4. 重放录制的视频

    按下 “Play” 按钮。

5. 分享视频

    视频存储在 “cloud-lab/recordings” 目录下，参考 [showdesk.io][019] 的帮助进行分享。

### 6.3.8 Web 界面无响应

Web 连接可能由于某些未知原因而挂起，导致 Linux Lab 有时可能无法响应，要恢复该状态，请点击 Web 浏览器的“刷新”按钮或断开连接后重新连接。

### 6.3.9 登录 WEB 界面时超时或报错

如果登陆 WEB 界面时出现 “Disconnect timeout”，请稍等片刻后继续点击左侧 “Connect” 按钮，如果依然无法成功，请按下述步骤检查。

首先检查 linux-lab 需要的 docker 容器是否正常启动（Up: 正常，Exit: 为不正常）：

    $ docker ps -a
    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    19a61ba075b5 tinylab/linux-lab "/tools/lab/run" 4 days ago Up 4 days 22/tcp, 5900/tcp linux-lab-21575
    75dae89984c9 tinylab/cloud-ubuntu-web "/startup.sh" 8 days ago Up 8 days ....443/tcp cloud-ubuntu-web

如果为 Exit，可能是关机后容器自动关闭了，也可能是容器启动失败，如果是容器自动关闭了可以通过如下命令启动：

    $ tools/docker/run linux-lab

如果依然无法启动，请检查并分析启动日志：

    $ tools/docker/logs linux-lab

如果日志正常，那说明之前保存的帐号和密码可能由于某次异常失效了，需要参考如下步骤重新生成新的帐号和密码。

**注意**: 下述 clean 和 rerun 命令会清理一些容器和数据，请自行做好相应备份，例如固化容器：

    $ tools/docker/save linux-lab

使用不匹配的密码时会导致 Web 登录失败，要解决此问题，请清理环境并重新运行。

    $ tools/docker/clean linux-lab
    $ tools/docker/rerun linux-lab

如果上述命令依然无法启动，请尝试执行下述命令（**该命令会清理整个 Cloud Lab 环境，请务必做好必要数据备份**)：

    $ tools/docker/clean-all
    $ tools/docker/rerun linux-lab

### 6.3.10 Ubuntu Snap 问题

用户报告了许多 `snap` 相关的问题，请改用 `apt-get` 安装 docker：

* 无法将普通用户添加到 docker 用户组从而导致必须通过 root 用户使用 docker。
* snap 服务会耗尽 `/dev/loop` 设备从而导致无法挂载文件系统。

### 6.3.11 如何退出 VNC 客户端全屏模式

在进入 VNC 客户端的全屏模式后，不同客户端软件在不同系统上的退出方式可能五花八门，甚至有些可能有 Bug，如果想切回主机，又没有便捷的方式，就会让人抓狂。

这个时候，就推荐下面的方式，理论上，与 VNC 客户端软件无关，那就是在 Linux Lab 内杀掉 VNC 服务：

    $ sudo pkill x11vnc

由于 Linux Lab 会自动恢复掉线的 x11vnc 服务，所以完全不会影响下次登陆。

## 6.4 Linux Lab 相关

### 6.4.1 No working init found

这意味着 rootfs.ext2 文件可能已损坏，请删除该文件，然后再次尝试执行 `make boot`，例如：

    $ rm boards/aarch64/raspi3/bsp/root/2019.02.2/rootfs.ext2
    $ make boot

`make boot` 命令可以自动创建该映像，请不要中途打断。

### 6.4.2 linux/compiler-gcc7.h: No such file or directory

这意味着您使用的 gcc 版本不为当前 Linux 内核所支持，可使用 `make gcc-switch` 命令切换到较旧的 gcc 版本，以 `i386 / pc` 开发板为例：

    $ make gcc-list
    $ make gcc-switch CCORI=internal GCC=4.4

### 6.4.3 linux-lab/configs: Permission denied

这个错误会在执行 `make boot` 时报出，原因可能是由于克隆代码仓库时使用了 `root` 权限，解决方式是修改 `cloud-lab/` 目录的所有者：

    $ cd /path/to/cloud-lab
    $ sudo chown <USER>:<USER> -R ./{*,.git}
    $ tools/docker/rerun linux-lab

**注意**：为确保环境一致，目前 Linux Lab 仅支持通过普通用户使用，如果是用 `root` 用户下载的代码，请务必确保普通用户可以读写。

### 6.4.4 scripts/Makefile.headersinst: Missing UAPI file

这是因为 MAC OSX 缺省的文件系统不区分大小写，请使用 `hdiutil` 或 `Disk Utility` 自己创建一个：

    $ hdiutil create -type SPARSE -size 60g -fs "Case-sensitive Journaled HFS+" -volname labspace labspace.dmg
    $ hdiutil attach -mountpoint ~/Develop/labspace -nobrowse labspace.dmg.sparseimage
    $ cd ~/Develop/labspace

**注意**：Linux Lab Disk 不存在该问题，建议直接选购 [Linux Lab Disk][022]。

### 6.4.5 unable to create file: net/netfilter/xt_dscp.c

这是因为 Windows 没有使能文件系统的大小写支持，通过 Git Bash 开启它：

    $ cd /path/to/cloud-lab
    $ fsutil file SetCaseSensitiveInfo ./ enable

也可以通过管理员打开 cmd，然后执行：

    $ fsutil.exe file SetCaseSensitiveInfo <path/to/cloud-lab> enable

**注意**：Linux Lab Disk 不存在该问题，建议直接选购 [Linux Lab Disk][022]。

### 6.4.6 如何切到 root 用户

默认情况下，可以免密直接切到 root：

    $ sudo -s

**注意**：请不要使用 su 命令。

### 6.4.7 提示指定的版本或者配置不存在

如果看到如下信息：

    $ make boot ROOTDEV=vda
    ERR: /dev/vda not in supported ROOTDEV list: /dev/sda /dev/ram0 /dev/nfs, update may help: 'make bsp B=mips64el/ls3a7a'.  Stop.

    $ make boot LINUX=v5.8
    Makefile:594: *** ERR: v5.8 not in supported Linux list: loongnix-release-1903 v5.7, clone one please: 'make kernel-clone KERNEL_NEW=v5.8'.  Stop.

    $ make boot QEMU=loongson-v1.1
    Makefile:606: *** ERR: loongson-v1.1 not in supported QEMU list: loongson-v1.0, clone one please: 'make qemu-clone QEMU_NEW=loongson-v1.1'.

表示当前设置的变量值无效，例如：

* 当前设定的版本还未支持或者还未验证和添加
    * 可以通过 `xxx-clone` 命令克隆出一个新版本，目前支持：`qemu-clone`, `uboot-clone`, `kernel-clone`, `root-clone`
    * 克隆完还需要进行配置和编译验证，验证完才能正确使用
    * 完整添加过程请参考第 5 大节

* 当前设定的变量值未经验证或者根本不支持
    * 比如说某个板子目前的 `ROOTDEV_LIST` 中只有 sda, ram0 和 nfs
    * vda 可能根本不支持或者需要重新配置内核后才支持
    * 这个因板子和内核版本而异，需要具体对待

### 6.4.8 is not a valid rootfs directory

如果当前使用的是预制文件系统，说明操作过程中可能有类似 `CTRL+C` 中断了正常根文件系统目录、Ramdisk 或 Hardisk 镜像的创建过程，导致文件系统不完整，在确保 BSP 目录无其他紧要修改的情况下，可以通过如下命令恢复 BSP 仓库为默认设置：

    $ make bsp-cleanup

如果当前使用的是用户自己构建的文件系统，请确保文件系统符合 Linux 的规范，确保相关的基础目录均存在。

# 7. 联系并赞助我们

## 7.1 联系方式

欢迎联系我们加入 Linux Lab 的用户和开发人员讨论组。

* 微信：**tinylab**
* 邮箱：contact /AT\ tinylab /dot/ org

## 7.2 关注并参与

欢迎收藏 Linux Lab 所属社区网站，并在仓库首页右上角标上 Star。

* 公众号：泰晓科技

* 网站：<https://tinylab.org>
    * 创立近十年，聚焦 Linux —— 追本溯源，见微知著
    * 主要关注 Linux 内核、嵌入式 Linux 系统等技术的原创与分享

* 仓库
    * Gitee: <https://gitee.com/tinylab/linux-lab>
    * Github：<https://github.com/tinyclub/linux-lab>

## 7.3 付费支持我们

* 网店：<https://shop155917374.taobao.com>
    * 泰晓开源小店，销售社区自研开源项目周边产品，用于补贴开源项目研发
    * 已上架即插即跑 Linux Lab Disk、Pocket Linux Disk 以及适配过的真实 Linux 开发板等
    * 欢迎选购，也可以在淘宝手机 App 内搜索 “泰晓 Linux” 找到我们

* 星球：<https://t.zsxq.com/uB2vJyF>
    * 泰晓科技 VIP 知识频道
    * 上线 3+ 年，累计 1000+ 分享，20+ 位行业 Linux 专家级嘉宾老师

* 课程：<https://m.cctalk.com/inst/sh8qtdag>
    * 泰晓学院 —— 泰晓科技视频频道
    * 不定期邀请社区长期活跃的 Linux 技术专家做视频直播与视频课程知识分享

## 7.4 扫码提供赞助

### 7.4.1 赞助我们

![Linux Lab 需要更多的用户或者赞助~ 加入我们吧！](doc/images/contact-sponsor.png)

### 7.4.2 赞助列表

以下是截止到本文档最新一次更新时的赞助列表：

* 2022
    * [Summer 2022][085]
        * 赞助项目：[Microbench][081], [OpenHW Lab][082], [PWN Lab][083]

    * PLCT 实验室
        * 赞助了 2 块 D1 开发板
        * 赞助了 [RISC-V Linux 内核技术调研][084] 活动

* 2021
    * [吴伟老师][016]
        * 赞助 5000 元人民币现金并长期友好支持泰晓科技 Linux 技术社区
        * HelloGCC 负责人，HelloLLVM 负责人，PLCT 实验室项目总监。长期致力于推动编译技术及开源工具在国内的推广。欢迎关注公众号：HelloGCC

    * [开源之夏 2021][026]
        * 赞助项目：Rust for Linux, openEuler Kernel for aarch64/virt and x86_64/pc

    * 平头哥，赞助 1 块 D1 开发板
    * 全志，赞助 3 块 D1 开发板

* 2020
    * [龙芯][005]
        * 国产龙芯系列处理器设计与制造商
        * 龙芯公司赞助开发了 mips64el/ls2k, mips64el/ls3a7a, mipsel/ls1b, mipsel/ls232 和相关文档及视频课程

    * [开源之夏 2020][026]
        * 赞助项目：从 Ubuntu 14.04 升级到 Ubuntu 20.04

    * 野火电子，赞助 6 块 IMX6ULL 开发板

[001]: https://gitee.com/tinylab/linux-lab/blob/master/doc/install/arch-docker.md
[002]: https://gitee.com/tinylab/linux-lab/blob/master/doc/install/manjaro-docker.md
[003]: https://gitee.com/tinylab/linux-lab/blob/master/doc/install/ubuntu-docker.md
[004]: http://gitee.com/tinylab/linux-0.11-lab
[005]: http://loongson.cn/
[006]: https://cctalk.com/m/group/89507527
[007]: https://docs.docker.com
[008]: https://docs.docker.com/config/daemon/
[009]: https://docs.docker.com/storage/storagedriver/select-storage-driver/
[010]: https://elinux.org/Work_on_Tiny_Linux_Kernel
[011]: https://get.daocloud.io/toolbox/
[012]: https://gitee.com/loongsonlab/loongson
[013]: https://gitee.com/tinylab/csky
[014]: https://gitee.com/tinylab/linux-lab/issues/I1FZBJ
[015]: https://gitee.com/tinylab/linux-lab/issues/I49VV9
[016]: https://github.com/lazyparser
[017]: https://git-scm.com/downloads
[018]: https://help.aliyun.com/document_detail/60750.html
[019]: http://showdesk.io/post
[020]: https://lug.ustc.edu.cn/wiki/mirrors/help/docker
[021]: https://lwn.net/images/conf/rtlws-2011/proc/Yong.pdf
[022]: https://shop155917374.taobao.com
[023]: https://shop155917374.taobao.com/
[024]: https://space.bilibili.com/687228362/channel/detail?cid=152574
[025]: https://store.docker.com/search?type=edition&offering=community
[026]: https://summer.iscas.ac.cn
[027]: https://tinylab.org/cloud-lab
[028]: https://tinylab.org/linux-lab-disk
[029]: https://tinylab.org/linux-lab-v0.1/
[030]: https://tinylab.org/linux-lab-v0.1-rc1/
[031]: https://tinylab.org/linux-lab-v0.1-rc2/
[032]: https://tinylab.org/linux-lab-v0.1-rc3/
[033]: https://tinylab.org/linux-lab-v02/
[034]: https://tinylab.org/linux-lab-v0.2-rc1/
[035]: https://tinylab.org/linux-lab-v0.2-rc2/
[036]: https://tinylab.org/linux-lab-v0.2-rc3/
[037]: https://tinylab.org/linux-lab-v0.3/
[038]: https://tinylab.org/linux-lab-v03-rc1/
[039]: https://tinylab.org/linux-lab-v03-rc2/
[040]: https://tinylab.org/linux-lab-v03-rc3/
[041]: https://tinylab.org/linux-lab-v0.4/
[042]: https://tinylab.org/linux-lab-v04-rc1/
[043]: https://tinylab.org/linux-lab-v04-rc2/
[044]: https://tinylab.org/linux-lab-v04-rc3/
[045]: https://tinylab.org/linux-lab-v0.5/
[046]: https://tinylab.org/linux-lab-v05-rc1/
[047]: https://tinylab.org/linux-lab-v05-rc2/
[048]: https://tinylab.org/linux-lab-v05-rc3/
[049]: https://tinylab.org/linux-lab-v0.6/
[050]: https://tinylab.org/linux-lab-v06-rc1/
[051]: https://tinylab.org/linux-lab-v06-rc2/
[052]: https://tinylab.org/linux-lab-v0.7/
[053]: https://tinylab.org/linux-lab-v07-rc1/
[054]: https://tinylab.org/linux-lab-v0.8/
[055]: https://tinylab.org/linux-lab-v08-rc3/
[056]: https://tinylab.org/linux-lab-v0.9/
[057]: https://tinylab.org/linux-lab-v09-rc1/
[058]: https://tinylab.org/linux-lab-v09-rc2/
[059]: https://tinylab.org/linux-lab-v09-rc3/
[060]: https://tinylab.org/linux-lab-v1.0/
[061]: https://tinylab.org/manjaro2go/
[062]: https://tinylab.org/pdfs/linux-lab-loongson-manual-v0.2.pdf
[063]: https://tinylab.org/pdfs/linux-lab-v0.8-manual-zh.pdf
[064]: https://tinylab.org/pdfs/linux-lab-v0.9-manual-zh.pdf
[065]: https://tinylab.org/pdfs/linux-lab-v1.0-manual-zh.pdf
[066]: https://tinylab.org/pocket-linux-disk-ubuntu/
[067]: https://tinylab.org/why-linux-lab
[068]: https://tinylab.org/why-linux-lab-v2
[069]: https://wiki.qemu.org/Documentation/9psetup
[070]: https://www.cctalk.com/m/group/88089283
[071]: https://www.cctalk.com/m/group/88948325
[072]: https://www.cctalk.com/m/group/89626746
[073]: https://www.cctalk.com/m/group/89715946
[075]: https://www.kernel.org
[076]: http://showdesk.io/2017-03-11-14-16-15-linux-lab-usage-00-01-02/
[077]: https://tinylab.org
[078]: https://tinylab.org/linux-lab-v1.1-rc1/
[079]: https://tinylab.org/linux-lab-v1.1/
[080]: https://gitee.com/tinylab/tinycorrect
[081]: https://gitee.com/tinylab/microbench
[082]: https://gitee.com/tinylab/openhw-lab
[083]: https://gitee.com/tinylab/pwn-lab
[084]: https://tinylab.org/riscv-linux
[085]: https://tinylab.org/summer2022
[086]: https://tinylab.org/pdfs/linux-lab-v1.1-manual-zh.pdf
[087]: https://www.cctalk.com/m/group/90483396
[088]: https://www.cctalk.com/m/group/90251209
[089]: https://tinylab.org/pdfs/linux-lab-v1.2-manual-zh.pdf
[090]: https://tinylab.org/tiny-riscv-box
[091]: https://tinylab.org/pdfs/linux-lab-v1.3-manual-zh.pdf
[092]: https://tinylab.org/pdfs/linux-lab-v1.4-manual-zh.pdf
