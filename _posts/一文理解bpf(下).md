---
layout: post
author: 'Wu Daemon'
title: "bcc overview
draft: true
top: false
license: "cc-by-nc-nd-4.0"
permalink: /linux-ebpf/
description: "本文详细分析了bpf程序调用过程"
category:
  - 调试和优化
tags:
  - Linux
  - Kprobe
  - strace
  - bcc
  - perf
---
> By Wu Daemon of [TinyLab.org](http://tinylab.org)
> 2020/2/20


上一篇我们讲述了eBPF框架，了解了BPF程序的组成，大致分析了bpf指令和map数据通信，本节来分析下调用流程

# 解析elf文件流程

加载bpf程序实质上是加载elf格式文件，linux加载普通ELF格式的文件在通过`load_elf_binary`来实现，而linux加载bpf elf其实在用户态实现的，使用的是开源的libelf库实现的，调用过程不太一样，而且只是把elf格式的指令dump出来，接下来还需要JIT编译器翻译出机器汇编码才能执行，这明显调用过程比linux加载普通ELF格式文件简单。

libelf库实现的各个API可参考如下[链接](https://www.zybuluo.com/devilogic/note/139554),elf格式的详解可参考该[链接](https://tinylab.gitbooks.io/cbook)


ELF文件大体结构如下所示，包含elf头部，程序头表，各个段和程序段表 
```
ELF Header               #程序头，有该文件的Magic number(参考man magic)，类型等
Program Header Table     #对可执行文件和共享库有效，它描述下面各个节(section)组成的段
Section1
Section2
Section3
.....
Program Section Table   #仅对可重定位目标文件和静态库有效，用于描述各个Section的重定位信息等。
```

`samples/bpf/bpf_load.c` 中通过`get_sec`函数调用libelf库的API获取section内容，其中第四个参数是传入段的名字，最后一个参数获得的是该段的数据

```
static int get_sec(Elf *elf, int i, GElf_Ehdr *ehdr, char **shname,
		   GElf_Shdr *shdr, Elf_Data **data)
{
	Elf_Scn *scn;

	scn = elf_getscn(elf, i);  //从elf描述符获取按照节索引获取节接口
	if (!scn)
		return 1;

	if (gelf_getshdr(scn, shdr) != shdr) //	通过节结构复制节表头
		return 2;

	*shname = elf_strptr(elf, ehdr->e_shstrndx, shdr->sh_name); //	从指定的字符串表中通过偏移获取字符串
	if (!*shname || !shdr->sh_size)
		return 3;

	*data = elf_getdata(scn, 0);  //从节中获取节数据（经过了字节序的转换）
	if (!*data || elf_getdata(scn, *data) != NULL)
		return 4;

	return 0;
}
```



#  BPF字节码(BPF ELF)解析过程


tracex4_user.c通过`load_bpf_file`加载o文件，我们来分析一下 load_bpf_file  实质是调用do_load_bpf_file，在这个函数里首先打开 o文件，do_load_bpf_file 会将输入的 .o 文件作为 ELF 格式文件的逐个 section 进行分析，如 section 的名字是特殊的(比如 ‘kprobe’)，那么就会将这个 section 的内容作为 load_and_attach 的参数。如section的名字是"license"或"version"则保存license或version。如section是map则解析出map段

 ```
 //  samples/bpf/bpfload.c
                                    文件路径                     NULL
509  static int do_load_bpf_file(const char *path, fixup_map_cb fixup_map)
510  {
511  	int fd, i, ret, maps_shndx = -1, strtabidx = -1;
512  	Elf *elf;
513  	GElf_Ehdr ehdr;
514  	GElf_Shdr shdr, shdr_prog;
515  	Elf_Data *data, *data_prog, *data_maps = NULL, *symbols = NULL;
516  	char *shname, *shname_prog;
517  	int nr_maps = 0;
		... ...
527  	fd = open(path, O_RDONLY, 0);  //打开elf文件
528  	if (fd < 0)
529  		return 1;
530  
531  	elf = elf_begin(fd, ELF_C_READ, NULL);//获取elf描述符,使用‘读取’的方式
		... ...
536  	if (gelf_getehdr(elf, &ehdr) != &ehdr)  //获取elf文件头副本
537  		return 1;
	    ... ...
542  	/* scan over all elf sections to get license and map info */
543  	for (i = 1; i < ehdr.e_shnum; i++) {                   //遍历各个section
544  
545  		if (get_sec(elf, i, &ehdr, &shname, &shdr, &data))  // shname 为"section"的名字
546  			continue;
547  
548  		if (0) /* helpful for llvm debugging */        //打印各个section 对应的数据保存在data->d_buf中
549  			printf("section %d:%s data %p size %zd link %d flags %d\n",
550  			       i, shname, data->d_buf, data->d_size,
551  			       shdr.sh_link, (int) shdr.sh_flags);
552  
553  		if (strcmp(shname, "license") == 0) {        //如果是"license"段
554  			processed_sec[i] = true;
555  			memcpy(license, data->d_buf, data->d_size); //把 data->d_buf 拷贝到license数组
556  		} else if (strcmp(shname, "version") == 0) { //如果是"version"段 
557  			processed_sec[i] = true;
558  			if (data->d_size != sizeof(int)) {
559  				printf("invalid size of version section %zd\n",
560  				       data->d_size);
561  				return 1;
562  			}
563  			memcpy(&kern_version, data->d_buf, sizeof(int));//把 data->d_buf 拷贝到kern_version变量
564  		} else if (strcmp(shname, "maps") == 0) {      //如果是map 段
565  			int j;
566  
567  			maps_shndx = i;
568  			data_maps = data;
569  			for (j = 0; j < MAX_MAPS; j++)
570  				map_data[j].fd = -1;                 
571  		} else if (shdr.sh_type == SHT_SYMTAB) {
572  			strtabidx = shdr.sh_link;
573  			symbols = data;
574  		}
575  	}
		... ...
583  
584  	if (data_maps) {     //对map段的处理
585  		nr_maps = load_elf_maps_section(map_data, maps_shndx,elf, symbols, strtabidx);   //获取map段内容
587  		if (nr_maps < 0) {
588  			printf("Error: Failed loading ELF maps (errno:%d):%s\n",
589  			       nr_maps, strerror(-nr_maps));
590  			goto done;
591  		}
592  		if (load_maps(map_data, nr_maps, fixup_map))  //这里加载map
593  			goto done;
594  		map_data_count = nr_maps;
595  
596  		processed_sec[maps_shndx] = true;
597  	}
598  
599  	/* process all relo sections, and rewrite bpf insns for maps */
600  	for (i = 1; i < ehdr.e_shnum; i++) {  //遍历所有的重定向段，
601  		if (processed_sec[i])  ////flag 置位表示已经是处理了的段 ，跳过去 
602  			continue;
603  
604  		if (get_sec(elf, i, &ehdr, &shname, &shdr, &data))
605  			continue;
606  
607  		if (shdr.sh_type == SHT_REL) {
608  			struct bpf_insn *insns;
609  
610  			/* locate prog sec that need map fixup (relocations) */
611  			if (get_sec(elf, shdr.sh_info, &ehdr, &shname_prog,
612  				    &shdr_prog, &data_prog))  //该段保存到data_prog
613  				continue;
614  
615  			if (shdr_prog.sh_type != SHT_PROGBITS ||
616  			    !(shdr_prog.sh_flags & SHF_EXECINSTR))
617  				continue;
618  
619  			insns = (struct bpf_insn *) data_prog->d_buf;  //得到bpf字节码对应的结构体
620  			processed_sec[i] = true; /* relo section */
621  
622  			if (parse_relo_and_apply(data, symbols, &shdr, insns,
623  						 map_data, nr_maps))
624  				continue;
625  		}
626  	}
627  
628  	/* load programs */
629  	for (i = 1; i < ehdr.e_shnum; i++) {
630  
631  		if (processed_sec[i])  //flag 置位表示已经是处理了的段 ，跳过去  
632  			continue;
633  
634  		if (get_sec(elf, i, &ehdr, &shname, &shdr, &data))    
635  			continue;
636  
637  		if (memcmp(shname, "kprobe/", 7) == 0 ||
638  		    memcmp(shname, "kretprobe/", 10) == 0 ||
639  		    memcmp(shname, "tracepoint/", 11) == 0 ||
640  		    memcmp(shname, "raw_tracepoint/", 15) == 0 ||
641  		    memcmp(shname, "xdp", 3) == 0 ||
642  		    memcmp(shname, "perf_event", 10) == 0 ||
643  		    memcmp(shname, "socket", 6) == 0 ||
644  		    memcmp(shname, "cgroup/", 7) == 0 ||
645  		    memcmp(shname, "sockops", 7) == 0 ||
646  		    memcmp(shname, "sk_skb", 6) == 0 ||
647  		    memcmp(shname, "sk_msg", 6) == 0) {
648  			ret = load_and_attach(shname, data->d_buf,
649  					      data->d_size);  //事件类型  字节码 字节码大小
650  			if (ret != 0)
651  				goto done;
652  		}
653  	}
654  
655  done:
656  	close(fd);
657  	return ret;
658  }
 ```


 打开elf 调试log，可以得到该elf文件各个段的内容首地址，大小，属性等信息。
 ```
 wu@ubuntu:~/linux/samples/bpf$ sudo ./tracex4
[sudo] password for wu:
section 1:.strtab data 0x556034a3d070 size 277 link 0 flags 0
section 3:kprobe/kmem_cache_free data 0x556034a3d5a0 size 72 link 0 flags 6
section 4:.relkprobe/kmem_cache_free data 0x556034a3d5f0 size 16 link 26 flags 0
section 5:kretprobe/kmem_cache_alloc_node data 0x556034a3d610 size 192 link 0 flags 6
section 6:.relkretprobe/kmem_cache_alloc_node data 0x556034a3d6e0 size 16 link 26 flags 0
section 7:maps data 0x556034a3d700 size 28 link 0 flags 3
section 8:license data 0x556034a3d730 size 4 link 0 flags 3
section 9:version data 0x556034a3d750 size 4 link 0 flags 3
section 10:.debug_str data 0x556034a3d770 size 489 link 0 flags 48
section 11:.debug_loc data 0x556034a3d970 size 336 link 0 flags 0
section 12:.rel.debug_loc data 0x556034a3dad0 size 80 link 26 flags 0
section 13:.debug_abbrev data 0x556034a3db30 size 257 link 0 flags 0
section 14:.debug_info data 0x556034a3dc40 size 886 link 0 flags 0
section 15:.rel.debug_info data 0x556034a3dfc0 size 1200 link 26 flags 0
section 16:.debug_ranges data 0x556034a3e480 size 48 link 0 flags 0
section 17:.rel.debug_ranges data 0x556034a3e4c0 size 64 link 26 flags 0
section 18:.BTF data 0x556034a3e510 size 1384 link 0 flags 0
section 19:.rel.BTF data 0x556034a3ea80 size 48 link 26 flags 0
section 20:.BTF.ext data 0x556034a3eac0 size 376 link 0 flags 0
section 21:.rel.BTF.ext data 0x556034a3ec40 size 320 link 26 flags 0
section 22:.eh_frame data 0x556034a3ed90 size 80 link 0 flags 2
section 23:.rel.eh_frame data 0x556034a3edf0 size 32 link 26 flags 0
section 24:.debug_line data 0x556034a3ee20 size 327 link 0 flags 0
section 25:.rel.debug_line data 0x556034a3ef70 size 32 link 26 flags 0
section 26:.symtab data 0x556034a3efa0 size 1704 link 1 flags 0

 ```


#  BPF字节码加载过程

 接下来调用load_and_attach，第一个参数是event，本例就是"kprobe/" ，第二个参数是bpf字节码，第三个参数是字节码大小这里会再调用 bpf_load_program， 填入的参数为程序类型 prog_type, 和虚拟机指令 insns_cnt 等。判断events是kprobe/kretprobe ，然后填充buf为debugfs
 相关路径打开该路径，然后调用sys_perf_event_open ioctl设置等，这个和strace追踪到的调用过程基本一致。

bpf_insn，bpf_insn是一个结构体，代表一条eBPF指令，包含5个字段组成

```
struct bpf_insn {
    __u8    code;        /* opcode */
    __u8    dst_reg:4;    /* dest register */
    __u8    src_reg:4;    /* source register */
    __s16    off;        /* signed offset */
    __s32    imm;        /* signed immediate constant */
};
每一个eBPF程序都是由若干个bpf指定构成，就是一个一个bpf_insn数组，使用bpf系统调用将其载入内核
```


```
 static int load_and_attach(const char *event, struct bpf_insn *prog, int size)
{
    bool is_socket = strncmp(event, "socket", 6) == 0;


    ......

    fd = bpf_load_program(prog_type, prog, insns_cnt, license, kern_version,
                            bpf_log_buf, BPF_LOG_BUF_SIZE);

    ......  
           if (is_kprobe || is_kretprobe) {
                bool need_normal_check = true;
                const char *event_prefix = "";

                if (is_kprobe)
                        event += 7;
                else
                        event += 10;

                if (*event == 0) {
                        printf("event name cannot be empty\n");
                        return -1;
                }

                if (isdigit(*event))
                        return populate_prog_array(event, fd);

#ifdef __x86_64__
                if (strncmp(event, "sys_", 4) == 0) {
                        snprintf(buf, sizeof(buf), "%c:__x64_%s __x64_%s",
                                is_kprobe ? 'p' : 'r', event, event);
                        err = write_kprobe_events(buf);
                        if (err >= 0) {
                                need_normal_check = false;
                                event_prefix = "__x64_";
                        }
                }
#endif
                if (need_normal_check) {
                        snprintf(buf, sizeof(buf), "%c:%s %s",
                                is_kprobe ? 'p' : 'r', event, event);
                        err = write_kprobe_events(buf);
                        if (err < 0) {
                                printf("failed to create kprobe '%s' error '%s'\n",
                                       event, strerror(errno));
                                return -1;
                        }
                }

                strcpy(buf, DEBUGFS);
                strcat(buf, "events/kprobes/");
                strcat(buf, event_prefix);
                strcat(buf, event);
                strcat(buf, "/id");
        } 

        efd = open(buf, O_RDONLY, 0);
        if (efd < 0) {
                printf("failed to open event %s\n", event);
                return -1;
        }

        err = read(efd, buf, sizeof(buf));
        if (err < 0 || err >= sizeof(buf)) {
                printf("read from '%s' failed '%s'\n", event, strerror(errno));
                return -1;
        }

        close(efd);

        buf[err] = 0;
        id = atoi(buf);
        attr.config = id;

        efd = sys_perf_event_open(&attr, -1/*pid*/, 0/*cpu*/, -1/*group_fd*/, 0);
        ... ...
        event_fd[prog_cnt - 1] = efd;
        err = ioctl(efd, PERF_EVENT_IOC_ENABLE, 0);
        ... ...
        err = ioctl(efd, PERF_EVENT_IOC_SET_BPF, fd);
        ... ...

        return 0;
}
```


而 bpf_load_program 会通过 BPF_PROG_LOAD 系统调用，将字节码传入内核，返回一个文件描述符 fd，attr->insns 就是`code=BPF_ALU64|BPF_X|BPF_MOV, dst_reg=BPF_REG_6, src_reg=BPF_REG_1, off=0, imm=0 `这种bpf字节码
```
kernel/bpf/syscall.c

SYSCALL_DEFINE3(bpf, int, cmd, union bpf_attr __user *, uattr, unsigned int, size)
{
    ......
	case BPF_MAP_CREATE:
  		err = map_create(&attr);
  		break;
    case BPF_PROG_LOAD:
        err = bpf_prog_load(&attr);  //attr包含字节码
    ... ...
}
```
bpf_prog_load是真正的加载bpf字节码，首先从bpf字节码中获得license，判断是不是GPL license 。然后分配内核 bpf_prog 程序数据结构空间，将 bpf 虚拟机指令从用户空间拷贝到内核空间，把指令保存在struct bpf_prog结构体中，然后运行bpf_check 验证bpf指令在注入内核是否安全，比如检查栈是否会溢出，除数是否为零，否则不检测安不安全容易造成内核panic等严重问题，这一部分内容很多，就暂时不分析了。验证通过之后，核心调用是运行bpf_prog_select_runtime里的do_jit把bpf字节码转换成机器汇编码，最后运行bpf_prog_kallsyms_add将机器汇编码添加到kallsyms，在/proc/kallsyms中会看到bpf程序的符号表


```
1359  static int bpf_prog_load(union bpf_attr *attr)
1360  {
1361  	enum bpf_prog_type type = attr->prog_type;
1362  	struct bpf_prog *prog;
1363  	int err;
1364  	char license[128];
1365  	bool is_gpl;
		... ...
1373  	/* copy eBPF program license from user space */
1374  	if (strncpy_from_user(license, u64_to_user_ptr(attr->license),
1375  			      sizeof(license) - 1) < 0)  //拷贝license  attr->license
1376  		return -EFAULT;
1377  	license[sizeof(license) - 1] = 0;  //最后一位设空字符
1378  
1379  	/* eBPF programs must be GPL compatible to use GPL-ed functions */
1380  	is_gpl = license_is_gpl_compatible(license);
1381  

1397  
1398  	/* plain bpf_prog allocation */
1399  	prog = bpf_prog_alloc(bpf_prog_size(attr->insn_cnt), GFP_USER); /* 分配内核 bpf_prog 程序数据结构空间 */
1400  	if (!prog)
1401  		return -ENOMEM;
1402  
1403  	prog->expected_attach_type = attr->expected_attach_type;
1404  
1405  	prog->aux->offload_requested = !!attr->prog_ifindex;
1406  
1407  	err = security_bpf_prog_alloc(prog->aux);
1408  	if (err)
1409  		goto free_prog_nouncharge;
1410  
1411  	err = bpf_prog_charge_memlock(prog);
1412  	if (err)
1413  		goto free_prog_sec;
1414  
1415  	prog->len = attr->insn_cnt;
1416  
1417  	err = -EFAULT;
1418  	if (copy_from_user(prog->insns, u64_to_user_ptr(attr->insns),
1419  			   bpf_prog_insn_size(prog)) != 0)  //将若干指令从用户态拷贝到内核态
1420  		goto free_prog;
1421  
1422  	prog->orig_prog = NULL;
1423  	prog->jited = 0;
1424  
1425  	atomic_set(&prog->aux->refcnt, 1);
1426  	prog->gpl_compatible = is_gpl ? 1 : 0;  //设置gpl_compatible字段
1427  
		... ...
1444  	/* run eBPF verifier */
1445  	err = bpf_check(&prog, attr);  //运行verifier 检查字节码安全性  
1446  	if (err < 0)
1447  		goto free_used_maps;
1448  
1449  	prog = bpf_prog_select_runtime(prog, &err); //这里调用do_jit 将bpf字节码转换成汇编码
1450  	if (err < 0)
1451  		goto free_used_maps;
1452  
1453  	err = bpf_prog_alloc_id(prog);
1454  	if (err)
1455  		goto free_used_maps;
1456  

1471  	bpf_prog_kallsyms_add(prog);  //添加kallsyms
1472  
1473  	err = bpf_prog_new_fd(prog);
1474  	if (err < 0)
1475  		bpf_prog_put(prog);
1476  	return err;
		... ...
1488  }

```




##  运行bpf程序


jit编译器将机器汇编码的首地址转换成一个函数指针，保存到 prog->bpf_func,再看看哪里调用 prog->bpf_func 这个函数指针的呢？ 当 debugfs中创建 kprobe events中 init_kprobe_trace在 bpf加载的时候就调用 trace_kprobe_create继而调用 kprobe_dispatcher ，因为定义了 `CONFIG_PERF_EVENTS`而后调用 kprobe_perf_func

```

45  static struct dyn_event_operations trace_kprobe_ops = {
46  	.create = trace_kprobe_create,
47  	.show = trace_kprobe_show,
48  	.is_busy = trace_kprobe_is_busy,
49  	.free = trace_kprobe_release,
50  	.match = trace_kprobe_match,
51  };

1691  /* Make a tracefs interface for controlling probe points */
1692  static __init int init_kprobe_trace(void)   
1693  {
		... ...
1697  
1698  	ret = dyn_event_register(&trace_kprobe_ops);
1699  	if (ret)
1700  		return ret;
1701  
1702  	if (register_module_notifier(&trace_kprobe_module_nb))
1703  		return -EINVAL;
1704  
1705  	d_tracer = tracing_init_dentry();
1706  	if (IS_ERR(d_tracer))
1707  		return 0;
1708  
1709  	entry = tracefs_create_file("kprobe_events", 0644, d_tracer,
1710  				    NULL, &kprobe_events_ops);
1711  
		... ...
1725  	return 0;
1726  }
1727  fs_initcall(init_kprobe_trace);

trace_kprobe_create
{
	
   ... ...
   kprobe_dispatcher
   ... ...

}

1518  static int kprobe_dispatcher(struct kprobe *kp, struct pt_regs *regs)
1519  {
1520  	struct trace_kprobe *tk = container_of(kp, struct trace_kprobe, rp.kp);
1521  	int ret = 0;
1522  
1523  	raw_cpu_inc(*tk->nhit);
1524  
1525  	if (trace_probe_test_flag(&tk->tp, TP_FLAG_TRACE))
1526  		kprobe_trace_func(tk, regs);
1527  #ifdef CONFIG_PERF_EVENTS
1528  	if (trace_probe_test_flag(&tk->tp, TP_FLAG_PROFILE))
1529  		ret = kprobe_perf_func(tk, regs);
1530  #endif
1531  	return ret;
1532  }

```
kprobe_perf_func 会调用 trace_call_bpf,在这里会执行 bpf程序 BPF_PROG_RUN_ARRAY_CHECK是一个宏 ,其实质上执行BPF_PROG_RUN里的一个函数

```

1372  /* Kprobe profile handler */
1373  static int
1374  kprobe_perf_func(struct trace_kprobe *tk, struct pt_regs *regs)
1375  {

1381  
1382  	if (bpf_prog_array_valid(call)) {
1383  		unsigned long orig_ip = instruction_pointer(regs);
1384  		int ret;
1385  
1386  		ret = trace_call_bpf(call, regs);
1387  
1388  		/*
1389  		 * We need to check and see if we modified the pc of the
1390  		 * pt_regs, and if so return 1 so that we don't do the
1391  		 * single stepping.
1392  		 */
1393  		if (orig_ip != instruction_pointer(regs))
1394  			return 1;
1395  		if (!ret)
1396  			return 0;
1397  	}
1398  

1417  	return 0;
1418  }


/ * trace_call_bpf - invoke BPF program
 * @call: tracepoint event
 * @ctx: opaque context pointer
 *
 * kprobe handlers execute BPF programs via this helper.
 * Can be used from static tracepoints in the future.
 *
 * Return: BPF programs always return an integer which is interpreted by
 * kprobe handler as:
 * 0 - return from kprobe (event is filtered out)
 * 1 - store kprobe event into ring buffer
 * Other values are reserved and currently alias to 1
 */
unsigned int trace_call_bpf(struct trace_event_call *call, void *ctx)
{
        unsigned int ret;

        ... ...
        ret = BPF_PROG_RUN_ARRAY_CHECK(call->prog_array, ctx, BPF_PROG_RUN);  //运行bpf程序

 out:
        __this_cpu_dec(bpf_prog_active);
        preempt_enable();

        return ret;
}
```
其中的 trace_event_call 结构体定义了 bpf_prog_array,该结构体数组中包含了要执行的函数指针
```
259  struct trace_event_call {
260  	struct list_head	list;
261  	struct trace_event_class *class;
262  	union {
263  		char			*name;
264  		/* Set TRACE_EVENT_FL_TRACEPOINT flag when using "tp" */
265  		struct tracepoint	*tp;
266  	};
        ... ...
282  
283  #ifdef CONFIG_PERF_EVENTS
284  	int				perf_refcount;
285  	struct hlist_head __percpu	*perf_events;
286  	struct bpf_prog_array __rcu	*prog_array;
287  
288  	int	(*perf_perm)(struct trace_event_call *,
289  			     struct perf_event *);
290  #endif
291  };

516  struct bpf_prog_array {
517  	struct rcu_head rcu;
518  	struct bpf_prog_array_item items[0];
519  };

511  struct bpf_prog_array_item {
512  	struct bpf_prog *prog;
513  	struct bpf_cgroup_storage *cgroup_storage[MAX_BPF_CGROUP_STORAGE_TYPE];
514  };



```

BPF_PROG_RUN_ARRAY_CHECK， BPF_PROG_RUN 宏展开如下所示，实质是在 BPF_PROG_RUN中调用ret = (*(prog)->bpf_func)(ctx, (prog)->insnsi) 这个函数指针来执行bpf指令 
```
#define BPF_PROG_RUN_ARRAY_CHECK(array, ctx, func)      \
        __BPF_PROG_RUN_ARRAY(array, ctx, func, true)


#define __BPF_PROG_RUN_ARRAY(array, ctx, func, check_non_null)  \
        ({                                              \
                struct bpf_prog_array_item *_item;      \
                struct bpf_prog *_prog;                 \
                struct bpf_prog_array *_array;          \
                u32 _ret = 1;                           \
                preempt_disable();                      \
                rcu_read_lock();                        \
                _array = rcu_dereference(array);        \
                if (unlikely(check_non_null && !_array))\
                        goto _out;                      \
                _item = &_array->items[0];              \
                while ((_prog = READ_ONCE(_item->prog))) {              \
                        bpf_cgroup_storage_set(_item->cgroup_storage);  \
                        _ret &= func(_prog, ctx);       \
                        _item++;                        \
                }                                       \
_out:                                                   \
                rcu_read_unlock();                      \
                preempt_enable();                       \
                _ret;                                   \
         })



#define BPF_PROG_RUN(prog, ctx) ({                              \
        u32 ret;                                                \
        cant_sleep();                                           \
        if (static_branch_unlikely(&bpf_stats_enabled_key)) {   \
                struct bpf_prog_stats *stats;                   \
                u64 start = sched_clock();                      \
                ret = (*(prog)->bpf_func)(ctx, (prog)->insnsi); \
                stats = this_cpu_ptr(prog->aux->stats);         \
                u64_stats_update_begin(&stats->syncp);          \
                stats->cnt++;                                   \
                stats->nsecs += sched_clock() - start;          \
                u64_stats_update_end(&stats->syncp);            \
        } else {                                                \
                ret = (*(prog)->bpf_func)(ctx, (prog)->insnsi); \
        }                                                       \
        ret; })


```



参考链接 :
1  https://github.com/DavadDi/bpf_study/blob/master/bpf-prog-type.md