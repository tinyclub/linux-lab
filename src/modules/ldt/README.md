# LDT - Linux Driver Template

LDT project is useful for Linux driver development beginners and as starting point for a new drivers. 
The driver uses following Linux facilities: 
module, platform driver, file operations (read/write, mmap, ioctl, blocking and nonblocking mode, polling), kfifo, completion, interrupt, tasklet, work, kthread, timer, simple misc device, multiple char devices, Device Model, configfs, UART 0x3f8, HW loopback, SW loopback, ftracer.

## Usage:

Just run

git clone git://github.com/makelinux/ldt.git && cd ldt && make && ./ldt-test && sudo ./misc_loop_drv_test

and explore sources.

## Files:

Main source file of LDT:
**[ldt.c](https://github.com/makelinux/ldt/blob/master/ldt.c)**

Test script, run it: **[ldt-test](https://github.com/makelinux/ldt/blob/master/ldt-test)**

Generic testing utility for Device I/O: **[dio.c](https://github.com/makelinux/ldt/blob/master/dio.c)**

Simple misc driver with read, write, fifo, tasklet and IRQ:
**[misc_loop_drv.c](https://github.com/makelinux/ldt/blob/master/misc_loop_drv.c)**

Browse the rest of source: https://github.com/makelinux/ldt/


## Compiled and tested on Linux versions:

3.19.0-33-generic (Ubuntu 15.04)

v3.18-rc1

3.13.0-37-generic (Ubuntu 14.04.1 LTS)

v3.6-rc5

3.2.0-30-generic-pae (Ubuntu 12.04 LTS)

2.6.38-11-generic (Ubuntu 11.04)

v2.6.37-rc8

v2.6.36-rc8

### Failed compilation with:

v2.6.35-rc6 failed because of DEFINE_FIFO
