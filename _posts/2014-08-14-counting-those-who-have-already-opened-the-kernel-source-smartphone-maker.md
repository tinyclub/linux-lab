---
title: 盘点那些已经开放 Linux 内核源代码的智能手机厂商
author: Wu Zhangjin
layout: post
permalink: /counting-those-who-have-already-opened-the-kernel-source-smartphone-maker/
tags:
  - CyanogenMod
  - 魅族
  - 魔趣
  - HTC
  - kernel
  - Linux
  - maker
  - Meizu
  - Mokee
  - open source
  - Oppo
  - ROM
  - Samsung
  - Smartphone
  - 刷机
  - 小米
categories:
  - Android
  - Linux
  - Mobile
---

> by falcon of [TinyLab.org][2]
> 2014/08/14

Linux内核源代码遵循 [GPL v2版权协议][3]，既然Android手机厂商选择使用Android Linux，那么他们就有义务公开Linux内核源代码。

但实际公开的手机厂商有多少呢？我们稍微盘点一下并列出他们公布源代码的地址：

  * [魅族][4]

    除了最新一款在卖的MX3以外，已经公开M9，MX和MX2的内核源代码。

    公开地址：<https://github.com/meizuosc>

  * [小米][5]

    小米开放了MI 2/MI 2S/MI 2A的内核源代码，但MI 3/MI 4/MI 1都缺席。

    公开地址：<https://github.com/mitwo-dev>

  * Oppo

    Oppo也已公开Find5，Find7，N1，R819机型的内核源代码。

    公开地址：<https://github.com/oppo-source>

  * Samsung

    三星公开了大部分手机的内核源代码。通过下面可以搜索，例如S4 I9500，搜索i9500即可找到对应的源代码包。

    公开地址：<http://opensource.samsung.com/reception.do>

  * HTC

    HTC在开放内核源码这一块也非常积极。

    公开地址：<http://www.htcdev.com/devcenter/downloads>

  * Google

    Nexus作为Android的标配硬件，这个内核源代码是第一次时间随Android发布的。

    公开地址：<https://android.googlesource.com/>

其他公司基本都藏着掖着。

源代码公开除了版权协议要求外，还有什么其他的实际好处呢？

  * 个性化定制ROM

    有了内核源代码以后，牛人们就可以从原始固件中挖出不开放的库和其他固件，结合原生 Android，然后自由发挥，定制更个人性的ROM。

    国外的 [CyanogenMod][6] 和国内的 [魔趣][7] 是开放源代码的定制ROM的典范。

    不过，如果要刷机，引导器的解锁通常是必须的，如果不解锁，即使定制了ROM，也刷不了。

  * 技术学习和参考

    各大厂商，既然敢公开代码，代码的质量，包括稳定性，基本上应该是已经达到了一定的程度，相应的支持和优化也会做得比较到位。

    这样，作为学生、研究人员、甚至是其他做类似SOC方案的手机厂商都可以把这些代码作为参考。

  * 应用开发参考

    开放源代码意味着公开了更多内核接口的细节，那么某些依赖底层接口的上层应用就可以更好地开发，因为应用工程师可以通过代码分析接口的具体实现，然后做更合理的使用。

  * 没有后门？

    既然敢公开代码，那后门主观上应该是不存在的。

总之，对于用户，源码开放总体来说是一件有百利的事情，至于有无害处，就要看刷机时会不会刷成砖头了 ;-P

另外，千万不要随便刷网络中不可信的ROM，因为源代码公开后，某些制作ROM的坏人可能会随意植入后门了，流量、银行帐号、各种密码通通不安全了。





 [2]: http://tinylab.org
 [3]: https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/plain/COPYING
 [4]: http://www.meizu.com
 [5]: http://www.mi.com
 [6]: http://www.cyanogenmod.org/
 [7]: http://www.mokeedev.com/en/
