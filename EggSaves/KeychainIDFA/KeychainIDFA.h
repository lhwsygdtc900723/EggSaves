//
//  KeychainIDFA.h
//  KeychainIDFA
//
//  Created by Qixin on 14/12/18.
//  Copyright (c) 2014年 Qixin. All rights reserved.
//

#import <Foundation/Foundation.h>

//设置你idfa的Keychain标示,该标示相当于key,而你的IDFA是value
#define IDFA_STRING @"com.adwan.eggs.idfa"
#define USERID_STRING @"com.adwan.eggs.userid"
#define PASWORD_STRING @"com.adwan.eggs.password"

@interface KeychainIDFA : NSObject

//获取IDFA
+ (NSString*)IDFA;

//删除keychain的IDFA(一般不需要)
+ (void)deleteIDFA;

+ (NSString*)getIdfaString;
+ (BOOL)setIdfaString:(NSString *)secValue;

//userid
+ (void)deleteUSERID;

+ (NSString*)getUserId;
+ (BOOL)setUserID:(NSString *)userID;

//password
+ (void)deletePassword;

+ (NSString *)getPassword;
+ (BOOL)setPassword:(NSString *)password;

@end
