---
title: Android 加载不同 DPI 资源与内存消耗间的关系
author: will
layout: post
permalink: /android-loading-a-different-relationship-between-dpi-and-memory-consumption-of-resources/
tags:
  - Android
  - DPI
  - Memory
  - 内存
categories:
  - 性能优化
---

<!-- 链接：原创空间 -->

<!-- 作者：Will, wumin156@126.com -->

<!-- 时间：NULL -->

<!-- 分类：Android -->

<!-- 标签：Android,Memory,DPI -->

> by Will of [TinyLab.org][1]
> 2015/04/21


## Android DPI 分级标准简介

Android 设备在物理尺寸和屏幕密度上都有很大的不同，为了简化多设备的设计方案，就是设定一套分级标准。屏幕密度上的分级标准就是：LDPI、MDPI、HDPI、XHDPI，也就是各种大小的 DPI(Dots per inch)。**DPI 就是屏幕像素密度的衡量标准**。

## 不同设备共享同一套 DPI 资源有哪些问题？

现在进入正题。

**Q**：不少公司出于简化设计和研发的目的，往往在方案中只使用一套 DPI 资源，这样做可不可行呢？

**A**：Android 有一套加载资源的规则，如果对应的 DPI 文件夹不存在要用的资源就会按照规则去找其它的DPI 文件夹，如果最终能找到就可以使用。所以上述方案是“可行的”&#8211; 可以正常运行不报错的。那可行性的另一个方面就是对性能有没有影响。上述问题就变为下面问题：

**Q**：同一套 DPI 资源在不同手机上使用时内存消耗有什么不同？ 或 App 中加载不同 DPI 文件夹中的资源内存消耗有什么不同？

## 问题：DPI 越小的文件夹内存消耗越大？

下面以 png 图片的加载为例。

![demo pic][2]

原始图片（attribute—width:960，height:540，bit depth:32，size:217082bytes）。

做简单的 demo app，即在 activity 中只加载这一个图片。

放在 hdpi 文件夹中，dumpsys meminfo 后发现 Heap Alloc 为 5420，远远大于 size，所以先肯定的是内存消耗与图片文件大小无关。

再放到不同的 DPI 文件夹中发现：**越是 DPI 小的文件夹内存消耗越大！**

## 分析：加载低 DPI 资源会额外拉伸放大图片

由于 Heap Alloc 只能看到堆的分配总体大小，不能看到上述发现有什么“规律”，所以接着使用 MAT 分析。

在 hdpi 中抓取 hprof 文件，用 MAT 打开：

![mat][3]

见图中的 byte 数组，大小为 2073600，这个大小就是加载的那张 png 图片占用的内存大小。

分别分析图片资源放在 mdpi、ldpi 和 xhdpi 时的 hprof 文件，byte 数组大小分别为：4665600、8294400、1166400。不同 DPI 文件夹与图片占用的内存大小关系如下：

<table class="table table-bordered table-striped table-condensed">
  <tr>
    <td>
      DPIs
    </td>

    <td>
      ldpi
    </td>

    <td>
      mdpi
    </td>

    <td>
      hdpi
    </td>

    <td>
      xhdpi
    </td>
  </tr>

  <tr>
    <td>
      Byte[] size
    </td>

    <td>
      8294400
    </td>

    <td>
      4665600
    </td>

    <td>
      2073600
    </td>

    <td>
      1166400
    </td>
  </tr>

  <tr>
    <td>
      Ratio
    </td>

    <td>
      8^2
    </td>

    <td>
      6^2
    </td>

    <td>
      4^2
    </td>

    <td>
      3^2
    </td>
  </tr>
</table>

开始就说到 Android 的屏幕密度的分级标准是 LDPI、MDPI、HDPI、XHDPI 这些各种大小的 DPI。也就是 LDPI 的设备默认使用的是 ldpi 文件夹下的资源。根据 DPI 值的大小再整理一下，屏幕像素密度的值对应使用的 DPI 文件夹关系如下：

<table class="table table-bordered table-striped table-condensed">
  <tr>
    <td>
      DPIs
    </td>

    <td>
      ldpi
    </td>

    <td>
      mdpi
    </td>

    <td>
      hdpi
    </td>

    <td>
      xhdpi
    </td>
  </tr>

  <tr>
    <td>
      Density
    </td>

    <td>
      120
    </td>

    <td>
      160
    </td>

    <td>
      240
    </td>

    <td>
      320
    </td>
  </tr>

  <tr>
    <td>
      Ratio
    </td>

    <td>
      3
    </td>

    <td>
      4
    </td>

    <td>
      6
    </td>

    <td>
      8
    </td>
  </tr>
</table>

根据上面两个表格的 Ratio 值，可以发现内存占用和 DPI 资源是有一定规律的。**其实我们知道 png 加载内存的消耗与文件大小无关，而是与 png 图片的长宽和位深有关**，也就是：

<pre>Memory Consumption Size(UOM:byte) = Width * Height * (Bit depth / 8) </pre>

上面公式是不能完全在 Android 中使用的，根据上述找到的规律，Android 中 png 图片内存消耗公式可以概括为：

<pre>Memory Consumption Size(UOM:byte) = ScaledWidth * ScaledHeight * (Bit depth / 8) ScaledWidth = Width * factor
ScaledHeight = Height * factor
factor = DENSITY_DEVICE / ResourceDensity  // DENSITY_DEVICE 是设备的 DPI 大小， ResourceDensity 是设备加载的 DPI 文件夹对应的 DPI 大小
</pre>

所以：

<pre>Memory Consumption Size = Width * Height * (DENSITY_DEVICE / ResourceDensity)^2 * (Bit depth / 8) </pre>

上述 hdpi 中的 2073600 可以由此计算得出:

<pre>960 * 540 * (240 / 240)^2 * (32 / 8) = 2073600
</pre>

在 BitmapFactory.cpp 的 doDecode() 中 添加 log ，可验证上述公式(资源在 xdpi 中，sx、sy 就是上述公式中的 factor)：

<pre>01-15 21:00:49.479  3079  3079 D BitmapFactory: doDecode----sx:0.750000 ,sy:0.750000 ,scaledWidth:405 ,scaledHeight:720 ,decodingBitmap.width:540 ,decodingBitmap.heigth:960
</pre>

**Android 加载资源默认选用和设备 DPI 匹配的资源，如果没有就去到其它 DPI 文件夹中寻找资源。找到后它会认为使用了不同 DPI 的资源，为了保持与设备 DPI 一致，就会对资源做拉伸或缩放处理再加载**。下面是上述 png 图片分别放在 mdpi 和 xxhdpi 文件夹下的截图：

| ![mdpi][4] | ![xxhdpi][5] |
|:----------:|:------------:|
|    mdpi    |    xxhdpi    |

很明显就可以看到在 xxhdpi 下时的截图模糊了不少。使用的测试手机是 hdpi 的，但是默认 hdpi 找不到图片资源，它就会按照一定规则找到我放在 xxhdpi 中的资源。手机认为从 xxhdpi 获取的资源比手机的 dpi 要高，它就会按照表格中的比例把资源缩小，也就是加载到内存中的图片资源已经是原来大小的 1/2，占用的内存当然会缩小不做缩放操作图片的 1/4。但是坏处也是显而易见的，显示到手机的图片资源清晰度下降，模糊了很多。

相反的，hdpi 的手机加载低 dpi 资源，例如 ldpi，加载到内存前会先按比例拉伸。拉伸后再显示到手机中清晰度是没有问题，但是内存占用确增大为原来的 4 倍！**还是要注意到这一点，如果图片资源在 app 中放错 dpi 文件夹，使用体验会大打折扣**，或者尽量使用 9patch 图片。

## 小结：建议根据设备配置 DPI 资源

现在就可以回答提出的问题了：

**Q**：同一套 DPI 资源在不同手机上使用时内存消耗有什么不同？ 或 App 中加载不同 DPI 文件夹中的资源内存消耗有什么不同？

**A**：不要使用一套资源适用于各种不同 DPI 的设备，这样图片的清晰度和内存消耗都会有问题。这就是为什么 Android 要求对不同 DPI 文件做不同的资源，并且不同 DPI 资源的长宽比要与 DPI Ratio 相对应。

PS：此文结论一句话就能给说清楚，但推导的过程更重要。爱因斯坦说过：`Imagination is more important than knowledge`.

## 参考资料

参考的 Android 源码:

<pre>/frameworks/base/core/java/android/util/DisplayMetrics.java
/frameworks/base/graphics/java/android/graphics/Bitmap.java
/frameworks/base/graphics/java/android/graphics/drawable/BitmapDrawable.java
/frameworks/base/core/jni/android/graphics/BitmapFactory.cpp
</pre>





 [1]: http://tinylab.org
 [2]: https://wt-prj.oss.aliyuncs.com/d1b5415c872549dcb9f47d0af7295722/26d2fc94-ba91-4c55-b1c4-ce035ef7177a.png
 [3]: https://wt-prj.oss.aliyuncs.com/d1b5415c872549dcb9f47d0af7295722/3ff8480d-a250-44a0-82d9-5d3e028d4313.png
 [4]: https://wt-prj.oss.aliyuncs.com/d1b5415c872549dcb9f47d0af7295722/939c07e4-1880-49fa-aa04-cda4b0d410b4.png
 [5]: https://wt-prj.oss.aliyuncs.com/d1b5415c872549dcb9f47d0af7295722/8b2caec5-3440-4556-911c-1049b21c3168.png
