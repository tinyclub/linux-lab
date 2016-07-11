
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?= powerpc-linux-gnu-

AS = $(CROSS_COMPILE)as -a64
LD = $(CROSS_COMPILE)ld -melf64ppc

all: $(OBJS)

%.o: %.s
	$(AS) -o $@ $<
	$(LD) -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
