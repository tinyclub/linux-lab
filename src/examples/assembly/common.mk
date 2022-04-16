ARCH = $(shell basename `pwd`)
ASMS = $(wildcard *.s)
OBJS = $(ASMS:.s=.o)

CROSS_COMPILE ?= $(or $(CARCH),$(ARCH))-linux-gnu$(EABI)-
QEMU_USER ?= env PATH=$(QEMU_PATH):$(PATH) qemu-$(or $(QARCH),$(ARCH))

AS := $(CROSS_COMPILE)as
LD := $(CROSS_COMPILE)ld

AFLAGS  ?= $(strip $(if $(MARCH),-march=$(MARCH)) $(or $(ABI),$(if $(MABI),-mabi=$(MABI))))
LDFLAGS ?= $(if $(OFORMAT),-m$(OFORMAT))

ifeq ($(DEBUG)$(D),1)
  AFLAGS    += -g
  LDFLAGS   += -g
  QEMU_USER += -g 1234 -singlestep
  QEMU_BACK := &
  GDBINIT   := $(if $(AUTO)$(A),gdbinit.auto,gdbinit)
  GDB_ARCH  ?= gdb-multiarch -q -x ../$(GDBINIT)
endif

all: $(OBJS)
	@$(QEMU_USER) $(basename $^) $(QEMU_BACK)
	@if [ -n "$(GDB_ARCH)" ]; then $(GDB_ARCH) $(basename $^); fi

%.o: %.s
	$(AS) $(AFLAGS) -o $@ $<
	$(LD) $(LDFLAGS) -o $(basename $@) $@

clean:
	rm -rf *.o $(basename $(OBJS))
