---
title: 一张图看明白手机设备内存管理
author: Chen Jie
layout: post
permalink: /a-picture-see-device-memory-management/
tags:
  - CMA
  - DMA-BUF
  - IOMMU
  - 手机
categories:
  - 内存管理
---

<!-- title: 一张图看明白手机设备内存管理 -->

<!-- %s/!\[image\](/&#038;\/wp-content\/uploads\/2015\/07\// -->

> by Chen Jie of [TinyLab.org][1]
> 2015/7/12

一张源自『Memory Management in Tizen ([pdf][2])』的图，介绍了地道的手机设备内存管理：

![image][3]

相机、codec、radio，由内核 V4L2 子系统处理，使用 VB2 ([Video Buffer 2][4]) 接口来管理设备内存。GPU 由 DRM 子系统处理，使用 GEM ([the Graphics Execution Manager][5]) 接口来管理设备内存。

跨子系统的设备内存共享，例如显示相机的一帧，从 V4L2 经 **相机 App** 到 DRM，借助 DMA-Buf([DMA buffer sharing][6]) 机制。

当设备内存可以共享时，同步问题也随之而来。由此对 DMA-Buf 进一步引入了 [DMA Fence][7]。

对于手机而言，并无专用内存，即所有设备内存均从系统内存分配。因此落实上述设备内存，通常使用 CMA([Contiguous Memory Allocator][8])，@teawater 同学对 CMA 贡献了诸多改进，可参阅『[Buddy 和 CMA 简介，以及在 Android 中实际使用 CMA 遇到问题的改进][9]』。

CMA 用来分配连续物理内存，因此还有较大的限制。如果硬件足够高大上，即支持 IOMMU 机制，就可以摆脱这种限制。就像借助 MMU 单元，CPU 可以虚拟分页访问物理内存一样；借助 IOMMU 单元，IO 设备达到同样的目的。





 [1]: http://tinylab.org
 [2]: https://events.linuxfoundation.org/images/stories/slides/lfcs2013_ham.pdf
 [3]: /wp-content/uploads/2015/07/tizen-kern-mm.jpg
 [4]: https://lwn.net/Articles/416649/
 [5]: https://lwn.net/Articles/283798/
 [6]: https://lwn.net/Articles/474819/
 [7]: https://lwn.net/Articles/506435/
 [8]: https://lwn.net/Articles/447029/
 [9]: /buddy-actually-use-cma-and-cma-brochures-as-well-as-android-problem-improving/
