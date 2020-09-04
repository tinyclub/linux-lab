#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>

/* ref: linux-stable/drivers/misc/lkdtm/bugs.c */
static void create_exception(void)
{
	*((volatile int *) 0) = 0;	
}

static int __init my_exception_init(void)
{
	pr_info("exception module init\n");

	create_exception();

	return 0;
}

static void __exit my_exception_exit(void)
{
	pr_info("exception module exit\n");
}

module_init(my_exception_init);
module_exit(my_exception_exit);

MODULE_DESCRIPTION("exception - Linux Lab module example");
MODULE_AUTHOR("Wu Zhangjin <wuzhangjin@gmail.com>");
MODULE_LICENSE("GPL");
