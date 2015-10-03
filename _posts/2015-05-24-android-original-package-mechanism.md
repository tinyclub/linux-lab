---
title: 'Android original-package 机制'
author: will
layout: post
permalink: /android-original-package-mechanism/
tags:
  - Android
  - original-package
  - PackageManagerService
categories:
  - 包管理
---

<!-- 链接：原创空间 -->

<!-- 作者：Will, wumin156@126.com -->

<!-- 时间：NULL -->

<!-- 分类：Android -->

<!-- 标签：Android,original-package,PackageManagerService -->

> by Will of [TinyLab.org][1]
> 2015/05/20


## 问题

之前项目上遇到一个问题：手机系统从版本 A 通过 FOTA 升级到版本 B 后，系统源码中的输入法（LatinIME.apk，下面称 LatinIME）不见了！也就是设置中语言和输入法选项没有 Android Keyboard 这一项，并且设置中的应用选项中也找不到。

## 问题情况

先了解了一下两个版本的情况：版本 A 是只有 LatinIME 的；版本 B 中除了 LatinIME 还新预制了 GMS 中的输入法（LatinImeGoogle.apk, 下面称 LatinImeGoogle）。升级后版本 B 的 LatinIME 输入法不见了，只剩下 LatinImeGoogle 输入法。

## 初步分析

分析的大概步骤如下：

  1. 首先确定升级后版本 LatinIME 虽然是看不见了，但 apk 包依然存在并且此情况是必现的，所以不可能是 FOTA 升级的某些意外导致的。

  2. 同时已经确定的情况：

      * 直接 download B 版本，两个 App 是同时存在的。
      * 不管是 A 版本还是 B 版本通过 adb install 或 adb push 安装两个输入法应用，两个 App 都是同时存在的。

  3. 通过 `pm list package` 命令查看

      * 版本 A 信息如下

            package:/system/app/LatinImeGoogle.apk=com.google.android.inputmethod.latin
            package:/system/app/LatinIME.apk=com.android.inputmethod.latin


      * 版本 B 的信息如下

            package:/system/app/LatinImeGoogle.apk=com.android.inputmethod.latin


        版本 B 的输入法包名是变了的，而且是变成了 LatinIME 的包名了！

  4. 反编译应用，在 LatinImeGoogle 的 manifest 文件中发现有 orignial-package 属性：

        <original-package android:name="com.android.inputmethod.latin" />


看，与步骤 3 已经联系上了。所以这个属性应该就是问题所在。

## 深入分析 original-package 作用

接下来分析 original-package 属性。

源码中搜 original-package, PackageParser.java 中的 parsePackage() 方法对属性的处理：

<pre>} else if (tagName.equals("original-package")) {
    sa = res.obtainAttributes(attrs,
        com.android.internal.R.styleable.AndroidManifestOriginalPackage);

    String orig =sa.getNonConfigurationString(
        com.android.internal.R.styleable.AndroidManifestOriginalPackage_name, 0);
    if (!pkg.packageName.equals(orig)) {
        if (pkg.mOriginalPackages == null) {
            pkg.mOriginalPackages = new ArrayList&lt;String>();
            pkg.mRealPackage = pkg.packageName;
        }
        pkg.mOriginalPackages.add(orig);
    }

    sa.recycle();

    XmlUtils.skipCurrentTag(parser);
}
</pre>

查 AndroidManifestOriginalPackage 的定义，在 attrs_manifest.xml 文件中：

<pre>&lt;!-- Private tag to declare the original package name that this package is
 based on.  Only used for packages installed in the system image.  If given, and different than the actual package name, and the given
 original package was previously installed on the device but the new one was not, then the data for the old one will be renamed to be for the new package.
 &lt;p&gt;This appears as a child tag of the root
 {@link #AndroidManifest manifest} tag. --&gt;

&lt;declare-styleable name="AndroidManifestOriginalPackage" parent="AndroidManifest"&gt;
    &lt;attr name="name" /&gt;
&lt;/declare-styleable&gt;
</pre>

官方的解释很清楚了：之前安装的应用是系统应用，并且包名不同，之前应用的数据就会以新安装应用的名字保留下来。

这已经可以解释 LatinIME 消失的原因了。但是仅仅通过这个说明是不能完全解释步骤2中的现象的.为什么 adb push 和 adb install LatinImeGoogle 后的现象是两个应用并存呢？

## 深入分析 original-package 机制

继续看源码。

上面 parsePackage() 方法中的 mOriginalPackages，查源码可知对 mOriginalPackages 的其余处理只在 PackageManagerServerice 中了。mOriginalPackages 在 PackageManagerService 中出现的次数并不多，但要搞清流程，简单有效的方法就是打 log。 打 log 这里有个小技巧。当时因为是 FOTA 升级上来的，总不可能添加一些 log 就去做一次升级抓 log 吧，很麻烦并且不能保证有用的 log 没有被冲刷掉。所以当时直接拿版本 B 的手机做 dumpsys 操作，查找有没有相关 package 信息。果然是有的：

<pre>Package warning messages:
1/1/14 12:08 AM: No settings file; creating initial state
1/1/14 12:06 AM: New package com.google.android.inputmethod.latin renamed to replace old package com.android.inputmethod.latin
1/1/14 12:47 AM: System package com.android.inputmethod.latin signature changed; retaining data.
1/1/14 12:51 AM: System package com.android.inputmethod.latin signature changed; retaining data.
</pre>

对应源码 scanPackageLI(pkg,&#8230;) 的代码：

<pre>// File a report about this.
String msg = "New package " + pkgSetting.realName
        + " renamed to replace old package " + pkgSetting.name;
reportSettingsProblem(Log.WARN, msg);
</pre>

reportSettingsProblem() 方法是既可以在 dumpsys 又可以在 logcat 中打印出来的，用此方法添加 log 发现 FOTA 升级上来走的流程是 if (pkg.mOriginalPackages.contains(renamed)) ,而 adb install 和 adb push 走的流程是它的 else 流程，是因为 renamed 为空，也就是 mSettings.mRenamedPackages 不包含 com.google.android.inputmethod.latin 。

mRenamedPackages 的值添加是在 Settings.java (/frameworks/base/services/java/com/android/server/pm/Settings.java) 中，最终处理（具体调用过程不写了）在两个地方：上面提到的 if 语句下面调用的 getPackageLPw() 方法，这个显然不是原因。另一个是在 PackageManagerService 的构造函数调用 readLPw() 方法处理。

我们知道 PackageManagerService 是 SystemServer 调用启动，SystemServer 又是 Zygote 启动，这就是原因：adb push 和 adb install 不会导致构造函数重新走一遍，所以这样安装应用 “original-package” 机制是不起作用的，FOTA 当然是会走构造函数的，所以“original-package” 机制是有效的。到此问题已经解决，更详细的内容可以查看 PackageManagerService 源码。

## 总结

Android 的 “original-package” 运行机制：

之前已安装的应用是系统应用，并且新安装的应用与之包名不同，那么定义有 original-package 属性的新应用就可以在走 PackageManagerService 构造函数的流程下（例如 FOTA 升级）实现应用替换，保持原有应用数据不变，但是以新安装应用的形式展现给用户。查看源码 /packages/apps/ 下的应用，会发现很多都有此属性，就是为了以后升级时应用数据共享。这一属性从 Android 的 Froyo 版本就有，可以看出主要是针对 Google 自己和 ROM 厂商而设置的，一般的开发者使用不到。

Android 源码中有很多这样的小设计之类的，很有意思，欢迎一起探索。





 [1]: http://tinylab.org
