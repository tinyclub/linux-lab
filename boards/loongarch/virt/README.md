
# loongarch/virt board Usage

## Select me

    $ make B=loongarch/virt

## Boot me with initrd

    $ make boot

## Debug with qemu

  Debug interactively:

    $ make debug

  Debug automatically:

    $ make test DEBUG=1

## References

* src/qemu/docs/system/loongarch/virt.rst
* https://github.com/foxsen/qemu-loongarch-runenv
