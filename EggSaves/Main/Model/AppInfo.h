//
//  AppInfo.h
//  EggSaves
//
//  Created by 郭洪军 on 5/21/16.
//  Copyright © 2016 郭洪军. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppInfo : NSObject

/**
 *  对应进程的进程号
 */
@property (copy, nonatomic)NSString* appName;

/**
 *  通过这个appUrl打开应用
 */
@property (copy, nonatomic)NSString* appUrl;

/**
 *  通过app bundle id 获取手机所有已经安装的应用
 */
@property (copy, nonatomic)NSString* appBundleID;

@end
