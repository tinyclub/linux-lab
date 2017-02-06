/*
 *	LDT - Linux Driver Template
 *
 *	Copyright (C) 2012 Constantine Shulyupin  http://www.makelinux.net/
 *
 *	Dual BSD/GPL License
 *
 *	platform_driver template driver
 *	Power Management (dev_pm_ops)
 *	Device Tree (of_device_id)
 *
 */

#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/of_platform.h>
#include <linux/mod_devicetable.h>
#include <linux/of_irq.h>

#include "common.h"
#include "tracing.h"

static int irq;
static int port;
static int port_size;

static __devinit int ldt_plat_probe(struct platform_device *pdev)
{
	char *data = NULL;
	struct resource *r;
	struct device *dev = &pdev->dev;

_entry:
	dev_dbg(dev, "probe\n");
	data = pdev->dev.platform_data;
	irq = platform_get_irq(pdev, 0);
	r = platform_get_resource(pdev, IORESOURCE_IRQ, 0);
	pr_debug("pdev->dev.of_node = %p\n", pdev->dev.of_node);
#ifdef CONFIG_OF_DEVICE
	if (pdev->dev.of_node) {
		const __be32 *p;
		int property;
		of_platform_populate(pdev->dev.of_node, NULL, NULL, &pdev->dev);
		irq = irq_of_parse_and_map(pdev->dev.of_node, 0);
		p = of_get_property(pdev->dev.of_node, "property", NULL);
		if (p)
			property = be32_to_cpu(*p);
	}
#endif
	/*
	   sample code for drvdata usage:
	   struct ldt_data *drvdata = platform_get_drvdata(pdev);
	   platform_set_drvdata(pdev, drvdata);
	*/

	data = dev_get_platdata(&pdev->dev);
	pr_debug("%p %s\n", data, data);
	r = platform_get_resource(pdev, IORESOURCE_IO, 0);
	port = r->start;
	port_size = resource_size(r);
	/*
	   devm_kzalloc

	   res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	   r = devm_request_and_ioremap(&pdev->dev, res);

	   */

	return 0;
}

static int __devexit ldt_plat_remove(struct platform_device *pdev)
{
_entry:
	return 0;
}

/*
 *	template for OF FDT ID
 *	(Open Firmware Flat Device Tree)
 */

static const struct of_device_id ldt_of_match[] = {
	{.compatible = "linux-driver-template",},
	{},
};

MODULE_DEVICE_TABLE(of, ldt_of_match);

#ifdef CONFIG_PM

static int ldt_suspend(struct device *dev)
{
	return 0;
}

static int ldt_resume(struct device *dev)
{
	return 0;
}

static const struct dev_pm_ops ldt_pm = {
	.suspend = ldt_suspend,
	.resume  = ldt_resume,
};

#define ldt_pm_ops (&ldt_pm)
#else
#define ldt_pm_ops NULL
#endif

static struct platform_driver ldt_plat_driver = {
	.driver = {
		   .name	= "ldt_device_name",
		   .owner	= THIS_MODULE,
		   .pm		= ldt_pm_ops,
		   .of_match_table = of_match_ptr(ldt_of_match),
		   },
	.probe = ldt_plat_probe,
	.remove = __devexit_p(ldt_plat_remove),

};

module_platform_driver(ldt_plat_driver);

MODULE_DESCRIPTION("LDT - Linux Driver Template: platform_driver template");
MODULE_AUTHOR("Constantine Shulyupin <const@makelinux.net>");
MODULE_LICENSE("Dual BSD/GPL");
