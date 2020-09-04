
ARCH = $(shell basename `pwd`)
_ARCH = $(shell basename `pwd` | sed -e "s/power/p/g")
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?= $(ARCH)-linux-gnu-
QEMU_USER ?= qemu-$(_ARCH)

AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld

all: $(OBJS)
	@$(QEMU_USER) $(basename $^)

%.o: %.s
	$(AS) -o $@ $<
	$(LD) -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
