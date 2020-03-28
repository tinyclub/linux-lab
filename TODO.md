
# TODO List

## V0.4

* Add uboot support for more archs (aarch64/virt)

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
* Upgrade docker image to ubuntu 18.04 LTS and reduce the size a lot
