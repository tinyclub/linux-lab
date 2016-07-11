
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?=

AS = $(CROSS_COMPILE)as --32
LD = $(CROSS_COMPILE)ld -m elf_i386

all: $(OBJS)

%.o: %.s
	$(AS) -o $@ $<
	$(LD) -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
