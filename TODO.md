
# TODO List

## V0.2

* Add loongson support
* Upgrade to Linux v5.2
* Add official RT feature support
* Add board specific linux repo support
  * Use patch/linux/linux-xxx.git, update tools/kernel/patch.sh
  * Use board specific linux submodule (in bsp/), customize KERNEL_SRC, update kernel-source
* Replace submodules with regular git repo for easier customization
* Upgrade docker image to ubuntu 18.04 LTS and reduce the size a lot
* Merge buildroot to external toolchain, do we need to share CCTYPE and CCORI?

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
* Update coreutils to add realpath for latest v5.2
* Add gdb-multiarch in docker image
* Add elixir cli, web and vim plugin support, github.com/bootlin/elixir
* Autoload host kernel modules, use /etc/modules-load.d/ for linux and learn how for win and mac
* Instruction encoding/decoding support should be added to easier ISA understanding: utds3lab/multiverse, unicorn
* Reuse linux-stable, uboot and qemu source code in buildroot?
