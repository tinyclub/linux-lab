
# Raspi3 Usage

## Boot with graphic

  Note: login console is there, but not accept input currently.

    $ make boot V=1 G=1

## Boot with serial

  Note: earlycon works, but no initial console for command line.

    $ make boot V=1        // with 8250

    or 

    $ make boot V=1 UART=0 // with pl011


  More:

    $ make kernel ORIDTB=arch/arm64/boot/dts/broadcom/bcm2837-rpi-3-b.dtb
    $ make boot V=1 ORIDTB=arch/arm64/boot/dts/broadcom/bcm2837-rpi-3-b.dtb UART=0

## References

* [Qemu raspi3 support](https://github.com/bztsrc/qemu-raspi3)
* [Raspi3 hardware spec](https://www.raspberrypi.org/magpi/raspberry-pi-3-specs-benchmarks/)
* [Raspi3 linux kernel](https://github.com/raspberrypi/linux)
