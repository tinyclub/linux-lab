---
layout: post
author: 'taotieren'
title: "ArchLinux AUR 打包实战：以 LPCScrypt 工具为例"
draft: false
license: "cc-by-nc-nd-4.0"
permalink: /archlinux-aur-packing/
description: "本文以 NXP 提供的 LPCScrypt 工具为例，详细介绍了 ArchLinux 软件打包的过程。LPCScrypt 工具用于 Linux 等系统下给 Link2 或 LPC Link2 调试器刷 CMSIS DAP 和 J Link 固件。"
category:
  - Arch Linux
  - JTAG
tags:
  - Arch Linux
  - JTAG
  - Link2
  - AUR
  - 打包
  - LPCScrypt
  - J Link
---

> By taotieren of [TinyLab.org][1]
> Jul 08, 2021

注意：以下所有命令行操作都是在 **用户模式** 下进行，需要 **root** 权限的地方会使用 `sudo` 命令。

## 背景简介

NXP 提供的 `LPCScrypt` 工具支持 Linux、macOS 和 Windows，详情阅读 [LPCScrypt][3] 上的介绍。

官网给的 Linux 版本的 `lpcscrypt-2.1.2_57.x86_64.deb.bin` 工具看名称是 Debian/Ubuntu 衍生版才能安装使用。

Arch 用户或其他 Linux 发行版用户想使用怎么办？

## 待打包软件分析

本节先分析原始包：`lpcscrypt-2.1.2_57.x86_64.deb.bin`，拆解包结构，得到核心二进制工具。

第1步，注册 NXP 官网下载相应的 Linux 版本文件，访问 NXP [LPCScrypt][3] 进行注册即可。

第2步，用文本编辑器打开查看里面的内容（内容较多，大体翻阅一下就好）：

    #!/bin/sh
    # This script was generated using Makeself 2.2.0

    umask 077

    CRCsum="4237188651"
    MD5="6c85e5870f1db1e3c66128409ecc8cb5"
    TMPROOT=${TMPDIR:=/tmp}

    label="lpcscrypt installer"
    script="./install.sh"
    scriptargs=""
    licensetxt=""
    targetdir="installer"
    filesizes="1736969"
    keep="n"
    quiet="n"

    print_cmd_arg=""
    if type printf > /dev/null; then
        print_cmd="printf"
    elif test -x /usr/ucb/echo; then
        print_cmd="/usr/ucb/echo"
    else
        print_cmd="echo"
    fi

    unset CDPATH

    MS_Printf()
    {
        $print_cmd $print_cmd_arg "$1"
    }

    MS_PrintLicense()
    {
      if test x"$licensetxt" != x; then
        echo $licensetxt
        while true
        do
          MS_Printf "Please type y to accept, n otherwise: "
          read yn
          if test x"$yn" = xn; then
            keep=n
        eval $finish; exit 1
            break;
          elif test x"$yn" = xy; then
            break;
          fi
        done
      fi
    }

    MS_diskspace()
    {
        (
        if test -d /usr/xpg4/bin; then
            PATH=/usr/xpg4/bin:$PATH
        fi
        df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
        )
    }

    MS_dd()
    {
        blocks=`expr $3 / 1024`
        bytes=`expr $3 % 1024`
        dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
        { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
          test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
    }

    MS_dd_Progress()
    {
        if test "$noprogress" = "y"; then
            MS_dd $@
            return $?
        fi
        file="$1"
        offset=$2
        length=$3
        pos=0
        bsize=4194304
        while test $bsize -gt $length; do
            bsize=`expr $bsize / 4`
        done
        blocks=`expr $length / $bsize`
        bytes=`expr $length % $bsize`
        (
            dd bs=$offset count=0 skip=1 2>/dev/null
            pos=`expr $pos \+ $bsize`
            MS_Printf "     0%% " 1>&2
            if test $blocks -gt 0; then
                while test $pos -le $length; do
                    dd bs=$bsize count=1 2>/dev/null
                    pcent=`expr $length / 100`
                    pcent=`expr $pos / $pcent`
                    if test $pcent -lt 100; then
                        MS_Printf "\b\b\b\b\b\b\b" 1>&2
                        if test $pcent -lt 10; then
                            MS_Printf "    $pcent%% " 1>&2
                        else
                            MS_Printf "   $pcent%% " 1>&2
                        fi
                    fi
                    pos=`expr $pos \+ $bsize`
                done
            fi
            if test $bytes -gt 0; then
                dd bs=$bytes count=1 2>/dev/null
            fi
            MS_Printf "\b\b\b\b\b\b\b" 1>&2
            MS_Printf " 100%%  " 1>&2
        ) < "$file"
    }

    MS_Help()
    {
        cat << EOH >&2
    Makeself version 2.2.0
     1) Getting help or info about $0 :
      $0 --help   Print this message
      $0 --info   Print embedded info : title, default target directory, embedded script ...
      $0 --lsm    Print embedded lsm entry (or no LSM)
      $0 --list   Print the list of files in the archive
      $0 --check  Checks integrity of the archive

     2) Running $0 :
      $0 [options] [--] [additional arguments to embedded script]
      with following options (in that order)
      --confirm             Ask before running embedded script
      --quiet        Do not print anything except error messages
      --noexec              Do not run embedded script
      --keep                Do not erase target directory after running
                the embedded script
      --noprogress          Do not show the progress during the decompression
      --nox11               Do not spawn an xterm
      --nochown             Do not give the extracted files to the current user
      --target dir          Extract directly to a target directory
                            directory path can be either absolute or relative
      --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
      --                    Following arguments will be passed to the embedded script
    EOH
    }

    MS_Check()
    {
        OLD_PATH="$PATH"
        PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
        MD5_ARG=""
        MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
        test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
        test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
        PATH="$OLD_PATH"

        if test "$quiet" = "n";then
            MS_Printf "Verifying archive integrity..."
        fi
        offset=`head -n 498 "$1" | wc -c | tr -d " "`
        verb=$2
        i=1
        for s in $filesizes
        do
            crc=`echo $CRCsum | cut -d" " -f$i`
            if test -x "$MD5_PATH"; then
                if test `basename $MD5_PATH` = digest; then
                    MD5_ARG="-a md5"
                fi
                md5=`echo $MD5 | cut -d" " -f$i`
                if test $md5 = "00000000000000000000000000000000"; then
                    test x$verb = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
                else
                    md5sum=`MS_dd "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
                    if test "$md5sum" != "$md5"; then
                        echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
                        exit 2
                    else
                        test x$verb = xy && MS_Printf " MD5 checksums are OK." >&2
                    fi
                    crc="0000000000"; verb=n
                fi
            fi
            if test $crc = "0000000000"; then
                test x$verb = xy && echo " $1 does not contain a CRC checksum." >&2
            else
                sum1=`MS_dd "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
                if test "$sum1" = "$crc"; then
                    test x$verb = xy && MS_Printf " CRC checksums are OK." >&2
                else
                    echo "Error in checksums: $sum1 is different from $crc" >&2
                    exit 2;
                fi
            fi
            i=`expr $i + 1`
            offset=`expr $offset + $s`
        done
        if test "$quiet" = "n";then
            echo " All good."
        fi
    }

    UnTAR()
    {
        if test "$quiet" = "n"; then
            tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
        else

            tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
        fi
    }

    finish=true
    xterm_loop=
    noprogress=n
    nox11=n
    copy=none
    ownership=y
    verbose=n

    initargs="$@"

    while true
    do
        case "$1" in
        -h | --help)
        MS_Help
        exit 0
        ;;
        -q | --quiet)
        quiet=y
        noprogress=y
        shift
        ;;
        --info)
        echo Identification: "$label"
        echo Target directory: "$targetdir"
        echo Uncompressed size: 3916 KB
        echo Compression: gzip
        echo Date of packaging: Wed Nov 25 13:12:38 CET 2020
        echo Built with Makeself version 2.2.0 on
        echo Build command was: "/usr/bin/makeself \\
        \"./installer\" \\
        \"./lpcscrypt-2.1.2_57.x86_64.deb.bin\" \\
        \"lpcscrypt installer\" \\
        \"./install.sh\""
        if test x$script != x; then
            echo Script run after extraction:
            echo "    " $script $scriptargs
        fi
        if test x"" = xcopy; then
            echo "Archive will copy itself to a temporary location"
        fi
        if test x"n" = xy; then
            echo "directory $targetdir is permanent"
        else
            echo "$targetdir will be removed after extraction"
        fi
        exit 0
        ;;
        --dumpconf)
        echo LABEL=\"$label\"
        echo SCRIPT=\"$script\"
        echo SCRIPTARGS=\"$scriptargs\"
        echo archdirname=\"installer\"
        echo KEEP=n
        echo COMPRESS=gzip
        echo filesizes=\"$filesizes\"
        echo CRCsum=\"$CRCsum\"
        echo MD5sum=\"$MD5\"
        echo OLDUSIZE=3916
        echo OLDSKIP=499
        exit 0
        ;;
        --lsm)
    cat << EOLSM
    No LSM.
    EOLSM
        exit 0
        ;;
        --list)
        echo Target directory: $targetdir
        offset=`head -n 498 "$0" | wc -c | tr -d " "`
        for s in $filesizes
        do
            MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
            offset=`expr $offset + $s`
        done
        exit 0
        ;;
        --tar)
        offset=`head -n 498 "$0" | wc -c | tr -d " "`
        arg1="$2"
        if ! shift 2; then MS_Help; exit 1; fi
        for s in $filesizes
        do
            MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - $*
            offset=`expr $offset + $s`
        done
        exit 0
        ;;
        --check)
        MS_Check "$0" y
        exit 0
        ;;
        --confirm)
        verbose=y
        shift
        ;;
        --noexec)
        script=""
        shift
        ;;
        --keep)
        keep=y
        shift
        ;;
        --target)
        keep=y
        targetdir=${2:-.}
        if ! shift 2; then MS_Help; exit 1; fi
        ;;
        --noprogress)
        noprogress=y
        shift
        ;;
        --nox11)
        nox11=y
        shift
        ;;
        --nochown)
        ownership=n
        shift
        ;;
        --xwin)
        finish="echo Press Return to close this window...; read junk"
        xterm_loop=1
        shift
        ;;
        --phase2)
        copy=phase2
        shift
        ;;
        --)
        shift
        break ;;
        -*)
        echo Unrecognized flag : "$1" >&2
        MS_Help
        exit 1
        ;;
        *)
        break ;;
        esac
    done

    if test "$quiet" = "y" -a "$verbose" = "y";then
        echo Cannot be verbose and quiet at the same time. >&2
        exit 1
    fi

    MS_PrintLicense

    case "$copy" in
    copy)
        tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
        mkdir "$tmpdir" || {
        echo "Could not create temporary directory $tmpdir" >&2
        exit 1
        }
        SCRIPT_COPY="$tmpdir/makeself"
        echo "Copying to a temporary location..." >&2
        cp "$0" "$SCRIPT_COPY"
        chmod +x "$SCRIPT_COPY"
        cd "$TMPROOT"
        exec "$SCRIPT_COPY" --phase2 -- $initargs
        ;;
    phase2)
        finish="$finish ; rm -rf `dirname $0`"
        ;;
    esac

    if test "$nox11" = "n"; then
        if tty -s; then                 # Do we have a terminal?
        :
        else
            if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
                if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                    GUESS_XTERMS="xterm rxvt dtterm eterm Eterm kvt konsole aterm"
                    for a in $GUESS_XTERMS; do
                        if type $a >/dev/null 2>&1; then
                            XTERM=$a
                            break
                        fi
                    done
                    chmod a+x $0 || echo Please add execution rights on $0
                    if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                        exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                    else
                        exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                    fi
                fi
            fi
        fi
    fi

    if test "$targetdir" = "."; then
        tmpdir="."
    else
        if test "$keep" = y; then
        if test "$quiet" = "n";then
            echo "Creating directory $targetdir" >&2
        fi
        tmpdir="$targetdir"
        dashp="-p"
        else
        tmpdir="$TMPROOT/selfgz$$$RANDOM"
        dashp=""
        fi
        mkdir $dashp $tmpdir || {
        echo 'Cannot create target directory' $tmpdir >&2
        echo 'You should try option --target dir' >&2
        eval $finish
        exit 1
        }
    fi

    location="`pwd`"
    if test x$SETUP_NOCHECK != x1; then
        MS_Check "$0"
    fi
    offset=`head -n 498 "$0" | wc -c | tr -d " "`

    if test x"$verbose" = xy; then
        MS_Printf "About to extract 3916 KB in $tmpdir ... Proceed ? [Y/n] "
        read yn
        if test x"$yn" = xn; then
            eval $finish; exit 1
        fi
    fi

    if test "$quiet" = "n";then
        MS_Printf "Uncompressing $label"
    fi
    res=3
    if test "$keep" = n; then
        trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
    fi

    leftspace=`MS_diskspace $tmpdir`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 3916; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (3916 KB)" >&2
            if test "$keep" = n; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi

    for s in $filesizes
    do
        if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; UnTAR x ) 1>/dev/null; then
            if test x"$ownership" = xy; then
                (PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
            fi
        else
            echo >&2
            echo "Unable to decompress $0" >&2
            eval $finish; exit 1
        fi
        offset=`expr $offset + $s`
    done
    if test "$quiet" = "n";then
        echo
    fi

    cd "$tmpdir"
    res=0
    if test x"$script" != x; then
        if test x"$verbose" = xy; then
            MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
            read yn
            if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
                eval $script $scriptargs $*; res=$?;
            fi
        else
            eval $script $scriptargs $*; res=$?
        fi
        if test $res -ne 0; then
            test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
        fi
    fi
    if test "$keep" = n; then
        cd $TMPROOT
        /bin/rm -rf $tmpdir
    fi
    eval $finish; exit $res
    �6J綺燧\曽炶夯E噒ww�wI    逸澮!妸€倀wùt)J妧历击9g遱嫖湙�}蛙遺褛 箈啧y�.n�/<�.聜偪=�潲雜_�/堪牥€€ 彁///� L峥囹浪勐Cp磓urp斛7唢遻��鳢o售沦櫵塔翼�+烂/n~^~庚!�0衠[:竢[Zx賑1纞=苫果{:刭{螟xxEaZF:拷肆fT辑狜鉻祦窭頲羆搛6�0+{7綆硩厳
    腆�+搪骈骀MG�=l�急l~�钷�0NNoog絾儠嶋�摰蟠眖眖觜踬9齧糪}FFV+o槑�+锟�#椃�7�纟鯙^V瀗挝�6縙u龙�开�0N;镞鴂�鹵押璱�#�'扇瘥]沖W岱o嫍F'    ＇斫~#f踣访�sp+`0N{X喁痡o沆析椬{7皐饌/拲'熳碟鮹L6^0W7o樂厯
    搪�鎛醝醔鉳汩E晴/忖紤濏_抉/_鸲珦珱鷦t0%7O豲W鲟渍E/讛霟}n�涫豿YXE/{[镞_秜s爹趼o凤弋氷_\砀竳抑頝v0N嘷灼滞邮営谄萜遮骒n�蔬輿搹嫍嬒LP標OD萀H€粟乞浊Y鼁嫕�7層�o禭6蝆6|%房浸窙纩桝侚�=€賉兰輅繊誳/��5嬁挖�齯�緋q記挲�+黭狍    瘕孆/(((�艆N侣邮^
    胱m韅崾纠掠�鰇q线齏H@圜�颊嫃�耸驼*纡吷e例飤�熜O弫 犞f唨�5缶�4I悦痜瑡��;idb�7TF�冉Xo鳫-^髫E褚癄F�!"1遀C,賭I3)y�'铻k�%躍U�kc_淓    fB堠p┭:    �4仜,雸�5_Wx噭
    �-\)z5耠�.�:jKa~)熶'Wv`轜圄^晪�'洫:蚙偵儆�WW挊莵騝壚E€�9丟7I畨C虸>E�-7
    Q綗�>h碦�t靸塡斶8~
    拰_V1鸃(|鸕|崎桴壟泳◣vf

可以看到，前半部分是 `shell` 脚本，从 `499` 行开始就是乱码了。

第 `437` 行有这个提示：

    offset=`head -n 498 "$0" | wc -c | tr -d " "`

推测 NXP 是使用 `gzexe` 进行了压缩和简单的加密处理

第3步，开始解密 lpcscrypt-2.1.2_57.x86_64.deb.bin：

    $ tail -n +499 lpcscrypt-2.1.2_57.x86_64.deb.bin > lpcscrypt-2.1.2_57.x86_64.deb

得到一个 `deb` 包（不知道是不是正常的 `deb` 包，进行下一步验证）

第4步，尝试当 deb 解压

    $ bsdtar -xf lpcscrypt-2.1.2_57.x86_64.deb

解压成功（狗头保命。如果不是 deb，可能得尝试其他格式了，这里不做进一步说明。

第5步，解压 `data.tar.gz`

    $ mkdir -p build
    $ tar -xf data.tar.gz -C build

最后，顺利得到了 NXP 的编译后的二进制文件：

    tree build
    build
    ├── lib
    │   └── udev
    │       └── rules.d
    │           └── 99-lpcscrypt.rules
    └── usr
        └── local
            └── lpcscrypt-2.1.2_57
                ├── bin
                │   ├── LPCScrypt_240.bin.hdr
                │   ├── image_manager
                │   └── lpcscrypt
                ├── docs
                │   ├── Debug_Probe_Firmware_Programming.pdf
                │   └── LPCScrypt_User_Guide.pdf
                ├── eula
                │   ├── SoftwareContentRegister.txt
                │   ├── licenses
                │   │   ├── Apache-2.0.txt
                │   │   ├── BSD-3-clause.txt
                │   │   ├── BSD-4-clause.txt
                │   │   ├── GPLV2.txt
                │   │   ├── LGPLV2.1.txt
                │   │   └── Zlib.txt
                │   ├── lpcscrypt_eula.docx
                │   ├── lpcscrypt_eula.rtf
                │   └── lpcscrypt_eula.txt
                ├── images
                │   ├── Link2_Fill_SPIFI.bin
                │   ├── Link2_Medium_SPIFI.bin
                │   ├── Link2_Small_SPIFI.bin
                │   ├── MCB1800_FillBlinky_BankA.bin
                │   ├── MCB1800_FillBlinky_BankB.bin
                │   ├── MCB1800_FillBlinky_SPIFI.bin
                │   ├── MCB1800_LargeBlinky_BankA.bin
                │   ├── MCB1800_LargeBlinky_BankB.bin
                │   ├── MCB1800_LargeBlinky_RAM.bin
                │   ├── MCB1800_LargeBlinky_SPIFI.bin
                │   ├── MCB1800_blinky_BankA.bin
                │   ├── MCB1800_blinky_BankB.bin
                │   ├── MCB1800_blinky_RAM.bin
                │   └── MCB1800_blinky_SPIFI.bin
                ├── probe_firmware
                │   ├── LPCLink2
                │   │   ├── Firmware_JLink_LPC-Link2_20190404.bin
                │   │   ├── LPC432x_CMSIS_DAP_NB_V5_224.bin.hdr
                │   │   ├── LPC432x_CMSIS_DAP_NB_V5_361.bin.hdr
                │   │   ├── LPC432x_CMSIS_DAP_SER_V5_224.bin.hdr
                │   │   ├── LPC432x_CMSIS_DAP_SER_V5_361.bin.hdr
                │   │   ├── LPC432x_CMSIS_DAP_V5_224.bin.hdr
                │   │   └── LPC432x_CMSIS_DAP_V5_361.bin.hdr
                │   └── LPCXpressoV2
                │       ├── Firmware_JLink_LPCXpressoV2_20190404.bin
                │       ├── LPC432x_IAP_CMSIS_DAP_NB_V5_224.bin
                │       ├── LPC432x_IAP_CMSIS_DAP_NB_V5_361.bin
                │       ├── LPC432x_IAP_CMSIS_DAP_SER_V5_224.bin
                │       ├── LPC432x_IAP_CMSIS_DAP_SER_V5_361.bin
                │       ├── LPC432x_IAP_CMSIS_DAP_V5_224.bin
                │       └── LPC432x_IAP_CMSIS_DAP_V5_361.bin
                └── scripts
                    ├── 99-lpcscrypt.rules
                    ├── LPCScrypt_CLI
                    ├── aeskey
                    ├── boot_lpcscrypt
                    ├── dfu_boot
                    ├── encrypt_and_program
                    ├── encrypt_and_program.scy
                    ├── install_udev_rules
                    ├── program_CMSIS
                    └── program_JLINK

    15 directories, 54 files


## 编写 `PKGBUILD` 打包脚本

接下来，按 Arch 的打包规范编写 `PKGBUILD` 打包脚本。

**注意**：需要根据 NXP 的介绍需要依赖最新版 jlink 软件包，Arch 下是 `jlink-software-and-documentation`，其他 Linux 可能在软件商店有，也可能没有，那就需要自行去 Segger 官网下载 Jlink 的软件包了。

    # Maintainer: taotieren <admin@taotieren.com>
    # Contributor:

    pkgname="lpcscrypt-bin"
    pkgver=2.1.2
    pkgrel=1
    pkgdesc="LPCScrypt is the recommended tool for programming the latest versions of CMSIS-DAP and J-Link firmware onto boards with Link2/LPC-Link2 debug probes."
    arch=("x86_64")
    makedepends=('imagemagick')
    depends=('jlink-software-and-documentation')
    optdepends=()
    conflicts=()
    url="https://www.nxp.com/design/microcontrollers-developer-resources/lpcscrypt-v2-1-2:LPCSCRYPT"
    license=('Commercial' 'Apache-2.0' 'BSD-4-clause' 'BSD-3-clause' 'LGPLV2.1' 'GPLV2' 'Zlib')
    options=(!strip)
    _pkgver_ext=${pkgver}_57
    _pkg_file_name=${pkgname%-bin}-${_pkgver_ext}.${arch}.deb.bin
    _deb_file_name=${pkgname%-bin}-${_pkgver_ext}.${arch}.deb
    _DOWNLOADS_DIR=`xdg-user-dir DOWNLOAD`
    if [ ! -f ${PWD}/${_pkg_file_name} ]; then
            if [ -f $_DOWNLOADS_DIR/${_pkg_file_name} ]; then
                    ln -sfn $_DOWNLOADS_DIR/${_pkg_file_name} ${PWD}
            else
                    msg2 ""
                    msg2 "The package can be downloaded here: "
                    msg2 "Please remember to put a downloaded package ${_pkg_file_name} into the build directory ${PWD} or $_DOWNLOADS_DIR"
                    msg2 ""
            fi
    fi

    source=("local://${_pkg_file_name}")
    sha256sums=('379c63b788a72e64571af870d760ad6b3be32e4c863d29ca58276f750e416750')
    noextract=(${_pkg_file_name})

    prepare(){
            cd "$srcdir"
        tail -n +499 ${_pkg_file_name} > ${_deb_file_name}
        mkdir -p build
        bsdtar xf ${_deb_file_name} -C build
        bsdtar xf build/${_deb_file_name} -C build
    }
    package() {
            cd "$srcdir"

            msg2 'Installing LPCScrypt'
            tar xf "build/data.tar.gz" -C "${pkgdir}/"
            mv "${pkgdir}/lib" "${pkgdir}/usr"
            msg2 'Instalation of binary file'
            install -Dm0755 /dev/stdin "${pkgdir}/usr/bin/${pkgname%-bin}" <<END
    #!/bin/sh
    /usr/local/lpcscrypt-2.1.2_57/bin/lpcscrypt "\$@"
    END

            msg2 'Instalation of license file'
            install -dm0755 "${pkgdir}/usr/share/licenses/${pkgname%-bin}/"
            cp -rv  "${pkgdir}/usr/local/lpcscrypt-2.1.2_57/eula" "${pkgdir}/usr/share/licenses/${pkgname%-bin}/"
    }

    #
    # makepkg --printsrcinfo > .SRCINFO
    #

    # vim: set ts=8 sw=8 tw=0 noet:


## 编译 `PKGBUILD` 并安装验证

如果需要更新 `PKGBUILD` 中`sha256sums` 校验值，请运行：

    $ updpkgsums

然后创建 `.SRCINFO` 文件：

    $ makepkg --printsrcinfo > .SRCINFO

接着编译 `PKGBUILD`：

    $ makepkg -sf
    ==> 正在创建软件包：lpcscrypt-bin 2.1.2-1 (2021年07月04日 星期日 14时04分10秒)
    ==> 正在检查运行时依赖关系...
    ==> 正在检查编译时依赖关系
    ==> 获取源代码...
      -> 找到 lpcscrypt-2.1.2_57.x86_64.deb.bin
    ==> 正在验证 source 文件，使用sha256sums...
        lpcscrypt-2.1.2_57.x86_64.deb.bin ... 通过
    ==> 正在释放源码...
    ==> 正在开始 prepare()...
    ==> 正在删除现存的 $pkgdir/ 目录...
    ==> 正在进入 fakeroot 环境...
    ==> 正在开始 package()...
      -> Installing LPCScrypt
      -> Instalation of binary file
      -> Instalation of license file
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/lpcscrypt_eula.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/lpcscrypt_eula.txt'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/lpcscrypt_eula.docx' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/lpcscrypt_eula.docx'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/lpcscrypt_eula.rtf' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/lpcscrypt_eula.rtf'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/licenses' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/licenses'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/licenses/Zlib.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/licenses/Zlib.txt'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/licenses/Apache-2.0.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/licenses/Apache-2.0.txt'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/licenses/GPLV2.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/licenses/GPLV2.txt'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/licenses/BSD-3-clause.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/licenses/BSD-3-clause.txt'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/licenses/BSD-4-clause.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/licenses/BSD-4-clause.txt'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/licenses/LGPLV2.1.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/licenses/LGPLV2.1.txt'
    '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/local/lpcscrypt-2.1.2_57/eula/SoftwareContentRegister.txt' -> '/home/taotieren/git_clone/aur/lpcscrypt-bin/pkg/lpcscrypt-bin/usr/share/licenses/lpcscrypt/eula/SoftwareContentRegister.txt'
    ==> 正在清理安装...
      -> 正在删除 libtool 文件...
      -> 正在清除不打算要的文件...
      -> 正在移除静态库文件...
      -> 正在压缩 man 及 info 文档...
    ==> 正在检查打包问题...
    ==> 正在构建软件包"lpcscrypt-bin"...
      -> 正在生成 .PKGINFO 文件...
      -> 正在生成 .BUILDINFO 文件...
      -> 正在生成 .MTREE 文件...
      -> 正在压缩软件包...
    ==> 正在离开 fakeroot 环境。
    ==> 完成创建：lpcscrypt-bin 2.1.2-1 (2021年07月04日 星期日 14时04分12秒)

接下来，安装 `lpcscrypt-bin 2.1.2-1.pkg.tar.zst`：

    $ sudo pacman -U lpcscrypt-bin 2.1.2-1.pkg.tar.zst
    # 或
    $ yay -U lpcscrypt-bin 2.1.2-1.pkg.tar.zst
    正在加载软件包...
    正在解析依赖关系...
    正在查找软件包冲突...

    软件包 (1) lpcscrypt-bin-2.1.2-1

    全部安装大小：  9.34 MiB

    :: 进行安装吗？ [Y/n]
    (1/1) 正在检查密钥环里的密钥                       [##########################] 100%
    (1/1) 正在检查软件包完整性                         [##########################] 100%
    (1/1) 正在加载软件包文件                           [##########################] 100%
    (1/1) 正在检查文件冲突                             [##########################] 100%
    (1/1) 正在检查可用存储空间                         [##########################] 100%
    :: 正在处理软件包的变化...
    (1/1) 正在安装 lpcscrypt-bin                       [##########################] 100%
    :: 正在运行事务后钩子函数...
    (1/3) Reloading device manager configuration...
    (2/3) Arming ConditionNeedsUpdate...
    (3/3) Refreshing PackageKit...


最后，运行并验证 `lpcscrypt`：

    $ lpcscrypt
    lpcscrypt: NXP LPC Scripting tool. v2.1.2 (Build 44) (Nov 25 2020 13:01:49)
    usage: lpcscrypt [-d serial_port] [-e dnqst] [-g usec] [-hp] [-v var=value]
    [-s script]|[-t]|[[-x] command]
    where:
             -h             display this help message
             -d serial_port use 'serial_port' (device) as target
                            use ? to list available ports
             -s script      read script from file
             -t             read script from terminal (stdin)
             -x command     execute 'command' only
                            the -s, -t and -x options and/or immediate commands
                            are mutually exclusive

             -v name=value  assign variable 'name' the value 'value'
                            Use [name] to reference the variable in the script
                            Simple text replacement is performed on each script line
             -p             pause before each script command
             -e denqst      set command echo options:
                    q - quiet  - echo nothing [default]
                    d - debug  - echo additional debug information
                    n - noisy  - echo everything
                    s - script - echo script commands
                    t - target - echo target commands
                    b - buffer - dump raw target buffer
                    e - exit   - display message on exit

    Supported high-level commands (implemented by this tool) are:
        program     program [+c|+wN] (<file>|<fill_value>) <baseAddress>
                              [<fill_length>].
                              where: +c==calculate checksum
                              +wN==width of fill_value, where N is 1, 2 or 4
                    program file or value into flash at baseAddress
        verify      verify [+c|+i|+wN] (<file>|<fill_value>) <baseAddress>
                              [<fill_length>].
                              where: +c==calculate checksum, +i==ignore checksum
                              +wN==width of fill_value, where N is 1, 2 or 4
                    verify that flash contents matches the file or value
        erase       erase <baseAddress>
                    erase flash contents
        blankCheck  blankCheck <baseAddress>
                    blankcheck
        setBoot     setBoot [BankA|BankB|0|1]
                    set the active boot flash bank
        setVidPid   setVidPid <vid> <pid>
                    program the OTP VID and PID
        echo        echo <parameters>*
                    echo all parameters to the output stream
        delay       delay <microseconds>
                    delay for number of microseconds
        pause       pause [on|off] | message
                    if on or off, switch autoPause on,
                            else display message and wait for <ENTER>.
                            (Not possible if script is from stdin)
        timer       timer <start|stop|print>
                    start/stop a timer
        var         var name=value
                    create a local variable
        <other>     Any command supported by the target
    Multiple serial ports found:
    /dev/ttyACM1
    /dev/ttyUSB0
    /dev/ttyACM0

## 发布 AUR 包

接下来把打好的软件包上传到 AUR 仓库。

首先，从 AUR 上创建一个空仓库：

    $ git clone ssh://aur@aur.archlinux.org/lpcscrypt-bin.git

添加刚才的 `PKGBUILD` `.SRCINFO` 文件到仓库中：

    $ git add PKGBUILD
    $ git add .SRCINFO
    $ cat > .gitignore << EOF
    *
    *.*
    EOF
    $ git add .gitignore -f
    $ git commit -am "Update lpcscrypt-bin"
    $ git push


发布后，就得到了 [lpcscrypt-bin AUR][3] 包。

[1]: http://tinylab.org
[2]: https://www.nxp.com/design/microcontrollers-developer-resources/lpcscrypt-v2-1-2:LPCSCRYPT
[3]: https://aur.archlinux.org/packages/lpcscrypt-bin/
