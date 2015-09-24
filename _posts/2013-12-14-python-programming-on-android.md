---
title: Python Programming on Android
author: Wu Zhangjin
layout: post
permalink: /python-programming-on-android/
views:
  - 442
tags:
  - ADT
  - Android
  - Py4A
  - Python
  - SL4A
  - ttsSpeak
categories:
  - Android
  - Python
---

> by falcon of [TinyLab.org][2]
> 2013/12/13

## Introduction

Python is a very graceful language, do you want to use it on Android? The [SL4A][3] and [Py4A][4] projects added Python programming support for Android.

## Download SL4A and Py4A

Let's install the already compiled SL4A and Py4A from <http://code.google.com/p/android-scripting/downloads/list> and <http://code.google.com/p/python-for-android/downloads/list> respectively. In the time of this writing, the latest SL4A is [sl4a_r6.apk][5], the latest Py4A is [PythonForAndroid_r6.apk][6].

    $ mkdir ~/workspace && cd ~/workspace
    $ wget -c http://python-for-android.googlecode.com/files/PythonForAndroid_r6.apk
    $ wget -c http://android-scripting.googlecode.com/files/sl4a_r6.apk

## Install SL4A and Py4A

If you don't have any Android devices, but want to try Python programming on Android, please learn how to create a virtual Android device from [Java Programming on Android][7] and this article also shows how to prepare the Android Java programming environment, which is also required by the coming practices.

Please make sure your sdcard has at least 1G free space. For the virtual Android device, please use the AVD Manager(android avd) to set the size of the virtual SD Card to bigger than 1G.

Now, Let's install the packages.

    $ adb install ./sl4a_r6.apk
    $ adb install ./PythonForAndroid_r6.apk

We still need to download the real Python libraries, modules and samples via the just installed PythonForAndroid package, please enter into the Home screen of your Android device, find out the Python For Android icon, start it and press *Install* to download and install more required files.

## Run the samples

After installation, the samples will be downloaded to /sdcard/sl4a/scripts/:

    $ adb shell ls /sdcard/sl4a/scripts/
    bluetooth_chat.py
    hello_world.py
    notify_weather.py
    say_chat.py
    say_time.py
    say_weather.py
    speak.py
    take_picture.py
    test.py
    weather.py

To run them, you can start the sl4a application on your Android, and it will list the above scripts and select any one of them, for example: say_time.py, press the left *Terminal* button to run it, after a while, the Android system will speak and tell you current time.

If want run the python program from command line, just need to issue:

    $ adb shell
    $ am start -a com.googlecode.android_scripting.action.LAUNCH_FOREGROUND_SCRIPT -n com.googlecode.android_scripting/.activity.ScriptingLayerServiceLauncher -e com.googlecode.android_scripting.extra.SCRIPT_PATH /sdcard/sl4a/scripts/say_time.py

## Package python program to a standalone APK

If want to package python program to a standalone APK, we can use the template provided by the SL4A project, Let's clone the SL4A project at first:

    $ git clone https://github.com/damonkohler/sl4a.git

Enter into the template and you will see the Python script is stored in res/raw as a resource file.

    $ cd sl4a/android/ScriptForAndroidTemplate
    $ cat res/raw/script.py
    import android,time
    droid = android.Android()
    droid.makeToast('Hello, Android!')
    droid.vibrate(300)

    try:
      droid.startSensing()
      time.sleep(1)
      e=droid.eventPoll(1)
      droid.eventClearBuffer()
      droid.makeToast("Polled: "+str(e))
    except:
      droid.makeToast("Unexpected error:"+str(sys.exc_info()[0]))

    droid.makeToast("Done")

And this resource is parsed in Script.java:

    $ grep R.raw.script -ur src/com/dummy/fooforandroid/Script.java
      public final static int ID = R.raw.script;

Now, Let's package it to a normal Android application.

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
    $ rm build.xml
    $ android project update -p ./ -t 1 -s
    $ ant debug
    $ ls bin/ScriptActivity-debug.apk

Now, we can install it and run it as the other Android Applications.

In a clean Android system, when running the above application, it will guide you to download SL4A and Py4A at first, after downloading SL4A and Py4A, it will run like a usual Android Java Application.

If want to package your own Python script, please replace the res/raw/script.py with your own, Let's try one:

    $ cat > res/raw/script.py
    import android
    droid=android.Android()

    droid.ttsSpeak('Android and Python, I love you!')
    $ ant debug
    $ adb install -r bin/ScriptActivity-debug.apk

It will save love to Android and Python!!

## Conclusion

It is really awesome to run Python on Android, thanks to both SL4A and Py4A projects.

To learn more about Python programming on Android, please read the resources from [the wiki page of SL4A][8].

 [2]: http://tinylab.org
 [3]: http://code.google.com/p/android-scripting/
 [4]: http://code.google.com/p/python-for-android/
 [5]: http://android-scripting.googlecode.com/files/sl4a_r6.apk
 [6]: http://python-for-android.googlecode.com/files/PythonForAndroid_r6.apk
 [7]: /java-programming-on-android/
 [8]: http://code.google.com/p/android-scripting/wiki/TableOfContents?tm=6
