#!/bin/bash
#
# dir2rd.sh -- rebuild rootfs.cpio.gz from rootfs directory
#

[ -z "$ROOTDIR" ] && ROOTDIR=$1
[ -z "$INITRD" ] && INITRD=$2
[ -z "$ROOTDIR" -o -z "$INITRD" ] && echo "Usage: $0 rootdir initrd" && exit 1
[ -z "${USER}" ] && USER=$(whoami)

ROOTDIR=$(echo ${ROOTDIR} | sed -e "s%/$%%g")
FS_CPIO_GZ=${INITRD}

if [ -d ${ROOTDIR} -a -d ${ROOTDIR}/bin -a -d ${ROOTDIR}/etc ]; then

  [ -f ${FS_CPIO_GZ} ] && rm ${FS_CPIO_GZ}

  # Add init/linuxrc for basic initramfs
  # ref: linux-stable/Documentation/admin-guide/initrd.rst
  [ -f $ROOTDIR/linuxrc -a $ROOTDIR/busybox ] && ln -sf $ROOTDIR/busybox $ROOTDIR/linuxrc

  [ ! -f $ROOTDIR/init ] && cat <<EOF > $ROOTDIR/init
#!/bin/sh
# devtmpfs does not get automounted for initramfs
/bin/mount -t devtmpfs devtmpfs /dev
exec 0</dev/console
exec 1>/dev/console
exec 2>/dev/console
exec /bin/init "\$@"
EOF

  [ ! -d $ROOTDIR/etc/init.d ] && mkdir -p $ROOTDIR/etc/init.d
  [ ! -f $ROOTDIR/etc/init.d/rcS ] && cat <<EOF > $ROOTDIR/etc/init.d/rcS
#!/bin/sh


# Start all init scripts in /etc/init.d
# executing them in numerical order.
#
for i in /etc/init.d/S??* ;do

     # Ignore dangling symlinks (if any).
     [ ! -f "$i" ] && continue

     case "$i" in
	*.sh)
	    # Source shell script for speed.
	    (
		trap - INT QUIT TSTP
		set start
		. $i
	    )
	    ;;
	*)
	    # No sh extension, so fork subprocess.
	    $i start
	    ;;
    esac
done
EOF

  chmod a+x $ROOTDIR/init
  chmod a+x $ROOTDIR/etc/init.d/rcS

  cd $ROOTDIR/ && find . | sudo cpio --quiet -R $USER:$USER -H newc -o | gzip -9 -n > ${FS_CPIO_GZ}

  exit 0
fi

echo "ERR: ${ROOTDIR} is not a valid rootfs directory." && exit 1
