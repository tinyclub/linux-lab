---
title: Lua Programing on Android
author: Wu Zhangjin
layout: post
permalink: /lua-programing-on-android/
tp_language:
  - en
views:
  - 995
tags:
  - Android
  - AndroLua
  - CLE
  - Lua
  - LuaJava
  - LuaJIT
  - SL4A
categories:
  - Android
  - Lua
---

> by falcon <wuzhangjin@gmail.com> of [TinyLab.org][1]
> 2013/11/24

## Introduction

The official programming languagesof Android areJava, C and C++, but up to now, lots of other programming languages have been supported on Android, such languages includePython, Perl, JRuby, Lua, BeanShell, JavaScript, Tcl, and shell, C#.

To do Java, C and C++ programming on Android, we can simply install Android [SDK][2] and [NDK][3]and follow the documents from [Android Developer Center][4].

To programming with the otherlanguages listed above, we can try the [Scripting Layer for Android][5](SL4A) and [Common Language Extension for Android][6](CLE), to get a quick start, please read the[wiki page][7]of SL4A and an [example][8] about CLE.

Here, will not use the powerful SL4A and CLE (will talk about them in other articles), but instead, will expore some other ways to let a language work on Android, Let'suse the small [Lua][9] as our demo language.

"Lua is a powerful, fast, lightweight, embeddable scripting language."

In this article, we will using LuaJIT, AndroLua on Android to do Lua programming.

  * [LuaJIT][10] is a Just-In-Time Compiler (JIT) for the Lua programming language.
  * [AndroLua][11] is the Lua interpreter ported to the Android platform. Others have ported Lua to Android, but this project is special:

    it includes [LuaJava][12], so you can access (almost) everything the Android API provides
    because writing code on the soft keyboard can be hard, you can connect to it using TCP an upload code from your computer

## LuaJIT

###  Build LuaJIT withAndroid NDK

To share the common libraries provided by Android system, we can build LuaJIT with the [ARM Cross Compiler from Android NDK](/install-arm-toolchain-from-android-ndk/) :

    $ wget -c http://luajit.org/download/LuaJIT-2.0.1.tar.gz
    $ tar zxf LuaJIT-2.0.1.tar.gz && cd LuaJIT-2.0.1
    $ apt-get install gcc-multilib
    $ make HOST_CC="gcc -m32" CROSS=arm-linux-androideabi- TARGET_SYS=Linux
    $ adb push src/luajit /data/
    3177 KB/s (378280 bytes in 0.116s)
    $ adb shell
    root@android:/ # chmod 777 /data/luajit
    root@android:/ # /data/luajit
    LuaJIT 2.0.1 -- Copyright (C) 2005-2013 Mike Pall. http://luajit.org/
    JIT: ON ARMv7 fold cse dce fwd dse narrow loop abc sink fuse
    > for i = 1,4 do print(i) end
    1
    2
    3
    4
    >

The above LuaJIT is dynamically linked and its dynamic linker is: /system/bin/linker:

    $ file src/luajit
    src/luajit: ELF 32-bit LSB executable, ARM, version 1 (SYSV), dynamically linked (uses shared libs), stripped
    $ arm-linux-androideabi-readelf -l src/luajit | grep interpreter
          [Requesting program interpreter: /system/bin/linker]

### Build LuaJIT with Linaro ARM Cross Compiler

If no Andriod NDK installed, the Linaro ARM Cross Compiler can be used, for example, in Ubuntu system, it can be simply installed with:

    $ sudo apt-get install gcc-arm-linux-gnueabi

Since this compiler use different dynamic linker and different libraries, to compile LuaJIT for Android, static linking may be better for it avoid the installation of the dynamic linker and the shared libraries:

The using is the same, let's use the math operation as an example:

    $ adb push src/luajit /data/
    $ adb shell
    root@android:/ # /data/luajit
    LuaJIT 2.0.1 -- Copyright (C) 2005-2013 Mike Pall. http://luajit.org/
    JIT: ON ARMv7 fold cse dce fwd dse narrow loop abc sink fuse
    > print(math.sin(2.3))
    0.74570521217672
    >

### Write a Lua script

    $ cat > /tmp/test.lua
    #!/data/luajit

    print(math.sin(2.3))
    $ adb push /tmp/test.lua /data/
    $ adb shell chmod 777 /data/test.lua
    $ adb shell /data/test.lua
    0.74570521217672

## AndroLua

The above method allows us to build theLua programming environment easily but it lacks of some features provided by AndroLua:

  * It integrates the official Lua 5.1, allows to execute generic Lua scripts, have no compatiblity issues
  * It integrates the [LuaJava][13],allows scripts written in Lua to manipulate components developed in Java
  * It allows to write Lua programs on Android, excute it and check the status (Not mature enough)
  * Because writing code on the soft keyboard can be hard, you can connect to it using TCP an upload code from your computer

Now, Let's refer to the [README][14], download, build, install and useAndrodLuaon Android.

### Download AndroLua

AndrodLua is maintained under a git repository, just clone it:

    $ git clone git://github.com/mkottman/AndroLua.git && cd AndroLua

### Build AndroLua

To build AndroLua, we need to update the project with new Android version with the 'android update' command and then build a debug package with the 'ant' command. Here, we build it for Android 4.2.

    $ android list
    Available Android targets:
    ----------
    id: 1 or "android-16"
         Name: Android 4.1.2
         Type: Platform
         API level: 16
         Revision: 4
         Skins: HVGA, WVGA800 (default), WXGA800, WVGA854, WQVGA400, WXGA800-7in, WQVGA432, QVGA, WSVGA, WXGA720
         ABIs : no ABIs.
    ----------
    id: 2 or "android-17"
         Name: Android 4.2
         Type: Platform
         API level: 17
         Revision: 1
         Skins: HVGA, WVGA800 (default), WXGA800, WVGA854, WQVGA400, WXGA800-7in, WQVGA432, QVGA, WSVGA, WXGA720
         ABIs : armeabi-v7a
    Available Android Virtual Devices:
    $ android update project -p ./ -t 2

Then, install ant, and build the AndroLua package:

    $ sudo apt-get install ant
    $ ant debug

As a result, the package is compiled: bin/Main-debug.apk.

### Install AndroidLua

Now, let's install it with 'adb':

    $ adb install bin/Main-debug.apk

### Using AndroLua

After installation, the AndrodLua icon will be listed in the desktop of your Android device, start it and it will looks like:

![image](/wp-content/uploads/file/AndroLua-UI.jpg)

Write your Lua programs and execute them there.

### Remote Programming

As we can see, the AndroLua UI interface is very simple andwriting code in Android with the soft keyboard is hard, so, we can try the remote programming feature of AndrodLua, to use it, Let's forward its remote service to local:

    $ adb forward tcp:3333 tcp:3333

And then, start the local Lua intepreter with:

    $ lua ./interp.lua
    loading init.lua

    > require 'import'
    > print(Math:sin(2.3))
    >
    >
    0.74570521217672

This is also very simple.

## Summary

In this article, we have shown two methods to build the Lua programming environment for Android, accordingly, simple Lua scripts are written and executed on Android system with these environments.

As we can see, both of them are simple and only for newcomers:

  * To build a full Lua programming environment, the SL4A and CLE, or the other commercial IDEs are required, we will discuss them in the other articles.
  * But, both of themshow us the hidden details behind SL4A and CLE, based on these practical steps and the open source codes, we may be able tobuild the other native programming environments and develop similar IDEs ourselves.

For example, the book: [Optimizing Embedded Systems using Busybox][15] shows how to build native Bash and C programming environments for Android system.

 [1]: http://tinylab.org
 [2]: http://developer.android.com/sdk/index.html
 [3]: http://developer.android.com/tools/sdk/ndk/index.html
 [4]: http://developer.android.com/develop/index.html
 [5]: http://code.google.com/p/android-scripting/
 [6]: http://code.google.com/p/cle-for-android/
 [7]: http://code.google.com/p/android-scripting/wiki/TableOfContents?tm=6
 [8]: http://www.codeproject.com/Articles/375293/Writing-Android-GUI-Using-LUA-Introduction
 [9]: http://www.lua.org/
 [10]: http://luajit.org/
 [11]: https://github.com/mkottman/AndroLua
 [12]: http://www.keplerproject.org/luajava/
 [13]: http://www.keplerproject.org/luajava/index.html
 [14]: https://github.com/mkottman/AndroLua/blob/master/README.md
 [15]: http://www.packtpub.com/optimizing-embedded-systems-using-busybox/book
