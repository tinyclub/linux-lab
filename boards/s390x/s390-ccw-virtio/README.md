
# s390x/s390-ccw-virtio board Usage

## Select me

    $ make B=s390x/s390-ccw-virtio

## Boot me with initrd

    $ make boot

## Debug with qemu

  Debug interactively:

    $ make debug

  Debug automatically:

    $ make test DEBUG=1

## References

* tools/testing/selftests/nolibc/Makefile
