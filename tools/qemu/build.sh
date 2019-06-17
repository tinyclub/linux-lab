#!/bin/bash
#
# build.sh -- build all of the supported qemu-system-$(XARCH) and $(XARCH)-linux-user
#
# Usage: build.sh VERSION QEMU_ALL
#

VERSION=$1
QEMU_ALL=$2

[ -z "$VERSION" ] && VERSION=v4.0.0
[ -z "$QEMU_ALL" ] && QEMU_ALL=1

export QEMU=$VERSION QEMU_ALL=$QEMU_ALL

# clean up at first
make qemu-clean QEMU_US=1

# Build qemu-system-$(XARCH) at first

export QEMU_US=0
make qemu-checkout
make qemu-patch
make qemu-defconfig
make qemu
make qemu-save

# clean up at first
make qemu-clean

# Build qemu-$(XARCH)

export QEMU_US=1
make qemu-checkout
make qemu-patch
make qemu-defconfig
make qemu
make qemu-save
