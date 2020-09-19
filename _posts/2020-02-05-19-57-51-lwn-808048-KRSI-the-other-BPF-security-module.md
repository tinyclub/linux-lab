---
layout: post
draft: true
top: false
author: '鲜卑拓跋枫'
title: "LWN 808048: KRSI —— 另一个基于BPF的安全模块"
album: 'LWN 中文翻译'
group: translation
license: "cc-by-sa-4.0"
permalink: /lwn-808048/
description: "LWN 中文翻译，KRSI —— 另一个基于BPF的安全模块"
category:
  - 系统安全
  - LWN
tags:
  - Linux
  - security
  - BPF
---

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

> 原文：[KRSI — the other BPF security module](https://lwn.net/Articles/808048/)
> 原创：By Jonathan Corbet @ Dec. 27, 2019
> 翻译：By [鲜卑拓跋枫](https://github.com/Murongfeng2018)
> 校对：By [Wen Yang](https://github.com/w-simon)

> One of the first uses of the [BPF virtual machine](http://lwn.net/Articles/740157/) outside of networking was to implement access-control policies for the [`seccomp()`](http://man7.org/linux/man-pages/man2/seccomp.2.html) system call. Since then, though, the role of BPF in the security area has not changed much in the mainline kernel, even though BPF has evolved considerably from the "classic" variant still used with `seccomp()` to the "extended" BPF now supported by the kernel. That has not been for a lack of trying, though. The out-of-tree Landlock security module was [covered here](https://lwn.net/Articles/703876/) over three years ago. We also [looked at](https://lwn.net/Articles/798157/) the kernel runtime security instrumentation (KRSI) patch set in September. KP Singh has posted [a new KRSI series](https://lwn.net/ml/linux-kernel/20191220154208.15895-1-kpsingh@chromium.org/), so the time seems right for a closer look.

[BPF 虚拟机][1] 在网络之外的最初用途之一便是为 [`seccomp()`][2] 系统调用实现访问控制策略。从那时起，尽管 BPF 已经从 `seccomp()` 中仍在使用的 “经典” 变体（译者注，即 cBPF）演进到如今内核支持的“扩展”BPF（译者注，即 eBPF），但在内核主线中，BPF 在安全领域的作用并没有太大的变化。不过这并非因为缺乏尝试。三年前 [这里][3] 就介绍过在内核源码树之外的 Landlock（译者注，[4]）安全模块。我们还 [关注][5] 了 9 月份提交的内核运行时安全监测(KRSI，Kernel Runtime Security Instrumentation)补丁。KP Singh 刚发布了[一个新的 KRSI 代码系列][6]，所以现在是时候仔细看看了。

> While KRSI is implemented as a Linux security module and is able to make access-control decisions, access control does not appear to be the core goal behind this work. Instead, KRSI exists to keep an eye on system behavior overall in order to detect attacks. It is, in a sense, better thought of as an extension of the kernel's audit mechanism that uses BPF to provide a higher level of configurability beyond what the audit subsystem can do. 

虽然 KRSI 是作为 Linux 安全模块来实现的，也能够进行访问控制策略的决策，但是访问控制似乎不是这项工作的核心目标。KRSI 的存在是为了全面监视系统行为，以便检测攻击。在某种意义上，它被认为是内核审计机制的扩展，使用 BPF 来提供比目前内核审计子系统更高级别的可配置性。

> The concept behind KRSI is simple enough: it allows a suitably privileged user to attach a BPF program to any of the hundreds of hooks provided by the Linux security module subsystem. To make this attachment easy, KRSI exports a new filesystem hierarchy under `/sys/kernel/security/bpf`, with one file for each hook. The [`bpf()`](http://man7.org/linux/man-pages/man2/bpf.2.html) system call can be used to attach a BPF program (of the new type `BPF_PROG_TYPE_LSM`) to any of these hooks; there can be more than one program attached to any given hook. Whenever a security hook is called, all attached BPF programs will be called in turn; if any BPF program returns an error status, then the requested action will be denied. 

KRSI 背后的概念非常简单: 它允许适当的特权用户将 BPF 程序挂载到 Linux 安全模块子系统提供的数百个钩子中的任何一个上面。为了简化这个步骤，KRSI在 `/sys/kernel/security/bpf` 下面导出了一个新的文件系统层次结构——每个钩子对应一个文件。可以使用 [`bpf()`][7] 系统调用将BPF程序(新的 `BPF_PROG_TYPE_LSM` 类型)挂载到这些钩子上；并且可以有多个程序挂载到任何给定的钩子。每当触发一个安全钩子时，将依次调用所有挂载的 BPF 程序；只要任一 BPF 程序返回错误状态，那么请求的操作将被拒绝。

> Many readers will be thinking that this mechanism sounds a lot like Landlock. While the fundamental idea — attaching BPF programs to security-module hooks — is the same, the underlying goals are different, and that leads to a different implementation. KRSI is a tool for system administrators who are interested in monitoring the behavior of the system as a whole; attaching a BPF program requires the `CAP_SYS_ADMIN` capability. Landlock, instead, is intended to allow unprivileged users to sandbox programs that they are running, so no privilege is needed to attach a BPF program to a hook via Landlock. 

很多读者会认为这种机制听起来与 Landlock 很像。虽然将 BPF 程序挂载到安全模块中的钩子这一基本思想是相同的，但由于底层目标不同，导致了不同的实现。KRSI 是一个面向系统管理员的工具，他们有兴趣监控整个系统的行为; 挂载一个 BPF 程序需要 `CAP_SYS_ADMIN` 能力。而 Landlock 致力于允许不具备特权的用户访问其所运行的沙箱程序，因此无需特权就可以通过 Landlock 将BPF程序挂到钩子上。

> This difference fundamentally affects how these modules execute. Consider, for example, the hook that the kernel calls in response to an `mprotect()` call from user space: 

这种差异从根本上影响了这些模块的执行方式。例如，考虑内核响应来自用户空间的 `mprotect()` 系统调用时会触发的钩子:

	int security_file_mprotect(struct vm_area_struct *vma, unsigned long reqprot,
			           unsigned long prot);

> In KRSI, the three parameters to this hook will be passed directly to any attached BPF programs; those programs can follow the vma pointer to learn all about the affected memory area. They can also follow `vma->vm_mm` to get to the calling processes top-level memory-management data (the `mm_struct` structure). There is, in short, a lot of information available to these programs. 

在 KRSI 中，这个钩子的三个参数将直接传递给任何挂载的 BPF 程序; 而这些程序可以通过 vma 指针来了解所有受影响的内存区域。它们还可以根据 `vma->vm_mm` 来获得调用进程的顶层内存管理数据(`mm_struct` 结构体)。简而言之，这些程序可以获取大量信息。

> Since Landlock hooks are under the control of unprivileged users, they cannot be allowed to just wander through kernel data structures. So a Landlock hook for `mprotect()` is passed a structure like this: 

Landlock的情况则不同。由于控制钩子的是非特权用户，因此无权浏览内核数据结构。所以由 `mprotect()` 调用传递给的 Landlock 钩子的是这样一个结构体:

        struct landlock_ctx_mem_prot {
           __u64 address;
	   __u64 length;
	   __u8 protections_current;
	   __u8 protections_requested;
        };

> In other words, the information passed to this hook contains nothing that user space did not already know. That makes it safe for the intended use case, but is likely to be too limiting for the global auditing case.

换句话说，传递给这个钩子的数据中不会包含用户空间还不知道的任何信息。这使得它对于预期的用例是安全的，但对于全局审计用例可能就太有限了。

> The advent of speculative-execution vulnerabilities, along with other factors, has led to a slow simmer of questions about whether it can ever be safe to allow unprivileged users to run extended BPF code in the kernel. The BPF developers themselves have been [coming to the conclusion](https://lwn.net/Articles/796328/) that it cannot be done, and have scaled back their plans to make unprivileged BPF available. Indeed, even Mickaël Salaün, the author of Landlock, now [feels][https://lwn.net/ml/linux-kernel/a6b61f33-82dc-0c1c-7a6c-1926343ef63e@digikod.net/] that "it is quite challenging to safely expose eBPF to malicious processes". He went on to say: 

业已暴光的投机性执行中的漏洞(译者注，即 [Spectre 漏洞][8])以及其他因素，导致了一个缓慢爆发的问题，即允许非特权用户在内核中运行 eBPF 代码是否安全？BPF 开发人员自己已经 [得出否定的结论][9]，并且缩减了其无特权 BPF 的计划。事实上，甚至连 Landlock 的作者 Mickael Salaun 现在也 [觉得][10] “安全地将 eBPF 暴露给恶意进程是相当有挑战性的”。他接着说道:

>     I'm working on a version of Landlock without eBPF, but still with the initial sought properties: safe unprivileged composability, modularity, and dynamic update. I'll send this version soon.

      我正在开发一个不基于 eBPF 的 Landlock 版本，但仍然满足最初要求的特性: 安全的无特权可组合性、模块化和动态更新。我将很快发送这个版本。

> So, while it may tempting to see KRSI and Landlock as being in competition with each other, that does not really appear to be the case. 

因此，尽管人们倾向于认为KRSI和Landlock在相互竞争，但事实并非如此。

> There does not appear to be any fundamental opposition to KRSI — so far — but Casey Schaufler did [raise](https://lwn.net/ml/linux-kernel/95036040-6b1c-116c-bd6b-684f00174b4f@schaufler-ca.com/) the inevitable concern with this approach: "This effectively exposes the LSM hooks as external APIs. It would mean that we can't change or delete them." API issues often come up around BPF, especially in the tracing area, so it is unsurprising that this question would arise here. In this case, Singh [replied](https://lwn.net/ml/linux-kernel/CACYkzJ5nYh7eGuru4vQ=2ZWumGPszBRbgqxmhd4WQRXktAUKkQ@mail.gmail.com/): "we *do not* want to make LSM hooks a stable API and expect the eBPF programs to adapt when such changes occur". It has repeatedly been made clear, though, that such expectations do not override the kernel's stable-ABI rules. Given the power that would be available to KRSI hooks, it is reasonable to expect that they would be used for a range of purposes far beyond those envisioned by its developers. If unrelated kernel changes break the resulting programs, there is a good chance that they would be reverted. 

到目前为止，对 KRSI 似乎还没有任何根本性的反对意见，但是 Casey Schaufler 确实对这个方案 [提出][11] 了不可避免的担忧: “这实际上暴露了 LSM 钩子作为外部 API。这意味着我们不能改变或删除它们。”API 方面的问题经常围绕着BPF出现，特别是在追踪(tracing)领域，所以这个问题出现在这里并不奇怪。对此，Singh [回答][12] 说:“我们*不想*让 LSM 钩子成为一个稳定的 API 并期望 eBPF 程序在这种变化发生时能够适应。”虽然这一点已一再表明，即这样的期望并不会凌驾于稳定的内核 ABI 之类的准则之上。但考虑到 KRSI 钩子将提供的强大功能，我们有理由相信它们将被用于远远超出其开发人员所设想的各种用途。如果不相关的内核改动破坏了 eBPF 程序，则很有可能会将这些钩子回退。

> Additionally, one could argue that this kind of problem is more likely to come about with KRSI than with, for example, tracepoints. While tracepoints have been added as an explicit way to make specific information available to user space, the security-module hooks were designed for internal use. They expose a lot of information, in internal-kernel formats, that one might otherwise not choose to make available even to privileged users. That can only make them more likely to break as those kernel data structures change. Changes to the security hooks are not that common, but they do happen ([example](https://git.kernel.org/linus/e3f20ae21079)); developers are unlikely to react well to the idea that they would no longer be able to make that kind of change. 

此外，有人可能会分辩说，这种问题更有可能出现在 KRSI 中，而不是追踪点（tracepoint)之类的地方。虽然追踪点是作为一种显式地向用户空间传递特定信息的方式，但安全模块中的钩子本是为内部使用而设计的。这些钩子以内部格式公开了大量信息，而人们甚至可能不会选择将这些信息提供给特权用户。那只会使它们在内核数据结构改变时更容易崩溃。对安全钩子的更改并不常见，但确实会发生([举例][13]);开发者则难以对这种他们无法做出的改动有很好的反应。

> The ABI issue could thus end up being the biggest obstacle to the merging of KRSI, even though such concerns have not (yet) stalled efforts in areas like tracing. It will be interesting to see what happens as the awareness of this functionality spreads. The usefulness of KRSI seems clear, but the potential for long-term problems it could bring is rather murkier.

ABI问题可能最终会成为 KRSI 合并到内核的最大障碍，尽管这种担忧(迄今)并没有阻碍诸如追踪等领域的工作。随着 KRSI 功能的完善，会发生些什么将是很有趣的事情。KRSI 的用途似乎很明确，但它可能带来的长期问题却相当模糊。

**了解更多有关 “LWN 中文翻译计划”，请点击 [这里](/lwn/)**

[1]: https://lwn.net/Articles/740157/
[2]: http://man7.org/linux/man-pages/man2/seccomp.2.html
[3]: https://lwn.net/Articles/703876/
[4]: https://landlock.io/
[5]: https://lwn.net/Articles/798157/
[6]: https://lwn.net/ml/linux-kernel/20191220154208.15895-1-kpsingh@chromium.org/
[7]: http://man7.org/linux/man-pages/man2/bpf.2.html
[8]: https://software.intel.com/security-software-guidance/api-app/sites/default/files/Intel_Mitigation_Overview_for_Potential_Side-Channel_Cache_Exploits_Linux_white_paper.pdf
[9]: https://lwn.net/Articles/796328/
[10]: https://lwn.net/ml/linux-kernel/a6b61f33-82dc-0c1c-7a6c-1926343ef63e@digikod.net/
[11]: https://lwn.net/ml/linux-kernel/95036040-6b1c-116c-bd6b-684f00174b4f@schaufler-ca.com/
[12]: https://lwn.net/ml/linux-kernel/CACYkzJ5nYh7eGuru4vQ=2ZWumGPszBRbgqxmhd4WQRXktAUKkQ@mail.gmail.com/
[13]: https://git.kernel.org/linus/e3f20ae21079
