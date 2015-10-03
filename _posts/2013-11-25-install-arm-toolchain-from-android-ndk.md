---
title: Install ARM toolchain from Android NDK
author: Wu Zhangjin
layout: post
permalink: /install-arm-toolchain-from-android-ndk/
tags:
  - busybox
  - Cross compiler
categories:
  - Android NDK
  - C
---

> by falcon <wuzhangjin@gmail.com> of [TinyLab.org][1]
> 2013/11/24

## Introduction

[Android NDK][2] is a toolset that allows you to implement parts of your app using native-code languages such as C and C++, itincludes a set of cross-toolchains (compilers, linkers, etc..) that can generate native ARM binaries on Linux, OS X, and Windows (with Cygwin) platforms, here shows how to export this toolchain and use it standalonely.

## Download Android NDK

At the time of this writing, the latest NDK version is r9b, download it:

    $ wget -c http://dl.google.com/android/ndk/android-ndk-r9b-linux-`uname -m`.tar.bz2

## Create Standalone Toolchain

Under android-ndk-r9b/toolchains/, all supported toolchains are listed. Here, for example, we install arm-linux-androideabi-4.7 into /opt/android-ndk-toolchain for Android 4.2.1:

    $ sudo android-ndk-r9b/build/tools/make-standalone-toolchain.sh --platform=android-17 --system=linux-`uname -m` --toolchain=arm-linux-androideabi-4.7 --install-dir=/opt/android-ndk-toolchain/
    $ sudo echo "export PATH=\$PATH:/opt/android-ndk-toolchain/bin" >> ~/.bashrc
    $ source ~/.bashrc

## Build Busybox with Android ARM Toolchain

Busybox is a very useful toolset, it includes lots of tiny Unix utilities and it's more powerful than the Android toolbox, let's compile it for Android.

    $ wget -c http://www.busybox.net/downloads/busybox-1.21.1.tar.bz2
    $ tar jxf busybox-1.21.1.tar.bz2 && cd busybox-1.21.1
    $ make android2_defconfig
    $ sed -i -e "s/CONFIG_UDHCPC=y/# CONFIG_UDHCPC is not set/g" .config
    $ make -j10
    $ file busybox
    busybox: ELF 32-bit LSB executable, ARM, version 1 (SYSV), dynamically linked (uses shared libs), stripped

The above sed command disable the udhcpc support to workaround the compiling failure. The above Busybox binary is able to be used on Android system directly, to learn more about Busybox using on Android system, the book: [Optimizing Embedded Systems using BusyBox][3] is recommended.

 [1]: http://tinylab.org
 [2]: http://developer.android.com/tools/sdk/ndk/index.html
 [3]: http://www.packtpub.com/optimizing-embedded-systems-using-busybox/book
