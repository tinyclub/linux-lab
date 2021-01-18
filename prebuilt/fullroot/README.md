
# Docker images for full rootfs

list available docker images containing a full root with package management tool.

## ARM

* ARM32 / arm
  - Ubuntu
    - arm32v7/ubuntu (18.04)
    - tinylab/arm32v7-ubuntu (18.04)
  - Busybox
    - arm32v7/busybox

* ARM64 / aarch64
  - Ubuntu
    - arm64v8/ubuntu (18.04)
    - tinylab/arm64v8-ubuntu (18.04)
  - Busybox
    - arm32v7/busybox

## MIPS

* MIPS32 / mipsel
  - aoqi/debian-mipsel

* MIPS64 / mips64el
  - aoqi/debian-mips64el

## PPC

* PPC64 / ppc64sel
  - ppc64le/ubuntu

## X86

* X86_32 / i386
  - i386/ubuntu

* X86_64 / x86_64
  - ubuntu

## More

Search more from docker images repository:

    $ docker search ppc | grep ubuntu

Extrat one:

    $ tools/rootfs/docker/extra.sh arm64v8/ubuntu aarch64

Run with docker:

    $ tools/rootfs/docker/run.sh arm64v8/ubuntu aarch64

Run with chroot:

    $ tools/rootfs/docker/chroot.sh arm64v8/ubuntu

## References

* [Ubuntu rootfs][1]
* [Ubuntu docker image][2]
* [Debian rootfs][3]
* [Debian docker image][4]
* [Reproducible, snapshot-based Debian rootfs builder][5]

[1]: https://partner-images.canonical.com/core/
[2]: https://hub.docker.com/r/arm64v8/ubuntu
[3]: https://github.com/debuerreotype/docker-debian-artifacts/tree/dist-arm64v8
[4]: https://hub.docker.com/r/arm64v8/debian
[5]: https://github.com/debuerreotype/debuerreotype
