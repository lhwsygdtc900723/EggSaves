//
//  Task.m
//  EggsSave
//
//  Created by 郭洪军 on 12/24/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import "Task.h"
#import <UIKit/UIKit.h>
#import "LoginManager.h"
#import "ProcessManager.h"
#import "DataCenter.h"

@interface Task ()
{
    NSTimer* swTimer;
    NSTimer* processTimer;
}

@property(assign, nonatomic)NSUInteger  swTime;


@end

@implementation Task

- (void)openit{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.url]];
}

- (void)weianzhuang{
    
    if (![DataCenter getInstance].isBackGround) {
        //弹出一个提示框
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"未安装此应用" message:@"请先安装此应用，返回任务列表" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
    }
}

- (void) start{
    
    //开始任务， 计时监控都在这里进行。
    
    BOOL isDownLoaded = NO;
    NSArray* arr = [[DataCenter getInstance] getPreBundleId];
    
    for (NSString* idd in arr) {
        if ([idd isEqualToString:self.bundleid]) {
            isDownLoaded = YES;
        }
    }
    
    if (isDownLoaded) {
        [NSThread detachNewThreadSelector:@selector(openit) toTarget:self withObject:nil];
        
        //开始监听任务
        //向服务器请求 任务开始
        [[LoginManager getInstance] requestToMonitorTime:_appid];
        //开始计时  计时需要定时器
        _swTime = 0;
        swTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(jishi) userInfo:nil repeats:YES];
        [swTimer fire];
    }else
    {
        //弹出一个提示框
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"未安装此应用" message:@"请先安装此应用，返回任务列表" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
    }
    
}

- (void)jishi{
    //判断试玩时间是否达到了任务要求的时间
    
    NSLog(@"swTime = %lu", (unsigned long)_swTime);
    
    if (_swTime >= _time * 60) {
        //任务完成 无需再进行监控
        [swTimer invalidate];
        swTimer = nil;
        
        _swTime = 0 ;
        
        //向服务器发请求任务已经完成
        [[LoginManager getInstance] requestTaskFinishedWithTaskID:_appid AppName:_name AppUrl:_url OtherName:_otherName Bounus:_bounus] ;
        
        NSLog(@"任务完成") ;
    }
    
    _swTime += 1;
}

- (void)stopTimer{
    
    if (swTimer) {
        [swTimer invalidate];
        swTimer = nil;
    }
    
    if (processTimer) {
        [processTimer invalidate];
        processTimer = nil;
    }
    
}


@end
