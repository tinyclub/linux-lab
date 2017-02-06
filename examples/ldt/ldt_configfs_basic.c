/*
 *	LDT - Linux Driver Template - basic configfs
 *
 *	Copyright (C) 2012 Constantine Shulyupin http://www.makelinux.net/
 *
 *	Dual BSD/GPL License
 *
 *	based on configfs_example_explicit.c and much more simple, without containers, just 70 LOC
 *
 *	Sample usage:
 *	sudo insmod ldt_configfs_basic.ko
 *	ls /configfs/ldt_configfs_basic/
 *	sudo sh -c "echo 123 >  /configfs/ldt_configfs_basic/parameter"
 *	cat /configfs/ldt_configfs_basic/parameter
 *
 */

#include <linux/module.h>
#include <linux/configfs.h>

static int parameter;

static struct configfs_attribute ldt_parameter_attr = {
	.ca_owner = THIS_MODULE, .ca_name = "parameter",
	.ca_mode = S_IRUGO | S_IWUSR
};

static struct configfs_attribute ldt_description_attr = {
	.ca_owner = THIS_MODULE, .ca_name = "description",
	.ca_mode = S_IRUGO
};

static struct configfs_attribute *ldt_attrs[] = {
	&ldt_description_attr,
	&ldt_parameter_attr,
	NULL,
};

static ssize_t ldt_attr_show(struct config_item *item, struct configfs_attribute *attr, char *page)
{
	ssize_t ret = -EINVAL;
	if (attr == &ldt_description_attr)
		return sprintf(page, "basic sample of configfs\n");
	else if (attr == &ldt_parameter_attr)
		return sprintf(page, "%d\n", parameter);
	return ret;
}

static ssize_t ldt_attr_store(struct config_item *item, struct configfs_attribute *attr, const char *page, size_t count)
{
	ssize_t ret = -EINVAL;
	if (attr == &ldt_parameter_attr) {
		ret = kstrtoint(page, 0, &parameter);
		if (ret)
			return ret;
		ret = count;
	}
	return ret;
}

static struct config_item_type ci_type = {
	.ct_item_ops = (struct configfs_item_operations[]){ {
		.show_attribute = ldt_attr_show,
		.store_attribute = ldt_attr_store,} },
	.ct_attrs = ldt_attrs,
	.ct_owner = THIS_MODULE,
};

static struct configfs_subsystem ldt_subsys = {
	.su_group = {
		.cg_item = {
			.ci_namebuf = KBUILD_MODNAME,
			.ci_type = &ci_type,
		},
	},
};

static int __init configfs_example_init(void)
{
	int ret;
	config_group_init(&ldt_subsys.su_group);
	mutex_init(&ldt_subsys.su_mutex);
	ret = configfs_register_subsystem(&ldt_subsys);
	if (ret)
		pr_err("Error %d while registering subsystem %s\n",
		       ret, ldt_subsys.su_group.cg_item.ci_namebuf);
	return ret;
}

static void __exit configfs_example_exit(void)
{
	configfs_unregister_subsystem(&ldt_subsys);
}

module_init(configfs_example_init);
module_exit(configfs_example_exit);
MODULE_LICENSE("GPL");
