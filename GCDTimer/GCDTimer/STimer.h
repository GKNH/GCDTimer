//
//  STimer.h
//  GCDTimer
//
//  Created by Sun on 2020/1/29.
//  Copyright © 2020 sun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STimer : NSObject

// 执行任务，任务是block形式
+ (NSString *)execTask:(void(^)(void))task
                 start:(NSTimeInterval)start
              interval:(NSTimeInterval)interval
               repeats:(BOOL)repeats async:(BOOL)async;

// 执行任务，任务是 target selector 形式
+ (NSString *)execTask:(id)target selector:(SEL)selector start:(NSTimeInterval)start interval:(NSTimeInterval)interval repeats:(NSTimeInterval)repeats async:(BOOL)async;

// 停止任务
+ (void)cancelTask:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
