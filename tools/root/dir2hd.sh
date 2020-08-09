#!/bin/bash
#
# dir2hd.sh rootdir hrootfs fstype -- directory to harddisk fs image
#
# Copyright (C) 2016-2020 Wu Zhangjin <lzufalcon@163.com>
#

[ -z "$ROOTDIR" ] && ROOTDIR=$1
[ -z "$HROOTFS" ] && HROOTFS=$2
[ -z "$FSTYPE" ] && FSTYPE=$3

[ -z "${ROOTDIR}" -o -z "${HROOTFS}" ] && echo "Usage: $0 rootdir hrootfs fstype" && exit 1

[ -z "${FSTYPE}" ] && FSTYPE=ext2

[ -z "${USER}" ] && USER=$(whoami)

ROOTDIR=$(echo ${ROOTDIR} | sed -e "s%/$%%g")

_ROOTDIR=$(echo ${HROOTFS} | sed -e "s%.${FSTYPE}%%g")
FS_CPIO_GZ=${_ROOTDIR}.cpio.gz
FS_CPIO=${_ROOTDIR}.cpio

# Convert to cpio.gz from directory
if [ -d ${ROOTDIR} -a -d ${ROOTDIR}/bin -a -d ${ROOTDIR}/etc ]; then
  # sync with directory content ??
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
exec /sbin/init "\$@"
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

  cd ${ROOTDIR} && sudo find . | sudo cpio --quiet -R $USER:$USER -H newc -o | gzip -9 -n > ${FS_CPIO_GZ}
else
  echo "ERR: $ROOTDIR: invalid root directory." && exit 1
fi

# Calculate the size
ROOTFS_SIZE=`ls -s ${FS_CPIO_GZ} | cut -d' ' -f1`
ROOTFS_SIZE=$((${ROOTFS_SIZE} * 5))
ROOTFS_SIZE=$(( (${ROOTFS_SIZE} / 1024 + 1) * 1024 ))
echo "LOG: Rootfs size: $ROOTFS_SIZE (kilo bytes)"

# Create the file system image
dd if=/dev/zero of=${HROOTFS} bs=1024 count=$ROOTFS_SIZE
yes | mkfs.${FSTYPE} ${HROOTFS}

# Copy content to fs image
mkdir -p ${ROOTDIR}.tmp
sudo mount ${HROOTFS} ${ROOTDIR}.tmp
pushd ${ROOTDIR}.tmp

if [ -f ${FS_CPIO_GZ} ]; then
   gzip -cdkf ${FS_CPIO_GZ} | sudo cpio --quiet -idmv -R ${USER}:${USER} >/dev/null 2>&1
elif [ -f ${FS_CPIO} ]; then
   sudo cpio --quiet -idmv -R ${USER}:${USER} < ${FS_CPIO} >/dev/null 2>&1
fi

sudo chown ${USER}:${USER} -R ./
#sync
popd
sudo umount ${ROOTDIR}.tmp
rm -rf ${ROOTDIR}.tmp
