---
layout: post
author: 'Jempty.liang'
title: "一个休眠唤醒失败的案例分享"
draft: true
license: "cc-by-nc-nd-4.0"
permalink: /str-failure-fixup/
description: "本文介绍了 Linux 系统一个休眠唤醒失败的案例。"
category:
  - 内核调试与跟踪
  - 功耗优化
tags:
  - STR
  - Suspend
  - Embedded Linux
  - 嵌入式 Linux
---

> By Jempty.liang of [TinyLab.org][1]
> Jan 22, 2021

## 休眠唤醒测试时休眠失败

大体情况：

* 内核：Linux 4.19
* 硬件：32bit ARM SOC
* 问题：某板子在休眠唤醒流程验证的过程中，休眠失败；
* 复现：`echo standby > /sys/power/state`

其中，异常日志如下：


    # echo standby > /sys/power/state
    PM: suspend entry (shallow)
    PM: Syncing filesystems ... done.
    Freezing user space processes ...
    Freezing of tasks failed after 20.003 seconds (1 tasks refusing to freeze, wq_busy=0):
    jempty_test    R runing task  ...
    [] (__schedule) from [] (preempt_schedule_common+0x1c/0x2c)
    [] (preempt_schedule_common) from [] (_cond_resched+0x34/0x48)
    [] (_cond_resched) from [] (jempty_msgctl_message_ioctl+0x76c/0x938)
    [] (jempty_msgctl_message_ioctl) from [] (vfs_ioctl+0x28/0x3c)
    [] (vfs_ioctl) from [] (do_vfs_ioctl+0x90/0x84c)
    [] (do_vfs_ioctl) from [] (ksys_ioctl+0x38/0x54)
    [] (ksys_ioctl) from [] (ret_fast_syscall+0x0/0x54)
    Exception stack (0x... to 0x...)
    ...
    oom killer enabled.
    Restarting tasks • • • done.
    PM: suspend exit

    sh: write error: Device or resource busy

## 休眠异常日志分析

好了，我们有了第一现场，开始分析问题：

### 根据现场 Log，找到出问题的代码位置

这里使用了 `gdb+vmlinux`，找到了异常代码的位置，也就是出错（`jempty_msgctl_message_ioctl+0x76c`）所在代码行。


    (gdb) list *(jempty_msgctl_message_ioctl+0x76c)
     0xc0407034 is in jempty_msgctl_message_ioctl (...:191)
     186             ret = -EFAULT;
     187            }
     188 else {
     189            spin_unlock_irqrestore(&tdev->read_lock, flags);
     190            if (tdev->block_read) {
     191                    wait_event_interruptible(tdev->read_waitq, s_mbox_data_ready);
     192                    goto re_read;
     193            } else {
     194                    rx_msg->len = 0;

异常位置在 Driver 中的第 191 行，这里该模块在等待另一个 CPU 核的中断唤醒它，即 `wake_up_interruptible`，唤醒以后进行下一步处理；所以此时该进程是陷入了内核态，并一直处于内核态，没有机会退出。

更多定位代码行位置的方法请阅读历史文章：[如何快速定位 Linux Panic 出错的代码行](http://tinylab.org/find-out-the-code-line-of-kernel-panic-address/)。

### 分析跟用户态进程唤醒相关的内核代码

关于休眠唤醒的全部流程就不细细分析了，这里仅分析该进程休眠失败的原因。

根据现场 Log 来看，这是进入 standby 失败的现场，导致 standby 失败的原因是进程(`jempty_test`)拒绝 freeze；这里需要进一步看一下 freeze 进程的 code，才能找到出现这个问题的具体原因，来到代码。

首先，对应的 call stack 是酱紫的：

    pm_suspend ->
        suspend_freeze_processes ->
            try_to_freeze_tasks->
                freeze_task（到这里进行本案的用户空间进程的冻结）

接下来分析 `try_to_freeze_tasks`。

```c
static int try_to_freeze_tasks(bool user_only)
{
    if (!user_only)   // 这里用来区别，是用户进程还是内核线程；
        freeze_workqueues_begin();
    while (true) {
        todo = 0;
        read_lock(&tasklist_lock);
        for_each_process_thread(g, p) {    // 遍历所有任务
            if (p == current || !freeze_task(p)) // 冻结除了本进程以外的其他进程
                continue;
            if (!freezer_should_skip(p))    // 执行到这块说明任务冻结失败
                                            // jempty_test 也执行到这块，todo++
                todo++;
        }
        read_unlock(&tasklist_lock);
        /*********/
        if (!todo || time_after(jiffies, end_time)) // 冻结完成所有进程或者超时退出
            break;
        /*********/
    }

    end = ktime_get_boottime();
    elapsed = ktime_sub(end, start);
    elapsed_msecs = ktime_to_ms(elapsed);

    if (todo) {  // todo 不为0，证明有进程冻结失败，dump 失败信息，jempty_test 就是在这里跪了
        pr_cont("\n");
        pr_err("Freezing of tasks %s after %d.%03d seconds "
               "(%d tasks refusing to freeze, wq_busy=%d):\n",
               wakeup ? "aborted" : "failed",
               elapsed_msecs / 1000, elapsed_msecs % 1000,
               todo - wq_busy, wq_busy);
        /*************/
    } else {
        pr_cont("(elapsed %d.%03d seconds) ", elapsed_msecs / 1000,
            elapsed_msecs % 1000);    // 所有进程冻结成功，并输出花费时间
    }
    return todo ? -EBUSY : 0;
}
```

接着分析 `freeze_task`：

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
    if (!(p->flags & PF_KTHREAD)) { // 至此，根据 flags 区别内核进程和用户进程
        fake_signal_wake_up(p);     // 用户空间进程冻结，jempty_test 执行这块
                                    // 发送一个虚假的信号去唤醒该进程
    } else {
        wake_up_state(p, TASK_INTERRUPTIBLE); // 内核空间进程冻结，不做分析
    }
    spin_unlock_irqrestore(&freezer_lock, flags);
    return true;
}
```

酱的话，进程 `jempty_test` 快要冻结了，但是还需要分析下 `fake_signal_wake_up`，那么 call stack 是：

    fake_signal_wake_up->
        signal_wake_up->
            signal_wake_up_state

然后分析 `signal_wake_up_state`：

```c
void signal_wake_up_state(struct task_struct *t, unsigned int state)
{
    set_tsk_thread_flag(t, TIF_SIGPENDING);  // 这里设置 SIGPENDING 标志位，
                                             // 说明该进程有延迟的信号要等待处理，
                                             // 当进程返回到用户空间的时候，
                                             // 会处理信号，进而 freeze 该进程
    /*
     * TASK_WAKEKILL also means wake it up in the stopped/traced/killable
     * case. We don't check t->state here because there is a race with it
     * executing another processor and just now entering stopped state.
     * By using wake_up_state, we ensure the process will wake up and
     * handle its death signal.
     */
    if (!wake_up_state(t, state | TASK_INTERRUPTIBLE)) { // 设置进程状态并唤醒
        kick_process(t);
    }
}
```

### 结论

到了这里的话，`jempty_test` 进程不能唤醒的原因已经大白于世了，由于 `jempty_test` 调用的驱动的原因，使得 `jempty_test` 长期陷入内核态，进程不能返回用户空间，去检查 `SIGPENDING`，导致该进程不能被 freeze；

## 提出解决方案

### Workaround

首先提出的 Workaround 方案是将 Driver 调用到的接口更改为 `wake_up_interruptible_timeout`，增加超时机制，使得调用该接口的用户进程有机会返回到用户空间，进而冻结该进程；


```
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
+                       rx_msg->len = 0;
+                       return 0;
                } else {
```

### Solution

（该节由本站编辑补充）

这里解决的关键应该是在代码休眠过程中确保 `wait_event_interruptible()` 的条件满足，不过按照当前实现，如果没有 mbox data 过来，条件肯定是没法满足。那是不是可以加一个条件呢，比如说判断是否正在休眠？类似这样：

```
-                       wait_event_interruptible(tdev->read_waitq, s_mbox_data_ready);
+                       wait_event_interruptible(tdev->read_waitq, in_suspend || s_mbox_data_ready);
```

当前普通 Linux 系统一般都是用户主动发起休眠，不会自动休眠，主动发起休眠以后，用户不再使用系统，这个时候用户态确实没必要再监测数据，所以，加个 `in_suspend` 判断是合理的，`in_suspend` 满足后程序退出数据监测。

更进一步地，驱动需要实现 `dev_pm_ops`，实现相应的 suspend 和 resume 函数，进行相应的休眠和恢复支持，这里可以用来简单的控制 `in_suspend` 状态的更新。而上层应用在唤醒后需要能够自动重启数据监控。

## 参考资料

* [如何快速定位 Linux Panic 出错的代码行](http://tinylab.org/find-out-the-code-line-of-kernel-panic-address/)
* [wait_event_interruptible() 与 wake_up_start() 学习笔记](http://blog.chinaunix.net/uid-29054367-id-3809059.html)
* [wait_event_interruptible() v.s. wake_up_interruptible()](https://stackoverflow.com/questions/19064177/wait-event-interruptible-vs-wake-up-interruptible)
* [进程冻结（freezing of task）](https://blog.csdn.net/rikeyone/article/details/103182748)
* [freezing-of-tasks.txt](https://www.kernel.org/doc/html/latest/power/freezing-of-tasks.html)
