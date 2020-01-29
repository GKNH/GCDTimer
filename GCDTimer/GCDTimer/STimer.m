//
//  STimer.m
//  GCDTimer
//
//  Created by Sun on 2020/1/29.
//  Copyright © 2020 sun. All rights reserved.
//

#import "STimer.h"

@implementation STimer

static NSMutableDictionary *timers_;
dispatch_semaphore_t semaphore_;

// initialize 是类在第一次接收到消息时候调用
+ (void)initialize {
    // 保证 timers_，semaphore_ 只被初始化一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timers_ = [NSMutableDictionary dictionary];
        semaphore_ = dispatch_semaphore_create(1);
    });
}
/**
   执行任务，任务是block形式
   返回可以取得定时器的 key
 */
+ (NSString *)execTask:(void (^)(void))task start:(NSTimeInterval)start interval:(NSTimeInterval)interval repeats:(BOOL)repeats async:(BOOL)async {
    
    // 如果task不存在 或者 开始时间小于0 或者 需要重复操作，但是操作的时间间隔 <= 0 直接返回n空
    if (!task || start < 0 || (interval <= 0 && repeats)) return nil;
    /**
     创建队列
     如果 async 为 YES，表示需要异步执行任务（新线程执行任务），那么就创建新的全局队列
     如果 async 为 NO，表示不需要异步执行任务，那么直接用主队列即可
     */
    dispatch_queue_t queue = async ? dispatch_get_global_queue(0, 0) : dispatch_get_main_queue();
    /**
     创建源
     创建的源类型是 DISPATCH_SOURCE_TYPE_TIMER （定时器类型）
     放在队列 queue 里
     */
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    /**
     设置时间源
     dispatch_source_set_timer(
     dispatch_source_t source, // 源
     dispatch_time_t start, // unsigned long long 开始时间
     uint64_t interval, // unsigned long long 间隔时间
     uint64_t leeway); // unsigned long long 允许偏差
     
     typedef unsigned long long uint64_t;
     typedef uint64_t dispatch_time_t;
     */
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC), interval * NSEC_PER_SEC, 0);
    
    // 加锁
    dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
    // 字典的数量当做key
    NSString *name = [NSString stringWithFormat:@"%zd", timers_.count];
    // 添加字典元素
    timers_[name] = timer;
    // 解锁
    dispatch_semaphore_signal(semaphore_);
    // 定时器执行任务会回调block
    dispatch_source_set_event_handler(timer, ^{
        // 执行任务
        task();
        // 如果不需要重复执行任务，就结束任务
        if (!repeats) {
            [self cancelTask:name];
        }
    });
    
    // 重新开始定时器
    dispatch_resume(timer);
    return name;
}

// 执行任务，任务是 target selector 形式
+ (NSString *)execTask:(id)target selector:(nonnull SEL)selector start:(NSTimeInterval)start interval:(NSTimeInterval)interval repeats:(NSTimeInterval)repeats async:(BOOL)async {
 
    // 执行任务者不存在 或者 任务为空，返回 nil
    if (!target || !selector) return nil;
    
    // 返回可以取得定时器的 key
    return [self execTask:^{
        if ([target respondsToSelector:selector]) {
            [target performSelector:selector];
        }
    } start:start interval:interval repeats:repeats async:async];
    
}

+ (void)cancelTask:(NSString *)name {
    // key 是空，什么都不做
    if (name.length == 0) return;
    // 加锁
    dispatch_semaphore_wait(semaphore_, DISPATCH_TIME_FOREVER);
    // 从字典中取出源 source
    dispatch_source_t timer = timers_[name];
    // 如果源存在
    if (timer) {
        // 停止源
        dispatch_source_cancel(timer);
        // 从字典中移除源
        [timers_ removeObjectForKey:name];
    }
    // 解锁
    dispatch_semaphore_signal(semaphore_);
}
@end
