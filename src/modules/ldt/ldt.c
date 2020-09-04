/*
 *	LDT - Linux Driver Template
 *
 *	Copyright (C) 2012 Constantine Shulyupin http://www.makelinux.net/
 *
 *	Licensed under the GPLv2.
 *
 *
 *	The driver demonstrates usage of following Linux facilities:
 *
 *	Linux kernel module
 *	file_operations
 *		read and write (UART)
 *		blocking read and write
 *		polling
 *		mmap
 *		ioctl
 *	kfifo
 *	completion
 *	interrupt
 *	tasklet
 *	timer
 *	work
 *	simple single misc device file (miscdevice, misc_register)
 *	debugfs
 *	platform_driver and platform_device in another module
 *	simple UART driver on port 0x3f8 with IRQ 4
 *
 *	Use test script ldt-test to see the driver running
 *
 */

#include <linux/io.h>
#include <linux/ioport.h>
#include <linux/mm.h>
#include <linux/interrupt.h>
#include <linux/sched.h>
#include <linux/delay.h>
#include <linux/timer.h>
#include <linux/kfifo.h>
#include <linux/fs.h>
#include <linux/poll.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/miscdevice.h>
#include <linux/serial_reg.h>
#include <linux/debugfs.h>
#include <linux/cdev.h>

#include "common.h"

#undef pr_fmt
#define pr_fmt(fmt)    "%s.c:%d %s " fmt, KBUILD_MODNAME, __LINE__, __func__

static int port = 0x3f8;
module_param(port, int, 0);
MODULE_PARM_DESC(port, "io port number, default 0x3f8 - UART");

static int port_size = 8;
module_param(port_size, int, 0);
MODULE_PARM_DESC(port_size, "number of io ports, default 8");

static int irq = 4;
module_param(irq, int, 0);
MODULE_PARM_DESC(irq, "interrupt request number, default 4 - UART");

static int loopback;
module_param(loopback, int, 0);
MODULE_PARM_DESC(loopback, "loopback mode for testing, default 0");

#define FIFO_SIZE 128		/* must be power of two */

static int bufsize = 8 * PAGE_SIZE;

/**
 * struct ldt_data - the driver data
 * @in_buf:	input buffer for mmap interface
 * @out_buf:	outoput buffer for mmap interface
 * @in_fifo:	input queue for write
 * @out_fifo:	output queue for read
 * @fifo_lock:	lock for queues
 * @readable:	waitqueue for blocking read
 * @writeable:	waitqueue for blocking write
 * @port_ptr:	mapped io port
 * @uart_detected: UART is detected and will be used.
 *	Otherwise emulation mode will be used.
 *
 * stored in static global variable drvdata for simplicity.
 * Can be also retrieved from platform_device with
 * struct ldt_data *drvdata = platform_get_drvdata(pdev);
 */

struct ldt_data {
	void *in_buf;
	void *out_buf;
	DECLARE_KFIFO(in_fifo, char, FIFO_SIZE);
	DECLARE_KFIFO(out_fifo, char, FIFO_SIZE);
	spinlock_t fifo_lock;
	wait_queue_head_t readable, writeable;
	struct mutex read_lock;
	struct mutex write_lock;
	void __iomem *port_ptr;
	int uart_detected;
};

static struct ldt_data *drvdata;

/**
 * ldt_received	- puts data to receive queue
 * @data: received data
 */

static void ldt_received(char data)
{
	kfifo_in_spinlocked(&drvdata->in_fifo, &data,
			sizeof(data), &drvdata->fifo_lock);
	wake_up_interruptible(&drvdata->readable);
}

/**
 * ldt_send - sends data to HW port or emulates SW loopback
 * @data: data to send
 */

static void ldt_send(char data)
{
	if (drvdata->uart_detected)
		iowrite8(data, drvdata->port_ptr + UART_TX);
	else
		if (loopback)
			ldt_received(data);
}

static inline u8 tx_ready(void)
{
	return ioread8(drvdata->port_ptr + UART_LSR) & UART_LSR_THRE;
}

static inline u8 rx_ready(void)
{
	return ioread8(drvdata->port_ptr + UART_LSR) & UART_LSR_DR;
}

/*
 *	tasklet section
 *
 *	template function for deferred call in interrupt context
 */


static void ldt_tasklet_func(unsigned long d)
{
	char data_out, data_in;

	if (drvdata->uart_detected) {
		while (tx_ready() && kfifo_out_spinlocked(&drvdata->out_fifo,
					&data_out, sizeof(data_out),
					&drvdata->fifo_lock)) {
			wake_up_interruptible(&drvdata->writeable);
			pr_debug("data_out=%d %c\n", data_out, data_out >= 32 ? data_out : ' ');
			ldt_send(data_out);
		}
		while (rx_ready()) {
			data_in = ioread8(drvdata->port_ptr + UART_RX);
			pr_debug("data_in=%d %c\n", data_in, data_in >= 32 ? data_in : ' ');
			ldt_received(data_in);
		}
	} else {
		while (kfifo_out_spinlocked(&drvdata->out_fifo,
					&data_out, sizeof(data_out),
					&drvdata->fifo_lock)) {
			wake_up_interruptible(&drvdata->writeable);
			pr_debug("data_out=%d\n", data_out);
			ldt_send(data_out);
		}
	}
}

static DECLARE_TASKLET(ldt_tasklet, ldt_tasklet_func, 0);

/*
 *	interrupt section
 */

static int isr_counter;

static irqreturn_t ldt_isr(int irq, void *dev_id)
{
	/*
	 *      UART interrupt is not fired in loopback mode,
	 *      therefore fire ldt_tasklet from timer too
	 */
	isr_counter++;
	pr_debug("UART_FCR=0x%02X\n", ioread8(drvdata->port_ptr + UART_FCR));
	pr_debug("UART_IIR=0x%02X\n", ioread8(drvdata->port_ptr + UART_IIR));
	tasklet_schedule(&ldt_tasklet);
	return IRQ_HANDLED;	/* our IRQ */
}

/*
 *	timer section
 */

static struct timer_list ldt_timer;

static void ldt_timer_func(unsigned long data)
{
	/*
	 *      this timer is used just to fire ldt_tasklet,
	 *      because there is no interrupts in loopback mode
	 */
	if (loopback)
		tasklet_schedule(&ldt_tasklet);
	mod_timer(&ldt_timer, jiffies + HZ / 100);
}

static DEFINE_TIMER(ldt_timer, ldt_timer_func, 0, 0);

/*
 *	file_operations section
 */

static int ldt_open(struct inode *inode, struct file *file)
{
	pr_debug("from %s\n", current->comm);
	/* client related data can be allocated here and
	   stored in file->private_data */
	return 0;
}

static int ldt_release(struct inode *inode, struct file *file)
{
	pr_debug("from %s\n", current->comm);
	/* client related data can be retrived from file->private_data
	   and released here */
	return 0;
}

static ssize_t ldt_read(struct file *file, char __user *buf,
		size_t count, loff_t *ppos)
{
	int ret = 0;
	unsigned int copied;

	pr_debug("from %s\n", current->comm);
	if (kfifo_is_empty(&drvdata->in_fifo)) {
		if (file->f_flags & O_NONBLOCK) {
			return -EAGAIN;
		} else {
			pr_debug("waiting\n");
			ret = wait_event_interruptible(drvdata->readable,
					!kfifo_is_empty(&drvdata->in_fifo));
			if (ret == -ERESTARTSYS) {
				pr_err("%s\n", "interrupted");
				return -EINTR;
			}
		}
	}
	if (mutex_lock_interruptible(&drvdata->read_lock))
		return -EINTR;
	ret = kfifo_to_user(&drvdata->in_fifo, buf, count, &copied);
	mutex_unlock(&drvdata->read_lock);
	return ret ? ret : copied;
}

static ssize_t ldt_write(struct file *file, const char __user *buf,
		size_t count, loff_t *ppos)
{
	int ret;
	unsigned int copied;

	pr_debug("from %s\n", current->comm);
	if (kfifo_is_full(&drvdata->out_fifo)) {
		if (file->f_flags & O_NONBLOCK) {
			return -EAGAIN;
		} else {
			ret = wait_event_interruptible(drvdata->writeable,
					!kfifo_is_full(&drvdata->out_fifo));
			if (ret == -ERESTARTSYS) {
				pr_err("%s\n", "interrupted");
				return -EINTR;
			}
		}
	}
	if (mutex_lock_interruptible(&drvdata->write_lock))
		return -EINTR;
	ret = kfifo_from_user(&drvdata->out_fifo, buf, count, &copied);
	mutex_unlock(&drvdata->write_lock);
	tasklet_schedule(&ldt_tasklet);
	return ret ? ret : copied;
}

static unsigned int ldt_poll(struct file *file, poll_table *pt)
{
	unsigned int mask = 0;
	poll_wait(file, &drvdata->readable, pt);
	poll_wait(file, &drvdata->writeable, pt);

	if (!kfifo_is_empty(&drvdata->in_fifo))
		mask |= POLLIN | POLLRDNORM;
	mask |= POLLOUT | POLLWRNORM;
/*
	if case of output end of file set
	mask |= POLLHUP;
	in case of output error set
	mask |= POLLERR;
*/
	return mask;
}

/*
 *	pages_flag - set or clear a flag for sequence of pages
 *
 *	more generic solution instead SetPageReserved, ClearPageReserved etc
 *
 *	Poposing to move pages_flag to linux/page-flags.h
 */

static void pages_flag(struct page *page, int page_num, int mask, int value)
{
	for (; page_num; page_num--, page++)
		if (value)
			__set_bit(mask, &page->flags);
		else
			__clear_bit(mask, &page->flags);
}

static int ldt_mmap(struct file *filp, struct vm_area_struct *vma)
{
	void *buf = NULL;
	if (vma->vm_flags & VM_WRITE)
		buf = drvdata->in_buf;
	else if (vma->vm_flags & VM_READ)
		buf = drvdata->out_buf;
	if (!buf)
		return -EINVAL;
	if (remap_pfn_range(vma, vma->vm_start, virt_to_phys(buf) >> PAGE_SHIFT,
			    vma->vm_end - vma->vm_start, vma->vm_page_prot)) {
		pr_err("%s\n", "remap_pfn_range failed");
		return -EAGAIN;
	}
	return 0;
}

#define trace_ioctl(nr) pr_debug("ioctl=(%c%c %c #%i %i)\n", \
	(_IOC_READ & _IOC_DIR(nr)) ? 'r' : ' ', \
	(_IOC_WRITE & _IOC_DIR(nr)) ? 'w' : ' ', \
	_IOC_TYPE(nr), _IOC_NR(nr), _IOC_SIZE(nr))

static DEFINE_MUTEX(ioctl_lock);

static long ldt_ioctl(struct file *f, unsigned int cmnd, unsigned long arg)
{
	int ret = 0;
	void __user *user = (void __user *)arg;

	if (mutex_lock_interruptible(&ioctl_lock))
		return -EINTR;
	pr_debug("%s:\n", __func__);
	pr_debug("cmnd=0x%X\n", cmnd);
	pr_debug("arg=0x%lX\n", arg);
	trace_ioctl(cmnd);
	switch (_IOC_TYPE(cmnd)) {
	case 'A':
		switch (_IOC_NR(cmnd)) {
		case 0:
			if (_IOC_DIR(cmnd) == _IOC_WRITE) {
				if (copy_from_user(drvdata->in_buf, user,
							_IOC_SIZE(cmnd))) {
					ret = -EFAULT;
					goto exit;
				}
				/* copy data from in_buf to out_buf to emulate loopback for testing */
				memcpy(drvdata->out_buf, drvdata->in_buf, bufsize);
				memset(drvdata->in_buf, 0, bufsize);
			}
			if (_IOC_DIR(cmnd) == _IOC_READ) {
				if (copy_to_user(user, drvdata->out_buf,
							_IOC_SIZE(cmnd))) {
					ret = -EFAULT;
					goto exit;
				}
				memset(drvdata->out_buf, 0, bufsize);
			}
			break;
		}
		break;
	}
exit:
	mutex_unlock(&ioctl_lock);
	return ret;
}


static const struct file_operations ldt_fops = {
	.owner	= THIS_MODULE,
	.open	= ldt_open,
	.release = ldt_release,
	.read	= ldt_read,
	.write	= ldt_write,
	.poll	= ldt_poll,
	.mmap	= ldt_mmap,
	.unlocked_ioctl	= ldt_ioctl,
};

static struct miscdevice ldt_miscdev = {
	.minor	= MISC_DYNAMIC_MINOR,
	.name	= KBUILD_MODNAME,
	.fops	= &ldt_fops,
};

/*
 *	UART initialization section
 */

static struct resource *port_r;

static int uart_probe(void)
{
	int ret = 0;

	if (port) {
		/*
		   port_r = request_region(port, port_size, KBUILD_MODNAME);
		   if (!port_r) {
		   pr_err("%s\n", "request_region failed");
		   return -EBUSY;
		   }
		 */
		drvdata->port_ptr = ioport_map(port, port_size);
		pr_debug("drvdata->port_ptr=%p\n", drvdata->port_ptr);
		if (!drvdata->port_ptr) {
			pr_err("%s\n", "ioport_map failed");
			return -ENODEV;
		}
	}
	if (!irq || !drvdata->port_ptr)
		goto exit;
	/*
	 *	Minimal configuration of UART for trivial I/O opertaions
	 *	and ISR just to porform basic tests.
	 *	Some configuration of UART is not touched and reused.
	 *
	 *	This minimal configiration of UART is based on
	 *	full UART driver drivers/tty/serial/8250/8250.c
	 */
	ret = request_irq(irq, ldt_isr,
			IRQF_SHARED, KBUILD_MODNAME, THIS_MODULE);
	if (ret < 0) {
		pr_err("%s\n", "request_irq failed");
		return ret;
	}
	iowrite8(UART_MCR_RTS | UART_MCR_OUT2 | UART_MCR_LOOP,
			drvdata->port_ptr + UART_MCR);
	drvdata->uart_detected = (ioread8(drvdata->port_ptr + UART_MSR) & 0xF0)
		== (UART_MSR_DCD | UART_MSR_CTS);

	if (drvdata->uart_detected) {
		iowrite8(UART_IER_RDI | UART_IER_RLSI | UART_IER_THRI,
				drvdata->port_ptr + UART_IER);
		iowrite8(UART_MCR_DTR | UART_MCR_RTS | UART_MCR_OUT2,
				drvdata->port_ptr + UART_MCR);
		iowrite8(UART_FCR_ENABLE_FIFO | UART_FCR_CLEAR_RCVR | UART_FCR_CLEAR_XMIT,
				drvdata->port_ptr + UART_FCR);
		pr_debug("loopback=%d\n", loopback);
		if (loopback)
			iowrite8(ioread8(drvdata->port_ptr + UART_MCR) | UART_MCR_LOOP,
					drvdata->port_ptr + UART_MCR);
	}
	if (!drvdata->uart_detected && loopback)
		pr_warn("Emulating loopback in software\n");
exit:
	return ret;
}

/*
 *	main initialization and cleanup section
 */

static struct dentry *debugfs;

static void ldt_cleanup(void)
{
	debugfs_remove(debugfs);
	if (ldt_miscdev.this_device)
		misc_deregister(&ldt_miscdev);
	del_timer(&ldt_timer);
	if (irq) {
		if (drvdata->uart_detected) {
			iowrite8(0, drvdata->port_ptr + UART_IER);
			iowrite8(0, drvdata->port_ptr + UART_FCR);
			iowrite8(0, drvdata->port_ptr + UART_MCR);
			ioread8(drvdata->port_ptr + UART_RX);
		}
		free_irq(irq, THIS_MODULE);
	}
	tasklet_kill(&ldt_tasklet);
	if (drvdata->in_buf) {
		pages_flag(virt_to_page(drvdata->in_buf), PFN_UP(bufsize), PG_reserved, 0);
		free_pages_exact(drvdata->in_buf, bufsize);
	}
	if (drvdata->out_buf) {
		pages_flag(virt_to_page(drvdata->out_buf), PFN_UP(bufsize), PG_reserved, 0);
		free_pages_exact(drvdata->out_buf, bufsize);
	}

	pr_debug("isr_counter=%d\n", isr_counter);
	if (drvdata->port_ptr)
		ioport_unmap(drvdata->port_ptr);
	if (port_r)
		release_region(port, port_size);
	kfree(drvdata);
}

static struct ldt_data *ldt_data_init(void)
{
	struct ldt_data *drvdata;

	drvdata = kzalloc(sizeof(*drvdata), GFP_KERNEL);
	if (!drvdata)
		return NULL;
	init_waitqueue_head(&drvdata->readable);
	init_waitqueue_head(&drvdata->writeable);
	INIT_KFIFO(drvdata->in_fifo);
	INIT_KFIFO(drvdata->out_fifo);
	mutex_init(&drvdata->read_lock);
	mutex_init(&drvdata->write_lock);
	return drvdata;
}

static __devinit int ldt_init(void)
{
	int ret = 0;

	pr_debug("MODNAME=%s\n", KBUILD_MODNAME);
	pr_debug("port = %d irq = %d\n", port, irq);

	drvdata = ldt_data_init();
	if (!drvdata) {
		pr_err("ldt_data_init failed\n");
		goto exit;
	}

	/*
	 *	Allocating buffers and pinning them to RAM
	 *	to be mapped to user space in ldt_mmap
	 */
	drvdata->in_buf = alloc_pages_exact(bufsize, GFP_KERNEL | __GFP_ZERO);
	if (!drvdata->in_buf) {
		ret = -ENOMEM;
		goto exit;
	}
	pages_flag(virt_to_page(drvdata->in_buf), PFN_UP(bufsize), PG_reserved, 1);
	drvdata->out_buf = alloc_pages_exact(bufsize, GFP_KERNEL | __GFP_ZERO);
	if (!drvdata->out_buf) {
		ret = -ENOMEM;
		goto exit;
	}
	pages_flag(virt_to_page(drvdata->out_buf), PFN_UP(bufsize), PG_reserved, 1);
	isr_counter = 0;
	/*
	 *	This drivers without UART can be sill used
	 *	in emulation mode for testing and demonstation of work
	 */
	ret = uart_probe();
	if (ret < 0) {
		pr_err("uart_probe failed\n");
		goto exit;
	}
	mod_timer(&ldt_timer, jiffies + HZ / 10);
	debugfs = debugfs_create_file(KBUILD_MODNAME, S_IRUGO, NULL, NULL, &ldt_fops);
	if (IS_ERR(debugfs)) {
		ret = PTR_ERR(debugfs);
		pr_err("debugfs_create_file failed\n");
		goto exit;
	}
	ret = misc_register(&ldt_miscdev);
	if (ret < 0) {
		pr_err("misc_register failed\n");
		goto exit;
	}
	pr_debug("ldt_miscdev.minor=%d\n", ldt_miscdev.minor);

exit:
	pr_debug("ret=%d\n", ret);
	if (ret < 0)
		ldt_cleanup();
	return ret;
}

module_init(ldt_init);
module_exit(ldt_cleanup);

MODULE_DESCRIPTION("LDT - Linux Driver Template");
MODULE_AUTHOR("Constantine Shulyupin <const@makelinux.net>");
MODULE_LICENSE("GPL");
