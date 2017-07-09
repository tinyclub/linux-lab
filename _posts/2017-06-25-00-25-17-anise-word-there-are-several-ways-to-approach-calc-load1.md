---
layout: post
author: 'Chen Jie'
title: "“茴”字有几种写法：系统负载是怎样计算的？（一）"
# tagline: " 子标题，如果存在的话 "
# album: " 所属文章系列/专辑，如果有的话"
# group: " 默认为 original，也可选 translation, news, resume or jobs, 详见 _data/groups.yml"
permalink: /how-to-calc-load-and-part1/
description: "Load, CPU Utilization, Linux"
category:
  - Linux 内核
tags:
  - Linux
---

> By Chen Jie of [TinyLab.org][1]
> 2017-06-25 00:25:17

## 前言

> 简单说，机器学习中的 “机器” 就是统计模型，“学习” 就是用数据来拟合模型。
>
> 「[初探计算机视觉的三个源头、兼谈人工智能｜正本清源][2]」，_朱松纯（Song-Chun Zhu），加州大学洛杉矶分校 UCLA 统计学和计算机科学教授_

大数据时代，统计很重要。通过统计事件、定期采样，定量评估现在，对比过去，预测将来。

系统负载，以及 CPU 利用率，也是统计得到的指标。指标对实际的拟合情况分好与更好，比如在近月，大名鼎鼎的 Linux 系统调优专家 Brendan Gregg [对现有 CPU 利用率统计提出了质疑，言其误导用户][3]。

然而，诸如系统负载目下是如何统计的？—— “不就是个 C 实现的公式吗？” —— 这似乎是一个细究 “茴” 字有多少种写法的问题。

然而，吃掉一大块油腻腻新知识，不妨先从小处入手，追本溯源，知微见著。

本系列第一部分从 `/proc/loadavg`，来看该场景下的负载定义与计算。公式不是重点，内核常见的定点拟浮点会剐蹭下，而 tick 则成为浮光掠影般的沿途风景。

## /proc/loadavg

	# cat /proc/loadavg
	# 0.20 0.18 0.12 1/80 11206

- 前三个数代表过去 1 / 5 / 15 分钟内，所有处于 __就绪__（等待和使用 CPU 资源）和 __不可中断睡眠__（等待和使用 IO 资源）的平均任务数，即平均负载。
- “1/80” 表示当前 1 个 任务就绪，总共 80 个任务。
- “11206” 代表最近一次分配出的 process ID 是 11206。

背后的代码为 [loadavg_proc_show()][4]。其中逻辑在于：

1. 如何用 int 类型来编码 _一定精度的小数_ ？
2. 如何 printf 如上编码的小数？
3. 若要保留 n 位，如何四舍五入？

以上弎问题答案图示如下：

![image][5]

## 统计量 avenrun\[3\]

/proc/loadavg 内容来自全局统计量 avenrun\[3\]，后者在函数 [calc_global_load()][6]，由 全局变量 calc_load_tasks 计算而来，如下图所示：

![image][9]

若 kernel 允许进行浮点操作，则其计算公式为：

	/* 每 5 秒采样一次，1 分钟内的均值 */
	float avenrun_f[0] = avenrun_f[0] * e^(-5/60) + calc_load_tasks * (1.0 - e^(-5/60);

	/* 每 5 秒采样一次，5 分钟内的均值 */
	float avenrun_f[1] = avenrun_f[1] * e^(-5/300) + calc_load_tasks * (1.0 - e^(-5/300);

	/* 每 5 秒采样一次，15 分钟内的均值 */
	float avenrun_f[2] = avenrun_f[2] * e^(-5/900) + calc_load_tasks * (1.0 - e^(-5/900);

然而，为支持无 FPU 硬件，同时也避免污染 FPU context，kernel 采用定点模拟浮点，如下表：

<iframe src="/wp-content/uploads/2017/06/table-float-emul-in-calc_load.xhtml" frameborder="0" width="100%" scrolling="no"> </iframe>

> 对应代码位于函数 [calc_load()][8]。留意当 “active >= load”，会进行 “ceil” 形式的向上进位。

## 任务数（calc_load_tasks）来衡量负载

全局变量 calc_load_tasks 记录了处于 'R' 和 'DI' 状态的任务数：

- __Commit__: 每隔 5s，各个 CPU 以 delta 形式，上报给 calc_load_tasks
  - 每隔 5s 是通过在 tick 中比较 jiffies 和 `rq->calc_load_update` 做到的
  - 对应代码：[calc_global_load_tick()][7]
  - 下图例中，对应蓝色圆点
- __Sampling__: 每隔 5s，索引为 tick_do_timer_cpu 的 CPU 将 calc_load_tasks 累计入 avenrun\[3\]
  - 每隔 5s 是通过在 tick 中比较 jiffies 和 `calc_load_update` 做到的
  - 对应代码：[calc_global_load()][6]
  - 下图例中，对应蓝色三角

如下图所示：

![image][10]

> 进一步说明图中 “tick 处理”，分成俩维度：1) periodic tick 和 NOHZ；2）是否使用高精度 timer。其中 tickless 意味着 CPU idle 或仅有一个任务。
>
> 对其中细节感兴趣的，大家可以出门左转阅读蜗窝的[时间子系统系列][11]。特别是「[periodic tick][12]」、「[Tick Device layer综述][13]」和「[tick broadcast framework][14]」

## 拾遗：针对 nohz 的补丁

上文提到了间隔 5s 的 tick 中，更新 calc_load_tasks，并累计入 avenrun\[3\]。然而，处于 nohz 模式时，tick 不定期到达（dynamic tick），分为俩情形：

- __Patch commit__：当前 CPU 进入 nohz，将其原本要提交的 delta，存入 calc_load_idle[idx]
  - calc_load_idle\[2\] 是个 “double buffer”：“front buffer” 由 calc_load_idx 所指出。
  - 在 calc_global_load() →  [calc_load_fold_idle()][15] 中，“front buffer” 被消费（“front buffer” 清 0）
  - 在 calc_global_load() →  [calc_global_nohz()][16] 中，swap “front/back buffer”。
  - 对应代码：[calc_load_enter_idle()][17]
  - 退出 nohz 对应代码：[calc_load_exit_idle()][18] —— 主要是更新 `rq->calc_load_update`：取决于是否在 “10 ticks 的 sampling window” 内，或为 `calc_load_update + 5s`，或就是全局时间戳 `calc_load_update`。 
- __Patch sampling__：当全部 CPU 进入 nohz，采样间隔可能 >5s，即可能错过多个采样周期，需要一次性补回来：

<span/>

	/* code snippet in calc_global_nohz() */
	sample_window = READ_ONCE(calc_load_update);
	if (!time_before(jiffies, sample_window + 10)) {
		/*
		 * Catch-up, fold however many we are behind still
		 */
		delta = jiffies - sample_window - 10;
		n = 1 + (delta / LOAD_FREQ);

		active = atomic_long_read(&calc_load_tasks);
		active = active > 0 ? active * FIXED_1 : 0;

		avenrun[0] = calc_load_n(avenrun[0], EXP_1, active, n);
		avenrun[1] = calc_load_n(avenrun[1], EXP_5, active, n);
		avenrun[2] = calc_load_n(avenrun[2], EXP_15, active, n);

		WRITE_ONCE(calc_load_update, sample_window + n * LOAD_FREQ);
	}

留意补偿后，`calc_load_update` 须是个未来的时间戳，故而 n 计算中还有 “+ 1”。

在具体的“采样累计”算法上，要考虑 missing 的采样周期，这就是函数 calc_load_n()： 

	/*
	 * a1 = a0 * e + a * (1 - e)
	 *
	 * a2 = a1 * e + a * (1 - e)
	 *    = (a0 * e + a * (1 - e)) * e + a * (1 - e)
	 *    = a0 * e^2 + a * (1 - e) * (1 + e)
	 *
	 * a3 = a2 * e + a * (1 - e)
	 *    = (a0 * e^2 + a * (1 - e) * (1 + e)) * e + a * (1 - e)
	 *    = a0 * e^3 + a * (1 - e) * (1 + e + e^2)
	 *
	 *  ...
	 *
	 * an = a0 * e^n + a * (1 - e) * (1 + e + ... + e^n-1) [1]
	 *    = a0 * e^n + a * (1 - e) * (1 - e^n)/(1 - e)
	 *    = a0 * e^n + a * (1 - e^n)
	 *
	 * [1] application of the geometric series:
	 *
	 *              n         1 - x^(n+1)
	 *     S_n := \Sum x^i = -------------
	 *             i=0          1 - x
	 */	
	static unsigned long
	calc_load_n(unsigned long load, unsigned long exp,
	            unsigned long active, unsigned int n)
	{
		return calc_load(load, fixed_power_int(exp, n), active);
	}

函数头这个拉风的注释中，a0 为旧值，推导了补偿到 a1（a0 之后的一个 5s 周期），补偿到 a2（a0 之后两个周期），一直到 an（a0 之后 n 个周期）。

留意 an 推导中，`1 + e + ... + e^n-1 = 1 * (1 - e^n) / (1 - e)`，应用了等比数列求和公式（共 n 项，比值为 e，第一项为 e^0 == 1）。

最后，fixed_power_int() 是个浮点数 “整数次方” 的模拟：

	/* 计算 x^n 的值 */
	static unsigned long
	fixed_power_int(unsigned long x, unsigned int n)
	{
		unsigned long result = FIXED_1;

		if (n) {
			for (;;) {
				if (n & 1) {
					/* 
					 * 模拟浮点乘法，例如：
					 *  result = 0.21 * FIXED_1
					 *  x = 0.92 * FIXED_1
					 *  result * x = 0.21 * 0.92 * FIXED_1
					 *             = 0.21 FIXED_1 * 0.92 * FIXED_1 / FIXED_1
					 */
					result *= x;
					result += FIXED_1 / 2; /* 四舍五入 */
					result /= FIXED_1;
				}
				n >>= 1;
				if (!n)
					break;
				x *= x;
				x += FIXED_1 / 2; /* 四舍五入 */
				x /= FIXED_1;
			}
		}

		return result;
	}

留意循环中，`x^n == x^(n0 * 2^0 + n1 * 2^1 + ... nk * 2^k)`，其中 nk 取值 0 或 1 —— 即把 n 做二进制展开 —— 对于 “nk == 0” 项目，求和中跳过不累加，这就是“if (n & 1)”处的分支。

[1]: http://tinylab.org
[2]: http://www.sohu.com/a/119732356_505819
[3]: http://www.brendangregg.com/blog/2017-05-09/cpu-utilization-is-wrong.html
[4]: http://elixir.free-electrons.com/linux/v4.11/source/fs/proc/loadavg.c
[5]: /wp-content/uploads/2017/06/seq_printf_int_encoded_floatnumber.jpg
[6]: http://elixir.free-electrons.com/linux/v4.11/source/kernel/sched/loadavg.c#L355
[7]: http://elixir.free-electrons.com/linux/v4.11/source/kernel/sched/loadavg.c#L390
[8]: http://elixir.free-electrons.com/linux/v4.11/source/kernel/sched/loadavg.c#L101
[9]: /wp-content/uploads/2017/06/calc_global_load.jpg
[10]: /wp-content/uploads/2017/06/when-calc_global_load.jpg
[11]: http://www.wowotech.net/sort/timer_subsystem
[12]: http://www.wowotech.net/timer_subsystem/periodic-tick.html
[13]: http://www.wowotech.net/timer_subsystem/tick-device-layer.html
[14]: http://www.wowotech.net/timer_subsystem/tick-broadcast-framework.html
[15]: http://elixir.free-electrons.com/linux/v4.11/source/kernel/sched/loadavg.c#L220
[16]: http://elixir.free-electrons.com/linux/v4.11/source/kernel/sched/loadavg.c#L309
[17]: http://elixir.free-electrons.com/linux/v4.11/source/kernel/sched/loadavg.c#L183
[18]: http://elixir.free-electrons.com/linux/v4.11/source/kernel/sched/loadavg.c#L200
