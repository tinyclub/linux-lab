---
title: 'Vulkan：替代 OpenGL 的下一代图形 API'
author: Chen Jie
layout: post
permalink: /vulkan-an-alternative-the-next-generation-opengl-graphics-api/
views:
  - 311
tags:
  - Denver
  - GDC15
  - GPU
  - Khronos
  - MIMD
  - OpenCL
  - OpenGL
  - SIMD
  - SPIR
  - Tegra K1
  - Vulkan
categories:
  - Linux
---

<!-- title: vulakn - 替代 openGL 的下一代图形 API -->

<!-- %s/!\[image\](/&#038;\/wp-content\/uploads\/2015\/03\// -->

> by Chen Jie of [TinyLab.org][1]
> 2015/3/21


## OpenGL 的接班人叫 Vulkan

去年，OpenGL 过时，效率低下的争论红红火火。接着就来了各种替代，性能更是各种 Duang Duang Duang 的超越，比如 AMD 的馒头（Mantle），哦不，地幔；水果的合金（Metal）。。。

作为行业标准的制定者，Khronos 终于站出来，在本月的 GDC 大会上，宣布了 Vulkan，作为 OpenGL 的接班人，性能果然是霸气外漏。[Imagination][2] 甚至已经体验过，祭出[博文一篇][3]细致说明霸气是怎么漏出来的。

## Vulkan 是肿么回事

虽然 Khronos 说 Vulkan 不是一个底层 API，仅是更好抽象了现代的显卡硬件（Vulkan is not “low level” – just a better abstraction of modern hardware）。但事实上 应用开发者 要干的活变多了，这个“底层” API 的印象想掩都掩不住了，所以得靠着图形引擎才能愉快地玩耍吧。

应用开发时，首先“连上” Vulkan，得到 Vulkan Instance，然后从该 Instance 列举出硬件 GPUs。选择一个 GPU，打开为 Device，进一步获得 Device 上的 **某个类型** 的 **某个** Queue。然后就不断准备命令块（Command Buffer），丢到 Queue 中。

应用需要进行资源管理（额，比如 CPU 和 GPU 内存的分配，CPU 分配的内存资源叫 **vkCreate***，GPU 端的则叫 **vkAlloc*** ）：Pipeline，用于同步的 Event &#8230;（编不下去了，呵呵），并将操作资源的命令写到 命令块中，丢给 Queue 来处理。

一个简略的说明图如下：

![image][4]

## 说说 SPIR

IR（Intermediate Representation）可以认为是一种抽象的汇编语言。编译器将 C，C++ 不同前端编成 IR，再映射到具体到 CPU 上。对于 GPU 也是一样的。

不过 GPU 端的指令花样更多，且不像 CPU 指令这样标准化，这些差异性带来驱动开发上的工作量。所以将上层各种调用（OpenGL，Vulkan，OpenCL &#8230;）汇聚到 IR，再由驱动来映射到具体的 GPU 汇编，能复用公共部分，解放程序猿（万岁！万岁！！）。

上面这个主意，早有人想到，只是造一种合适的 IR，一直有分歧。比如 Mesa Gallium 驱动框架中，有 [TGSI IR][5]；也有人说咱能不能用 LLVM IR；最近 Intel 又在开用了 [NIR][6]。

Khronos 作为硬件厂商的联合组织，大概能标准化合适的 IR，期望能成功应用开。

## 聊聊未来的各位 U 们

异构计算的兴起，使得 CPU 独力计算的局面，变成了 CPU 带领下的计算。CPU 是 Team Leader，大堆的加工任务交给 GPU，丢个 SOP 过去，分分钟就完成了。

另外，CPU 也是有差异的，比如 big.LITTLE 大小核，还比如 它 —— 动态将 RISC 指令优化翻译成 VLIW 的 [Tegra K1（Denvor Core）][7]。它的特点是慢热型，需要一段时间的代码动态分析，生成优化的 VLIW 指令块，存到缓存中。热身完成后，再运行原代码，既快又省电。

也许将来，在普通 CPU 带领下的计算中，引入上面这样一个特殊的 CPU，让那些“长存”的程序跑在其上，至完美效率（嗯，我们的原创 idea，转述麻烦说明下）。

如下图：

![image][8]





 [1]: http://tinylab.org
 [2]: http://imgtec.com/
 [3]: http://blog.imgtec.com/powervr/trying-out-the-new-vulkan-graphics-api-on-powervr-gpus
 [4]: /wp-content/uploads/2015/03/vulkan-overview.jpg
 [5]: http://gallium.readthedocs.org/en/latest/tgsi.html
 [6]: http://www.phoronix.com/scan.php/?page=news_item&px=Intel-NIR-Default-Mesa-IR
 [7]: /nvidia黑科技-丹佛核心杀到！
 [8]: /wp-content/uploads/2015/03/idea-of-CPU-SIMD-MIMD-co-work.jpg
