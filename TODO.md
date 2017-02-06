
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
13. Add user demostration with showterm.io and lxsession record
14. Add https support? or at least add ssl support for x11vnc or novnc itself.
15. Allow to set GCC version for different kernel version
16. Add more features: BFS, UKSM, KGTP, RT-preempt ...
17. Add more examples and utilities
18. Add testsuites, benchmarks and test automation support
19. Add Android emulator support?
