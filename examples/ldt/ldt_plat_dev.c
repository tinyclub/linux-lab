/*
 *	LDT - Linux Driver Template
 *
 *	Copyright (C) 2012 Constantine Shulyupin  http://www.makelinux.net/
 *
 *	GPL License
 *
 *	platform_device template driver
 *
 *	uses
 *
 *	platform_data
 *	resources
 *
 */

#include <linux/module.h>
#include <linux/platform_device.h>

static struct resource ldt_resource[] = {
	{
		.flags = IORESOURCE_IO,
		.start = 0x3f8,
		.end = 0x3ff,
	},
	{
		.flags = IORESOURCE_IRQ,
		.start = 4,
		.end = 4,
	},
	{
		.flags = IORESOURCE_MEM,
		.start = 0,
		.end = 0,
	},
};

static void ldt_dev_release(struct device *dev)
{
}

static struct platform_device ldt_platform_device = {
	.name	= "ldt_device_name",
	.resource	= ldt_resource,
	.num_resources	= ARRAY_SIZE(ldt_resource),
	.dev.platform_data = "test data",
	.dev.release	= ldt_dev_release,
};

static int ldt_plat_dev_init(void)
{
	return platform_device_register(&ldt_platform_device);
}

static void ldt_plat_dev_exit(void)
{
	platform_device_unregister(&ldt_platform_device);
}

module_init(ldt_plat_dev_init);
module_exit(ldt_plat_dev_exit);

MODULE_DESCRIPTION("LDT - Linux Driver Template: platform_device");
MODULE_AUTHOR("Constantine Shulyupin <const@makelinux.net>");
MODULE_LICENSE("GPL");
