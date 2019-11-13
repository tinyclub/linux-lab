---
title: Linux 图形栈一览：基于 DRM 和 Wayland
author: Chen Jie
layout: post
draft: false
top: true
album:
permalink: /linux-graphics-stack-overview
tags:
  - DRM
  - Wayland
  - Compositor
  - Weston
  - Mutter
  - PipeWire
category:
  - UI
---

<!-- Linux 图形栈一览：基于 DRM 和 Wayland -->

<!-- %s/!\[image\](/&\/wp-content\/uploads\/2019\/10\// -->

> by Chen Jie of [TinyLab.org][1]
> 2019/10/07

本文图示了基于 DRM 还有 Wayland 的 Linux 图形栈。在这个图形栈中，App 将画好的 surface，通过 Wayland 协议提交给 Compositor。Compositor 将来自各个应用的 surface(s) 合成为一帧，通过 DRM 接口最终画在 Frame Buffer，如下图所示：

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/Linux-DRM-wayland-overview.png)

<center>图 1：Linux 图形栈概览：Wayland 协议, Compositor 和 DRM 子系统</center>

本文接下来自下而上，先介绍 Linux Kernel 的 DRM 子系统，而后步入 Userspace 来介绍：代入两个代表性的 GUI App，情景分析其渲染过程。

通常，GUI App 是通过图形控件库来布局和放置控件。对这类普通 GUI App 渲染过程分析，是为情景分析的第一章节。

随后分析了多媒体 App：它是进一步细分的一个情景，即 App 界面一部分内容，是多媒体。

伴随情景的细分，渲染过程会经由特定的一些软件栈，故而“花开两朵，各表一枝”。

## 背景：DRM —— buffer management、Frame Buffer / plane、Kernel Mode Setting

Linux DRM 子系统，主要提供了以下功能：

- 操作 Frame Buffer / Plane 接口
- Buffer 管理
- 模式设定（分辨率、色深、刷新率等）

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/Linux-DRM-concept.png)

<center>图 2：Linux DRM 中的概念：Frame Buffer，Plane，CRTC，Encoder 以及 Connector</center>

> 简单地理解， DRM 功能上相当于 HW Composer + gralloc，只不过 “接口” 是 Linux Kernel 导出的，而不是 HAL。
>
> 换句话说，HW Composer 和 gralloc 可以映射到 DRM 实现。事实上，一些平台的 Android BSP 正是这样做的。
>
> 下图对比了两者：
>
> ![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/Android-vs-Linux-DRM.png) 

其中 Compositor 负责将合成后的帧，写入 Frame Buffer。下面聚焦在 Compositor 及其以上。

## Linux 图形栈：一览

下图是一个 Linux 发行版图形栈的示意。其中，会话服务中：

- Mutter 是 GNOME 下的 Compositor，实现了 Wayland 协议。它主要用到了源自 Linux DRM 子系统的功能。
- 而图示中 [PipeWire](https://pipewire.org/) 出现，相当时髦。PipeWire 将替代 PulseAudio（故而用到了 Linux ALSA 子系统），但它更主要目的，是作为一个 Audio / Video IO 的守护，后文还将作进一步介绍。

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/Linux-Graphics-stack-overview.png)

<center>图 3：Linux 图形栈一览，相关的 Kernel 子系统，用户会话中的服务，以及典型应用。</center>

上图中，展示了两类典型应用，普通 GUI 应用，还有多媒体应用。下文就此分别展开描述。

### 普通 GUI App：渲染过程

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/Linux-Graphics-stack-normal-App.png)

<center>图 4：由 Graphics Widgets 所撑起的普通 GUI 应用，其工作流程</center>

在普通 GUI 应用中，界面是由 Graphics Widgets （例如 [Gtk+](https://www.gtk.org/)、[Qt](https://www.qt.io/)）布局，进而生成 Scene Graph（SG），通过遍历 SG 渲染在 surface。最后，这个 surface （或曰 buffer），提交给 Mutter 来进行合成。

这里展开两个细节，其一，遍历 SG 进行渲染时，通常是通过 [Cario](https://www.cairographics.org/) 或 [Skia](https://skia.org/) 等绘图工具：

- 绘图工具常有多实现后端。其中 GPU 加速后端，常见基于 OpenGL ES（或其后继者 Vukan，此处暂且不提）
- OpenGL ES 是个 API 的 SPEC，基于开源的 _实现方案_ 常由 Mesa 提供。相关 buffer 分配，最终落实在「通过 DRM 接口，分配 GEM Buffer Object」

> 以 intel i915 芯片为例，背后的 GEM BO 分配如下述伪调用栈所示：
>
> ```c
> /* 代码摘录 Mesa：dri2/platform_wayland.c */
> get_back_bo()
> |-> gbm_bo_create() /* Wrapper 函数，主要调用 gbm_dri_bo_create */
>     |-> intelImageExtension.createImage /* 函数指针：指向 intel_create_image() */
>         |-> drm_intel_bo_alloc_tiled()  /* libdrm */
>             |-> bo_alloc_tiled          /* 函数指针：指向 drm_intel_gem_bo_alloc_tiled */
>                 |-> drm_intel_gem_bo_alloc_internal()
>                     |-> drmIoctl(drm_fd, DRM_IOCTL_I915_GEM_CREATE, &create)
> ```



展开细节其二：App 提交 buffer 到最终显示在屏幕的过程，一喻以蔽之，可以比喻成网购：

- 在当天 _截止时间_ 之前下单的，当天发货
- 错过了，则明天发货

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/weston-howto-schedule-compositing.png)

<center>图 5：Weston 周期性更新 Frame Buffer 示意（Weston 是 Wayland Server 的参考实现）</center>

> 在一些操作系统上，例如 Fuchsia，还有一种统一渲染的思路，即 App 通过 _另一协议_，直接更新远程的 Scene Graph。
>
> 这样，最终渲染动作统一在一进程，如下图：
>
> ![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/unified-rendering.png)
>
> 相应的好处，比如有：
>
> 1. 更平滑的动画效果。动画是若干个状态间的渐变插值，由于 SG 统一在一进程，故而对其 Node(s) 进行渐变插值，效果更为平滑。
> 2. 可以将多个应用 UI 的局部，组合起来，看起来像一个应用。
>
> 统一渲染看似回归了 XServer 时代的 indirect rendering，但是围绕 SG 来展开的。从 MVC 视角来说，SG 是 View 范畴的。统一渲染将各应用 View 范畴的一部分，归总在一个进程处理。
>
> 更进一步想，可以将各应用 Model 范畴的一部分，归总在某个进程处理（例如，验证输入参数的一致性）。换言之，输入处理的一部分，统一在某处，从而平滑一部分的交互过程。对这个脑洞感兴趣的朋友，可参见本站「[量子化的 UI](/quantized-UI/)」一文。
>
> 另一方面，UI 中输入参数一致性的约束逻辑，不仅图形 UI 中用到，在[以语音等对话为主的新兴 UI](/brain-wide-open-hole-doing-a-ratio-table-screen-big-than-phone-portable-mobile-devices/#即时通讯风格的交互界面) 中，也能用到。



### 多媒体 App：渲染过程

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/Linux-Graphics-stack-multimedia.png)

<center>图 6：多媒体应用中，相关的会话服务 PipeWire、Mutter 以及各间的数据流</center>

上图中，（相机）多媒体应用从 PipeWire 获得 Camera 的输入帧，经由应用内的多媒体管线处理，最后提交到 Compositor（Mutter），显示于屏幕。

上图中的 PipeWire 作为 Audio / Video IO 守护，其主要功能有：

- Audio record / playback
  - 基于 ALSA 子系统
  - 其中 playback 包含了多个音频流的混音（Mixing）逻辑
  - 作为 PulseAudio 的替代
- Video capture：通过 V4L2 子系统，获得 Camera 的输入画面
- Screen capture：通过 Mutter 的 plugin，获得截屏
- 其他

作为 Audio / Video IO 守护，PipeWire 还可以进行：

- 策略化的访问控制
- 简化 buffer 共享，避免不必要的拷贝
- 对流经数据进行处理，特别是利用硬件（例如 DSP）进行处理
  - 处理数据的 Processing Graph 可由 Client 来构建

下图示意了 PipeWire 的内部数据流，[取自 FOSDEM 2019 上，PipeWire 作者 Wim 的幻灯](https://archive.fosdem.org/2019/schedule/event/pipewire/attachments/slides/2826/export/events/attachments/pipewire/slides/2826/PipeWire.pdf)

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/pipewire-overview.png)

<center>图 7：PipeWire 的内部数据流一览</center>



## 附录

在现代的移动设备上，通常借由 OpenGL ES（及其后继者 Vulkan，此处暂且不提）来进行图形渲染。而 OpenGL ES 和 Platform OS 上的 Window System 的交互，是通过 EGL 来隔开的。

在本文讨论的开源图形栈中 EGL 的实现：

- 对于 App：EGL 基于 Wayland （以及 libgbm）来实现接口
-  对于 Compositor，EGL 基于 DRM（以及 DRM 进一步封装，如 libgbm） 来实现接口

下表列举 OpenGL ES 和 EGL 相关的一些扩展：

| OpenGL ES 扩展                                               | 相关函数                       |
| ------------------------------------------------------------ | ------------------------------ |
| [GL_OES_EGL_image_external](https://www.khronos.org/registry/OpenGL/extensions/OES/OES_EGL_image_external.txt) | glEGLImageTargetTexture2DOES() |
| [GL_EXT_texture_format_BGRA8888](https://www.khronos.org/registry/OpenGL/extensions/EXT/EXT_texture_format_BGRA8888.txt) |                                |
| [GL_EXT_read_format_bgra](https://www.khronos.org/registry/OpenGL/extensions/EXT/EXT_read_format_bgra.txt) |                                |
| [GL_EXT_unpack_subimage](https://www.khronos.org/registry/OpenGL/extensions/EXT/EXT_unpack_subimage.txt) |                                |

| EGL 扩展                                                     | 相关函数                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
|                                                              | eglCreateImageKHR()<br/>eglDestroyImageKHR()                 |
| [EGL_WL_bind_wayland_display](https://cgit.freedesktop.org/mesa/mesa/tree/docs/specs/WL_bind_wayland_display.spec) | eglBindWaylandDisplayWL()<br/>eglUnbindWaylandDisplayWL()<br/>eglQueryWaylandBufferWL() |
| [EGL_EXT_buffer_age](https://www.khronos.org/registry/EGL/extensions/EXT/EGL_EXT_buffer_age.txt) |                                                              |
| [EGL_EXT_swap_buffers_with_damage](https://www.khronos.org/registry/EGL/extensions/EXT/EGL_EXT_swap_buffers_with_damage.txt) | eglSwapBuffersWithDamageEXT()                                |
| [EGL_EXT_image_dma_buf_import](https://www.khronos.org/registry/EGL/extensions/EXT/EGL_EXT_image_dma_buf_import.txt) |                                                              |
| [EGL_EXT_platform_base](https://www.khronos.org/registry/EGL/extensions/EXT/EGL_EXT_platform_base.txt) | eglCreatePlatformWindowSurfaceEXT()                          |

以及更底层的 Wayland、DRM 中相关特性：

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/Linux-DRM-wayland-EGL-stack.png)

下面就正文提及场景，补充一些代码级的流程示意

### Wayland Client 和 Server 如何提交 buffer?

Client 通过 `eglSwapBuffersWithDamageEXT()` 将画好的 buffer，提交给 Compositor。

Server 通过同一 API 将合成好的一帧，写入 Frame Buffer。其中，Client 和 Compositor 加载了不同的 EGL 实现，如下图所示：

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/eglSwapBuffers-weston-vs-its-client.png)

### Wayland Client 和 Server 各有哪些初始化步骤？

（同上，Wayland Server 端，以其参考实现 Weston 来说明）

- 获取 Display，初始化并进行配置

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/egl-context-init-weston-vs-its-clients-part1.png)

<br/>

- 获取 Surface，并将 Display，Surface 以及 Context 绑定在当前的渲染线程上。

![image](/wp-content/uploads/2019/10/linux-graphics-stack-overview/egl-context-init-weston-vs-its-clients-part2.png)

[1]: http://tinylab.org/
