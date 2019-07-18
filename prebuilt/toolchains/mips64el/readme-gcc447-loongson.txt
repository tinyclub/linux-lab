#
# The loongson cross-compiler.
# Bug report: xuchenghua@loongson.cn
#

######################################################################################################
#
# o32 Usage
#
#######################################################################################################
1. Please untar the package in directory "/opt"
	# tar -xzf gcc-4.4.7-7215-xxx-loongson.tar.gz -C /opt   # xxx means o32
2. Set compiler PATH.
	# export PATH=/opt/gcc-4.4.7-7215-xxx-loongson/usr/bin/:$PATH  # xxx means o32
	# export LD_LIBRARY_PATH=/opt/gcc-4.4.7-7215-xxx-loongson/usr/x86_64-unknown-linux-gnu/mipsel-redhat-linux/lib:$LD_LIBRARY_PATH  # xxx means o32

3. The cross compiler prefix name is "mipsel-redhat-linux-"
	# eg. CC=mipsel-redhat-linux-gcc
	# eg. AS=mipsel-redhat-linux-as
	# eg. LD=mipsel-redhat-linux-ld
	# eg. objdump=mipsel-redhat-linux-objdump


4. If something wrong (Optional).
	put follow lib path in your "LD_LIBRARY_PATH"
	/opt/gcc-4.4.7-7215-o32-loongson/usr/lib
	/opt/gcc-4.4.7-7215-o32-loongson/usr/mipsel-redhat-linux/lib
	/opt/gcc-4.4.7-7215-o32-loongson/usr/mipsel-redhat-linux/sysroot/lib
	/opt/gcc-4.4.7-7215-o32-loongson/usr/mipsel-redhat-linux/sysroot/usr/lib


######################################################################################################
#
# n32 or n64 Usage
#
#######################################################################################################
1. Please untar the package in directory "/opt"
	# tar -xzf gcc-4.4.7-7215-o32-loongson.tar.gz -C /opt   # xxx means n32 or n64
2. Set compiler PATH.
	# export PATH=/opt/gcc-4.4.7-7215-xxx-loongson/usr/bin/:$PATH  # xxx means n32 or n64
	# export LD_LIBRARY_PATH=/opt/gcc-4.4.7-7215-xxx-loongson/usr/x86_64-unknown-linux-gnu/mips64el-redhat-linux/lib:$LD_LIBRARY_PATH  # xxx means n32 or n64

3. The cross compiler prefix name is "mips64el-redhat-linux-"
	# eg. CC=mips64el-redhat-linux-gcc
	# eg. AS=mips64el-redhat-linux-as
	# eg. LD=mips64el-redhat-linux-ld
	# eg. objdump=mips64el-redhat-linux-objdump

4. If something wrong (Optional).
	put follow lib path in your "LD_LIBRARY_PATH"
	/opt/gcc-4.4.7-7215-o32-loongson/usr/lib
	/opt/gcc-4.4.7-7215-o32-loongson/usr/mips64el-redhat-linux/lib
	/opt/gcc-4.4.7-7215-o32-loongson/usr/mips64el-redhat-linux/sysroot/lib
	/opt/gcc-4.4.7-7215-o32-loongson/usr/mips64el-redhat-linux/sysroot/usr/lib


######################################################################################################
# Version.
######################################################################################################
The binutils is binutils-2.20.
The glibc is glibc-2.12.
The kernel-heads is kernel-heads-3.10.
The gcc-4.4.7 version commit last four number is "7215".



######################################################################################################
#
# The cross compiler installed absolute path is "/home/xuchenghua/toolchain/cross-tools".
# If above did't works, do follow thing.
#
######################################################################################################
1. please untar the package in directory "/home/xuchenghua/toolchain/cross-tools"
	# tar -xzf gcc-4.4.7-7215-xxx-loongson.tar.gz -C /home/xuchenghua/toolchain/cross-tools   # xxx means o32,n32 or n64
2. Set compiler PATH.
	# export PATH=/home/xuchenghua/toolchain/cross-tools/gcc-4.4.7-7215-xxx-loongson/usr/bin/:$PATH  # xxx means o32,n32 or n64
	# export LD_LIBRARY_PATH=/home/xuchenghua/toolchain/cross-tools/gcc-4.4.7-7215-xxx-loongson/usr/x86_64-unknown-linux-gnu/mips<64>el-redhat-linux/lib:$LD_LIBRARY_PATH  # xxx means o32,n32 or n64

