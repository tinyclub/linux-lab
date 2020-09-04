
ARCH = $(shell basename `pwd` | tr -d [0-9])
_ARCH = $(shell basename `pwd` | sed -e "s/power/p/g")
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?= $(ARCH)-linux-gnu-
QEMU_USER ?= qemu-$(_ARCH)

AS = $(CROSS_COMPILE)as -a64
LD = $(CROSS_COMPILE)ld -melf64ppc

all: $(OBJS)
	@$(QEMU_USER) $(basename $^)

%.o: %.s
	$(AS) -o $@ $<
	$(LD) -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
