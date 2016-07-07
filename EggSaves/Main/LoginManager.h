//
//  LoginManager.h
//  EggsSave
//
//  Created by 郭洪军 on 12/24/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LoginManager : NSObject

+ (id)getInstance;

/**
 *  注册接口
 */
- (void)signUp;

/**
 *  登录接口
 */
- (void)login;

/**
 *  查询所有的任务
 */
- (void)requestAllTasks;

/**
 *  向服务器提交本地已经下载的应用的任务列表
 */
- (void)requestWithTaskIds:(NSArray *)ids;

/**
 *  向服务器请求任务已经完成
 */
- (void)requestTaskFinishedWithTaskID:(NSString*)taskid;

@end




