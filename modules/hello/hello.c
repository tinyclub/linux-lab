#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/init.h>

static int __init my_hello_init(void)
{
	pr_info("hello module init\n");

	return 0;
}

static void __exit my_hello_exit(void)
{
	pr_info("hello module exit\n");
}

module_init(my_hello_init);
module_exit(my_hello_exit);
