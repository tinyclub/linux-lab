# Copyright (C) 2023 Wu Zhangjin <falcon@ruma.tech>
_BASE   := 1
ARCH    := s390
XARCH   := s390x
CPU     ?= max,zpci=on,aen=on,ais=on
MEM     ?= 1024M
SERIAL  ?= ttyS0

QEMU    ?= v8.0.2

NETDEV_LIST ?= virtio
NETDEV  ?= virtio

VIRTIO_NET_DEVICE ?= virtio-net-pci

LINUX   ?= v6.3.6

HOST_GCC := 9

# no buildroot support for loongarch currently, use nolibc initrd by default
NOLIBC  := $(or $(NOLIBC),1)

ROOTDEV_LIST := /dev/ram0 /dev/nfs
ROOTDEV      ?= /dev/ram0

ORIIMG  ?= arch/$(ARCH)/boot/bzImage
KIMAGE  ?= $(BSP_KERNEL)/$(LINUX)/bzImage

QTOOL   ?= $(BSP_QEMU)/$(QEMU)/bin/qemu-system-$(XARCH)

CCORI   ?= mirrors.edge.kernel.org
