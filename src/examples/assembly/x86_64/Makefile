
TOP_DIR = $(CURDIR)
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?=

AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld

all: $(OBJS)
	$(TOP_DIR)/$(basename $^)

%.o: %.s
	$(AS) -o $@ $<
	$(LD) -o $(basename $@) $@

clean: $(OBJS)
	rm -rf *.o $(basename $^)
