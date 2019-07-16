
ARCH = $(shell basename `pwd`)
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

# make toolchain CCORI=mips b=mipsel/malta
# export PATH=/labs/linux-lab/prebuilt/toolchains/mipsel/mips-img-elf/2018.09-03/bin/:$PATH
# CROSS_COMPILE ?= mips-img-elf-

CROSS_COMPILE ?= $(ARCH)-linux-gnu-
QEMU_USER ?= qemu-$(ARCH)

AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld

all: $(OBJS)
	@$(QEMU_USER) $(basename $^)

%.o: %.s
	$(AS) -mabi=32 -EL -o $@ $<
	$(LD) -m elf32ltsmip -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
