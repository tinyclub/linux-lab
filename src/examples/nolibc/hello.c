/*
 * hello.c for nolibc
 *
 * refs:
 *   $(linux-src)/tools/include/nolibc
 *   $(linux-src)/tools/testing/selftests/nolibc/nolibc-test.c
 *   http://git.formilux.org/?p=people/willy/nolibc.git;a=blob_plain;f=hello.c;hb=refs/heads/master
 *
 * usage:
 *   $ cd /labs/linux-lab/
 *   $ make kernel nolibc=1 nolibc_src=$PWD/src/examples/nolibc/hello.c
 *   $ make boot nolibc=1
 */
#ifndef NOLIBC
#include <stdio.h>
#include <unistd.h>
#else
#define __NOLIBC__
#endif

#ifndef __NOLIBC__
#include <linux/reboot.h>
#endif

int main(int argc, char *argv[])
{
	printf("Hello, nolibc!\n");

#ifdef __NOLIBC__
	reboot(LINUX_REBOOT_CMD_POWER_OFF);
#endif

	return 0;
}
