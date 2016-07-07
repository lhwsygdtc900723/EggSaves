//
//  TasksManager.m
//  EggsSave
//
//  Created by 郭洪军 on 12/24/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import "TasksManager.h"
#import "Task.h"
#import "ProcessManager.h"

@interface TasksManager()

@property(strong, nonatomic)NSArray* mTasks;

@end

@implementation TasksManager

+ (id)getInstance
{
    static TasksManager* sharedTasksManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTasksManager = [[self alloc]init];
    });
    
    return sharedTasksManager;
}

- (void)setTasks:(NSArray *)tasks
{
    self.mTasks = tasks;
}

- (NSArray*)getTasks
{
    return _mTasks;
}

- (NSUInteger)getTimeFromDetailString:(NSString*)str
{
    NSString *regex = @"试玩\\d分钟";
    NSError *error;
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex
                                                                             options:NSRegularExpressionCaseInsensitive
                                                                               error:&error];
    // 对str字符串进行匹配
    NSArray *matches = [regular matchesInString:str
                                        options:0
                                          range:NSMakeRange(0, str.length)];
  
    NSUInteger shiwantime ;
    if (matches.count > 0) {
        NSTextCheckingResult *match = matches[0];
        NSRange range = [match range];
        NSString *mStr = [str substringWithRange:range];
        
        NSString* st1 = [mStr stringByReplacingOccurrencesOfString:@"试玩" withString:@""];
        NSString* st2 = [st1 stringByReplacingOccurrencesOfString:@"分钟" withString:@""];
        
        if (st2) {
            shiwantime = [st2 integerValue];
        }else
        {
            shiwantime = 0;
        }
    }else
    {
        shiwantime = 5;
    }
    
    return shiwantime ;
}

- (NSArray *)parseLoginData:(NSDictionary *)data
{
    NSDictionary* dict = data;
    NSArray* dataArr = dict[@"data"];
    
    //此处需要扫描手机已经安装的应用，如果已经安装，就不再显示
    NSArray* installedAppBundles = [[ProcessManager getInstance] getAllAppsInstalled];
    
    NSMutableArray* listExist = [NSMutableArray new];
    
    for (int i=0; i<[dataArr count]; i++) {
        NSDictionary* tempDict = dataArr[i];
        
        long      t_id = [tempDict[@"id"] longValue];   //任务id
        NSString*  t_bundleId = tempDict[@"bundleId"];    //app bundle id
        
        if (!t_bundleId) {
            t_bundleId = @"1111111";
        }
        BOOL isExist = NO;
        
        for (NSUInteger j = 0; j<installedAppBundles.count; ++j) {
            if ([installedAppBundles[j] isEqualToString:t_bundleId]) {
                
                //手机已安装
                isExist = YES;
                
                [listExist addObject:[NSString stringWithFormat:@"%ld",t_id]] ;
                
            }
        }
    }

    return listExist;
}

@end
