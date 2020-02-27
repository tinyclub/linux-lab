
# TODO List

## V0.4

* optimize docker image size

## Future

* Add more tools support: trace-cmd, perf, memtester
* Add prebuilt toolchains with sysroot for buildroot
* Add uboot support for more archs, currently, only ARM
* Add LDT, LDD3 examples, need kernel modules support
* Allow to customize GCC version for different kernel version, e.g. GCC[LINUX_v5.x]
* Add more kernel features: BFS, NFS
* Add more examples and utilities
* Add more test functions: testsuites, benchmarks and test automation
  * [use expect as interactive test automation](https://fadeevab.com/how-to-setup-qemu-output-to-console-and-automate-using-shell-script/#3inputoutputthroughanamedpipefile)
* Do we need to save/restore every checking out of source code
* Find out kernel option dependencies for non-interactive config method
* Add dhcp support
* Add elixir cli, web and vim plugin support, github.com/bootlin/elixir
* Reuse linux-stable, uboot and qemu source code in buildroot?
* Allow terminal users to share their own boards online
* Fix up network issue introduced by /etc/resolv.conf
* Fix up filesystem issue while rootfs.ext2 is broken (verify and re-generate it)
* Add real hardware boards support
* Upgrade docker image to ubuntu 18.04 LTS and reduce the size a lot
* Instruction encoding/decoding support should be added to easier ISA understanding: pwntools
* Only need to update source if the required version is not there (check with git show)
* Add user customize support, allow add something like boards/i386/pc/Makefile.{abc,xyz,efg}
