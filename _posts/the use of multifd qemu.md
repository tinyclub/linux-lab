# qemu multifd 功能的应用场景及代码分析
    作者：高承博  金琦  刘唐
## multifd 功能的应用场景
云计算环境计算节点上的一个物理网卡会有两个物理网口，而这两个物理网口一般都采用bond 模式加入OVS 的某一个网桥的。对于一条流来讲(一个TCP 链接)每次只能从两个物理网口的其中一个流入或流出，也就是说带宽只有一个网口的带宽。在qemu 没有打开multifd 进行迁移时，内存的数据流量如下图所示：
![alt figure1](D:\tinylab\tinylab.org\wp-content\uploads\2021\1\qemu\figure1.png)
    
打开multifd 后qemu在进行迁移内存时，会使用两条TCP 链接，流量如下图所示：
![alt figure2](D:\tinylab\tinylab.org\wp-content\uploads\2021\1\qemu\figure2.png)

## 代码分析
### 使用版本
因为multifd 功能是个比较新的功能，我在使用qemu 2.12版本时发现，虽然可以开启multifd 这个capability，但实际上multifd的实现函数是空的。所以作者使用的是qemu 3.0.0进行实验分析的。所以下文代码以3.0.0为基础进行分析。

### qemu 的命令行参数
#### 源虚机
    ./x86_64-softmmu/qemu-system-x86_64 /vms/gaocb/vm/t1_bak.qcow2 -smp 2 -m 100000 -vnc 0.0.0.0:5  -monitor stdio -machine pc-i440fx-2.6,accel=kvm
#### 目的虚机
    ./x86_64-softmmu/qemu-system-x86_64 /vms/gaocb/vm/t1_bak.qcow2 -smp 2 -m 100000 -vnc 0.0.0.0:5  -monitor stdio -machine pc-i440fx-2.6,accel=kvm  -incoming tcp:192.168.1.2:55555

### 如何启动multifd
#### hmp命令
打开multifd功能：

    (qemu) migrate_set_capability x-multifd on
每次传输的物理页：

    (qemu) migrate_set_parameter x-multifd-page-count 20
打开multifd的通道数(TCP了链接数)：

    (qemu) migrate_set_parameter x-multifd-channels 2
开启迁移：

    (qemu) migrate -d tcp:192.168.1.2:55555

### multifd 部分代码分析
#### 代码框架
普通的虚机内存迁移都是通过migration_thread 一个函数去进行的。对于multifd 的实现也是基于migration_thread 进行的，但multifd 比传统的内存迁移方式又多了两个multifd_send_thread 辅助线程用来执行。如图所示：
![alt figure3](D:\tinylab\tinylab.org\wp-content\uploads\2021\1\qemu\figure3.png)

migration_thread 线程把准好的物理页数据结构multifd_send_state 就像一块肉一样丢给线程池里的两个multifd_send_thread 辅助线程。两个线程谁争抢到了这个信号量，谁就开始传送数据。没争抢到的线程就会继续等待migration_thread 下一次发出的物理数据结构multifd_send_state。
#### 传统迁移和multifd 迁移的代码的流程对比
由于篇幅有限，而且本次的话题也不是传统的迁移流程，所以在画代码调用流程时有些函数省略了。
![alt figure4](D:\tinylab\tinylab.org\wp-content\uploads\2021\1\qemu\figure4.png)

#### 关键代码分析
    static void multifd_send_pages(void)
    {
        int i;
        static int next_channel;
        MultiFDSendParams *p = NULL; /* make happy gcc */
        MultiFDPages_t *pages = multifd_send_state->pages;
        uint64_t transferred;

        qemu_sem_wait(&multifd_send_state->channels_ready);
        for (i = next_channel;; i = (i + 1) % migrate_multifd_channels()) {
            p = &multifd_send_state->params[i];

            qemu_mutex_lock(&p->mutex);
            if (!p->pending_job) {
                p->pending_job++;
                next_channel = (i + 1) % migrate_multifd_channels();
                break;
            }
            qemu_mutex_unlock(&p->mutex);
        }
        p->pages->used = 0;

        p->packet_num = multifd_send_state->packet_num++;
        printf("%s: p->pages->block = NULL \n", __func__);
        p->pages->block = NULL;
        multifd_send_state->pages = p->pages;
        p->pages = pages;
        transferred = pages->used * TARGET_PAGE_SIZE + p->packet_len;
        ram_counters.multifd_bytes += transferred;
        ram_counters.transferred += transferred;;
        qemu_mutex_unlock(&p->mutex);
        qemu_sem_post(&p->sem);
    }
    static void *multifd_send_thread(void *opaque)
    {
        MultiFDSendParams *p = opaque;
        Error *local_err = NULL;
        int ret;

        trace_multifd_send_thread_start(p->id);

        if (multifd_send_initial_packet(p, &local_err) < 0) {
            goto out;
        }
        /* initial packet */
        p->num_packets = 1;

        while (true) {
            qemu_sem_wait(&p->sem);
            qemu_mutex_lock(&p->mutex);

            if (p->pending_job) {
                uint32_t used = p->pages->used;
                uint64_t packet_num = p->packet_num;
                uint32_t flags = p->flags;

                multifd_send_fill_packet(p);
                p->flags = 0;
                p->num_packets++;
                p->num_pages += used;
                p->pages->used = 0;
                qemu_mutex_unlock(&p->mutex);

                trace_multifd_send(p->id, packet_num, used, flags);

                ret = qio_channel_write_all(p->c, (void *)p->packet,
                                            p->packet_len, &local_err);
                if (ret != 0) {
                    break;
                }

                ret = qio_channel_writev_all(p->c, p->pages->iov, used, &local_err);
                if (ret != 0) {
                    break;
                }

                qemu_mutex_lock(&p->mutex);
                p->pending_job--;
                qemu_mutex_unlock(&p->mutex);

                if (flags & MULTIFD_FLAG_SYNC) {
                    qemu_sem_post(&multifd_send_state->sem_sync);
                }
                qemu_sem_post(&multifd_send_state->channels_ready);
            } else if (p->quit) {
                qemu_mutex_unlock(&p->mutex);
                break;
            } else {
                qemu_mutex_unlock(&p->mutex);
                /* sometimes there are spurious wakeups */
            }
        }

    out:
        if (local_err) {
            multifd_send_terminate_threads(local_err);
        }

        qemu_mutex_lock(&p->mutex);
        p->running = false;
        qemu_mutex_unlock(&p->mutex);

        trace_multifd_send_thread_end(p->id, p->num_packets, p->num_pages);

        return NULL;
    }
可以看到multifd_send_pages 函数负责把准备好的数据准备让multifd_send_thread 线程接收。multifd_send_thread 在产生之后就阻塞在while循环中的qemu_sem_wait(&p->sem)，当multifd_send_thread 在qemu_sem_post(&p->sem)释放信号量时，multifd_send_pages就可以由阻塞状态变为运行状态进行数据发送了。可以看到这里的信号量p->sem是当做同步信号量使用的，用于生产者(migration_thread)和消费者(multifd_send_thread)之间唤醒使用。

### 实验结果
![alt figure4](D:\tinylab\tinylab.org\wp-content\uploads\2021\1\qemu\figure4.png)
图中business 网桥是ens3f0 和ens3f1 两个网口做了bond。可以看到ens3f0 和ens3f1 两个网口都有流量。