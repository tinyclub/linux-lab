# centos7.3 和centos7.5 中iperf3 中udp 测试性能差异的原因
    作者：高承博  金琦  刘唐
---
layout: post
author: 'Gao Chengbo'
title: "一文介绍了定位iperf3 中udp 测试性能差异的整个过程"
top: false
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /libvirt/
description: "用iperf3 进行udp 和tcp 性能测试是云环境中很基本的性能测试，其中udp 的带宽是评价虚机网络很重要的指标"
category:
  - iperf
  - 虚拟化

tags:
  - iperf
---


>
> By 高承博 金琦 刘唐 of [TinyLab.org](http://tinylab.org)
> 2020/01/17
>

## iperf3 对比测试
用iperf3记性udp 和tcp 性能测试是云环境中很基本的性能测试，其中udp的带宽是评价虚机网络性能的关键指标。
### iperf3打udp 64字节小包命令：
#### server 端：

    iperf3 -s -p 5672
    -p 5672：表示端口号
#### client 端:

    iperf3 -c xxx.xxx.xx -t 100 -P 1 -u -b 5000M -l 64 -p 5672
    -t 100：表示打流时间为100秒
    -P 1：表示几个client端并行打流
    -u：表示报文种类为udp
    -b：表示带宽
    -l：报文数据长度(注意是数据长度，不是报文总长度)
    -p：填server端的监听端口号
### 测试环境
![alt 图1](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure1.png)

#### 测试结果对比:
##### centos7.4 测试结果：
![alt 图2](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure2_centos693.png)
##### centos7.5 测试结果：
![alt 图3](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure3_centos862.png)

## 定位过程
### 火焰图定位
#### 火焰图命令
    git clone https://github.com/cobblau/FlameGraph
    perf record -F 99 -p xxx -g -- sleep 10
    -p xxx: 为iperf3 的进程号
    perf script | FlameGraph/stackcollapse-perf.pl | FlameGraph/flamegraph.pl > 862.svg

#### 514火焰图
![alt 图4](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure4_centos693.png)
#### 862火焰图
![alt 图5](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure5_centos862.png)

从cento862 火焰图的火焰图可以看出在__select 调用后有很大的空档。我们是基于centos693 的基础上安装了centos862 的内核。glibc前后都是一样的，可以排除。那么glibc 的select 后调用了系统调用找到了内核的select.c 文件中的sys_select，但从centos862 的火焰图可以看出在__select有很大一部分空档。并且centos862中的system_call_fastpath的占比明显少了很多，我们怀疑这可能是影响iperf3性能的关键。

### 检查系统调用代码。
#### system_call
在X86 的体系架构里glibc 通过系统调用把系统调用号放到rax寄存器，然后调用syscall 指令进入内核态，这个细节不是我们讨论的重点。我们关心的是内核的系统调用响应函数system_call 函数。函数的代码centos 的版本中放在了arch/x86/kernel/entry_64.S 中。system_call 函数中执行了system_call_fastpath 这个标签，很有可能是在system_call 函数进入system_call_fastpath 前做了一些操作导致了system_call_fastpath 执行的时间变少。出于此怀疑，我们对比一下centos693 和 centos862 的system_call 代码。

#### centos693 和 centos862 代码对比
![alt 图6](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure6.png)

![alt 图7](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure7.png)

我们可以看到在system_call 代码中加入了：

	IBRS_ENTRY /* no indirect jump allowed before IBRS */
	FILL_RETURN_BUFFER /* no ret allowed before stuffing the RSB */

经过查询资料发现，这个是当年meltdown 漏洞相关。

还有一个在system_call_fastpath 中加入了：
   
  #ifdef CONFIG_RETPOLINE
	movq sys_call_table(, %rax, 8), %rax
	call __x86_indirect_thunk_rax

经过查询资料发现，这个也是跟安全相关的一个补丁

#### 去掉centos862 上述两部分代码测试结果
![alt 图8](D:\tinylab_workspace\tinylab.workspace\wp-content\uploads\2021\1\udp_test\figure7.png)



