#
# Core Makefile
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

# Init all
include core/init/global
include core/init/generic

# Check running host
include core/env/init

# Board init
include core/board/init

# app targets init
include core/app/config

# Core variables and functions
include core/libs/global
include core/libs/generic

# Verify arguments
include core/verify/generic

# Board targets
include core/board/config

# Build bsp targets
include core/bsp/config

# Qemu targets
include core/qemu/config

# Linux Kernel and module targets
include core/kernel/config

# Root targets
include core/root/config

# Uboot targets
include core/uboot/config

# Boot, test and debug targets
include core/boot/config

# Toolchains targets
include core/toolchain/config

# Env targets
include core/env/config

# Fini support
include core/fini/config

PHONY += FORCE

FORCE:

.PHONY: $(PHONY)
