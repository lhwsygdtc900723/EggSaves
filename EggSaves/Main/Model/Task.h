//
//  Task.h
//  EggsSave
//
//  Created by 郭洪军 on 12/24/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Task : NSObject

@property(copy, nonatomic)NSString*     appid;                //任务Id
@property(copy, nonatomic)NSString*     name;                 //要试玩应用的进程号
@property(copy, nonatomic)NSString*     url;                  //打开应用的url
@property(assign, nonatomic)NSUInteger  time;                 //需要试玩应用的时间
@property(copy, nonatomic)NSString*     bundleid;             //试玩应用的bundleid
@property(copy, nonatomic)NSString*     otherName;            //任务名称
@property(assign, nonatomic)float       bounus;               //任务奖励


- (void) start;

//卸载应用的时候，需要停止计时
- (void)stopTimer;

@end


static inline Task* TaskMake(NSString* tId, NSString* tName, NSString* tUrl, NSUInteger tTime, NSString* bundleId, NSString* otherName, float bounus)
{
    Task* task = [[Task alloc] init];
    
    task.appid = tId;
    task.name  = tName;
    task.url   = tUrl;
    task.time  = tTime;
    task.bundleid = bundleId;
    task.otherName = otherName;
    task.bounus = bounus;
    
    return task;
}

