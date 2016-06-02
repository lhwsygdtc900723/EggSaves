//
//  TimeHeart.m
//  EggsSave
//
//  Created by 郭洪军 on 4/5/16.
//  Copyright © 2016 Adwan. All rights reserved.
//

#import "TimeHeart.h"

@implementation TimeHeart

+ (TimeHeart *) getInstance
{
    static TimeHeart* sharedHeart = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedHeart = [[self alloc]init];
        sharedHeart.time = 0;
        sharedHeart.isRunning = NO;
        sharedHeart.isDownloaded = NO;
        sharedHeart.swTime = 0;
    });
    
    return sharedHeart;
}

@end
