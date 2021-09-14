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

ARCH = $(shell basename `pwd`)
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?= riscv64-linux-gnu-
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
