
# aarch64/virt

## Dump dtb

    $ /labs/linux-lab/boards/aarch64/virt/bsp/qemu/v4.0.0/bin/qemu-system-aarch64 -serial mon:stdio \
    -machine virt,gic_version=3 -machine type=virt,virtualization=true \
    -cpu cortex-a57 -smp 2 -m 256 -nographic \
    -machine usb=on -device nec-usb-xhci,id=xhci \
    -device usb-mouse -device usb-kbd -device sdhci-pci \
    -d guest_errors -nodefaults -no-reboot \
    -bios output/aarch64/uboot-v2019.10-virt/u-boot.bin \
    -machine dumpdtb=virt-gicv3.dtb

## Convert to dts

    $ /labs/linux-lab/tools/kernel/dtc -I dtb -O dts virt-gicv3.dtb -o virt-gicv3.dts

## Configuration

    It is based on configs/qemu_arm64_defconfig and include/configs/qemu-arm.h


## Usage

    $ make boot BOOTDEV=ram ROOTDEV=/dev/nfs
