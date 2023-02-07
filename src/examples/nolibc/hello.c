/*
 * hello.c for nolibc
 *
 * refs:
 *   $(linux-src)/tools/include/nolibc
 *   $(linux-src)/tools/testing/selftests/nolibc/nolibc-test.c
 *
 * usage:
 *   $ cd /labs/linux-lab/
 *   $ make kernel nolibc=1 nolibc_src=$PWD/src/examples/nolibc/hello.c
 *   $ make boot nolibc=1
 */
#include <stdio.h>
#include <unistd.h>

int main(int argc, int argv[])
{
	printf("Hello, nolibc!\n");

#ifdef NOLIBC
	reboot(LINUX_REBOOT_CMD_HALT);
#endif

	return 0;
}
