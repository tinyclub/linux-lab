
# TODO List

## V0.9

* Add GuiLite support
* Add RISC-V board support
* Allow config board,plugin,module and mpath in .labconfig

## Future

* Add more tools support: trace-cmd, perf, memtester
* Add prebuilt toolchains with sysroot for buildroot
* Add LDT, LDD3 examples, need kernel modules support
* Add more kernel features: BFS
* Add more examples and utilities
* Add more test functions: testsuites, benchmarks and test automation
  * [use expect as interactive test automation](https://fadeevab.com/how-to-setup-qemu-output-to-console-and-automate-using-shell-script/#3inputoutputthroughanamedpipefile)
* Do we need to save/restore every checking out of source code
* Find out kernel option dependencies for non-interactive config method
* Add dhcp support
* Add elixir cli, web and vim plugin support, github.com/bootlin/elixir
* Reuse uboot and qemu source code in buildroot?
* Allow terminal users to share their own boards online
* Fix up filesystem issue while rootfs.ext2 is broken (verify and re-generate it)
* Add real hardware boards support
* Instruction encoding/decoding support should be added to easier ISA understanding: pwntools
* Modulize the core Makefile to 'APP' level, reduce coupling and increase scalability & maintainability
* More 'APP's and functions: from top to bottom
  * GUI System
  * Tools for profile, trace and debug
  * Operating Systems, include busybox, openwrt, openembedded, yocto, openEuler, UOS
  * Virtualization, Container, Hypervisor, User-Mode OS, Real Time, OP-TEE
  * Bootloaders
* Clean up the 'shortcuts' support, current support differs from system
* Use "-e TZ=Asia/Shanghai" to set time zone
* Add an interative configure script
* Rename 'APP' to 'PKG', allow to add more packages support
* Add more system, like deepin, openeuler and even rt-thread os
* Add bash complete support
* Add serial port virtualization support, ref: http://tinylab.org/serial-port-over-internet/
* Add build output support for bsp, put rootfs dir and the other new generated files of bsp to build/bsp-xxx and let bsp-clean works as-is
* Add build right deps for the different type of rootfs, which will reduce unnecessary rebuilds
* Add tag or commit based shallow fetch
  * git fetch --depth 1 origin tag tagid
* Integrate vscode support or add a standalone plugin for vscode
* Integrate filebrowser support
* Extend the feature of temp setting with low-case variable, currently, the variables LINUX, BUILDROOT use upper-case but not save
  * The variables passed with upper-case should be saved automatically
  * And the one with low-case should be temporally
* Move KCFG configuration in standalone script, not put it in makefile
  * Let `make kernel-defconfig x86_64_defconfig` work directly without the need to download the source at first
* Parse tags better for github.com, gitee.com and gitlab.com
  * curl -v "https://api.github.com/repos/tinyclub/linux-lab/tags"
  * curl -v "https://gitee.com/api/v5/repos/tinylab/linux-lab/tags"
* Colorize help output
  * https://github.com/owenthereal/ccat
