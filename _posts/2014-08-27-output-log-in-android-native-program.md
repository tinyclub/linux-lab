---
title: 在 Android Native 程序中输出 LOG
author: Wen Pingbo
layout: post
permalink: /output-log-in-android-native-program/
tags:
  - Android
  - liblog
  - Log
  - logwrapper
categories:
  - Android 日志管理
---

> by WEN Pingbo of [TinyLab.org][2]
> 2014/08/27

尽管是在 Linux Kernel 层开发，但有时还是需要接触一些 Android Native 层代码，查看相关 Log。这篇文章主要是介绍 Android 下与 Log 相关工具的用法，以及在 Native 层模块里，如何去打印 Log。

## Liblog 库

Android 给 Native 层的程序提供一个 liblog 库，用来输出日志。如果程序中需要打印 Log，可以包含 cutils/log.h 这个头文件，并且定义自己的 LOG_TAG，就可以使用这个 liblog。liblog 提供了如下 Log 打印函数：

  * ALOGX
  * ALOGX_IF

其中 X 代表 Log 优先级，liblog 总共有5级，分别对应 V, D, I, W, E，具体意义如下：

  * V: Verbose, 调试时用的冗余信息，在 Release 版本中会被去掉，可以在程序中定义 LOG_NDEBUG 为0，来打开这个级别的 LOG
  * D: Debug, 调试 Log，在 Release 版本中会被保留，但可以动态关闭这个级别的 Log
  * I: Info，程序运行时的状态 Log，一般都会保留这个级别的 Log
  * W: Warning, 程序警告 Log，对调试非常有帮助，需要保留
  * E: Error, 程序错误 Log，这个级别 Log 优先级最高，出现这个 Log 意味着程序出错了

下面我们通过一个测试程序说明 liblog 的用法：

<pre>#include &lt;stdio.h>
#include &lt;cutils/log.h>
#include &lt;stdlib.h>
#include &lt;unistd.h>

#ifdef LOG_TAG
#undef LOG_TAG
#endif
#define LOG_TAG "mytest"

static bool con = true;

int main(int argc, char *argv[])
{
    printf("this is a test log using printf");

    ALOGI("This is a test log using ALOGI");
    ALOGD("This is a test log using ALOGD");
    ALOGD_IF(con, "this is a test using log ALOGD_IF");

    return 0;
}
</pre>

我们需要把这个程序编译成 Android 里的可执行文件，所以还需写一个 Android.mk:

<pre>LOCAL_PATH:= $(call my-dir)
include $(CLEAR_VARS)

LOCAL_CFLAGS += -Wall
LOCAL_LDLIBS := -L$(LOCAL_PATH)/lib -llog -g
LOCAL_C_INCLUDES := bionic
LOCAL_C_INCLUDES += $(LOCAL_PATH)/include
LOCAL_SHARED_LIBRARIES += liblog libcutils

LOCAL_SRC_FILES:= test.cpp

LOCAL_MODULE := test

include $(BUILD_EXECUTABLE)
</pre>

把这两个文件放到 Android 源码里的一个文件夹内，然后就可以通过 `mmm path/to/test` 来单独编译这个程序，最后用 `adb push` 命令把编译的测试程序复制到手机 / Android 模拟器里，这样就可以在 `adb shell` 里运行我们的程序了。

## Android Log 查看

如果直接运行，可能只能看到 printf 打印的 Log，因为使用 liblog 输出的 Log，都会放到 `/dev/log/system` 这个 BUFFER 里。我们可以通过 Android 自带的 logcat 工具去查看。

由于 Android 的庞大，单纯运行 logcat 命令后，我们会被各个模块打印的 Log 给淹没掉。所以得过滤没用的 Log。logcat 工具就是干这个的，使用格式如下：

<pre>$ adb logcat TAG1:PRIORITY TAG2:PRIORITY
</pre>

其中 TAG 就是程序中定义的 LOG_TAG，PRIORITY 就是要显示的最高 Log 级别。那么现在我们要 logcat 只显示 mytest 这个 TAG 打印的所有 Log，则可以这么写：

<pre>$ adb logcat mytest:V *:S
</pre>

后面跟的 `*:S` 就是把其他模块打印的 LOG 全部屏蔽掉。

如果需要把 printf 这样的标准打印函数也整合到 Android 日志缓存里，可以借助 logwrapper 工具。这里要注意的是所有通过 logwrapper 的日志，其 TAG 会变为程序名，而不是我们在程序里定义的 TAG。有的时候，我们需要在脚本向 Android Log 缓存中输出一些 Log，则可以借助 log 这个工具。例如：

<pre>$ log -p v -t MYTEST "this is a test"
</pre>

其中 `-p` 就是指定 Log 等级 `(v, d, i, w, e)`，`-t` 是指定该 Log 的 TAG。





 [1]: &#x6d;&#x61;&#105;&#108;&#116;&#x6f;&#x3a;&#x77;&#101;&#110;g&#x70;&#x69;&#110;&#103;&#98;&#x6f;&#x40;&#x67;&#109;&#97;i&#x6c;&#x2e;&#99;&#111;&#109;
 [2]: http://tinylab.org
