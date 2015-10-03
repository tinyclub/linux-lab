---
title: C Programming on Android
author: Wu Zhangjin
layout: post
permalink: /c-programming-on-android/
tp_language:
  - en
tags:
  - Android
  - c
  - JNI
  - NDK
categories:
  - C
  - Android NDK
---

> by falcon of [TinyLab.org][2]
> 2013/12/13

## Background

There are lots of powerful C/C++ applications in the FLOSS world, it is invaluable if we can reuse them in Android system.

We have introduced the installation of Android NDK in [Install ARM Toolchain from Android NDK][3] and we have shown how to cross compile a C program with its cross toolchain.

The cross compiled executable can be run through

    $ adb shell

command, but it is not convenient for users for they often have no USB connected and even don't know what adb is! so, a better method should be: package the program into an APK file and allow users to install it and run it through a generic Android application.

There are two ways to package a C program into an APK:

  * Package a standalone C executable into the APK, install it on a directory of the Android device(E.g. /data/) and execute this executable from the Java program
  * Call the 'main' entry of the C program from Java with the *JNI* support.

The basic principle of the first way is: If put an executable in the assets/ directory of the application source code, the executable will be packaged into the APK and decompressed into data/data/PACKAGE_NAME/ while installation, please read: [Android: Package executable and call it in APK][4], of course, the executable can also be downloaded, see: [Run native executable in Android App][5].

And as we know, Java is the mother language of Android, to call functions of the native C programs from Java, *JNI*: [Java Native Interface][6] must be applied, to simplify C programming with JNI, [Android NDK][7] and [some samples][8] are provided by Google, Let's use hell-jni as our example.

## Prepare ndk-build

ndk-build is a tool provided by Android NDK, which simplifies the whole building of the C programs wrapped with JNI symbols.

Let's download Android NDK, decompress it and set the PATH variable for the ndk-build tool, here my desktop system is Ubuntu.

    $ mkdir ~/workspace && cd ~/workspace/
    $ wget -c http://dl.google.com/android/ndk/android-ndk-r9b-linux-`uname -m`.tar.bz2
    $ tar jxf android-ndk-r9b-linux-`uname -m`.tar.bz2
    $ echo "export PATH=\$PATH:~/workspace/android-ndk-r9b" >> ~/.bashrc
    $ source ~/.bashrc

## Update the project: hello-jni

    $ cd android-ndk-r9b/samples/hello-jni
    $ android update project -p ./ -s

## Build native code into shared libraries

The native C code and the related Makefile are put in jni/, let's use ndk-build to build the C code and generate a shared library.

    $ ls jni/
    Android.mk  hello-jni.c
    $ cat jni/hello-jni.c
    cat jni/hello-jni.c  | tail -6
    jstring
    Java_com_example_hellojni_HelloJni_stringFromJNI( JNIEnv* env,
                                                      jobject thiz )
    {
        return (*env)->NewStringUTF(env, "Hello from JNI !");
    }
    $ ndk-build
    [armeabi] Gdbserver      : [arm-linux-androideabi-4.6] libs/armeabi/gdbserver
    [armeabi] Gdbsetup       : libs/armeabi/gdb.setup
    [armeabi] Install        : libhello-jni.so => libs/armeabi/libhello-jni.so

## Build and install a normal Android application

The C function: stringFromJNI() is called from the onCreate() function of src/com/example/hellojni/HelloJni.java:

    $ cat src/com/example/hellojni/HelloJni.java | grep -A 10 -B 4 onCreate
    public class HelloJni extends Activity
    {
        /** Called when the activity is first created. */
        @Override
        public void onCreate(Bundle savedInstanceState)
        {
            super.onCreate(savedInstanceState);

            /* Create a TextView and set its content.
             * the text is retrieved by calling a native
             * function.
             */
            TextView  tv = new TextView(this);
            tv.setText( stringFromJNI() );
            setContentView(tv);
        }

Before start the building, please make sure both [Android SDK][9] and [Oracle JDK6][10] are installed, if not, please refer to [Java Programming on Android][11] and install them.

Let's build the Android application:

    $ ant debug
    $ ant install bin/HelloJni-debug.apk

## Conclusion

After installation, it should be able to print 'Hello from JNI!'.

To do more complicated work, please learn the other [samples][8] and the [JNI tips][12].

If want to call existing C executables or not want to add extra our jni/ codes, the way of calling the executables directly from Java code is more convenient.

 [2]: tinylab.org
 [3]: /install-arm-toolchain-from-android-ndk/
 [4]: http://www.myexception.cn/android/1439932.html
 [5]: http://gimite.net/en/index.php?Run%20native%20executable%20in%20Android%20App
 [6]: http://docs.oracle.com/javase/6/docs/technotes/guides/jni/spec/jniTOC.html
 [7]: http://developer.android.com/tools/sdk/ndk/index.html
 [8]: http://developer.android.com/tools/sdk/ndk/index.html#Samples
 [9]: http://developer.android.com/sdk/index.html
 [10]: http://linuxg.net/how-to-install-oracle-java-jdk-678-on-ubuntu-13-04-12-10-12-04/
 [11]: /java-programming-on-android/
 [12]: http://developer.android.com/training/articles/perf-jni.html
