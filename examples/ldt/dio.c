/*
 *	DIO - Device Input/Output utility for testing device drivers
 *
 *	stdin/stdout <--> dio <--> mmap, ioctl, read/write
 *
 *	Copyright (C) 2012 Constantine Shulyupin <const@makelinux.net>
 *	http://www.makelinux.net/
 *
 *	Dual BSD/GPL License
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <getopt.h>
#include <string.h>
#include <sys/param.h>
#include <sys/poll.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/user.h>
#include <time.h>
#include <fcntl.h>
#include <assert.h>
#include <linux/ioctl.h>
#include "ctracer.h"

static enum io_type {
	file_io,
	mmap_io,
	ioctl_io
} io_type;

static void *inbuf, *outbuf;
static void *mm;
static void *mem;
static int buf_size;
static int offset;
static char *dev_name;
static int ignore_eof;
static int ioctl_num;
static int loops;
static int delay;
static char ioctl_type = 'A';
__thread int ret;
static int ro, wo; /* read only, write only*/

/*
#define VERBOSE
*/

int output(int dev, void *buf, int size)
{
#ifdef VERBOSE
_entry:
	trl_();
	trvd(size);
#endif
	ret = 0;
	if (dev < 0 || ro)
		return 0;
	switch (io_type) {
	case mmap_io:
		memcpy(mem, buf, size);
		ret = size;
		break;
	case ioctl_io:
		ioctl(dev, _IOC(_IOC_WRITE, ioctl_type, ioctl_num,
					size & _IOC_SIZEMASK), buf);
		break;
	case file_io:
	default:
		ret = write(dev, buf, size);
	}
	return ret;
}

int input(int dev, void *buf, int size)
{
	ret = 0;
#ifdef VERBOSE
_entry:
	trl_();
	trvd(size);
#endif
	if (dev < 0 || wo)
		return 0;
	switch (io_type) {
	case mmap_io:
		memcpy(buf, mem, size);
		ret = size;
		break;
	case ioctl_io:
		ioctl(dev, _IOC(_IOC_READ, ioctl_type, ioctl_num,
					size & _IOC_SIZEMASK), buf);
		ret = size;
		break;
	case file_io:
	default:
		ret = read(dev, buf, size);
	}
	return ret;
}

int io_start(int dev)
{
	struct pollfd pfd[2];
	ssize_t data_in_len, data_out_len, len_total = 0;
	int i = 0;

	/* TODO: wo, ro */
	pfd[0].fd = fileno(stdin);
	pfd[0].events = POLLIN;
	pfd[1].fd = dev;
	pfd[1].events = POLLIN;
	while (poll(pfd, sizeof(pfd) / sizeof(pfd[0]), -1) > 0) {
#ifdef VERBOSE
		trvd_(i);
		trvx_(pfd[0].revents);
		trvx_(pfd[1].revents);
		trln();
#endif
		data_in_len = 0;
		if (pfd[0].revents & POLLIN) {
			pfd[0].revents = 0;
			ret = data_in_len = read(fileno(stdin), inbuf, buf_size);
			if (data_in_len < 0) {
				usleep(100000);
				break;
			}
			if (!data_in_len && !ignore_eof) {
				/* read returns 0 on End Of File */
				break;
			}
#ifdef VERBOSE
			trvd_(data_in_len);
			trln();
#endif
again:
			chkne(ret = output(dev, inbuf, data_in_len));
			if (ret < 0 && errno == EAGAIN) {
				usleep(100000);
				goto again;
			}
			if (data_in_len > 0)
				len_total += data_in_len;
		}
		data_out_len = 0;
		if (pfd[1].revents & POLLIN) {
			pfd[1].revents = 0;
			chkne(ret = data_out_len = input(dev, outbuf, buf_size));
			if (data_out_len < 0) {
				usleep(100000);
				break;
			}
			if (!data_out_len) {
				/* EOF, don't expect data from the file any more
				   but wee can continue to write */
				pfd[1].events = 0;
			}
			if (!data_out_len && !ignore_eof) {
				/* read returns 0 on End Of File */
				break;
			}
			write(fileno(stdout), outbuf, data_out_len);
			if (data_out_len > 0)
				len_total += data_out_len;
		}
#ifdef VERBOSE
		trl_();
		trvd_(i);
		trvd_(len_total);
		trvd_(data_in_len);
		trvd_(data_out_len);
		trln();
#endif
		if ((!ignore_eof && pfd[0].revents & POLLHUP) || pfd[1].revents & POLLHUP)
			break;
		i++;
		if (loops && i >= loops)
			break;
		usleep(1000 * delay);
	}
#ifdef VERBOSE
	trl_();
	trvd_(i);
	trvd_(len_total);
	trvd_(data_in_len);
	trvd_(data_out_len);
	trln();
#endif
	return ret;
}

#define add_literal_option(o)  do { options[optnum].name = #o; \
	options[optnum].flag = (void *)&o; options[optnum].has_arg = 1; \
	options[optnum].val = -1; optnum++; } while (0)

#define add_flag_option(n, p, v) do { options[optnum].name = n; \
	options[optnum].flag = (void *)p; options[optnum].has_arg = 0; \
	options[optnum].val = v; optnum++; } while (0)

static struct option options[100];
int optnum;
static int verbose;

int options_init()
{
	optnum = 0;
	/* on gcc 64, pointer to variable can be used only on run-time
	 */
	memset(options, 0, sizeof(options));
	add_literal_option(io_type);
	add_literal_option(buf_size);
	add_literal_option(ioctl_num);
	add_literal_option(ioctl_type);
	add_literal_option(loops);
	add_literal_option(delay);
	add_literal_option(offset);
	add_flag_option("ioctl", &io_type, ioctl_io);
	add_flag_option("mmap", &io_type, mmap_io);
	add_flag_option("file", &io_type, file_io);
	add_flag_option("ignore_eof", &ignore_eof, 1);
	add_flag_option("verbose", &verbose, 1);
	add_flag_option("ro", &ro, 1);
	add_flag_option("wo", &wo, 1);
	options[optnum].name = strdup("help");
	options[optnum].has_arg = 0;
	options[optnum].val = 'h';
	optnum++;
	return optnum;
}

/*
 * expand_arg, return_if_arg_is_equal - utility functions
 * to translate command line parameters
 * from string to numeric values using predefined preprocessor defines
 */

#define return_if_arg_is_equal(entry) do { if (0 == strcmp(arg, #entry)) return entry; } while (0)

int expand_arg(char *arg)
{
	if (!arg)
		return 0;
/*
	return_if_arg_is_equal(SOCK_STREAM);
*/
	return strtol(arg, NULL, 0);
}

char *usage = "dio - Device Input/Output utility\n\
Usage:\n\
	dio <options> <device file>\n\
\n\
options:\n\
\n\
default values are marked with '*'\n\
\n\
	-h | --help\n\
		show this help\n\
\n\
	--buf_size <n> \n\
		I/O buffer size\n\
\n\
Samples:\n\
\n\
TBD\n\
\n\
";

int init(int argc, char *argv[])
{
	int opt = 0;
	int longindex = 0;
	options_init();
	opterr = 0;
	while ((opt = getopt_long(argc, argv, "h", options, &longindex)) != -1) {
		switch (opt) {
		case 0:
			if (options[longindex].val == -1)
				*options[longindex].flag = expand_arg(optarg);
			break;
		case 'h':
			printf("%s", usage);
			exit(0);
			break;
		default:	/* '?' */
			printf("Error in arguments\n");
			trvx(opt);
			exit(EXIT_FAILURE);
		}
	}
	if (optind < argc)
		dev_name = argv[optind];
	if (io_type == ioctl_io && buf_size >= 1 << _IOC_SIZEBITS)
		fprintf(stderr, "WARNING: size of ioctl data it too big\n");
	return 0;
}

int main(int argc, char *argv[])
{
	int dev;

	buf_size = sysconf(_SC_PAGESIZE);
	init(argc, argv);
	verbose && fprintf(stderr, "%s compiled " __DATE__ " " __TIME__ "\n", argv[0]);
	if (io_type == ioctl_io && buf_size >= 1 << _IOC_SIZEBITS)
		buf_size = (1 << _IOC_SIZEBITS) - 1;
	inbuf = malloc(buf_size);
	outbuf = malloc(buf_size);
	chkne(dev = open(dev_name, O_CREAT | O_RDWR, 0666));
	if (io_type == mmap_io) {
		mm = mmap(NULL, buf_size, PROT_READ | PROT_WRITE,
				MAP_SHARED, dev, offset & ~(sysconf(_SC_PAGESIZE)-1));
		if (mm == MAP_FAILED) {
			warn("mmap() failed");
			goto exit;
		}
		mem = mm + (offset & (sysconf(_SC_PAGESIZE)-1));
	}
	if (verbose) {
		trvs_(dev_name);
		trvd_(io_type);
		trvd_(buf_size);
		trvd_(ignore_eof);
		trvd_(verbose);
		trvp_(mm);
		trvp_(mem);
		trln();
	}
	switch (io_type) {
	case mmap_io:
	case ioctl_io:
		if (!ro) {
			chkne(ret = read(fileno(stdin), inbuf, buf_size));
			if (ret < 0)
				goto exit;
			chkne(ret = output(dev, inbuf, ret));
		}
		if (!wo) {
			chkne(ret = input(dev, outbuf, buf_size));
			if (ret < 0)
				goto exit;
			write(fileno(stdout), outbuf, ret);
		}
		break;
	case file_io:
	default:
		io_start(dev);
	}
exit:
	if (mm && mm != MAP_FAILED)
		munmap(mm, buf_size);
	free(outbuf);
	free(inbuf);
	close(dev);
	exit(EXIT_SUCCESS);
}
