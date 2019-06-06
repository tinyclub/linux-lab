
# Risc64 Virt Usage

Works perfectly:

    $ make boot V=1

    $ make boot SHARE=1

    $ make boot ROOTDEV=/dev/nfs

Buildroot provides rootfs config and toolchain, mainline linux provides the
official kernel config, everything goes well. Qemu v4.0.0 has the risc64 board
support.

The only difference is riscv32 requires a proxy kernel to do some prepare
before running the real linux kernel. and the proxy kernel currently is
replaced by the opensbi project.

## Notes

v5.1 kernel hangs at booting rootfs, the latest one is v5.0.13.

## References

* [Qemu RISCV Documentation](https://wiki.qemu.org/Documentation/Platforms/RISCV)
* [RISCV Software Status](https://riscv.org/software-status)
* [RV8: RISC-V simulator for x86-64 (Another simulator)](https://github.com/rv8-io/rv8)
* [RISC-V Debian](https://wiki.debian.org/RISC-V)
* [Running 64- and 32-bit RISC-V Linux on QEMU](https://risc-v-getting-started-guide.readthedocs.io/en/latest/linux-qemu.html)
* [RISC-V GNU Compiler Toolchain](https://github.com/riscv/riscv-gnu-toolchain)
* [Prebuilt GNU Toolchain](https://www.sifive.com/boards)
* [RISC-V Proxy Kernel and Boot Loader](https://github.com/riscv/riscv-pk)
* [RISC-V Open Source Supervisor Binary Interface](https://github.com/riscv/opensbi)
* buildroot/configs/qemu_riscv32_virt_defconfig
* buildroot/board/qemu/riscv32-virt/
