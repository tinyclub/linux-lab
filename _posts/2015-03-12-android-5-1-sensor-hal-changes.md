---
title: 解析 Android 5.1 Sensor HAL
author: Wen Pingbo
layout: post
permalink: /android-5-1-sensor-hal-changes/
tags:
  - Android 5.1
  - Android L
  - HAL
  - Lollipop
  - Sensor
categories:
  - Linux
---

> by WEN Pingbo of [TinyLab.org][1]
> 2015/03/11


## 预热

前几天研究了 Android 5.1 相对于 Android 4.4，Sensor HAL 做了什么改动。然后就有了这篇文章。

首先，怎么知道 Android 5.1 对 Sensor HAL 改了什么东西呢？其实只要运行了一下如下命令：

<pre>diff -u /path/to/android_5.1/hardware/libhardware/include/hardware/sensors.h \
            /path/to/android_4.4/hardware/libhardware/include/hardware/sensors.h
</pre>

估计都懂了。

## Android 5.1 Sensor HAL

好！进入正题！

一起来看看 Android 5.1 Sensor HAL 到底 引入了哪些变更？

### 更新 API Version 到 1.3

这次 Android 5.1 的更新，首先带来的就是 API Version 的更新。Anroid 4.4 用的是 1.1 的 API，到了 Android 5.1，改用 1.3 了。

### 新增 Flag：SENSOR_FLAG_WAKE_UP

其次，是增加了 `SENSOR_FLAG_WAKE_UP` 这个FLAG。带有 Wake Up Flag 的 Sensor，在有事件上报，或者 FIFO 满了的时候，都需要唤醒 AP。而非 Wake Up Sensor，则只能把数据存在 FIFO 中，而不能唤醒 AP，若 FIFO 满了，则覆盖。根据 Android 的描述，带有这个 Flag 的 Sensor，在数据上报时，驱动中需要保持一个 `wake_lock`。等 SensorService 把数据读回后，驱动释放 `wake_lock`，SensorService 会保持一个 `wake_lock`，让上层 APP 有时间处理这个事件。

同时在 Sensor HAL 这边，对于一个 Sensor 来说，它可以同时声明两个 Sensor Type，一个带 WAKE FLAG，另外一个不带。比如我们可以在写 Sensor List 的时候，做如下定义：

<pre>static struct sensor_t baseSensorList[] = {
    {
        "XXX Gyroscope", "XXX", 1,
         SENSORS_GYROSCOPE_HANDLE,
         SENSOR_TYPE_GYROSCOPE, 2000.0f, 1.0f, 0.5f, 10000, 0, 62,
         "android.sensor.gyroscope", "", 10000, SENSOR_FLAG_CONTINUOUS_MODE, {}
    },
    {
        "XXX Gyroscope - Wakeup", "XXX", 1,
         SENSORS_GYROSCOPE_WAKEUP_HANDLE,
         SENSOR_TYPE_GYROSCOPE, 2000.0f, 1.0f, 0.5f, 10000, 0, 62,
         "android.sensor.gyroscope", "", 10000, SENSOR_FLAG_CONTINUOUS_MODE | SENSOR_FLAG_WAKE_UP, {}
    },
};
</pre>

然后把这两个 Sensor 当做两个不同的 Sensor 去实现其 handler。这样，上层 APP 在用 `SensorManger::getDefaultSensor (int type, boolean wakeUp)` 来获取 Sensor 时，就可以指定是否带 Wake Up Flag。

这里要注意的是，一定要慎重选择是否带 Wake Up Flag，因为这对手机功耗有很大的影响。估计很多 OEM 厂商会在这个地方优化，不会任由上层 APP 去获取带 Wake Up Flag 的 Sensor。

### struct sensor_t 新增三字段

第三，Android 5.1 在 `struct sensor_t` 添加了3个新的字段：

<pre>const char* stringType;
    const char* requiredPermission;
    uint64_t flags;
</pre>

Android 规定，若 Sensor 的 Type 不是 Android 所支持的类型，则 stringType 不能是 `"android.sensor.*"`，这个字段应该是由于 Wake Up Flag 的加入，才添加进来，用来表示一个类的 Sensor。而对于 requiredPermission，暂时还没搞清楚这么个用法。flags 字段当然是用来放 Sensor 的 Mode 啦。

### 新增了 9 个 Sensor Type

最后一个改动，Android 5.1 添加了很多新类型的 Sensor：

<pre>SENSOR_TYPE_HEART_RATE
    SENSOR_TYPE_TILT_DETECTOR
    SENSOR_TYPE_WAKE_GESTURE
    SENSOR_TYPE_GLANCE_GESTURE
    SENSOR_TYPE_PICK_UP_GESTURE
    SENSOR_TYPE_IN_POCKET
    SENSOR_TYPE_ACTIVITY
    SENSOR_TYPE_FACE_DOWN
    SENSOR_TYPE_SHAKE
</pre>

每个 Sensor 具体的实现就不说了。但有一点疑问，就是完全不懂 Android 到底要干嘛。有些 Sensor，完全可以合并在一起，像 `TILT`, `GLANCE`, `PICK_UP` 和 `SHAKE`完全属于 GESTURE 范畴，`IN_POCKET`，`FACE_DOWN`，`ACTIVITY` 也是手机 STATE 范畴。而 `WAKE_GESTURE` 更加模糊，把很多 Sensor 厂商都搞懵了，这个 `WAKE_GESUTRE` 好像包含了其他那些 GESTURE。按这种逻辑，估计要不了多久，Android 的 Sensor 类型就会爆炸了。





 [1]: http://tinylab.org
