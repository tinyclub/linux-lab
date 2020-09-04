# ARCH = arm
# CROSS_COMPILE = arm-linux-gnueabi-

KERNEL_SRC ?= /lib/modules/`uname -r`/build

obj-m	+=   hello.o


modules:
	$(MAKE) -C $(KERNEL_SRC) M=$$PWD modules;

modules-install:
	$(MAKE) -C $(KERNEL_SRC) M=$$PWD modules-install;

clean:
	$(MAKE) -C $(KERNEL_SRC) M=$$PWD clean;
	rm -f *.ko;
