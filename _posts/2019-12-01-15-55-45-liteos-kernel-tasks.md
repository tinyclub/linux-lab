---
layout: post
draft: true
top: false
author: 'Wang Chen'
title: "LiteOS 内核初探 - 任务管理"
group: translation
license: "cc-by-sa-4.0"
permalink: /liteos-kernel-tasks/
description: "简单介绍一下 Huawei LiteOS 内核的任务管理机制"
category:
  - LiteOS
tags:
  - LiteOS
  - Kernel
  - Task
---

## Huawei LiteOS 介绍

Huawei LiteOS 是华为（Huawei）面向 IoT 领域构建的轻量级（这也是为何起名叫 Lite 的原因）物联网操作系统，遵循 [BSD-3][5] 开源许可协议，可广泛应用于智能家居、个人穿戴、车联网、城市公共服务、制造业等领域，大幅降低设备的部署及维护成本，有效降低开发门槛、缩短开发周期。

注意 LiteOS 指的不仅仅是一个内核，而是一个完整的操作系统套件，具体的系统框架图可以参考下图：

![](/wp-content/uploads/2019/12/liteos-kernel-tasks/liteos-fw.png)
<center>图 1 - Huawei LiteOS 框架图</center>

完整的系统由一个内核（Kernel）和多个功能组件构成，在华为 LiteOS 的官方主页上，称这儿写功能组件为 LiteOS SDK。

和 Android 系统对比一下，Android 的内核使用了 Linux。

![](http://www.techdesignforums.com/edasource/images/68/esd1004_mentor1_large.jpg)
<center>图 2 - Google Android 框架图</center>

## LiteOS 的内核

LiteOS Kernel是 Huawei LiteOS 操作系统的基础内核，具备高实时性和高稳定性；体积超小，基础内核体积可以裁剪至不到 10K；内核运行功耗较低；而且整个 LiteOS 支持功能静态裁剪。

整个基础内核包括以下组件，见下图中的蓝色部分，可谓 “麻雀虽小，五脏俱全”。

![](https://liteos.github.io/assets/img/kernel-overview.2dda8ec3.png)
<center>图 3 - LiteOS 的内核</center>

本文主要介绍 LiteOS 内核的任务管理子系统，通过两个实验例子分别了解一下在 LiteOS 中如何创建任务，以及体验一下作为一个实时操作系统，LiteOS 对任务抢占的支持。

对工程的编译使用 LiteOS Studio，运行基于 BearPi 物联网开发套件。实验采用的工程代码和相关的环境搭建请参考另一篇文章 [图解 LiteOS 开发环境快速搭建][4]

## 实验一：为 LiteOS 创建任务

### 代码讲解

实验代码在原 “Cloud_STM32L431_BearPi” 工程的代码基础上修改，修改涉及工程目录（假设工程目录是 `D:\ws\iot-dev\`）下的 `targets\Cloud_STM32L431_BearPi\Src` 子目录下的 `main.c` 和 `user_task.c` 两个文件。

![](/wp-content/uploads/2019/12/liteos-kernel-tasks/files.png)
<center>图 4 - 实验涉及的源码文件</center>

先看一下 `user_task.c`，在这个文件中我们将定义用户任务并执行创建任务的动作。LiteOS 中的任务类似于 Linux 中线程的概念。所有任务共享系统资源。

第一步，先定义一个变量存放创建的任务的标识，在 LiteOS 中称之为任务句柄（Handler），本质上是一个无符号的 32 位整数：
```
static UINT32 g_demo_task;
```

第二步，定义任务的入口函数，每个任务对应一个入口函数，函数中执行该任务的具体工作。在这里演示的任务中每隔一段时间打印一句话以及一个自增变量 count 的值。

任务定期延时通过调用 [`LOS_TaskDelay()`][1] 系统函数实现，该函数参数的单位是 tick，即系统的周期时钟中断发生的间隔。

```
void demo_task_entry()
{
	int count = 1;
	while (1) {
		printf("This is DEMO task, count = %d \r\n", count++);
		
		/* 延迟 1000 个 Tick */
		LOS_TaskDelay(1000);
	}
}
```

第三步，我们定义一个函数 `create_demo_tasks()` 实现任务的创建，代码如下：

```
UINT32 create_demo_tasks()
{
	UINT32 uwRet = LOS_OK;
	
	TSK_INIT_PARAM_S task_init_param  = {0};
	
	task_init_param.usTaskPrio = 0;
	task_init_param.pcName = "task";
	task_init_param.pfnTaskEntry = (TSK_ENTRY_FUNC)demo_task_entry;
	task_init_param.uwStackSize = 0x200;
	
	uwRet = LOS_TaskCreate(&g_demo_task, &task_init_param);
	if (LOS_OK != uwRet) {
		return LOS_NOK;
	}
	
	return uwRet;
}
```

其中核心代码是调用了一个系统函数 [`LOS_TaskCreate()`][2]。这个函数有两个参数。

第一个参数在函数执行成功后传回来创建的任务标识符；

第二个参数用于在创建任务时设置任务的相关参数，具体值通过一个类型为 [`TSK_INIT_PARAM_S`][3] 的结构体变量进行设置，该结构体类型包含多个成员，这里的代码示例中只设置了其中的四项：
- usTaskPrio：任务优先级，类型是一个整数，LiteOS 任务优先级最高为 0，最低为 31。
- pcName：任务名称，类型是一个字符串。
- pfnTaskEntry：任务入口函数，设置为第二步中我们定义的函数名 `demo_task_entry`，即该函数的地址。 
- uwStackSize：任务使用栈空间大小。

以上工作做好后，我们就可以转到 `main.c` 中，在 `main()` 函数中添加对 `create_demo_tasks()` 的调用完成实际的任务创建工作即可，注意添加的位置必须是在 `LOS_KernelInit()` 之后，`LOS_Start()` 之前。以下为代码示意（省略的代码用 `......` 表示）：

```
int main(void)
{
    ......
    uwRet = LOS_KernelInit();
    ......

    extern UINT32 create_demo_tasks(VOID);
    uwRet = create_demo_tasks();
    ......

    (void)LOS_Start();
    return 0;
}
```

### 运行实验

参考 [图解 LiteOS 开发环境快速搭建][4] 的 “3.4 编译 LiteOS Studio 工程” 和 “3.5 烧录 LiteOS Studio 工程” 将程序编译好并下载到开发板上即可运行。参考 “3.6 调试 LiteOS Studio 工程” 设置好串口后就可以在串口终端中观察到程序的打印输出如下：

![](/wp-content/uploads/2019/12/liteos-kernel-tasks/lab1-output.png)
<center>图 5 - 实验一的输出</center>

## 实验二、LiteOS 的多任务抢占

引入操作系统的最大有点就是可以创建任务并对任务按照优先级进行管理，高优先级任务可以抢占低优先级任务，确保整个系统可以在第一时间内优先完成 “最紧急” 的工作。

我们在实验一的基础上稍加改进，创建两个任务，并对它们设置不同的优先级，观察高优先级的任务是否会被优先执行。

主要的修改集中在 `user_task.c` 这个文件。

第一步，先定义两个变量分别用于存放创建的两个任务的标识：
```
static UINT32 g_demo_task_1;
static UINT32 g_demo_task_2;
```

第二步，定义任务的入口函数。两个任务实现的功能类似，以任务 1 为例，循环打印 "Task 1 is running"，但注意这里没有采用 [`LOS_TaskDelay()`][1] 实现延时，而是直接使用死循环的方式避免打印过于频繁，主要原因是因为 [`LOS_TaskDelay()`][1] 会导致任务主动放弃处理器，无法凸显高优先级任务抢占处理器的效果。具体代码如下：

```
static void demo_task_entry_1()
{
	UINT32 i;
	for (;;) {
		printf("Task 1 is running\r\n");
		for (i = 0; i < TASK_LOOP_COUNT; i++) {
			/* 占用 CPU 耗时运行 */
		}
	}
}
```

第三步，定义函数 `create_demo_tasks()` 实现任务的创建，具体代码不再赘述，和实验一类似，唯一的区别是这里调用 [`LOS_TaskCreate()`][2] 两次分别创建两个任务，同时对这两个任务设置不同的优先级，其中任务 1 的优先级设置为 0，任务 2 的优先级设置为 1。由于 LiteOS 中优先级的值越小其优先级越高，优先级最高为 0，最低为 31，所以这里任务 1 相对于任务 2 为高优先级，也就是说任务 1 会抢占任务 2。示意代码如下（省略的代码用 `......` 表示）：

```
#define TASK_PRIO_1 0
#define TASK_PRIO_2 1
......

UINT32 create_demo_tasks()
{
	......
	
	task_init_param.usTaskPrio = TASK_PRIO_1;
	......
	
	uwRet = LOS_TaskCreate(&g_demo_task_1, &task_init_param);
	......	
	
	task_init_param.usTaskPrio = TASK_PRIO_2;
	......
	
	uwRet = LOS_TaskCreate(&g_demo_task_2, &task_init_param);
	......
		
	return uwRet;
}
```

编译后烧录再执行，串口输出如下，我们看不到任务 2 的输出，只有任务 1 的输出，也就是说低优先级的任务得不到机会执行，被高优先级的任务抢占了。

![](/wp-content/uploads/2019/12/liteos-kernel-tasks/lab2-output-1.png)
<center>图 6 - 实验二的输出 1</center>

继续尝试，将两个任务的优先级设置为相同，如下：

```
#define TASK_PRIO_1 0
#define TASK_PRIO_2 0
```

此时我们发现两个任务都得到了执行的机会，输出如下。

![](/wp-content/uploads/2019/12/liteos-kernel-tasks/lab2-output-2.png)
<center>图 7 - 实验二的输出 2</center>

[1]: https://liteos.github.io/api-reference/a00068_gc7ab8061ace7abbd5a885bc6004aaf57.html#gc7ab8061ace7abbd5a885bc6004aaf57
[2]: https://liteos.github.io/api-reference/a00068_g0b1786be9a0f359ccc92786ba0079fc3.html#g0b1786be9a0f359ccc92786ba0079fc3
[3]: https://liteos.github.io/api-reference/a00022.html
[4]: https://tinylab.org/liteos-env-setup/
[5]: http://opensource.org/licenses/BSD-3-Clause