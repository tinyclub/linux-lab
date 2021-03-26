---
layout: post
author: 'Wu Zhangjin'
title: "Rust For Linux 项目启动 Upstream，是时候了解 Rust 语言了"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /rust-for-linux-to-linux-next/
description: "Rust 与 Linux 社区重要热点，Rust for Linux 开启 Upstream 之路"
category:
  - 技术动态
  - Linux 内核
tags:
  - Rust
  - Linux
  - 技术直播
  - RustCC
---

> By Falcon of [TinyLab.org][1]
> Mar 26, 2021

## 简介

两个礼拜前，泰晓科技技术社区刚邀请 RustCC 社区负责人 Mike 老师开讲了一堂 [Rust 入门直播课](https://www.cctalk.com/m/group/89507527)，那会儿刚好关注并讨论到 Rust for Linux，不过了解的人不多，所以讨论并不热烈。

没想到这几天社区已经开始往 Linux Next 提交支持了，看上去我们的关注是很及时的，预计在 5.13 可以在主线用上 Rust 写驱动了。

## Rust For Linux Upstream

![Rust + Linux](/wp-content/uploads/2021/03/rust-for-linux.png)
<p style="text-align:center">（图片源自网络）</p>

从当前的进展来看，Linux Next 里头已经提供了基础的支持，并有了第一个 char driver 的案例，相关代码路径如下：

1. [Documentation/rust](https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/tree/Documentation/rust)
2. [rust/](https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/tree/rust)（Linux 根目录下，rust for kernel 核心支持）
3. [drivers/char/rust_example.rs](https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/tree/drivers/char/rust_example.rs)

不过，粗略浏览了一下文档和模块案例，没有使用经验还真难看懂那些奇怪的关键字和语法，但是，保持接触的心态对新事物已经是很重要的一步。

另外，Rust for Linux 项目地址如下：

* [Rust For Linux](https://github.com/Rust-for-Linux)

## Rust 该不该学

从上次的课程、现有的趋势以及业界目前的部分实践来看，Rust 在 Safety/Stability 方面的前置语法层面的保障必然会成为很重要的一个特性，对于规模化产品的收益看上去是可以预期的。

感兴趣的同学可以回看 Mike 老师 Rust 直播课的精剪，已经上传到泰晓学院。

![Rust 课程宣传图](/wp-content/uploads/2021/03/rust/rust-course-pic.jpg)

也有邀请他准备一堂额外的实验课，正在紧张准备中，以下为课程报名地址：

* [《Rust 语言快速上手》视频直播课](https://www.cctalk.com/m/group/89507527)

课程大纲如下：

> 课程主要分为入门简介、十问十答和上手实验三部分。
>
> 一、入门简介
>
> 1. Rust 语言简介与历史
> 2. Rust 语言适用的领域
> 3. Rust 语言的几个高光特性
> 4. Rust 与 Linux 内核
> 5. Rust 与 GPU
> 6. Rust 与 嵌入式
> 7. Rust 与 Libc
> 8. 面向 C 与嵌入式的 Rust 特性介绍
> 9. Rust 与 C 代码的对比：所有权
> 10. Rust 与 C++ 的关联
>
> 二、十问十答
>
> 1. Rust 是否从语言层面保障能提前暴露产品问题？
> 2. Rust 在嵌入式/RTOS 领域对工程师有什么挑战？
> 3. Rust 对普通程序员的挑战？
> 4. 为什么 Rust 改造过的工具性能提升幅度很大？
> 5. 由 Rust 编写的驱动可以直接加载吗？
> 6. Rust 在编程范式方面是否有一些限制？
> 7. Rust 是否能从语法层面能保障多线程内存安全？
> 8. Rust 编译成的文件是什么格式？
> 9. 有一个用 Rust 写的 OS 是什么？
> 10. Rust 宏系统是什么？
>
> 三、上手实验
>
> 1. hello world
> 2. 函数调用与返回
> 3. 几种传参方式
> 4. 结构体实验
> 5. 枚举与 match 实验
> 6. 结构体的方法
> 7. 特质 trait
> 8. 模块结构
> 9. 输出格式化
> 10. 输入输出到文件

[1]: http://tinylab.org
