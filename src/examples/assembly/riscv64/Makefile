# Please make sure both of toolchain and bsp/qemu are prepared at first
#
# cd /path/to/linux-lab
#
# make B=riscv64/virt
# make bsp
# make toolchain
#
# Compile options, please refer to linux-stable/arch/riscv/Makefile
#

TOP_DIR=$(shell cd $(CURDIR)/../../../ && pwd)

ARCH = $(shell basename `pwd`)
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CC_PATH=$(TOP_DIR)/prebuilt/toolchains/riscv64/gnu-mcu-eclipse/riscv-none-gcc/8.2.0-2.2-20190521-0004/bin
QEMU_PATH=$(TOP_DIR)/boards/$(ARCH)/virt/bsp/qemu/v4.0.0/bin

CROSS_COMPILE ?= env PATH=$(CC_PATH):$(PATH) riscv-none-embed-
QEMU_USER ?= env PATH=$(QEMU_PATH):$(PATH) qemu-$(ARCH)

AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
AFLAGS += -march=rv64im -mabi=lp64
LDFLAGS += -melf64lriscv

all: $(OBJS)
	@$(QEMU_USER) $(basename $^)

%.o: %.s
	$(AS) $(AFLAGS) -o $@ $<
	$(LD) $(LDFLAGS) -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
