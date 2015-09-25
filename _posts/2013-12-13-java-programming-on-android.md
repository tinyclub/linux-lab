---
title: Java Programming on Android
author: Wu Zhangjin
layout: post
permalink: /java-programming-on-android/
tags:
  - ADT
  - Android
  - ant
  - 程序设计
  - Java
  - JDK
  - SDK
  - 开发环境
categories:
  - Android
  - Java
---

> by falcon of [TinyLab.org][2]
> 2013/12/13

### Introduction

Java is the mother language of Android, to simplify its programming, Google developed the [Android ADT][3]. It not only includes Android SDK, which provides you the API libraries and developer tools necessary to build, test, and debug apps for Android, but also a version of the Eclipse IDE with built-in [ADT][4] Plugin (Android Developer Tools) to streamline your Android app development.

In this article, we use Ubuntu as our desktop development system, and we will install Android ADT, Oracle JDK 6, and a Java based tool: ant, and then build our first Android application, install and run it on a virtual Android device created by Android emulator.

Here, We use Android 4.4 version for demonstration.

### Download & Install Android ADT

At the time of this writing, the latest version is 20140702, if it doesn't exist, please get it from the [sdk download page][4].

    $ version=20140702
    $ mkdir ~/workspace && cd ~/workspace
    $ wget -c http://dl.google.com/android/adt/adt-bundle-linux-`uname -p`-$version.zip
    $ unzip adt-bundle-linux-`uname -p`-$version.zip
    $ mv adt-bundle-linux-`uname -p`-$version adt-bundle-linux
    $ echo "export PATH=\$PATH:~/workspace/adt-bundle-linux/eclipse" >> ~/.bashrc
    $ echo "export PATH=\$PATH:~/workspace/adt-bundle-linux/sdk/tools" >> ~/.bashrc
    $ echo "export PATH=\$PATH:~/workspace/adt-bundle-linux/sdk/platform-tools" >> ~/.bashrc
    $ echo "export PATH=\$PATH:~/workspace/adt-bundle-linux/sdk/build-tools/android-4.4" >> ~/.bashrc
    $ source ~/.bashrc

After installation, we should be able to use the tools like android, adb, emulator and eclipse.

### Install Oracle JDK 6

Oracle JDK 6 is preferable for the recent Android versions, but it is not available in recent official Ubuntu repositories due to some license issues, to install it, must get one from official Oracle web site or install one from the webupd8team PPA.

  * Remove the default openjdk

        $ sudo apt-get purge openjdk*

  * Install a package to silence the issues related to the add-apt-repository command

        $ sudo apt-get install software-properties-common

  * Add the PPA

        $ sudo add-apt-repository ppa:webupd8team/java

  * Update the repo index

        $ sudo apt-get update

  * Install JDK 6

        $ sudo apt-get install oracle-java6-installer

  * Configure environment variables

  Here configures JAVA_HOME, PATH and CLASSPATH.

        $ echo "export JAVA_HOME=/usr/lib/jvm/java-6-oracle/" >> ~/.bashrc
        $ echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
        $ echo "export CLASSPATH=\$CLASSPATH:.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> ~/.bashrc
        $ source ~/.bashrc

### Install Java make tool: ant

*ant* is a Java based make tool, to build Android application with build.xml, it must be installed at first.

    $ sudo apt-get install ant

### Download samples

To help developers understand some fundamental Android APIs and coding practices, a variety of sample code is available from Android SDK, it can be downloaded by the Android SDK Manager, issue the android command to launch it:

    $ android

Afterwards, select Android 4.4 (API 19) and its "Samples for SDK", and then, press 'Install n packages&#8230;' button, accept the licenses and press 'Install' to continue.

The samples would be downloaded to samples/android-19/ of the sdk directory.

    $ cd ~/workspace/adt-bundle-linux/sdk/samples/android-19/
    $ ls
    connectivity         input   NOTICE.txt     testing
    content          legacy  security       ui
    content_hash.properties  media   source.properties

**Note**: If failed to download the samples for 'connection refused', 'Interrupted', 'Timed out' blabla, please append the following mapping into your /etc/hosts and force using http instead of https in SDK Manager --> Tools, or please make sure your target directory is owned by you, read [more&#8230;][5]. I must tell you, the G\_F\_W is really STUPID!!!!

    203.208.46.146 dl.google.com
    203.208.46.146 dl-ssl.google.com

### Build one sample

To build an existing Android project, we can use the just installed eclipse IDE with the builtin ADT plugin, since it is a very popular IDE, we will not introduce it, but instead, we will show the command line method:

We randomly select the sample: legacy/Snake/

    $ cd legacy/Snake/

List the available Android APIs:

    $ android list targets
    Available Android targets:
    ----------
    id: 1 or "android-19"
         Name: Android 4.4
         Type: Platform
         API level: 19
         Revision: 1
         Skins: HVGA, WVGA800 (default), WXGA800, WVGA854, WQVGA400, WXGA800-7in, WQVGA432, QVGA, WSVGA, WXGA720
         ABIs : armeabi-v7a

Update current project to the target API id: 1:

    $ android update project -p ./ -t 1 -s

And build it:

    $ ant debug

### Create a virtual Android device: tinybox

To create a Android Virtual Device(AVD), we can use command line:

    $ android create avd -n tinybox -t 1
    Auto-selecting single ABI armeabi-v7a
    Android 4.4 is a basic Android platform.
    Do you wish to create a custom hardware profile [no]
    Created AVD 'tinybox' based on Android 4.4, ARM (armeabi-v7a) processor,
    with the following hardware config:
    hw.lcd.density=240
    vm.heapSize=48
    hw.ramSize=512

To configure more options, we can use the Android Virtual Device Manager:

    $ android avd

To create one AVD, press the 'New' button, configure everything you want, or update one AVD, choose the just created: tinybox AVD, press the 'Edit' button to update some configurations.

To start the AVD, we can also the above AVD Manager, choose the just created AVD: tinybox, press 'Start', enable 'Scale the display to real size' and 'Launch' it.

Or we can simply launch it with the command line:

    $ emulator @tinybox

### Install and run your first Android APP

    $ adb install bin/Snake-debug.apk

### Conclusion

In this article, we have learned the basic procedure of Android Java Programming, to learn more, please learn more samples, read the [Build Your First App][6] tutorial and get more from <http://developer.android.com>.

 [2]: http://tinylab.org
 [3]: https://developer.android.com/sdk/index.html
 [4]: https://developer.android.com/tools/sdk/eclipse-adt.html
 [5]: http://code.google.com/p/android/issues/detail?id=21359
 [6]: http://developer.android.com/training/basics/firstapp/index.html
