---
title: 小米、魅族不约而同开源部分机型 Linux 内核
author: 泰晓科技
layout: post
permalink: /xiaomi-and-meizu-release-linux-kernel-for-parts-of-their-phones/
tags:
  - 魅族
  - Linux
  - MI 3C
  - MI 3W
  - MI 4
  - MI Note
  - MX3
  - 小米
  - 开源
categories:
  - 行业动向
  - 开源社区
---

> by 泰晓科技
> 2015/04/05


## 快讯

今天瞎逛微博看到这么一条消息：

![小米、魅族公开部分机型 Linux 源码][1]

## 小米开源 MI 3W/3C, MI 4/NOTE 序列内核

小米于 **5天前** 公开了包括如下机型的 Linux 内核源码：MI 3W，MI 3C，MI 4 series，MI NOTE。

  * 源码首页：[https://github.com/MiCode/Xiaomi\_Kernel\_OpenSource][2]

  * 机型分布（用不同 git 分支管理不同机型）

      * cancro-kk-oss(contain MI 3W, MI 3C, MI 4 series, MI NOTE)
      * armani-jb-oss(H1S)
      * dior-kk-oss(HM-NOTE-LTE)

  * 下载开源 MX3 序列内核

    以 MI3/MI4/Note为例：

        git clone -b cancro-kk-oss https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git


## 魅族

巧合的是，魅族也于 **3天前** 公开了 MX3 序列的 Linux 内核源码。

  * 源码首页：https://github.com/meizuosc
  * 机型分布（用不同 git 仓库管理不同机型）

      * MX3: <https://github.com/meizuosc/m35x>
      * MX2: <https://github.com/meizuosc/m040>
      * MX: <https://github.com/meizuosc/m03x>
      * M9: <https://github.com/meizuosc/m9>

  * 下载

    以 MX3 为例：

        git clone https://github.com/meizuosc/m35x.git


## 小结

从这个消息来看，国内手机公司，特别是小米和魅族对 GPL 协议还是比较重视的，特别是在前段时间 XDA 论坛的开发者控诉过后，它们能够积极应对及时响应了社区和用户的诉求。希望其他公司，比如说华为、中兴等也能积极响应。

关于更多手机厂商开放 Linux 内核的情况以及开放 Linux 内核的意义，之前本站也做过一次调研，具体信息请参考：[盘点那些已经开放 Linux 内核源代码的智能手机厂商][3]。





 [1]: /wp-content/uploads/2015/04/xiaomi_meizu_release_linux_kernel.jpg
 [2]: https://github.com/MiCode/Xiaomi_Kernel_OpenSource
 [3]: /counting-those-who-have-already-opened-the-kernel-source-smartphone-maker/
