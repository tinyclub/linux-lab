---
layout: post
author: 'simowce'
title: "Android 签名那些事"
draft: true
license: "cc-by-sa-4.0"
permalink: /android-signature/
description: "不涉及代码，介绍 Android 签名的那些事儿"
category:
  - Android 签名
tags:
  - 签名
  - Android
---

> By simowce of [TinyLab.org][1]
> Sep 21, 2019


作为一名 Android 系统工程师，替换系统应用是常事。但是刚入门的时候总会遇到这样的情况：把自己修改过的 app push 到手机以后发现无法运行，一问老鸟他会跟你说：你是不是下载了带签名的 ROM 了？去下个不带签名的就可以。可行自然是可行，但是终究不知其所以然，索性系统化学习了一番，总结成文，造福后人。

## 非对称加密

在了解 Android 的签名机制之前，需要了解一些基础知识。非对称加密是整个 Android 签名机制的基石，又称为公开密钥加密。它需要两个密钥，一个是所有人的都可见的，称为**公钥**；另一个是仅能自己可见的，称为**私钥**。这两个密钥的关系在维基百科中的[描述][1]是：

> **一个用于加密的时候，另一个则用于解密。使用其中一个密钥把明文加密后所得的密文，只能用相对应的另一个密钥才能解密得到原本的明文；甚至连最初用来加密的密钥也不能用作解密**。由于加密和解密需要两个不同的密钥，故被称为非对称加密。

至于公钥和私钥是如何产生，以及一个密钥加密的密文只能通过另一个密钥来解密背后的数学原理，可以参考阮一峰的科普文章：[这个][2]还有[这个][3]，这里就不详细说明。目前我们需要记住的第一个原则是：

* **原则一：**使用其中一个密钥把明文加密后所得的密文，只能用相对应的另一个密钥才能解密得到原本的明文，也就是说，用私钥加密之后的密文私钥自己都解不开。

## 签名

首先我们得理解签名的作用是什么？在很多场景里面，例如在银行办理业务，都需要我们本人的签名，作用是声明这个是我本人的行为。在加密学里面，称为**数字签名**，也是同样的道理，对一个东西进行签名，意思就是证明当你见到的这个东西跟我想要给你看的是一个东西。这样可能说可能有点虚，用一个例子来说明：

1. 我有两把钥匙，公钥和私钥。私钥我自己留着，公钥可以给任何人，例如我把公钥给了周杰伦
2. 周杰伦想要跟我进行过加密通信，他把要跟我说的话写完之后，**使用公钥进行加密**
3. 我收到加密后的内容，根据**原则一**，我可以用我的私钥去解密内容，得到原来的内容
4. 这个时候我想要回信，为了保证周杰伦看到的内容没有被修改，我决定使用**数字签名**。

这里得说明一下，数字签名是**对非对称加密的反应用**，在非对称加密的日常应用中，**公钥是用来加密，私钥是用来解密的**。而在数字签名中，是反过来的，具体流程是这样的：

 * 我写完信之后，使用一个 Hash 函数生成信件的**摘要**（注意，信件其实可以理解成一个字符串）
 * 然后我使用我的**私钥**对摘要进行加密，并且附在信件的后面
 * 当周杰伦收到我的信件之后，为了验证内容**没有被篡改**，先把附在信件后面的**加密后的摘要**取下，使用自己的公钥进行解密，得到了**信件的摘要** a。然后**使用相同的 Hash 函数**对信件进行哈希得到 b，如果 a 和 b 完全一致，那么说明信件没有被篡改，反之则反。

但是，上面的流程有一个问题就是。周杰伦手中的公钥其实不能够确定是不是我给他的。也就是说，坏人出现了。如果有坏人替换了周杰伦手中的公钥成坏人自己的公钥，那么周杰伦发出的公钥加密之后的信件坏人是可以直接使用自己私钥进行解密的。也就是说，上面的流程的关键是确认周杰伦手中的公钥是我的公钥。
 
上面的例子参考了阮一峰的一篇[博客][4]。维基百科有一张图很好地解释了数字签名里**签名**和**验签**的过程：

![数字签名][5]

因此我们得到了第二个原则：

* **原则二：**签名的作用是为了验证文件的完整性，即是否被篡改

有了上面的基础知识，就可以系统地阐述 Android 签名机制了。

## Android 签名机制

在 Android 源码库 `build/target/product/security` 下面，有这么一些文件，有的是以 `.pk8` 为后缀，有的是以 `.x509.pem` 为后缀，并且会发现 `.pk8` 和 `.x509.pem` 是一一对应的。这两种文件的关系是：`.pk8` 文件是私钥，用来对包进行签名；`.x509.pem` 文件是证书，用来验证签名。原生 Android 使用了 4 类密钥：

* testkey
* platform
* shared
* media

系统自带的应用通过在 `Android.mk` 文件中声明 `LOCAL_CERTIFICATE` 来指定用那个私钥进行签名，如果不声明那么默认使用 `testkey`。

### 简析

这里有个问题，上面说道这些 key 都是在源码中的，所有人都是可以访问的，那么这样其实是非常不安全的。任何人都可以使用这些 key 去对应用进行签名然后就可以通过系统的验证了。所以在实际的情况中，是会通过把原生的这一套 key 给替换掉。谷歌在[这里][6]提供了替换的方法。并且，在实际外发的 ROM 包中，是不会有 `testkey` 这个签名文件的，默认的变成了 `releasekey`


### 详细分析与实战

如果我们对一个 apk 文件进行解包，那么会发现里面有一个 `META-INF` 的文件夹，里面的内容根据不同的应用会有不同，但是一定会有这三个文件：`MANIFEST.MF`，`CERT.SF` 和 `CERT.RSA`。这三个文件就是 Android 签名机制的核心了。系统如何判断一个 `apk` 是不是被修改过的，就是通过这三个文件进行一系列的校验。现在我们以一个 apk 为例，简要说明这三个文件的内容和意义（**注意，有一些 APK 可能 META-INF 下面的内容可能后缀名一样，但是文件名不一样；又或者是不止这三个文件，这些都是正常现象**）。

* MANIFEST.MF

  这个文件的内容是当前 apk 里面所有文件的名字和文件的摘要值，例如在现在这个例子中，这个文件的内容大概长这样：

  ```
    Manifest-Version: 1.0
    Built-By: Generated-by-ADT
    Created-By: Android Gradle 3.0.1
    
    Name: AndroidManifest.xml
    SHA1-Digest: l5LrO+0CH4QwymZEEkgof6tKJKQ=
    
    Name: META-INF/INDEX.LIST
    SHA1-Digest: mV/vtpP5kHRZ0ZdWNzAWUorzn/M=
    
    Name: META-INF/io.netty.versions.properties
    SHA1-Digest: fHUsZp7XXjDcmXh7h88Qxku7PaQ=
    ...
  ```

  这里我们可以来实战一下，验证这里面内容的意义。以第一个 `AndroidManifest.xml` 为例，首先把这个文件提取出来，然后计算一下它的 **SHA-1** 值，在 Linux 可以这样：
  
  ```
  $ sha1sum AndroidManifest.xml 
  9792eb3bed021f8430ca66441248287fab4a24a4  AndroidManifest.xml
  ```
  咦，值好像不一样，没事，因为上面的值是经过 **Base64** 编码的，我们可以在[这里][7]进行转换：

  ![MANIFEST.MF][8]

  对比后就可以发现跟 `MANIFEST.MF` 的值是一模一样的。

* CERT.SF

  我们初看这个文件的时候，会发现它的内容跟 `MANITEST.MF` 非常的接近：
  
  ```
    Signature-Version: 1.0
    Created-By: 1.0 (Android)
    SHA1-Digest-Manifest: nezsP8TgzAKQ7BFky/chze3qmL0=
    
    Name: AndroidManifest.xml
    SHA1-Digest: mr/1kFRAFlcWQAo9hA69M29MAYs=
    
    Name: META-INF/INDEX.LIST
    SHA1-Digest: YFvH0U9NaeV1BDZUz5JkpfUm9aU=
    
    Name: META-INF/io.netty.versions.properties
    SHA1-Digest: rTBpHjFlmjueKQtX0IlpTl7X4uo=
    ...
  ```
  
  这里面分为两部分内容：`SHA1-Digest-Manifest` 和 `SHA1-Digest`，这两部分分别是这么计算的。首先这个 `SHA1-Digest-Manifest` 就是对 `MANIFEST.MF` 计算 **SHA-1** 之后再进行 **Base64** 编码：
  
  ```
  $ sha1sum META-INF/MANIFEST.MF 
  9decec3fc4e0cc0290ec1164cbf721cdedea98bd  META-INF/MANIFEST.MF
  ```
  ![CERT.MF][9]

  然后 `SHA1-Digest` 是对 `MANIFEST.MF` 里面的 **每一个 `\r\n` 分割开来的项分别进行 SHA-1 之后在进行 Bash64 编码**，例如上面的 `AndroidManifest.xml` 的 `SHA1-Digest` 是怎么算出来的呢？我们可以这么来：
 
  1. 首先把 **MANIFEST.MF** 里面这个文件的内容保存一下（**注意要自己手动增加换行**），例如咱们这里的是这个：

      > Name: AndroidManifest.xml
      > SHA1-Digest: l5LrO+0CH4QwymZEEkgof6tKJKQ=

  2. 然后如果你是在 Linux 下，使用 `unix2dos` 进行转换一下（因为 Linux 不认 "\r"）
  3. 然后计算一下 sha1：
      ```
      $ sha1sum 1
      9abff5905440165716400a3d840ebd336f4c018b  1
      ```
  4. 最后计算一下 Base64 编码就可以了

* CERT.RSA

  简单的说，这个文件是用私钥对 CERT.SF 进行签名，并且把公钥也附在这个文件里面。

### 原理解析

然后就需要说明，这种签名机制如何能够保证应用不被篡改呢？首先如果你修改了 APK 里面任何一个文件，那么相应的文件的 SHA1 摘要就会发生改变，那么就会跟 `MANIFEST.MF` 里面的值不一致；如果你不死心，修改 `MANIFEST.MF` 里面的内容，那么就会跟 `CERT.SF` 里面对应项的内容不一致；如果你还不死心，继续修改 `CERT.SF` 的内容，那么在 `CERT.RSA` 的验签那里不通过；如果依旧不死心，想要修改 `CERT.RSA` 的内容，能做到吗？不能，因为你没有私钥。从这里我们就可以看到，有了这三个文件的“保驾护航”，就可以达到一个效果就是，无论修改一个 Apk 里面的任何一个文件，都必须对其重新签名，否则会直接被系统识别出来，从而保证了安全性。 

## 尾巴

好了，Android 的签名机制也大概地说了一遍，感觉可以回答上面的问题了。每个手机公司的 ROM 肯定有两种，一种是内部版本，用的是咱们上面提到的 `build/target/product/security` 里面的 test key；另一种是外发版本，用的是 release key。所以呢，咱们自己本地调试编译的 App，在最后的签名阶段用的就是系统的 test key。那么导致的结果是，如果你用的是内部的 ROM，那么每次编译的使用用的都是系统 test key 的私钥进行签名，然后用的是 test key 的公钥进行验签，肯定能够通过。反之，如果你用的是外发的 ROM，外发的 ROM 用的是 release key，那么肯定会验签不通过，原因就是在这里啦。


  [1]: https://zh.wikipedia.org/wiki/%E5%85%AC%E5%BC%80%E5%AF%86%E9%92%A5%E5%8A%A0%E5%AF%86
  [2]: http://www.ruanyifeng.com/blog/2013/06/rsa_algorithm_part_one.html
  [3]: http://www.ruanyifeng.com/blog/2013/07/rsa_algorithm_part_two.html
  [4]: http://www.ruanyifeng.com/blog/2011/08/what_is_a_digital_signature.html
  [5]: /wp-content/uploads/2019/09/Digital_Signature_diagram_zh-CN.svg.png
  [6]: https://source.android.com/devices/tech/ota/sign_builds
  [7]: http://tomeko.net/online_tools/hex_to_base64.php?lang=en
  [8]: /wp-content/uploads/2019/09/MANIFEST_MF.png
  [9]: /wp-content/uploads/2019/09/CERT_SF.png
