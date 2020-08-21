---
layout: post
author: '刘立超'
title: "初识Linux网络栈及常用优化方法"
top: false
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /linux-net-stack-link/
description: " 文章摘要 "
category:
  - Linux 内核
  - 网络管理
tags:
  - network
---

> By 法海 of [TinyLab.org][1]
> Aug 20, 2020

## 文章简介

基于 ping 流程窥探 Linux 网络子系统，同时介绍各个模块的优化方法。

## ping 基本原理

1. Client 端发送 ICMP ECHO_REQUEST 报文给 Server
2. Server 端回应 ICMP ECHO_REPLY 报文给 Client

这其中涉及基本的二三层转发原理，比如：直接路由、间接路由、ARP 等概念。
不是本文重点，最基本的网络通信原理可以参考这篇文章：
* [TCP/IP 入门指导](https://mp.weixin.qq.com/s/5mwlij2iL83NdcPFUW6JuQ)

## ping 报文发送流程

**系统调用层**

1. sendmsg 系统调用
2. 根据目标地址获取路由信息，决定报文出口
3. `ip_append_data()` 函数构建 skb（这时才将报文从用户态拷贝到内核态），将报文放入 socket buffer
4. 调用 `ip_push_pending_frames()`，进入 IP 层处理

**IP 层**

1. 填充 IP 头
2. 根据 neighbour 信息，填充 MAC 头，调用 `dev_queue_xmit()` 进入网络设备层

**网络设备层**

1. 选择发送队列
2. `__dev_xmit_skb()` 尝试直接发送报文，如果网卡繁忙就将报文放入目标发送队列的 qdisc 队列，并触发 NET_TX_SOFTIRQ 软中断，在后续软中断处理中发送 qdisc 队列中的报文
3. 驱动层发包函数，将 skb 指向的报文地址填入 tx descriptor，网卡发送报文
4. 发送完成后触发中断，回收 tx descriptor（实际实现中一般放在驱动 poll 函数中）

## 优化点

* **socket buffer**

  应用程序报文首先放入 socket buffer，socket buffer 空间受 wmem_default 限制，而 wmem_default 最大值受 wmem_max 限制。

  调整方法：

      sysctl -w net.core.wmem_max=xxxxxx   ----  限制最大值
      sysctl -w net.core.wmem_default=yyyyyy

* **qdisc 队列长度**

  经过网络协议栈到达网络设备层的时候，报文从 socket buffer 转移至发送队列 qdisc。

  调整方法：

      ifconfig eth0 txqueuelen 10000

* **qdisc 权重**

  即一次 NET_TX_SOFTIRQ 软中断最大发送报文数，默认64。

  调整方法：

      sysctl -w net.core.dev_weight=600

* **tx descriptor 数量**

  即，多少个发送描述符。

  调整方法：

      ethtool -G eth0 rx 1024 tx 1024

* **高级特性：TSO/GSO/XPS**

  TSO（TCP Segmentation Offload）：超过 MTU 大小的报文不需要在协议栈分段，直接由网卡分段，降低 CPU 负载。

  GSO（Generic Segmentation Offload）：TSO 的软件实现，延迟大报文分段时机到 IP 层结束或者设备层发包前，不同版本内核实现不同。

  开启方法：

      ethtool -K eth0 gso on
      ethtool -K eth0 tso on

  XPS（Transmit Packet Steering）：对于有多队列的网卡，XPS 可以建立 CPU 与 tx queue 的对应关系，对于单队列网卡，XPS 没啥用。

  开启方法：

      内核配置CONFIG_XPS
      建立cpu与发送队列映射：echo cpu_mask > /sys/class/net/eth0/queues/tx-<n>/xps_cpus


## ping 报文收取过程

**驱动层**

1. 网卡驱动初始化，分配收包内存（ring buffer），初始化 rx descriptor
2. 网卡收到报文，将报文 DMA 到 rx descriptor 指向的内存，并中断通知 CPU
3. CPU 中断处理函数：关闭网卡中断开关，触发 NET_RX_SOFTIRQ 软中断
4. 软中断调用网卡驱动注册的 poll 函数，收取报文（著名的 NAPI 机制）
5. 驱动 poll 函数退出前将已经收取的 rx descriptor 回填给网卡

**协议栈层**
1. 驱动层调用 `napi_gro_receive()`，开始协议栈处理，对于 ICMP 报文，经过的处理函数：`ip_rcv()` -> `raw_local_deliver()` -> `raw_rcv()` -> `__sock_queue_rcv_skb()`

   现在内核都使用 GRO 机制将驱动层 skb 上送协议栈，GRO 全称 Generic Receive Offload，是网卡硬件的 LRO 功能（Intel 手册使用 RSC 描述）的软件实现，可以将同一条流的报文聚合后再上送协议栈处理，降低 CPU 消耗，提高网络吞吐量。

2. 送入 socket buffer
3. 基于 poll/epoll 机制唤醒等待 socket 的进程 

**应用读取报文**
1. 从 socket buffer 的读取文，并拷贝到用户态

## 优化点

* **rx descriptor 长度**

  瞬时流量太大，软件收取太慢，rx descriptor 耗尽后肯定丢包。增大 rx descriptor 长度可以减少因为瞬时流量大造成的丢包。但是不能解决性能不足造成的丢包。

  调整方法：

      查看 rx descriptor 长度：ethtool -g eth0
      调整 rx descriptor 长度：ethtool -G eth0 rx 1024 tx 1024

* **中断**

  为了充分利用多核 CPU 性能，高性能（现代）网卡一般支持多队列。配合底层 RSS（Receive-Side Scaling）机制，将报文分流到不同的队列。每个队列对应不同的中断，进而可以通过中断亲和性将不同的队列绑定到不同的 CPU。

  PS：只有 MSI-X 才支持多队列/多中断。

  调整方法：

      中断亲和性设置：echo cpu_mask > /proc/irq/<irq_no>/smp_affinity
      查看队列数：ethtool -l eth0
      调整队列数：ethtool -L eth0

  进阶：队列分流算法设置

* **NAPI**

  网卡中断中触发 NET_RX_SOFTIRQ 软中断，软中断中调用驱动 poll 函数，进行轮询收包。NAPI 的好处在于避免了每个报文都触发中断，避免了无意义的上下文切换带来的 Cache/TLB miss 对性能的影响。

  但是 Linux 毕竟是通用操作系统，NAPI 轮询收包也要有限制，不能长时间收包，不干其他活。所以 NET_RX_SOFTIRQ 软中断有收包 budget 概念。即，一次最大收取的报文数。
  收包数超过 netdev_budget（默认300）或者收包时间超过2个 jiffs 后就退出，等待下次软中断执行时再继续收包。驱动层 poll 收包函数默认一次收64个报文。

  netdev_budget 调整方法：

      sysctl -w net.core.netdev_budget=600

  驱动层 poll 函数收包个数只能修改代码。一般不需要修改。

* **开启高级特性 GRO/RPS/RFS**

  GRO（Generic Receive Offload）：驱动送协议栈时，实现同条流报文汇聚后再上送，提高吞吐量。对应 `napi_gro_receive` 函数。
  
  开启方法：

      ethtool -K eth0 gro on

  RPS（Receive Packet Steering）：对于单队列网卡，RPS 特性可以根据报文 hash 值将报文推送到其它 CPU 处理（把报文压入其它 CPU 队列，然后给其它 CPU 发送 IPI 中断，使其进行收包处理），提高多核利用率，对于多队列网卡，建议使用网卡自带的 RSS 特性分流。

  RFS（Receive Flow Steering）：RFS 在 RPS 基础上考虑了报文流的处理程序运行在哪个 CPU 上的问题。比如报文流 A 要被运行在 CPU 2 的 APP A 处理，RPS 特性会根据报文 hash 值送入 CPU 1，而 RFS 特性会识别到 APP A 运行在 CPU 2 信息，将报文流 A 送入CPU 2。

  **PS：** RFS 的核心是感知报文流的处理程序运行在哪个 CPU，核心原理是在几个收发包函数（`inet_recvmsg()`, `inet_sendmsg()`, `inet_sendpage()`、`tcp_splice_read()`）中识别并记录不同报文流的处理程序运行在哪个CPU。

  RPS 开启方法：

      echo cpu_mask > /sys/class/net/eth0/queues/rx-0/rps_cpus

  RFS 设置方法：

      sysctl -w net.core.rps_sock_flow_entries=32768
      echo 2048 > /sys/class/net/eth0/queues/rx-0/rps_flow_cnt

  **PS：** RFS 有些复杂，这里只说举例配置，不讲述原理（其实就是不会。。。）

* **socket buffer**

  `__sock_queue_rcv_skb()` 中会将 skb 放入 socket buffer，其中会检查 socket buffer 是否溢出。所以要保证 socket buffer 足够大。
  
  设置方法：

      sysctl -w net.core.rmem_max=xxxxxx   ----  限制最大值
      sysctl -w net.core.rmem_default=yyyyyy

## 参考文档

* [scaling](https://github.com/torvalds/linux/blob/v3.13/Documentation/networking/scaling.txt)
* [monitoring-tuning-linux-networking-stack-receiving-data](https://blog.packagecloud.io/eng/2016/06/22/monitoring-tuning-linux-networking-stack-receiving-data/)
* [monitoring-tuning-linux-networking-stack-sending-data](https://blog.packagecloud.io/eng/2017/02/06/monitoring-tuning-linux-networking-stack-sending-data/
)