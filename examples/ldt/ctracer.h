/*
	Tracing utility for C

	implemented in single h-file

	Copyright (C) 2012 Constantine Shulyupin  http://www.makelinux.net/

	Dual BSD/GPL License
*/

#if 0
/* Optional configuration flags: */
#define TRACE_TIME
#define TRACE_MALLOC
#define TRACE_LINUX_MEMORY_ON
#endif
/*
	VI command to include label _entry to each function start for tracing
	:%s/) *\n{ *$/)\r{\t_entry:;/
 */

#ifndef __ASSEMBLY__

#ifndef CTRACER_H_INCLUDED
#define CTRACER_H_INCLUDED
extern __thread int ret;

#define multistatement(ms) ms /* trick to bypass checkpatch.pl error */
/*
#define _entry multistatement(trllog(); goto _entry; _entry)
*/
#define _entry multistatement(_trace_enter_exit_(); \
	trln(); goto _entry_second; _entry_second)
/*
#define _entry once(trl()); goto _entry; _entry
#define return trlm("} "); return
*/

#define do_statement(a)	do { a } while (0)

/*
	trace variables: integer, hex, string, pointer, float, time value
	macro with '_' doesn't prints new line
	notation:
	tr = trace
	v<letter> = printf Variable in specified format (d, x, f, s, etc)
*/

#define trla(fmt, args...) tracef("%s:%i %s "fmt, __file__, __LINE__, __func__, ## args)
#define trv(t, v) tracef(#v" = %"t EOL, v)
#define trv_(t, v) tracef(#v" = %"t" ", v)
#define trvd(d) tracef(#d" = %ld"EOL, (long int)d)
#define trvd_(d) tracef(#d" = %ld ", (long int)d)
#define trvx_(x) tracef(#x" = 0x%x ", (int)x)
#define trvx(x) tracef(#x" = 0x%x"EOL, (int)x)
#define trvlx(x) tracef(#x" = %#llx"EOL, (int)x)
#define trvX(x) tracef(#x" = %#X"EOL, (int)x)
#define trvf(f) tracef(#f" = %f"EOL, f)
#define trvf_(f) tracef(#f" = %f ", f)
#define trvtv_(tv) tracef(#tv" = %u.%06u ", (unsigned int)tv.tv_sec, (unsigned int)tv.tv_usec)
#define trvtv(tv) tracef(#tv" = %u.%06u"EOL, (unsigned int)tv.tv_sec, (unsigned int)tv.tv_usec)
#define trvs(s) tracef(#s" = \"%s\""EOL, s)
#define trvs_(s) tracef(#s" = \"%s\" ", s)
#define trvp(p) tracef(#p" = %08x"EOL, (unsigned)p)
#define trvp_(p) tracef(#p" = %08x ", (unsigned)p)
#define trvdn(d, n) {int i; tracef("%s", #d"[]="); for (i = 0; i < n; i++) tracef("%d:%d,", i, (*((int *)d+i))); tracef(EOL); }
#define trvxn(d, n) {int i; tracef("%s", #d"[]="); for (i = 0; i < n; i++) tracef("%04x,", (*((int *)d+i))); tracef(EOL); }
#define trvdr(record) trvdn(&record, sizeof(record)/sizeof(int));
#define trvxr(record) trvxn(&record, sizeof(record)/sizeof(int));

/* trvdnz - TRace Digital Variable, if Not Zero */
#define trvdnz(d) { if (d) tracef(#d" = %d"EOL, (int)d); }
#define trace_call(a) do { trla("calling %s {\n", #a); a; tracef("} done\n"); } while (0)

/* trlm - TRace Location, with Message */
#define trlm(m) tracef(SOL"%s:%i %s %s"EOL, __file__, __LINE__, __func__, m)
#define trlm_(m) tracef(SOL"%s:%i %s %s ", __file__, __LINE__, __func__, m)
#define trl() do { trace_time(); trlm(""); } while (0)
#define trl_() tracef(SOL"%s:%i %s ", __file__, __LINE__, __func__)
#define trln() tracef(EOL)

#define trl_in() do_statement(trace_time(); trlm("{");)
#define trl_out() do_statement(trace_time(); trlm("}");)
#define empty_statement() do { } while (0)

#define trace_mem(P, N) \
	 IFTRACE({ int i = 0; tracef("%s=", #P); for (; i < (int)(N) ; i++) \
{ if (i && (!(i % 16))) tracef("%i:", i); \
tracef("%02x ", 0xFF & *((char *)((void *)(P))+i)); \
if (!((i+1) % 4)) \
	tracef(" "); \
if (!((i+1) % 16)) \
	tracef(EOL); \
}; tracef(EOL); })

#define trace_mem_int_list(P, N) \
IFTRACE({ int i = 0; for (; i < (int)(N); i += sizeof(int)) \
{ tracef("%i, ", *(int *)((void *)(P)+i)); \
}; })

#define trace_mem_int(P, N) \
IFTRACE({ int i = 0; for (; i < (int)(N) ; i += sizeof(int)) \
{ if (i && (!(i % 16))) tracef("%i:", i); \
tracef("%x ", *(int *)((void *)(P)+i)); \
if (!((i+1) % 64)) \
	tracef(EOL); \
}; tracef(EOL); })

#define trace_ioctl(nr) tracef("ioctl=(%c%c %c #%i %i)\n", \
	(_IOC_READ & _IOC_DIR(nr)) ? 'r' : ' ', (_IOC_WRITE & _IOC_DIR(nr)) ? 'w' : ' ', \
	_IOC_TYPE(nr), _IOC_NR(nr), _IOC_SIZE(nr))

#define trace_ioctl_(nr) tracef("ioctl=(%i %i %i %i)", _IOC_DIR(nr), _IOC_TYPE(nr), _IOC_NR(nr), _IOC_SIZE(nr))

#define chkz(a) \
(p = a,\
	((!p) ? tracef("%s %i %s FAIL %i = %s\n", __FILE__, __LINE__, __func__, p, #a) : 0),\
	p)

#define chkn(a) \
(ret = a,\
	((ret < 0) ? tracef("%s:%i %s FAIL\n\t%i=%s\n", __FILE__, __LINE__, __func__, ret, #a)\
	 : 0), ret)

#define chkne(a) \
(/* tracef("calling  %s\n",#a), */ \
	ret = a,\
	((ret < 0) ? tracef("%s:%i %s FAIL errno = %i \"%s\" %i = %s\n", __FILE__, __LINE__, __func__, errno, strerror(errno), ret, #a)\
	 : 0), ret)

#define chkn2(a) \
(ret = a,\
	((ret < 0) ? tracef("%s %i %s FAIL %i = %s\n", __FILE__, __LINE__, __func__, ret, #a)\
	 : tracef("%s %i %s %i = %s\n", __FILE__, __LINE__, __func__, ret, #a)),\
	ret)

#define once(exp) do_statement( \
	static int _passed; if (!_passed) {exp; }; _passed = 1;)


#ifdef CTRACER_OFF		/* force no tracing */
#undef CTRACER_ON
#endif

#ifdef CTRACER_ON
#define IFTRACE(x) x

#ifdef __KERNEL__
#undef TRACE_TIME
#include <linux/kernel.h>
#include <linux/printk.h>

#ifdef TRACE_LINUX_MEMORY_ON
#include <linux/mmzone.h>

extern int free_pages_prev;
#define trace_linux_mem() do { \
extern zone_t *zone_table[MAX_NR_ZONES*MAX_NR_NODES]; \
int mem_change = zone_table[0]->free_pages - free_pages_prev; \
if (mem_change) { \
	trl_(); trvi_(mem_change); trvi(zone_table[0]->free_pages); } \
	free_pages_prev = zone_table[0]->free_pages; \
} while (0)
#endif

#define SOL KERN_DEBUG
#define tracef(fmt, args...) printk(fmt, ##args)

#else /* !__KERNEL__ */
/* CTRACER_ON and not __KERNEL__ */
#include <stdio.h>

#define tracef(args...) fprintf(stderr, ##args)

#if 0
#include <signal.h>
#define BP {trl(); kill(0, SIGTRAP); }
#define BP kill(0, SIGTRAP)
#endif

#ifndef tracef
#define tracef printf
#endif
#endif /* !__KERNEL__ */

#ifndef _hweight32
static inline unsigned int _hweight32(unsigned int w)
{	/* from kernel */
	w -= (w >> 1) & 0x55555555;
	w = (w & 0x33333333) + ((w >> 2) & 0x33333333);
	w = (w + (w >> 4)) & 0x0f0f0f0f;
	return (w * 0x01010101) >> 24;
}

#define _hweight32 _hweight32
#endif
#define trllog(args ...) \
do {  \
	static int num;			\
	if (_hweight32(num) < 2) {		\
		trla("#%d\n", (int)num);	\
	}	num++;				\
} while (0)

#define trlnum(n, args ...) \
do {  \
	static int num;			\
	if (num < n) {		\
		trl_();				\
		tracef("#0x%x", (int)num);	\
		args;				\
		trln();			\
	}	num++;				\
} while (0)

#define trleach(n, args ...) \
do {  \
	static int num;			\
	if (!(num % n)) {	\
		trl_();				\
		trvi_(num);		\
		args;				\
		trln();			\
	}	num++;				\
} while (0)

#else /* !CTRACER_ON */
#define trllog(args ...)

static inline int empty_function(void)
{
	return 0;
}

#define IFTRACE(x) empty_statement()
#define trace_linux_mem() empty_statement()
#define tracef(fmt, args...) empty_function()
#define stack_trace() empty_statement()

#endif /* _TARCE */

#ifndef SOL
#define SOL ""
#endif
#define EOL "\n" /* for console */

#ifdef MODULE
/* omit full absolute path for modules */
extern char *strrchr(const char *s, int c);
#define ctracer_cut_path(fn) (fn[0] != '/' ? fn : (strrchr(fn, '/') + 1))
#define __file__	ctracer_cut_path(__FILE__)
#else
#define __file__	__FILE__
#endif

#ifdef TRACE_MALLOC
static int malloc_count;
static void *malloc_trace;
#endif
#ifdef TRACE_MALLOC

#define malloc(s) \
	(trla("malloc #%i %p %i\n", ++malloc_count, malloc_trace = malloc(s), s),\
	malloc_trace)

#define free(p) { free(p); trla("free   #%i %p\n", malloc_count--, (void *)p); }

#define strdup(s) \
	(trla("strdup #%i %p\n", ++malloc_count, malloc_trace = (void *)strdup(s)),\
	(char *)malloc_trace)

#endif

#ifdef TRACE_TIME

#include <time.h>
#include <sys/time.h>

#ifndef trace_time_defined
#define trace_time_defined

void trace_time();
/*
extern double time_prev_f;
void static inline trace_time()
{
	time_t time_cur;
	double time_cur_f;
	time(&time_cur);
	struct timeval tv;
	struct timezone tz;
	struct tm* time_tm;
	gettimeofday(&tv, &tz);
	time_tm = localtime(&time_cur);
	time_cur = tv.tv_sec;
	time_cur_f = 0.000001 * tv.tv_usec + time_cur;
	double passed = time_cur_f - time_prev_f;
	if (passed > 0.001)
	{
		tracef("time=%04d-%02d-%02d %02d:%02d:%02d %02d +%1.4f s\n",
				time_tm->tm_year+1900, time_tm->tm_mon+1, time_tm->tm_mday,
				time_tm->tm_hour, time_tm->tm_min, time_tm->tm_sec, (int)tv.tv_usec,
				passed);
		time_prev_f = time_cur_f;
	}
}
*/
#endif

#else
#define trace_time() empty_statement()
#endif

#ifdef __GLIBC__XX
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef stack_trace
#undef stack_trace
#endif
#ifndef stack_trace_difined
#define stack_trace_difined
/* only once */
static inline void stack_trace(void)
{
	void *array[5];
	size_t size;
	char **strings;
	size_t i;
	size = backtrace(array, sizeof(array) / sizeof(array[0]));
	strings = backtrace_symbols(array, size);
	tracef("Stack:\n");

	for (i = 0; i < size; i++) {
		if (!array[i])
			break;
		tracef("%i %p %s\n", i, array[i], strings[i]);
	}
	free(strings);
}
#endif
#endif /* __GLIBC__ */

/* see also nr_free_pages */
#define freeram() { \
	static unsigned int last; struct sysinfo i; si_meminfo(&i); trl_(); \
	int d = last-i.freeram; int used = i.totalram-i.freeram; \
	trvi_(i.freeram); trvi_(used);  trvi(d); \
	last = i.freeram; }

extern int sprint_symbol_no_offset(char *buffer, unsigned long address);

static inline void __on_cleanup(char *s[])
{
#ifdef __KERNEL__
	pr_debug(KERN_DEBUG"%s", *s);
#else
	fputs(*s, stderr);
#endif
}

#if !defined(__KERNEL__) || defined(MODULE)
static inline int lookup_symbol_name(unsigned long addr, char *symbol)
{
	return sprintf(symbol, "%lx", addr);
}
#else
int lookup_symbol_name(unsigned long addr, char *symname);
#endif

#define _trace_enter_exit_() char _caller[200]; \
	lookup_symbol_name((unsigned long)__builtin_return_address(0), _caller); \
	char __attribute__((cleanup(__on_cleanup))) *_s; \
	char _ret_msg[100]; _s = _ret_msg; \
	snprintf(_ret_msg, sizeof(_ret_msg), "%s < %s }\n", _caller, __func__); \
	tracef(SOL"%s > %s { @ %s:%d", _caller, __func__, __file__, __LINE__);

/*__END_DECLS */
#endif /* CTRACER_H_INCLUDED */
#endif /* __ASSEMBLY__ */
