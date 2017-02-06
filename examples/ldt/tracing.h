
#define multistatement(ms)	ms	/* trick to bypass checkpatch.pl error */
#define _entry multistatement(goto _entry; _entry)

/*
 *	ctracer_cut_paths - return filename without path
 */

#define trace_loc()	printk(KERN_DEBUG"%s:%d %s ", __file__, __LINE__, __func__)
#define trace_hex(h)	printk("%s = 0x%lX ", #h, (long int)h)
#define trace_dec(d)	printk("%s = %ld ", #d, (long int)d)
#define trace_dec_ln(d)	printk("%s = %ld\n", #d, (long int)d)
#define trace_ln(m)	printk(KERN_CONT"\n")

#define ctracer_cut_path(fn) (fn[0] != '/' ? fn : (strrchr(fn, '/') + 1))
#define __file__	ctracer_cut_path(__FILE__)

/*
 *	print_context prints execution context:
 *	hard interrupt, soft interrupt or scheduled task
 */

#define print_context()	\
	pr_debug("%s:%d %s %s 0x%x\n", __file__, __LINE__, __func__, \
			(in_irq() ? "harirq" : current->comm), preempt_count());

#define once(exp) do { \
	static int _passed; if (!_passed) { exp; }; _passed = 1; } while (0)

#define check(a) \
	(ret = a, ((ret < 0) ? pr_warn("%s:%i %s FAIL\n\t%i=%s\n", \
	__file__, __LINE__, __func__, ret, #a) : 0), ret)

#define pr_debug_hex(h)	pr_debug("%s:%d %s %s = 0x%lX\n", \
	__file__, __LINE__, __func__, #h, (long int)h)
#define pr_debug_dec(d)	pr_debug("%s:%d %s %s = %ld\n", \
	__file__, __LINE__, __func__, #d, (long int)d)

#define pr_err_msg(m)	pr_err("%s:%d %s %s\n", __file__, __LINE__, __func__, m)
