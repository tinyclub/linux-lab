#ccflags-y+=-Wfatal-errors
ccflags-y+=-DDEBUG
ccflags-y+=-DUSE_PLATFORM_DEVICE
ccflags-y+=-fmax-errors=5
#ccflags-y+=-DCTRACER_ON -include $M/ctracer.h
#ccflags-y+=-D USE_MISCDEV # uncomment to use single misc device instead char devices region

#obj-m+= misc_loop_drv.o
obj-m+= ldt.o
#obj-m+= ldt_plat_drv.o # implements platform_driver only
#obj-m+= ldt_plat_dev.o # implements platform_device and resource
#obj-m+= chrdev_region_sample.o
#obj-m+= ldt_configfs_basic.o
obj-m+= kthread_sample.o

KERNELDIR ?= /lib/modules/$(shell uname -r)/build

all:	modules dio

modules:
	$(MAKE) -C $(KERNELDIR) M=$$PWD modules

modules_install:
	$(MAKE) -C $(KERNELDIR) M=$$PWD modules_install

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions modules.order Module.symvers dio *.tmp *.log

dio: CPPFLAGS+= -DCTRACER_ON -include ctracer.h -g
#dio: CPPFLAGS+= -D VERBOSE

#_src = dio.c  ldt.c  ldt_plat_dev.c  ldt_plat_drv.c ctracer.h ldt_configfs_basic.c ctracer.h tracing.h
_src = dio.c  ldt.c  ldt_plat_dev.c  ldt_plat_drv.c ctracer.h ldt_configfs_basic.c misc_loop_drv.c

checkpatch:
	checkpatch.pl --no-tree --show-types --ignore LINE_CONTINUATIONS --terse -f $(_src) Makefile

checkpatch2:
	checkpatch.pl --no-tree --show-types --ignore LONG_LINE,LINE_CONTINUATIONS --terse -f $(_src) Makefile
