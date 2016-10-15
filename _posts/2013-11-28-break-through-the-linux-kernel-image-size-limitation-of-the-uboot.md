---
title: Break through Linux image size limitation of Uboot
author: Wu Zhangjin
layout: post
permalink: /break-through-the-linux-kernel-image-size-limitation-of-the-uboot/
tags:
  - kernel image size limitation
  - Linux
  - Uboot
categories:
  - C 语言
  - 系统裁剪
---

> by falcon <wuzhangjin@gmail.com> of [TinyLab.org](http://tinylab.org)
> 2013/11/28

## Background

During the booting procedure of an embedded Linux system, before decompressing the Linux kernel image, the Uboot loads the compressed Linux kernel image and Ramdisk image into two fixed contiguous memory spaces. That means, the size of the memory spacereserved for the Linux kernel image is limited by the difference between the start addresses of these two memory spaces, if the size of the compressed (anddecompressed) Linux kernel image is bigger than the size of the first reserved memory space, the ramdisk image will be overritten and result in kernel crash!

## Requirement & Issue

After the release of a product, the users maywant new functionalities, the developers may want more debug features, with the new functionalities and more debug features, the (decompressed) kernel image size may exceed the above limitation and result in system boot failure eventually.

Since Uboot has been released in the products, and there is no (easy/safe) way to update the Uboot, so, what's the solution?

## Solution

As we know, Linux has added the compressed kernel image support for most of the processors, including X86, MIPS and ARM, here uses ARM as an example.

In arch/arm/boot/compressed/misc.c, as we can see, there is a decompress_kernel() function, it calls do_decompress() to do the real decompression.

This is exactly the key to solve the above issue:

Before the calling to do_compress() function, If we hook the decompress_kernel() function, and move the ramdisk image forward and reserve more memory space for the decompressed kernel image, the isssue would be solved.

## Patch

A patch is prepared for ARM, see the patch  [ARM: compressed: Move ramdisk forward to reserve more memory for kernel image](https://patchwork.kernel.org/patch/3452931/)  posted. To enable the feature, the MOVE_RAMDISK configure option must be enabled and the MOVE_RAMDISK_OFFSET_M must be configured at least to be bigger than the decompressed kernel image: vmlinux, for example, reserve +20M for an ARM board:

    $ make menuconfig ARCH=arm
    General setup  --->
    [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support
    [*]   Move ramdisk forward to reserve more memory for kernel image
    (20)    Set the move offset of ramdisk (in Mbytes) (NEW)

## Notice

Please note, the patch is only tested for exynos boards, it may not work for the others.

If the boards don&#8217;t provide the PLAT_PHYS_OFFSET symbol, you need to define your own TAG_BASE_ADDR, otherwise, the kernel will not build. The TAG_BASE_ADDR should be defined as the tag address used by your Uboot, it is often the physical base address, please grep DDR_PHYS_BASE under your board&#8217;s header files, for example:

    $ grep DDR_PHYS_BASE -ur arch/arm/

Or, you can print the real tag base address after the following line of the setup_machine_tags() in arch/arm/kernel/atags_parse.c and then define TAG_BASE_ADDR as it.

    default_tags.mem.start = PHYS_OFFSET;
    pr_info("%s: TAG_BASE_ADDR = %lx\n", default_tags.mem.start);

This patch is still in the RFC stage, welcome your comments and patches.
