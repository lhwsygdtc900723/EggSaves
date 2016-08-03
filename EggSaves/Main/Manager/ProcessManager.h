//
//  ProcessManager.h
//  EggsSave
//
//  Created by 郭洪军 on 4/5/16.
//  Copyright © 2016 Adwan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProcessManager : NSObject

+ (ProcessManager *)getInstance;

/**
 *  扫描手机中所有当前正在运行的进程
 */
- (void)loadIOKit ;

/**
 *  判断进程name是否正在运行
 */
- (BOOL)processIsRunning:(NSString *)name;

/**
 *  获取所有已安装应用的bundle id
 **/
- (NSArray *)getAllAppsInstalled;

/**
 *  获取自己操作过的任务白名单 （此版本可能并不需要这个接口）
 */
- (NSArray *)getWhiteList ;

/**
 *  将某一个app bundle id 写入到任务白名单 （此版本可能并不需要这个接口）
 */
- (void)writeToWhiteList:(NSString *)bundleId;

@end
