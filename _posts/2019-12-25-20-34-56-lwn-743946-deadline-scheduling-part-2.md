---
layout: post
draft: true
author: 'Wang Chen'
title: "LWN 743946: Deadline 调度介绍的第二部分：细节和使用"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-743946/
description: "LWN 中文翻译，Deadline 调度介绍的第二部分：细节和使用"
category:
  - 进程调度
  - LWN
tags:
  - Linux
  - scheduling
  - deadline
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[Deadline scheduler part 2 — details and usage](https://lwn.net/Articles/743946/)
> 原创：By Daniel Bristot de Oliveira @ Jan. 19, 2018
> 翻译：By [unicornx](https://github.com/unicornx)
> 校对：By [xxx](https://github.com/xxx)

> Linux’s deadline scheduler is a global early deadline first scheduler for sporadic tasks with constrained deadlines. These terms were defined in [the first part of this series](https://lwn.net/Articles/743740/). In this installment, the details of the Linux deadline scheduler and how it can be used will be examined.

Linux 内核的 Deadline 调度器是一个全局的（global，译者注：指的是这个调度器同时控制任务在多个处理器上运行）、基于 “最早期限优先（Early Deadline First，简称 EDF）” 算法实现的调度器，它主要针对有 “受限期限（constrained deadline）” 的 “离散型（sporadic）” 任务。注意以上涉及的术语已经在 [本系列文章的第一部分][1] 中加以说明，所以这里不再赘述。本文我们将一起来看看 Linux 的 Deadline 调度器的实现细节以及我们应该如何使用它。

> The deadline scheduler prioritizes the tasks according to the task’s job deadline: the earliest absolute deadline first. For a system with ***M*** processors, the ***M*** earliest deadline jobs will be selected to run on the ***M*** processors.

Deadline 调度器基于任务的 “截止时间（deadline）” 来确定任务调度的优先顺序：最早到期的那个任务最先被调度执行。对于有 ***M*** 个处理器的系统，“截止时间（deadline）” 最早到期的前 ***M*** 个任务将被选中并安排在 ***M*** 个处理器上运行。

> The Linux deadline scheduler also implements the constant bandwidth server (CBS) algorithm, which is a resource-reservation protocol. CBS is used to guarantee that each task will receive its full run time during every period. At every activation of a task, the CBS replenishes the task’s run time. As the job runs, it consumes that time; if the task runs out, it will be throttled and descheduled. In this case, the task will be able to run only after the next replenishment at the beginning of the next period. Therefore, CBS is used to both guarantee each task’s CPU time based on its timing requirements and to prevent a misbehaving task from running for more than its run time and causing problems to other jobs.

Linux 的 Deadline 调度器还实现了 “恒定带宽服务（Constant Bandwidth Server，下文简称 CBS）” 算法，用于实现对 CPU 资源的预留。CBS 可以保证每个任务在它的每一个 “周期（period）” 内都能享有完整的 “运行时间（run time）”。在每个周期内，当任务被激活的时候，内核会依据 CBS 算法对该任务的运行时间配额重新进行补充。任务运行期间会不断消耗这个配额；当配额用完时，该任务就会被调度器调度出局。也就是说，该任务只能等到下一个周期到来时其配额值才能获得补充从而能够继续运行。因此，CBS 算法一方面保证了每个任务能根据其实际需要获得必要的运行时间，另外一方面，也保证不会因为单个任务异常消耗了过多的 CPU 时间而对其他任务的运行造成影响。

> In order to avoid overloading the system with deadline tasks, the deadline scheduler implements an acceptance test, which is done every time a task is configured to run with the deadline scheduler. This test guarantees that deadline tasks will not use more than the maximum amount of the system's CPU time, which is specified using the `kernel.sched_rt_runtime_us` and `kernel.sched_rt_period_us` sysctl knobs. The default values are 950000 and 1000000, respectively, limiting realtime tasks to 950,000µs of CPU time every 1s of wall-clock time. For a single-core system, this test is both necessary and sufficient. It means that the acceptance of a task guarantees that the task will be able to use all the run time allocated to it before its deadline.

为了避免 deadline 任务过多导致系统超负荷运行，Deadline 调度器实现了一个任务准入机制，每当我们向 Deadline 调度器提交一个任务时，调度器都会对该任务进行评估和检查。这种准入检查机制保证了这些 Deadline 任务对 CPU 时间的使用不会超过系统允许的上限。这个最大值通过 `kernel.sched_rt_runtime_us` 和 `kernel.sched_rt_period_us` （ （译者注：即 `/proc/sys/kernel/sched_rt_runtime_us` 和 `/proc/sys/kernel/sched_rt_period_us`））进行设置。默认值分别是 950000 和 1000000，表示在 1s 的时间周期内（墙上时钟方式，即按实际流逝的时间计算），CPU 用于执行实时任务的最长时间值是 950000µs。对于单个核心的系统，这个检查既保证了必要性，也保证了充分性。这意味着：只要一个任务提交给 Deadline 调度器并检查通过，那么这个任务一定能够在其最后期限到期之前用完其运行时间配额。

> However, it is worth noting that this acceptance test is necessary, but not sufficient, for global scheduling on multiprocessor systems. As Dhall’s effect (described in the first part of this series) shows, the global deadline scheduler acceptance task is unable to schedule the task set even though there is CPU time available. Hence, the current acceptance test does not guarantee that, once accepted, the tasks will be able to use all the assigned run time before their deadlines. The best the current acceptance task can guarantee is bounded tardiness, which is a good guarantee for soft real-time systems. If the user wants to guarantee that all tasks will meet their deadlines, the user has to either use a partitioned approach or to use a necessary and sufficient acceptance test, defined by:

然而，值得注意的是，对于一个多处理器系统上的全局调度器来说，准入检查是必要的，但却不是充分的。Dhall 效应（具体请参考本系列 [第一篇文章][1] 的介绍）告诉我们对于一个全局 Deadline 调度器来说，在通过了准入检查的前提条件下，即使 CPU 还有富余，也不能保证所有任务的 deadline 需求得到满足。也就是说准入测试并不保证任务能够在 deadline 之前用完分配给它的 “运行时间（run time）”。对于被接受的 deadline 任务而言，调度器最多能做到的是 “有限延迟（bounded tardiness）”（译者注，即无论负载如何总可以将延迟维持在一个有限的范围内），对于软实时系统而言，这已经是一个不错的结果了。如果用户希望保证所有任务都能满足它们的最后期限，就必须使用分组（partition）的方法，或者使用下面这个既能确保必要性又能满足充分性的准入测试标准：

    Σ(WCETi / Pi) <= M - (M - 1) x Umax

> Or, expressed in words: the sum of the run time/period of each task should be less than or equal to the number of processors, minus the largest utilization multiplied by the number of processors minus one. It turns out that, the bigger Umax is, the less load the system is able to handle.

把上面的公式换成文字表达就是：所有任务的（运行时间除以周期）的总和应该小于或等于处理器的数目 M 减去最大的利用率 Umax 和（M - 1）的乘积。事实证明，Umax 越大，系统整体调度能力越差。

> In the presence of tasks with a big utilization, one good strategy is to partition the system and isolate some high-load tasks in a way that allows the small-utilization tasks to be globally scheduled on a different set of CPUs. Currently, the deadline scheduler does not enable the user to set the affinity of a thread, but it is possible to partition a system using control-group cpusets.

当存在某些高负载（译者注，指 CPU 使用率较高）的任务时，较好的处理策略是对任务全体进行 “分组（partition）”。（这里 partition 的意思是指）将那些高负载的任务独立出来分配到自己专有的 CPU 上运行，而对于其他那些 CPU 使用率不高的 “小” 任务则共享其他的 CPU。目前，Deadline 调度器不支持用户对单个线程设置所谓的 “亲和性（affinity）”（译者注，即将一个线程限定在某个处理器上运行），但我们可以利用 control-group 的 cpusets 来实现对系统任务进行 “分组（partition）”。

> For example, consider a system with eight CPUs. One big task has a utilization close to 90% of one CPU, while a set of many other tasks have a lower utilization. In this environment, one recommended setup would be to isolate CPU0 to run the high-utilization task while allowing the other tasks to run in the remaining CPUs. To configure this environment, the user must follow the following steps:

例如，考虑一个有八个 CPU 的系统。在所有需要调度的任务中，存在一个 “大” 任务，其单核条件下 CPU 的使用率接近 90%，其他任务的使用率都较低。在这种场景下，推荐进行如下设置：CPU0 运行那个 “大” 任务，其余的 CPU 运行剩下的其他任务。要达到这个目标，用户可以按以下步骤进行操作：

> 1. Enter in the cpuset directory and create two cpusets:

1. 首先进入 cpuset 目录，创建两个 cpuset（译者注，对应创建两个目录）：

```
    # cd /sys/fs/cgroup/cpuset/
    # mkdir cluster
    # mkdir partition
```

> 2. Disable load balancing in the root cpuset to create two new root domains in the CPU sets:

2. 关闭 root cpuset （即 `/sys/fs/cgroup/cpuset/` 所对应的 cpuset）的负载均衡（load balancing），从而让新创建的 cluster 和 partition 这两个子目录所对应的 cpuset 变成两个新的 root cpuset。

```
    # echo 0 > cpuset.sched_load_balance
```

> 3. Enter the directory for the cluster cpuset, set the CPUs available to 1-7, the memory node the set should run in (in this case the system is not NUMA, so it is always node zero), and set the cpuset to the exclusive mode.

3. 进入 cluster 目录，设置可用的 CPU 编号为 1-7；设置该 cpuset 使用的内存节点（memory node，因为例子中的系统不是 NUMA 类型的，因此内存节点值始终是 0）；并将 cpuset 设置为独占（exclusive）模式。

```
    # cd cluster/
    # echo 1-7 > cpuset.cpus
    # echo 0 > cpuset.mems
    # echo 1 > cpuset.cpu_exclusive 
```

> 4. Move all tasks to this CPU set

4. 将所有任务加入 cluster 这个 cpuset

```
    # ps -eLo lwp | while read thread; do echo $thread > tasks ; done
```

> 5. Then it is possible to start deadline tasks in this cpuset.

5. 然后可以在此 cpuset 中启动 deadline 任务。

> 6. Configure the partition cpuset:

6. 配置另一个 cpuset：partition：

```
    # cd ../partition/
    # echo 1 > cpuset.cpu_exclusive 
    # echo 0 > cpuset.mems 
    # echo 0 > cpuset.cpus
```

> 7. Finally move the shell to the partition cpuset.

7. 最后将 shell 这个任务加入到 partition 这个 cpuset。

```
    # echo $$ > tasks 
```

> 8. The final step is to run the deadline workload.

8. 最后一步是运行 deadline 任务。

> With this setup, the task isolated in the partitioned cpuset will not interfere with the tasks in the cluster cpuset, increasing the system’s maximum load while meeting the deadline of real-time tasks.

采用以上方式设置后，隔离在 partition 这个 cpuset 中的任务将不会干扰 cluster 这个 cpuset 中的任务，从而在满足实时任务的 deadline 要求的同时提高了系统的最大处理能力。

## 从（应用）开发者的角度看（The developer’s perspective）

> There are three ways to use the deadline scheduler: as constant bandwidth server, as a periodic/sporadic server waiting for an event, or with a periodic task waiting for replenishment. The most basic parameter for the sched deadline is the period, which defines how often a task is activated. When a task does not have an activation pattern, it is possible to use the deadline scheduler in an aperiodic mode by using only the CBS features.

有三种使用 Deadline 调度器（编写 deadline 任务）的方式：第一种是仅利用其提供的 CBS 功能，第二种是针对 “周期型（periodic）” 或者 “离散型（sporadic）” 的任务，通过等待事件触发方式驱动实际任务处理，第三种是针对 “周期型（periodic）” 任务，在运行时间配额补充完毕后执行其处理。使用 deadline 调度方式需要确定的最基本的参数是 “周期（period）”，该参数值定义了一个任务被激活执行其相应处理工作的频率。如果任务不存在周期激活模式，则只能以 “非周期性的（aperiodic）” 方式利用 Deadline 调度器所提供的 CBS 功能。

> In the aperiodic case, the best thing the user can do is to estimate how much CPU time a task needs in a given period of time to accomplish the expected result. For instance, if one task needs 200ms each second to accomplish its work, run time would be 200,000,000ns and the period would be 1,000,000,000ns. The [`sched_setattr()`][2] system call is used to set the deadline-scheduling parameters. The following code is a simple example of how to set the mentioned parameters in an application:

在 “非周期性（aperiodic）” 模式下，用户能做的也就是估计出给定周期内一个任务为达到预期结果需要消耗多少 CPU 时间。例如，如果一个任务每 1 秒中需要花费 200 毫秒才能完成其工作，则其 “运行时间（run time）” 就是 200,000,000ns，周期则为 1,000,000,000ns。可以使用 [`sched_setattr()`][2] 这个系统调用来设置 deadline 调度参数。以下代码简单演示了在应用程序中如何设置上述参数：

```
    int main (int argc, char **argv)
    {
        int ret;
        int flags = 0;
        struct sched_attr attr;

        memset(&attr, 0, sizeof(attr)); 
        attr.size = sizeof(attr);

        /* This creates a 200ms / 1s reservation */
        attr.sched_policy   = SCHED_DEADLINE;
        attr.sched_runtime  =  200000000;
        attr.sched_deadline = attr.sched_period = 1000000000;

        ret = sched_setattr(0, &attr, flags);
        if (ret < 0) {
            perror("sched_setattr failed to set the priorities");
            exit(-1);
        }

        do_the_computation_without_blocking();
        exit(0);
    }
```

> In the aperiodic case, the task does not need to know when a period starts, and so the task just needs to run, knowing that the scheduler will throttle the task after it has consumed the specified run time.

在 “非周期性（aperiodic ）” 情况下，任务不需要关心周期的开始时间，它只管自己运行就好了，反正在该任务消耗完分配给它的 “运行时间（run time）” 之后，Deadline 调度器就会暂时收回它对 CPU 的使用权（throttling ）。

> Another use case is to implement a periodic task which starts to run at every periodic run-time replenishment, runs until it finishes its processing, then goes to sleep until the next activation. Using the parameters from the previous example, the following code sample uses the [`sched_yield()`][3] system call to notify the scheduler of end of the current activation. The task will be awakened by the next run-time replenishment. Note that the semantics of `sched_yield()` are a bit different for deadline tasks; they will not be scheduled again until the run-time replenishment happens.

另一个使用场景是实现一个 “周期性（periodic）” 的任务，每隔一个固定的周期，一旦获得内核为其补充的运行时间配额后该任务就可以开始运行，直到完成其处理工作，然后进入睡眠态直到下一次被激活。在上个例子代码的基础上，以下代码演示如何使用 [`sched_yield()`][3] 这个系统调用来通知调度器本次运行结束。下一次补充完运行时间配额后该任务将会被再次唤醒。需要注意的是，对于 deadline 型的任务，`sched_yield()` 函数实现的语义有所不同。任务只会在其运行时间配额补充完毕后才会被实际调度运行。

> Code working in this mode would look like the example above, except that the actual computation looks like:

在这种模式下的实现代码和上面的例子基本一致，除了实际的任务处理部分有所区别，如下所示（译者注，用以下代码替换了上面例子中的 `do_the_computation_without_blocking();` 语句）：

```
        for(;;) {
            do_the_computation();
            /* 
             * Notify the scheduler the end of the computation
             * This syscall will block until the next replenishment
             */
            sched_yield();
        }
```

> It is worth noting that the computation must finish within the given run time. If the task does not finish, it will be throttled by the CBS algorithm.

值得注意的是，计算部分（译者注，指上面代码例子中的 `do_the_computation()`）必须在给定的 “运行时间（run time）” 内完成。否则，同样地将受到调度器中 CBS 算法的限制（即 throttling 会起作用）。

> The most common realtime use case for the realtime task is to wait for an external event to take place. In this case, the task waits in a blocking system call. This system call will wake up the real-time task with, at least, a minimum interval between each activation. That is, it is a sporadic task. Once activated, the task will do the computation and provide the response. Once the task provides the output, the task goes to sleep by blocking waiting for the next event.

对于实时任务来说最常见的应用场景是等待一个外部事件发生（译者注，并对该事件做出响应处理）。在这种情况下，任务会阻塞在一个系统调用中。每隔一段时间（该间隔不会小于一个最小的时间段）任务将会被唤醒并从系统调用中退出。也就是说，该任务的运行模式是属于所谓的 “离散型（sporadic）” 任务。任务被激活后将执行相关计算来提供响应。处理完成后，任务重新阻塞等待下一次激活事件。

```
        for(;;) {
            /* 
             * Block in a blocking system call waiting for a data
             * to be processed.
             */
            process_the_data();
            produce_the_result()
            block_waiting_for_the_next_event();
        }
```

## 结论（Conclusion）

> The deadline scheduler is able to provide guarantees for realtime tasks based only in the task’s timing constraints. Although global multi-core scheduling faces Dhall’s effect, it is possible to configure the system to achieve a high load utilization using cpusets as a method to partition the systems. Developers can also benefit from the deadline scheduler by designing their application to interact with the scheduler, simplifying the control of the timing behavior of the task.

Deadline 调度器在对实时任务提供实时性保证时仅需要知道一个任务在执行时间上的限制。虽然在一个多核系统中，全局的 Deadline 调度器仍然避免不了 Dhall 效应，但我们可以通过对任务进行分组（partition）来解决这个问题，具体的做法是利用 cpusets 把 CPU 使用率高的任务分配到指定的 cpuset 里。Deadline 调度器提供的编程接口也很友好，开发人员可以调用函数和 Deadline 调度器进行交互，这简化了对任务运行时间行为的控制。

> The deadline scheduler tasks have a higher priority than realtime scheduler tasks. That means that even the highest fixed-priority task will be delayed by deadline tasks. Thus, deadline tasks do not need to consider interference from realtime tasks, but realtime tasks must consider interference from deadline tasks.

在 Linux 中，Deadline 任务比 Realtime 任务（译者注，指调度策略为 RR 和 FIFO 类型的实时任务）具有更高的优先级。这意味着即使是最高固定优先级的 Realtime 任务也会因为 Deadline 任务的运行而被延迟执行。换句话说，Deadline 任务是不用考虑来自 Realtime 任务的干扰的，但 Realtime 任务必须考虑 Deadline 任务的干扰。

> The deadline scheduler and the PREEMPT_RT patch play different roles in improving Linux’s realtime features. While the deadline scheduler allows scheduling tasks in a more predictable way, the PREEMPT_RT patch set improves the kernel by reducing and limiting the amount of time a lower-priority task can delay the execution of a realtime task. It works by reducing the amount of the time a processor runs with preemption and IRQs disabled and the amount of time in which a lower-priority task can delay the execution of a task by holding a lock.

Deadline 调度器和 PREEMPT_RT 补丁在改善 Linux 的实时性方面发挥着不同的作用。Deadline 调度器使得被调度的任务以一种更加可预期的方式运行，而 PREEMPT_RT 补丁的目标是减少和限制较低优先级的任务对实时任务的调度延迟。具体的做法是减少处理器上关中断和禁止抢占的时间以及一个低优先级任务由于持有锁而导致其他任务被延迟的时间。

> For example, as a realtime task can suffer an activation latency higher than 5ms when running in a non-realtime kernel, it is that this kernel cannot handle deadline tasks with deadlines shorter than 5ms. In contrast, the realtime kernel provides a guarantee, on well tuned and certified hardware, of not delaying the start of the highest priority task by more than 150µs, thus it is possible to handle realtime tasks with deadlines much shorter than 5ms. You can find more about the realtime kernel [here][4].

举个例子来说，当一个有实时性要求的任务运行在一个非实时内核上的时候（译者注，这里的非实时内核指的应该是没有应用 PREEMPT_RT 补丁的 Linux 原生内核），任务对激活事件响应的延迟本身就可能超过 5ms，也就是说该内核本身就无法处理 deadline 小于 5ms 的任务。相反，在实时内核的基础上，经过合理的调配以及使用满足要求的硬件后，一旦可以确保最高优先级任务的调度延迟都不会超过 150µs，那么再考虑支持 deadline 比 5ms 还小得多的实时任务也就更不是什么难事了（译者注，参考前文所述，在 Linux 中，Deadline 任务比 Realtime 任务具有更高的优先级）。更多有关实时内核的内容请参考 [这里][4]。

> Acknowledgment: this series of articles was reviewed and improved with comments from Clark Williams, Beth Uptagrafft, Arnaldo Carvalho de Melo, Luis Claudio R. Gonçalves, Oleksandr Natalenko, Jiri Kastner and Tommaso Cucinotta.

致谢：感谢 Clark Williams，Beth Uptagrafft，Arnaldo Carvalho de Melo，Luis Claudio R.Gonçalves，Oleksandr Natalenko，Jiri Kastner 和 Tommaso Cucinotta 对该系列文章的审阅和改进建议。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: /lwn-743740/
[2]: http://man7.org/linux/man-pages/man2/sched_setattr.2.html
[3]: http://man7.org/linux/man-pages/man2/sched_yield.2.html
[4]: http://developerblog.redhat.com/?p=425603&preview_id=425603&preview_nonce=28c03def3d&post_format=standard&preview=true
