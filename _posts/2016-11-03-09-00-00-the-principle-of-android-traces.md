---
layout: post
author: 'Huang Tao'
title: "Android trace文件抓取原理"
group: original
permalink: /android-traces/
description: "Android anr发生的时候，/data/anr/traces.txt保存了anr进程的Java、Native、Kernel堆栈，这篇文章主要介绍traces.txt的抓取原理"
category:
  - Android 开发
---
> By HuangTao of [TinyLab.org][1]
> 2016-11-03 09:04:30

Android系统每次发生ANR后，都会在/data/anr/目录下面输出一个traces.txt文件，这个文件记录了发生问题进程的虚拟机相关信息和线程的堆栈信息，通过这个文件我们就能分析出当前线程正在做什么操作，继而可以分析出ANR的原
因，它的生成与Signal Catcher线程是息息相关的，每一个从zygote派生出来的子进程都会有一个Signal Catcher线程，可以在终端的Shell环境下执行”ps -t &pid” 命令得到对应pid进程所有的子线程列表，如下所示：

```
USER      PID   PPID  VSIZE  RSS   WCHAN              PC  NAME
system    2953  2646  2784184 223904 SyS_epoll_ 7f92d20520 S system_server
system    2958  2953  2784184 223904 do_sigtime 7f92d20700 S Signal Catcher
system    2960  2953  2784184 223904 futex_wait 7f92cd3f20 S ReferenceQueueD
system    2961  2953  2784184 223904 futex_wait 7f92cd3f20 S FinalizerDaemon
system    2962  2953  2784184 223904 futex_wait 7f92cd3f20 S FinalizerWatchd
system    2963  2953  2784184 223904 futex_wait 7f92cd3f20 S HeapTaskDaemon
system    2970  2953  2784184 223904 binder_thr 7f92d20610 S Binder_1
system    2972  2953  2784184 223904 binder_thr 7f92d20610 S Binder_2
system    2985  2953  2784184 223904 SyS_epoll_ 7f92d20520 S android.bg
system    2986  2953  2784184 223904 SyS_epoll_ 7f92d20520 S ActivityManager
system    2987  2953  2784184 223904 SyS_epoll_ 7f92d20520 S android.ui
system    2988  2953  2784184 223904 SyS_epoll_ 7f92d20520 S android.fg
system    2989  2953  2784184 223904 inotify_re 7f92d20fe8 S FileObserver
system    2990  2953  2784184 223904 SyS_epoll_ 7f92d20520 S android.io
system    2991  2953  2784184 223904 SyS_epoll_ 7f92d20520 S android.display
system    2992  2953  2784184 223904 futex_wait 7f92cd3f20 S CpuTracker
system    2993  2953  2784184 223904 SyS_epoll_ 7f92d20520 S PowerManagerSer

```
上面打印的是system_server的线程列表，其中2958这个线程便是"Signal Catcher"线程，Signal是指进程发生问题时候Kernel发给它的信号，Signal Catcher这个线程就是在用户空间来处理信号。

[Linux软中断信号（信号）](http://www.cnblogs.com/hoys/archive/2012/08/19/2646377.html#/notebooks/6130015/notes/5653062/_blank)是系统用来通知进程发生了异步事件，是在软件层次上是对中断机制的一种模拟，在原理>上，一个进程收到一个信号与处理器收到一个中断请求可以说是一样的。信号是进程间通信机制中唯一的异步通信机制，一个进程不必通过任何操作来等待信号的到达，事实上，进程也不知道信号到底什么时候到达。进程之间可以互>相通过系统调用kill发送软中断信号。内核也可以因为内部事件而给进程发送信号，通知进程发生了某个事件。除此之外，信号机制除了基本通知功能外，还可以传递附加信息，总之信号是一种Linux系统中进程间通信手段，Linux默>认已经给进程的信号有处理，如果你不关心信号的话，默认系统行为就好了，但是如果你关心某些信号，例如段错误SIGSEGV（一般是空指针、内存访问越界的时候由系统发送给当事进程），那么你就得重新编写信号处理函数来覆盖系
统默认的行为，这种机制对于程序调试来说是很重要的一种手段，因为像这种段错误是不可预知的，它可以发生在任何地方，也就是说在应用程序的代码里面是不能处理这种异常的，这个时候要定位问题的话，就只能依靠信号这种机>制，虽然应用程序不知道什么时候发生了段错误，但是系统底层（Kernel）是知道的，Kernel发现应用程序访问了非法地址的时候，就会发送一个SIGSEGV信号给该进程，在该进程从内核空间返回到用户空间时会检测是否有信号等待处
理，如果用户自定义了信号处理函数，那么这个时候就会调用用户编写的函数，这个时候就可以做很多事情了：例如dump当前进程的堆栈、获取系统的全局信息（内存、IO、CPU）等，而这些信息对分析问题是非常重要的。

回到主题，Signal Catcher这个线程是由Android Runtime去创建的，在新起一个应用进程的时候，system_server进程会通过socket和zygote取得通信，并由zygote负责去创建一个子进程，在Linux系统中，创建一个进程一般通过fork机制，Android也不例外，zygote的子进程起来后，默认都会有一个main线程，在该main线程中都会调用到DidForkFromZygote@Runtime.cc这个函数，在这个函数中又会调用StartSignalCatcher@Runtime.cc这个函数，这个函数里面会>新建一个SignalCatcher对象，Signal Catcher线程的起源便是来源于此。

```
void Runtime::StartSignalCatcher() {
   if (!is_zygote_) {
       signal_catcher_ = new SignalCatcher(stack_trace_file_);
   }
}
```

在SignalCatcher的构造函数中会调用 pthread_create来创建一个传统意义上的Linux线程，说到底Android是一个基于Linux的系统，ART的线程概念直接复用了Linux的，毕竟Linux发展了这么久，线程机制这一方面已经很成熟了，ART没必要重复造轮子，在User空间再实现一套自己的线程机制，pthread_create是类Unix操作系统（Unix、Linux、Mac OS X等）的创建线程的函数，它的函数原型为：

```
int pthread_create(pthread_t *tidp,const pthread_attr_t *attr,(void*)(*start_rtn)(void*),void *arg);
```

**tidp** 返回线程标识符的指针，**attr** 设置线程属性，**start_rtn** 是线程运行函数的起始地址，**arg** 是传递给**start_rtn**的参数。在SignalCatcher的构造函数中调用该函数的语句为：

```
CHECK_PTHREAD_CALL(pthread_create, (&pthread_, nullptr,&Run, this), "signal catcher thread");
```

CHECK_PTHREAD_CALL是一个宏定义，最终会调用pthread_create来新起一个Linux线程，从pthread_create的参数来看，线程创建出来之后会执行Run@SignalCatcher.cc这个函数，并且把this指针也就是创建的SignalCatcher对象作为>参数传递给了Run函数，看一下Run函数的实现：

```
void* SignalCatcher::Run(void* arg) {
......
Runtime* runtime = Runtime::Current();
CHECK(runtime->AttachCurrentThread("Signal Catcher", true, runtime->GetSystemThreadGroup(),//attach linux线程，使得该线程拥有调用JNI函数的能力
Thread* self = Thread::Current();
......
// Set up mask with signals we want to handle.
SignalSet signals;
signals.Add(SIGQUIT); //监听SIGQUIT信号
signals.Add(SIGUSR1);
while (true) {
int signal_number = signal_catcher->WaitForSignal(self, signals); //等待Kernel给进程发送信号
if (signal_catcher->ShouldHalt()) {
    runtime->DetachCurrentThread();
    return nullptr;
}
switch (signal_number) {
    case SIGQUIT:
        signal_catcher->HandleSigQuit();  //调用HandleSigQuit去处理SIGQUIT信号
        break;
    ......
    default:
        LOG(ERROR) << "Unexpected signal %d" << signal_number;
        break;
}
}
}
```

在这个函数里面，首先调用 runtime->AttachCurrentThread去attach当前线程，然后安装信号处理函数，最后就是一个无限循环，在循环里等待信号的到来，如果Kernel发送了信号给虚拟机进程，那么就会执行对应信号的处理过程，
这篇文章只关注SIGQUIT信号的处理，下面一步一步来分析这四个过程。

-  AttachCurrentThread
这个是通过调用Runtime的AttatchCurrentThread函数完成的，Runtime也只是简单的调用了Thread类的Attach函数，这里多出来一个Thread类，看上去像是创建一个thread，其实不然，在Android里面只能通过pthread_create去创建一
个线程，这里的Thread只是Android Runtime里面的一个类，一个Thread对象创建之后就会被保存在线程的TLS区域，所以一个Linux线程都对应了一个Thread对象，可以通过Thread的Current()函数来获取当前线程关联的Thread对象，>通过这个Thread对象就可以获取一些重要信息，例如当前线程的Java线程状态，Java栈帧，JNI函数指针列表等等,之所以说是Java线程状态，Java栈帧，是因为Android运行时其实是没有自己单独的线程机制的，Java线程底层都是一个
Linux线程，但是Linux线程是没有像Watting、Blocked等状态的，并且Linux线程也是没有Java堆栈的，那么这些Java线程状态和和Java栈帧必须有一个地方保存，要不然就丢失了，Thread对象就是这个理想的“储物柜”，下面介绍Thread对象创建过程的时候会讲到这一块内容。

```
bool Runtime::AttachCurrentThread(const char* thread_name, bool as_daemon, jobject thread_group, bool create_peer) {
    return Thread::Attach(thread_name, as_daemon, thread_group, create_peer) != nullptr;
}
```

```
Thread* Thread::Attach(const char* thread_name, bool as_daemon, jobject thread_group,bool create_peer) {
    Runtime* runtime = Runtime::Current();
    ......
    Thread* self;
    {
        MutexLock mu(nullptr, *Locks::runtime_shutdown_lock_);
        if (runtime->IsShuttingDownLocked()) {
        ......
        } else {
                Runtime::Current()->StartThreadBirth();
                self = new Thread(as_daemon); //新建一个Thread对象
                bool init_success = self->Init(runtime->GetThreadList(), runtime->GetJavaVM()); //调用init函数
                Runtime::Current()->EndThreadBirth();
                if (!init_success) {
                    delete self;
                    return nullptr;
                }
         }
      }
    ......
    self->InitStringEntryPoints();  
    CHECK_NE(self->GetState(), kRunnable);
    self->SetState(kNative);
    ......
    return self;
}
```

在Thread的attach函数里面，首先新建了一个Thread对象，然后调用Thread对象的Init过程，最后通过调用self->SetState(kNative)将当前的Java线程状态设置为kNative状态，先看一下Thread的SetState这个函数，因为这个函数比>较简单，它是用来设置Java线程状态的。

```
inline ThreadState Thread::SetState(ThreadState new_state) {
  // Cannot use this code to change into Runnable as changing to Runnable should fail if
  // old_state_and_flags.suspend_request is true.
  DCHECK_NE(new_state, kRunnable);
  if (kIsDebugBuild && this != Thread::Current()) {
    std::string name;
    GetThreadName(name);
    LOG(FATAL) << "Thread \"" << name << "\"(" << this << " != Thread::Current()="
               << Thread::Current() << ") changing state to " << new_state;
  }
  union StateAndFlags old_state_and_flags;
  old_state_and_flags.as_int = tls32_.state_and_flags.as_int;
  tls32_.state_and_flags.as_struct.state = new_state;
  return static_cast<ThreadState>(old_state_and_flags.as_struct.state);
}
```

Java线程的状态是保存在Thread对象中的，具体来说是由该对象中的tls32_这个结构体保存的，可以通过修改这个结构体来设置当前的状态，ART目前支持的Java线程状态列表如下，通过状态后面的注释，大概就可以知道什么时候会进
行状态的切换。

```
enum ThreadState {
  //                                   Thread.State   JDWP state
  kTerminated = 66,                 // TERMINATED     TS_ZOMBIE    Thread.run has returned, but Thread* still around
  kRunnable,                        // RUNNABLE       TS_RUNNING   runnable
  kTimedWaiting,                    // TIMED_WAITING  TS_WAIT      in Object.wait() with a timeout
  kSleeping,                        // TIMED_WAITING  TS_SLEEPING  in Thread.sleep()
  kBlocked,                         // BLOCKED        TS_MONITOR   blocked on a monitor
  kWaiting,                         // WAITING        TS_WAIT      in Object.wait()
  kWaitingForGcToComplete,          // WAITING        TS_WAIT      blocked waiting for GC
  kWaitingForCheckPointsToRun,      // WAITING        TS_WAIT      GC waiting for checkpoints to run
  kWaitingPerformingGc,             // WAITING        TS_WAIT      performing GC
  kWaitingForDebuggerSend,          // WAITING        TS_WAIT      blocked waiting for events to be sent
  kWaitingForDebuggerToAttach,      // WAITING        TS_WAIT      blocked waiting for debugger to attach
  kWaitingInMainDebuggerLoop,       // WAITING        TS_WAIT      blocking/reading/processing debugger events
  kWaitingForDebuggerSuspension,    // WAITING        TS_WAIT      waiting for debugger suspend all
  kWaitingForJniOnLoad,             // WAITING        TS_WAIT      waiting for execution of dlopen and JNI on load code
  kWaitingForSignalCatcherOutput,   // WAITING        TS_WAIT      waiting for signal catcher IO to complete
  kWaitingInMainSignalCatcherLoop,  // WAITING        TS_WAIT      blocking/reading/processing signals
  kWaitingForDeoptimization,        // WAITING        TS_WAIT      waiting for deoptimization suspend all
  kWaitingForMethodTracingStart,    // WAITING        TS_WAIT      waiting for method tracing to start
  kWaitingForVisitObjects,          // WAITING        TS_WAIT      waiting for visiting objects
  kWaitingForGetObjectsAllocated,   // WAITING        TS_WAIT      waiting for getting the number of allocated objects
  kStarting,                        // NEW            TS_WAIT      native thread started, not yet ready to run managed code
  kNative,                          // RUNNABLE       TS_RUNNING   running in a JNI native method
  kSuspended,                       // RUNNABLE       TS_RUNNING   suspended by GC or debugger
};
```

在attach函数中，主要关注的是Init过程，详细分析Init过程之前，需要大概了解一下ART执行代码的方式，ART相对与Dalvik一个重要的变化就是不再直接执行字节码，而是先把字节码翻译成本地机器码，这个过程是通过在安装应用>程序的时候执行dex2oat进程得到一个oat文件完成的，这个oat文件一般保存在  /data/app/应用名称/oat/ 目录下面， oat文件里面就包含了编译好的机器码，这里的编译其实只是把dex文件中java类的方法翻译成本地机器码，然后>在执行的时候，不是去解释执行字节码，而是找到对应的机器码直接执行。这样效率就提高了， 这些机器码不可能单独存在，有一些功能必须借助于ART运行时，例如在heap中分配一个对象、执行一个jni方法等，所以编译好的本地机
器码中会引用到ART运行时的一些方法，这就像我们编译一个so库文件的时候引用到了外部函数**其实oat文件和so文件一样都是ELF可执行格式文件，只是oat文件相比于标准的ELF格式文件多出了几个section**，那么在加载这些oat文
件的时候需要重定位这些外部函数，打开标准的so文件的时候，一般用的是dlopen这个函数，该函数会自动把没有加载的so库加载进来，然后把这些外部函数重定位好，然而oat文件的打开方式不同，为了快速加载oat文件，ART在线程
的TLS区域保存了一些函数，编译好的机器码就是调用这些函数指针来和ART运行时联系，这些函数就是在Thread的Init过程中初始化好的。

```
void Thread::InitTlsEntryPoints() {
  // Insert a placeholder so we can easily tell if we call an unimplemented entry point.
  uintptr_t* begin = reinterpret_cast<uintptr_t*>(&tlsPtr_.interpreter_entrypoints);
  uintptr_t* end = reinterpret_cast<uintptr_t*>(reinterpret_cast<uint8_t*>(&tlsPtr_.quick_entrypoints) +
      sizeof(tlsPtr_.quick_entrypoints));
  for (uintptr_t* it = begin; it != end; ++it) {
    *it = reinterpret_cast<uintptr_t>(UnimplementedEntryPoint);
  }
  InitEntryPoints(&tlsPtr_.interpreter_entrypoints, &tlsPtr_.jni_entrypoints,
                  &tlsPtr_.quick_entrypoints);
}
```

这些函数指针是保存在Thread对象里面，而Thread对象是保存在线程的TLS区域里面的，所以本地机器码可以访问这块TLS区域，从而拿到这些函数指针。执行了attach函数之后，一个Linux线程才真正和虚拟机运行时关联起来，一个Linux线程摇身一变成了Java线程，才有了自己的java线程状态和java栈帧等数据结构，那些纯粹的native线程是不能执行java代码的，所以后面看到在dump进程的堆栈的时候，有些线程是没有java堆栈的，只有native和kernel堆栈，就
是这个原因。

- 安装信号处理函数

上面分析了进程如果想要自己处理一个信号，那么就得在代码里面添加信号处理函数，ART封装了一个SignalSet类来安装信号处理函数，但其实里面还是使用sigaddset、sigemptyset、sigwait等标准的Linux接口来实现对信号的处理>的，通过调用 signals.Add(SIGQUIT);  signals.Add(SIGUSR1);就实现了 SIGQUIT和 SIGUSR1两个信号的自定义处理，安装完信号处理函数之后是一个无限循环，在循环里面执行sigwait函数来等待信号。

```
while (true) {
    int signal_number = signal_catcher->WaitForSignal(self, signals);
    if (signal_catcher->ShouldHalt()) {
        runtime->DetachCurrentThread();
        return nullptr;
    }
    switch (signal_number) {
        case SIGQUIT:
            signal_catcher->HandleSigQuit();
            break;
        case SIGUSR1:
            signal_catcher->HandleSigUsr1();
            break;
        default:
            LOG(ERROR) << "Unexpected signal %d" << signal_number;
        break;
    }
}
```

- SIGQUIT信号的处理

发生ANR的时候，system_server进程会执行dumpStackTraces函数，在该函数中会发送一个SIGQUIT信号给对应的进程，用来获取该进程的一些运行时信息，并最终把这些信息输出到/data/anr/traces.txt文件里面。

```
public static File dumpStackTraces(boolean clearTraces, ArrayList<Integer> firstPids,
            ProcessCpuTracker processCpuTracker, SparseArray<Boolean> lastPids, String[] nativeProcs) {
        String tracesPath = SystemProperties.get("dalvik.vm.stack-trace-file", null);
        if (tracesPath == null || tracesPath.length() == 0) {
            return null;
        }

        File tracesFile = new File(tracesPath);
        try {
            File tracesDir = tracesFile.getParentFile();
             if (!tracesDir.exists()) {
                tracesDir.mkdirs();
                if (!SELinux.restorecon(tracesDir)) {
                    return null;
                }
            }
            FileUtils.setPermissions(tracesDir.getPath(), 0775, -1, -1);  // drwxrwxr-x

            if (clearTraces && tracesFile.exists()) tracesFile.delete();
            tracesFile.createNewFile();
            FileUtils.setPermissions(tracesFile.getPath(), 0666, -1, -1); // -rw-rw-rw-
        } catch (IOException e) {
            Slog.w(TAG, "Unable to prepare ANR traces file: " + tracesPath, e);
            return null;
        }

        dumpStackTraces(tracesPath, firstPids, processCpuTracker, lastPids, nativeProcs);
        return tracesFile;
    }
```

如果一个进程接收到了SIGQUIT信号的时候，Signal Catcher线程的signal_catcher->WaitForSignal(self, signals);这个语句就会返回，返回后接着会调用HandleSigQuit @ Signal _Watcher.cc函数来处理该信号。

```
void SignalCatcher::HandleSigQuit() {
    Runtime* runtime = Runtime::Current();
    std::ostringstream os;
    ......
    DumpCmdLine(os);
    ......
    runtime->DumpForSigQuit(os);
    ......
    }
    ......
    Output(os.str());
}
```

Signal Catcher线程的作用是打印当前进程的堆栈（Java、Native、Kernel），同时还会把当前虚拟机的一些状态信息也打印出来，这就是我们所看到的traces.txt文件内容，HandleSigQuit函数里面先建立了标准输出流，把所有的信
息都输出到这个输出流里面，其实也就是保存在内存当中，当dump过程完了之后，最后调用Output函数将输出流的内容保存到文件里面。

```
void Runtime::DumpForSigQuit(std::ostream& os) {
    GetClassLinker()->DumpForSigQuit(os); //已经加载和初始化的类、方法等信息
    GetInternTable()->DumpForSigQuit(os);
    GetJavaVM()->DumpForSigQuit(os);
    GetHeap()->DumpForSigQuit(os); //GC信息
    TrackedAllocators::Dump(os);//对象分配信息
    os << "\n";
    thread_list_->DumpForSigQuit(os); //线程堆栈信息
    BaseMutex::DumpAll(os);
}
```

从Runtime的DumpForSigQuit这个函数里，大致可以看到都dump了哪些运行时信息。dump过程里面读取了哪些信息其实并不重要，重要的是什么时候去读取这些信息，也就是说什么条件下去dump才能保证获取的确实是我们需要的东西，
例如GC信息、当前分配了多少对象、线程堆栈的打印等一般都需要suspend当前进程里面所有的线程，接下来主要分析的就是这个suspend过程。SuspendAll是在Thread_list.cc中实现的，它的作用就是用来suspend当前进程里面所有其
他的线程，SuspendAll一般发生在像GC、DumpForSigQuit等过程中。

```
void ThreadList::SuspendAll(const char* cause, bool long_suspend) {
    Thread* self = Thread::Current();
    ......
    ++suspend_all_count_;
    // Increment everybody's suspend count (except our own).
    for (const auto& thread : list_) {
          if (thread == self) {
              continue;
          }
        VLOG(threads) << "requesting thread suspend: " << *thread;
        thread->ModifySuspendCount(self, +1, false);
        ......
     }
}
```

其实SuspendAll的实现过程非常简单，其中最重要的就是thread->ModifySuspendCount(self, +1, false);这一语句，它会修改对应Thread对象的suspend引用计数，核心代码如下：

```
void Thread::ModifySuspendCount(Thread* self, int delta, bool for_debugger) {
    ......
    tls32_.suspend_count += delta;
    ......
    if (tls32_.suspend_count == 0) {
        AtomicClearFlag(kSuspendRequest);
    } else {
        AtomicSetFlag(kSuspendRequest);
        TriggerSuspend();
   }
}
```

因为我们传入的delta的值是+1，所以会走到if语句的else分支，它首先使用原子操作设置了kSuspendRequest标志位，代表当前这个Thread对象有suspend请求，那么什么时候会触发线程去检查这个标志位呢？CheckSuspend这个函数在
运行时当中会有好几个地方被调用到，我们先看其中的两个

```
static void GoToRunnable(Thread* self) NO_THREAD_SAFETY_ANALYSIS {
    ArtMethod* native_method = *self->GetManagedStack()->GetTopQuickFrame();
    bool is_fast = native_method->IsFastNative();
    if (!is_fast) {
        self->TransitionFromSuspendedToRunnable();
    } else if (UNLIKELY(self->TestAllFlags())) {
        // In fast JNI mode we never transitioned out of runnable. Perform a suspend check if there
        // is a flag raised.
        DCHECK(Locks::mutator_lock_->IsSharedHeld(self));
        self->CheckSuspend();
    }
}
```

```
extern "C" void artTestSuspendFromCode(Thread* self) SHARED_LOCKS_REQUIRED(Locks::mutator_lock_) {
    // Called when suspend count check value is 0 and thread->suspend_count_ != 0
    ScopedQuickEntrypointChecks sqec(self);
    self->CheckSuspend();
}
```

GoToRunnable是在线程切换到Runnable状态的时候会调用到，而artTestSuspendFromCode如我们前面所讲的是提供给编译好的native代码调用的，他们都调用了Thread的CheckSuspend函数，所以只要给对应线程的Thread对象设置了kSuspendRequest标志位，那么这个线程基本上都是可以暂停下来的，除非因为某些原因当前线程被阻塞住了并且该线程还恰好占据了Locks::mutator_lock_这个读写锁，导致调用SuspendAll的线程阻塞在这个读写锁上面，最终导致suspend超时，如SuspendAll的如下代码所示：

```
void ThreadList::SuspendAll(const char* cause, bool long_suspend) {
    ......
    #if HAVE_TIMED_RWLOCK
    while (true) {
        if (Locks::mutator_lock_->ExclusiveLockWithTimeout(self, kThreadSuspendTimeoutMs, 0)) {
            break;
        } else if (!long_suspend_) {
            ......
            UnsafeLogFatalForThreadSuspendAllTimeout();
        }
    }
    #else
    Locks::mutator_lock_->ExclusiveLock(self);
    #endif
    ......
}
```

接下来我们着重分析Thread的CheckSuspend这个函数，这个函数里面才会把当前线程真正suspend住.

```
inline void Thread::CheckSuspend() {
    DCHECK_EQ(Thread::Current(), this);
    for (;;) {
        if (ReadFlag(kCheckpointRequest)) {
           RunCheckpointFunction();
        } else if (ReadFlag(kSuspendRequest)) {
           FullSuspendCheck();
        } else {
            break;
        }
    }
}
```

如果检测到设置了kCheckpointRequest标记就会执行RunCheckpointFunction函数，另外如果检测到设置了kSuspendRequest标记就会执行FullSuspendCheck函数，kCheckpointRequest标志位是用来dump线程的堆栈的，分析完SuspendAll之后，我们再着重看这个标志位的作用，这里我们继续分析FullSuspendCheck这个函数：

```
void Thread::FullSuspendCheck() {
    VLOG(threads) << this << " self-suspending";
    ATRACE_BEGIN("Full suspend check");
    // Make thread appear suspended to other threads, release mutator_lock_.
    tls32_.suspended_at_suspend_check = true;
    TransitionFromRunnableToSuspended(kSuspended);
    // Transition back to runnable noting requests to suspend, re-acquire share on mutator_lock_.
    TransitionFromSuspendedToRunnable();
    tls32_.suspended_at_suspend_check = false;
    ATRACE_END();
    VLOG(threads) << this << " self-reviving";
}
```

调用TransitionFromRunnableToSuspended这个函数之后，当前Java线程就进入了kSuspended状态，然后在调用TransitionFromSuspendedToRunnable从suspend切换到Runnable状态的时候，就会阻塞在一个条件变量上，除非调用SuspendAll的线程接着又调用了ResumeAll函数，要不然这些线程就会一直被阻塞住。

```
void ThreadList::ResumeAll() {
    Thread* self = Thread::Current();
    ......
    Locks::mutator_lock_->ExclusiveUnlock(self);
    {
        ......
        --suspend_all_count_;
        // Decrement the suspend counts for all threads.
        for (const auto& thread : list_) {
           if (thread == self) {
                continue;
           }
        thread->ModifySuspendCount(self, -1, false); //修改线程的suspend计数
        }
    ......
    Thread::resume_cond_->Broadcast(self);//唤醒那些等待这个条件变量的线程
    }
    ......
}
```

至此我们就把SuspendAll的过程分析完了，我们上面提到过dump线程堆栈的时候并不是在设置了kSuspendRequest标志位之后会执行的，与它相关的是另外一个标志位kCheckpointRequest.  接下来我们看一下Thread_list的Dump函数,>这个函数会在Thread_list的DumpForSigQuit中会被调用到，也就是在Signal Cathcer线程处理SIGQUIT信号的过程中。
```
void ThreadList::Dump(std::ostream& os) {
    ......
    DumpCheckpoint checkpoint(&os);
    size_t threads_running_checkpoint = RunCheckpoint(&checkpoint);
    if (threads_running_checkpoint != 0) {
        checkpoint.WaitForThreadsToRunThroughCheckpoint(threads_running_checkpoint);
    }
}
```

这个函数里面首先创建了一个DumpCheckpoint对象checkpoint，然后以这个对象作为参数调用RunCheckpoint函数，RunCheckpoint会返回现在处于Runnable状态的线程个数，然后调用DumpCheckpoint的WaitForThreadsToRunThroughCheckpoint函数等待这些处于Runnable状态的线程都执行完DumpCheckpoint的Run函数，如果等待超时就会报Fatal类型的错误，如下所示：

```
void WaitForThreadsToRunThroughCheckpoint(size_t threads_running_checkpoint) {
    Thread* self = Thread::Current();
    ScopedThreadStateChange tsc(self, kWaitingForCheckPointsToRun);
    bool timed_out = barrier_.Increment(self, threads_running_checkpoint, kDumpWaitTimeout);
    if (timed_out) {
        // Avoid a recursive abort.
        LOG((kIsDebugBuild && (gAborting == 0)) ? FATAL : ERROR) << "Unexpected time out during dump checkpoint.";
    }
}
```

我们接着分析RunCheckpoint这个函数，这个函数有点长，我们分为两部分来分析该过程。

```
size_t ThreadList::RunCheckpoint(Closure* checkpoint_function) {
    ......
    for (const auto& thread : list_) {
       if (thread != self) {
           while (true) {
               if (thread->RequestCheckpoint(checkpoint_function)) {
                   kSuspendRequestcount++;
                   break;
               } else {
                   if (thread->GetState() == kRunnable) {
                       continue;
                    }
               thread->ModifySuspendCount(self, +1, false);
               suspended_count_modified_threads.push_back(thread);
               break;
            }
       }
   }
    ......
    return count;
}
```
对于那些处于Runnable状态的线程执行它的RequestCheckpoint函数会返回true，其他非Runnable状态的线程则会返回false，对于这些线程就会像SuspendAll过程中一样给它设置kSuspendRequest标志位，后面如果他们变为Runnable状
态的时候就会先检查这个标志位，从而进入suspend状态，同时RunCheckpoint函数会把这些线程统计到suspended_count_modified_threads这个Vector变量中，在suspended_count_modified_threads这个Vector变量中的线程，Signal Catcher线程会主动触发他们的dump堆栈过程。待会分析RunCheckpoint的第二部分的时候，我们再来看这个过程，我们先分析Thread的RequestCheckpoint函数。

```
bool Thread::RequestCheckpoint(Closure* function) {
    ......
    if (old_state_and_flags.as_struct.state != kRunnable) { //如果当前线程不为Runnable状态就直接返回false
        return false;  // Fail, thread is suspended and so can't run a checkpoint.
    }
    uint32_t available_checkpoint = kMaxCheckpoints;
    for (uint32_t i = 0 ; i < kMaxCheckpoints; ++i) {
        if (tlsPtr_.checkpoint_functions[i] == nullptr) { //在数组中寻找一个还没占据的空位
            available_checkpoint = i;
            break;
        }
    }
    ......
    tlsPtr_.checkpoint_functions[available_checkpoint] = function; //设置数组元素的值
    // Checkpoint function installed now install flag bit.
    // We must be runnable to request a checkpoint.
    DCHECK_EQ(old_state_and_flags.as_struct.state, kRunnable);
    union StateAndFlags new_state_and_flags;
    new_state_and_flags.as_int = old_state_and_flags.as_int;
    new_state_and_flags.as_struct.flags |= kCheckpointRequest; //设置kCheckpointRequest标志位
    ......
}
```

从前面Thread的CheckSuspend函数来看设置了kCheckpointRequest标志位的线程会执行RunCheckpointFunction这个函数，RunCheckpointFunction会检查checkpoint_functions数组是否为空，如果不为空，就会执行元素的run函数。

```
void Thread::RunCheckpointFunction() {
    ......
    for (uint32_t i = 0; i < kMaxCheckpoints; ++i) {
        if (checkpoints[i] != nullptr) {
             checkpoints[i]->Run(this);
             found_checkpoint = true;
        }
    }
    ......
}
```

其实就是执行DumpCheckpoint的Run函数，因为RequestCheckpoint(Closure* function)的function就是一个DumpCheckpoint对象，它是从Thread_list的Dump函数中传递过来的,我们看一下DumpCheckpoint的Run函数实现：

```
void Run(Thread* thread) OVERRIDE {
    Thread* self = Thread::Current();
    std::ostringstream local_os;
    {
        ScopedObjectAccess soa(self);
        thread->Dump(local_os); //调用Thread的Dump函数
    }
    ......
}
```

饶了一大圈，原来最终调用的还是Thread的Dump函数，这个函数就不继续分析了，线程的Java堆栈、Native堆栈和Kernel堆栈就是在这里打印的，有兴趣的同学可以自己去分析。上面我们说了对于处于Runnable状态的线程是通过调用>他们的RequestCheckpoint函数，然后他们自己去dump当前堆栈的，而对于那些不是处于Runnable状态的线程我们是把它添加到了suspended_count_modified_threads这个Vector中，我们接着分析RunCheckpoint函数的第二部分

```
size_t ThreadList::RunCheckpoint(Closure* checkpoint_function) {
    Thread* self = Thread::Current();
    ......
    checkpoint_function->Run(self); //以Signal Catcher线程的Thread对象为参数，主动调用DumpCheckpoint的Run函数
    // Run the checkpoint on the suspended threads.
    for (const auto& thread : suspended_count_modified_threads) {
        .......
        checkpoint_function->Run(thread);//主动调用DumpCheckpoint的Run函数
    {
        MutexLock mu2(self, *Locks::thread_suspend_count_lock_);
        thread->ModifySuspendCount(self, -1, false);//修改suspend引用计数
    }
    }
    ......
}
```

对于这些不是Runnable状态的线程，他们可能不会主动去调用Run函数，所以只能由Signal Catcher线程去帮他们Dump，至于DumpCheckpoint的Run函数的功能还是和Runnable状态的线程一样的，都是打印线程堆栈。
                                                                                                                                                                                           566,1         Bot
