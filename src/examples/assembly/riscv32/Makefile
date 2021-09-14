# ref: https://www.sifive.com/blog/all-aboard-part-1-compiler-args

ARCH = $(shell basename `pwd`)
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?= riscv64-linux-gnu-
QEMU_USER ?= env PATH=$(QEMU_PATH):$(PATH) qemu-$(ARCH)

AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld

AFLAGS = -march=rv32imc -mabi=ilp32
LDFLAGS = -melf32lriscv_ilp32

all: $(OBJS)
	@$(QEMU_USER) $(basename $^)

%.o: %.s
	$(AS) $(AFLAGS) -o $@ $<
	$(LD) $(LDFLAGS) -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
