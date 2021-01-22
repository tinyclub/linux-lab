

---
layout: post
author: 'Jempty.liang'
title: "一个休眠唤醒失败的案例分享"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /ply-intro/
description: "本文介绍了Linux系统一个休眠唤醒失败的案例。"
category:
  - STR调试与跟踪
tags:
  - STR
  - Embedded Linux
  - 嵌入式 Linux
---

> By Jempty.liang of [TinyLab.org][1]
> Jan 22, 2021

## 案情背景介绍
内核版本：4.19
硬件：32bit ARM SOC
举个栗子：公司确定了一个客户案子以后，在进行休眠唤醒流程验证的过程中，发现一个进程休眠失败的案例；
案情复现：echo standby > /sys/power/state
异常LOG：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20210122143506940.bmp?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM5MjA0NzAy,size_16,color_FFFFFF,t_70#pic_center)

## 问题分析
好了，我们有了第一现场，开始分析问题：
**第一步 根据第一现场的log，首先找到出问题的代码位置：**
这里我使用了gdb+vmlinux，找到的异常代码位置：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20210122143517443.bmp?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM5MjA0NzAy,size_16,color_FFFFFF,t_70#pic_center)

异常位置在driver中的第191行，此时的场景（这里涉及到一部分公司的业务，我就不赘述了）：emmmm，这里是在该模块在等待另一个CPU核的中断唤醒它，即wake_up_interruptible，唤醒以后进行下一步处理；所以此时该进程（即jempty_test）是陷入了内核态，并一直处于内核态，没有机会退出。

**第二步 分析跟用户态进程唤醒相关的内核代码**
关于休眠唤醒的全部流程我就不细细分析了，这也不是本文主题，想要了解全部细节的同学可以去网上搜索，详细的文章有很多，这里我们仅仅分析该进程休眠失败的原因；

根据现场log来看，这是进入standby失败的现场，导致standby失败的原因是进程jempty_test（PS:PID号为127）拒绝freeze；这里需要进一步看一下freeze进程的code，才能找到出现这个问题的具体原因，来到代码。

首先，对应的call stack是酱紫的：
	...->pm_suspend->...->suspend_freeze_processes->try_to_freeze_tasks->freeze_task（到这里进行本案的用户空间进程的冻结）
- 分析try_to_freeze_tasks
	

```c
static int try_to_freeze_tasks(bool user_only)
	{
		/****************/
		if (!user_only)		//这里用来区别，是用户进程还是内核线程；
			freeze_workqueues_begin();
		while (true) {
			todo = 0;
			read_lock(&tasklist_lock);
			for_each_process_thread(g, p) {	//遍历所有任务
				if (p == current || !freeze_task(p))	//冻结除了本进程以外的其他进程
					continue;
				if (!freezer_should_skip(p))	//执行到这块说明任务冻结失败
												//jempty_test也执行到这块，todo++
					todo++;
			}
			read_unlock(&tasklist_lock);
			/*********/
			if (!todo || time_after(jiffies, end_time)) //冻结完成所有进程或者超时退出
				break;
			/*********/
		}

		end = ktime_get_boottime();
		elapsed = ktime_sub(end, start);
		elapsed_msecs = ktime_to_ms(elapsed);

		if (todo) {	//todo不为0，证明有进程冻结失败，dump失败信息，jempty_test就是在这里跪了
			pr_cont("\n");
			pr_err("Freezing of tasks %s after %d.%03d seconds "
				   "(%d tasks refusing to freeze, wq_busy=%d):\n",
				   wakeup ? "aborted" : "failed",
				   elapsed_msecs / 1000, elapsed_msecs % 1000,
				   todo - wq_busy, wq_busy);
			/*************/
		} else {
			pr_cont("(elapsed %d.%03d seconds) ", elapsed_msecs / 1000,
				elapsed_msecs % 1000);	//所有进程冻结成功，并输出花费时间
		}
		return todo ? -EBUSY : 0;
	}
```
- 分析freeze_task
```c
bool freeze_task(struct task_struct *p)
	{
		/********/
		if (freezer_should_skip(p))
			return false;
		spin_lock_irqsave(&freezer_lock, flags);
		if (!freezing(p) || frozen(p)) {
			spin_unlock_irqrestore(&freezer_lock, flags);
			return false;
		}
		if (!(p->flags & PF_KTHREAD)) { //至此，根据flags区别内核进程和用户进程
			fake_signal_wake_up(p); 	//用户空间进程冻结，jempty_test执行这块
										//发送一个虚假的信号去唤醒该进程
		} else {
			wake_up_state(p, TASK_INTERRUPTIBLE);//内核空间进程冻结，不做分析
		}
		spin_unlock_irqrestore(&freezer_lock, flags);
		return true;
	}
```
酱的话，进程jempty_test快要冻结了，但是还需要分析下fake_signal_wake_up，那么call stack是：
fake_signal_wake_up->signal_wake_up->signal_wake_up_state
- 分析signal_wake_up_state
```c
void signal_wake_up_state(struct task_struct *t, unsigned int state)
	{
		set_tsk_thread_flag(t, TIF_SIGPENDING);  //这里设置SIGPENDING标志位，
												 //说明该进程有延迟的信号要等待处理，
												 //当进程返回到用户空间的时候，
												 //会处理信号，进而freeze该进程
		/*
		 * TASK_WAKEKILL also means wake it up in the stopped/traced/killable
		 * case. We don't check t->state here because there is a race with it
		 * executing another processor and just now entering stopped state.
		 * By using wake_up_state, we ensure the process will wake up and
		 * handle its death signal.
		 */
		if (!wake_up_state(t, state | TASK_INTERRUPTIBLE)) {	//设置进程状态并唤醒（发送核间中断）
			kick_process(t);
		}
	}
```
**第三步 结案**
到了这里的话，jempty_test进程不能唤醒的原因已经大白于世了，由于jempty_test调用的驱动的原因，使得jempty_test长期陷入内核态，进程不能返回用户空间，去检查SIGPENDING，导致该进程不能被freeze；
## 提出解决方案
根据上面的分析结果来看的话，通过wake_up_state可以发送核间中断（IPI），使得系统陷入中断处理程序，处理完成中断处理函数后，系统有机会返回用户态，并检查进程的signal pending的情况，这时进程就可以被冻结了；但是我们的Linux系统在这块的实现存在问题，这部分流程没有走通。如果先要解决这个问题的话，可以先提出一个workaround来暂时fix这个issue，至于wake_up_state唤醒的问题，后续我还会继续debug。
**更改driver中的接口（workaround）**
将driver调用到的接口更改为wake_up_interruptible_timeout，增加超时机制，使得调用该接口的用户进程有机会返回到用户空间，进而冻结该进程；
	

```handlebars
Author: jempty <jempty.liang@jempty.com.cn>
	Date:   Mon Nov 9 14:00:17 2020 +0800

		jempty-test:fix up standby issue.

	diff --git a/drivers/mailbox/jempty-msgctl.c b/drivers/mailbox/jempty-msgctl.c
	index d3415b0..dfc3ff1 100755
	--- a/drivers/mailbox/jempty-msgctl.c
	+++ b/drivers/mailbox/jempty-msgctl.c
	@@ -176,7 +176,6 @@ jempty_mu_read_shmem(struct jempty_msgctl_device *tdev, struct mu_transfer *rx_m
			s_mbox_data_ready = false;
			spin_unlock_irqrestore(&tdev->read_lock, flags);
	 */
	-re_read:
			spin_lock_irqsave(&tdev->read_lock, flags);
			if (!kfifo_is_empty(&tdev->recv_fifo[rx_msg->mu_id])) {
					size = kfifo_out(&tdev->recv_fifo[rx_msg->mu_id], 
	@@ -188,8 +187,9 @@ jempty_mu_read_shmem(struct jempty_msgctl_device *tdev, struct mu_transfer *rx_m
			} else {
					spin_unlock_irqrestore(&tdev->read_lock, flags);
					if (tdev->block_read) {
	-                       wait_event_interruptible(tdev->read_waitq, s_mbox_data_ready);
	-                       goto re_read;
	+                       wait_event_interruptible_timeout(tdev->read_waitq, s_mbox_data_ready, HZ * 5);
	+                       rx_msg->len = 0;	+            return 0;
					} else {
```

**其他问题**
	按照接口的说明的话，通过wake_up_state，执行完成核间中断，可以返回到用户空间，再去检查进程signal pending状态，但是我们的Linux系统并没有完成这个动作，很诡异；这一点，暂时还没找到原因，请大佬赐教。
## 参考资料
[1] https://blog.csdn.net/rikeyone/article/details/103182748
[2] http://tinylab.org/find-out-the-code-line-of-kernel-panic-address/
[3] kernel-4.19/Documentation/power/freezing-of-tasks.txt


