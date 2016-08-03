//
//  TimeHeart.h
//  EggsSave
//
//  Created by 郭洪军 on 4/5/16.
//  Copyright © 2016 Adwan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeHeart : NSObject

+ (TimeHeart *) getInstance;

@property(assign, nonatomic)NSUInteger  time;          //用于计时，做任务已经消耗的时间

@property(assign, nonatomic)BOOL        isDownloaded;  //判断试玩应用是否已下载,任务是否开始
@property(assign, nonatomic)NSUInteger  swTime;        //试玩了多长时间 shiwanTime

@end
