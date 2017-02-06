#include <linux/kthread.h>
#include <linux/module.h>

static DECLARE_COMPLETION(completion);

static int thread_sample(void *data)
{
	int ret = 0;
	allow_signal(SIGINT);
	while (!kthread_should_stop()) {
		ret = wait_for_completion_interruptible(&completion);
		if (ret == -ERESTARTSYS) {
			pr_debug("interrupted\n");
			return -EINTR;
		}
		/*
		   perform here a useful work in scheduler context
		 */
	}
	return ret;
}

static struct task_struct *thread;

static int thread_sample_init(void)
{
	int ret = 0;
	thread = kthread_run(thread_sample, NULL, "%s", KBUILD_MODNAME);
	if (IS_ERR(thread)) {
		ret = PTR_ERR(thread);
		goto exit;
	}
	complete(&completion);
exit:
	return ret;
}

static void thread_sample_exit(void)
{
	if (!IS_ERR_OR_NULL(thread)) {
		send_sig(SIGINT, thread, 1);
		kthread_stop(thread);
	}
}

module_init(thread_sample_init);
module_exit(thread_sample_exit);

MODULE_LICENSE("Dual BSD/GPL");
