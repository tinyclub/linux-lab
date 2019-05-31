
1. Add multi-archs support: ARM, MIPS, X86 and PPC
2. Add multi-versions linux support: 2.6, 3.18, 4.6 ...
3. Add multi-rootfs support: /dev/ram, /dev/nfs
4. Add multi-tools support: trace-cmd, perf, memtester ...
5. Add prebuilt toolchains with sysroot for buildroot
6. Add uboot support for more archs, currently, only ARM
7. Add Ftrace support
8. Add LDT, LDD3 examples, need kernel modules support
9. Add some patchsets, e.g: Preempt-RT, GC-sections
10. Add debug support, with CONFIG_DEBUG_INFO=y, CONFIG_DEBUG_KERNEL=y
11. Resource limitation
    * CPU, --cpuset-cpus=1 -c 512 (relative), docker run
    * MEM, -m 128M --memory-swap=128M, docker run
    * HD, /etc/default/docker: --storage-opt dm.basesize=10G
    * IO,  echo "253:1 10485760" > /sys/fs/cgroup/blkio/docker/$CONTAINER_ID/ blkio.throttle.write_bps_device
12. Make everything work with minimal root permission for specific binaries with 'sudo'+nopasswd
13. Add user demostration with showterm.io and lxsession record (showdesk.io)
14. Add https support? or at least add ssl support for x11vnc or novnc itself.
15. Allow to set GCC version for different kernel version
16. Add more features: BFS, UKSM, KGTP, RT-preempt ...
17. Add more examples and utilities
18. Add testsuites, benchmarks and test automation support
19. Add Android emulator support?
20. Add Features list and test support
21. Add Modules list and test support
22. Add rootfs and uboot test support
23. Automate everything, download sources, build and boot.
24. Boot uboot with kernel/rootfs from flash
   http://www.cnblogs.com/WuCountry/archive/2012/05/01/2477876.html
25. Load env variables from external images, allow pass arguments via a standalone image to uboot
26. Add development support
    * Allow to fetch latest source code from a customized git repository (k-d, KERNEL_GIT=https://github.com..)
    * Allow to checkout the master branch of above git repo (k-o, LINUX=master)
    * Allow to configure the board configure files (Makefile.dev?), allow to load specific Makefile.$(VERSION) in top Makefile
    * Must be compatible with current make targets and especially the 'test' target.
    * Allow run auto test simply with 'make test BOARD=csky/virt VERSION=dev'
27. Use git-am instead of patch command to apply the changes, need to convert .patch with git-am format
28. Create branch for boards to avoid override while checking out source code for boards.
29. 0day test: https://lkml.org/lkml/2017/11/21/179
30. module: need to find out module name and module config instead of module directory.
31. make a list about different boards's ROOTDEV feature
32. use expect as interactive test automation: https://fadeevab.com/how-to-setup-qemu-output-to-console-and-automate-using-shell-script/#3inputoutputthroughanamedpipefile
33. List verified rootfs devices in board specific Makefile
34. Add buildroot version in the defconfig file name, or simple add the config in Makefile.
