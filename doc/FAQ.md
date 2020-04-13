
# FAQ for developers

## buildroot

### libfakeroot error

    $ rm -rf output/aarch64/buildroot-cortex-a57/build/_fakeroot.fs
    $ rm -rf output/aarch64/buildroot-cortex-a57/build/host-fakeroot-1.20.2/
    $ rm -rf output/aarch64/buildroot-cortex-a57/host/usr/bin/{tic,toe,tset,clear,infocmp,tput,tabs}
    $ make root

## qemu

### git update issue

  This may workaround the git update issue:

    $ sed -i -e 's/exit 1/exit 0/g' qemu/Makefile
    $ make qemu QEMU_UPDATE=0
