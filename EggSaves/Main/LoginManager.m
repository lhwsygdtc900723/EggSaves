//
//  LoginManager.m
//  EggsSave
//
//  Created by 郭洪军 on 12/24/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import "LoginManager.h"
#import "HashUtils.h"
#import "EncryptUtils.h"
#import "TasksManager.h"
#import "KeychainIDFA.h"
#import "CommonDefine.h"
#import "AFNetworking.h"
#import "DataCenter.h"
#import "NSString+MD5.h"

NSString* const NSUserSignUpNotification           = @"NSUserSignUpNotification" ;
NSString* const NSUserRequestAllTaskNotification   = @"NSUserRequestAllTaskNotification" ;
NSString* const NSUserLoginNotification            = @"NSUserLoginNotification" ;
NSString* const NSUserCommitListIdsNotification    = @"NSUserCommitListIdsNotification" ;
NSString* const NSUserDoTaskCompletedNotification  = @"NSUserDoTaskCompletedNotification" ;

static NSInteger signupcount = 0;

@implementation LoginManager

+ (id)getInstance
{
    static LoginManager* sharedloginmanager = nil;
    
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedloginmanager = [[self alloc]init];
    });
    
    return sharedloginmanager;
}

- (NSURLRequest *)requestWithInterface:(NSString *)interface Data:(NSDictionary *)data UncalData:(NSString*)uncalStr
{
    // 1.创建请求
    NSString* urlString = [NSString stringWithFormat:@"http://%@/newwangluo/app/%@.dsp", DOMAIN_URL,interface];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    // 2.设置请求头
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString* uncal = uncalStr;
    const char *cuncal =[uncal UTF8String];
    
    int caledKey = [HashUtils calculateHashKey:(unsigned char*)cuncal];
    NSString* keyStr = [NSString stringWithFormat:@"%d",caledKey];
    
    // 3.设置请求体
    NSDictionary *json = @{@"data":data,@"KEY":keyStr};
    
    NSData *data1 = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    
    Byte *dataByte = (Byte *)[data1 bytes];
    
    Byte* encryptByte = [EncryptUtils xorString:dataByte len:(int)[data1 length]];
    Byte* e1 = (Byte*)malloc([data1 length]);
    memset(e1, 0, [data1 length] + 1);
    memcpy(e1, encryptByte, [data1 length]);
    free(encryptByte);
    
    NSData *encryptData = [[NSData alloc] initWithBytes:e1 length:(int)[data1 length]];
    
    request.HTTPBody = encryptData;
    
    free(e1);
    
    return request;
}

- (NSDictionary *)getDataFromEncryptData:(NSData*)data
{
    unsigned char* decryptByte = [EncryptUtils xorString:(Byte *)[data bytes] len:(int)[data length]];
    NSData* dataData = [[NSData alloc]initWithBytes:decryptByte length:[data length]];
    
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:dataData options:NSJSONReadingMutableLeaves error:nil];
    
    free(decryptByte);
    
    return dict;
}

- (void)signUp
{
    signupcount ++;
    if (signupcount > 3) {
        return;
    }
    
    NSString* userIDFA = [KeychainIDFA IDFA];
    
    __weak __typeof__(self) weakSelf = self;
    
    NSString* requestStr = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/player/register.app?key=%@&idfa=%@", @"ghj", userIDFA];
    NSURL *URL = [NSURL URLWithString:requestStr];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
    
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSDictionary* dict = responseObject;
        
        BOOL success = [dict[@"success"] boolValue];
        
        if (success) {
            NSDictionary* dataDict = dict[@"data"];
            
            long userid = [dataDict[@"p"] longValue];
            NSString* passwd = dataDict[@"w"];
            
            [KeychainIDFA setUserID:[NSString stringWithFormat:@"%ld", userid]];
            [KeychainIDFA setPassword:passwd];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:NSUserSignUpNotification object:nil userInfo:nil];
        }else
        {
            [weakSelf requestAllTasks];
        }
        
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"FlyElephant-Error: %@", error);
        
        [weakSelf requestAllTasks];
        
    }];
    
}

- (void)requestAllTasks
{
    NSString* userID = [KeychainIDFA getUserId] ;
    
    NSString* requestStr = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/palyerTask/queryAcceptableTasks.app?playerSequenceId=%@", userID];
    NSURL *URL = [NSURL URLWithString:requestStr];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
    
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSDictionary* dict = responseObject;
        
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserRequestAllTaskNotification object:nil userInfo:dict];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"FlyElephant-Error: %@", error);
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserRequestAllTaskNotification object:nil userInfo:nil];
    }];
}

- (void)login
{
    NSString* usid = [KeychainIDFA getUserId];
    NSString* pwd  = [KeychainIDFA getPassword];
    
    NSString* requestUrl = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/login.app?playerSequenceId=%@&password=%@", usid, pwd];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:requestUrl]] ;
    
}

- (void)requestWithTaskIds:(NSArray *)ids
{
    NSString* userID = [KeychainIDFA getUserId] ;
    NSString* pwd    = [KeychainIDFA getPassword];
    
    NSString* requestStr = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/playertTask/hideTasks.app?playerSequenceId=%@&password=%@&doHideTasks=%@", userID, pwd, ids];
    NSURL *URL = [NSURL URLWithString:requestStr];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
    
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSDictionary* dict = responseObject;
        
        NSLog(@"dict");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NSUserCommitListIdsNotification object:nil userInfo:dict];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"FlyElephant-Error: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NSUserCommitListIdsNotification object:nil userInfo:nil];
    }];
    
}

- (void)requestTaskFinishedWithTaskID:(NSString*)taskid
{
    
    
    NSString* appurl  = [[DataCenter getInstance] getappurl];
    NSString* appname = [[DataCenter getInstance] getappname];
    NSString* appid   = [[DataCenter getInstance] getappid];
    
    NSString* userid  = [KeychainIDFA getUserId];
    
    NSString* keystr  = [NSString stringWithFormat:@"%@%@%@ghj",appurl,appname,appid];
    NSString* key     = [keystr MD5Digest];
    
    NSString* requestStr = [NSString stringWithFormat:@"playerTask/complateTask.app?playerSequenceId=%@&key=%@", userid, key];
    NSURL *URL = [NSURL URLWithString:requestStr];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
    
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSDictionary* dict = responseObject;
        
        NSLog(@"dict");
        
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserDoTaskCompletedNotification object:nil];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"FlyElephant-Error: %@", error);
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserDoTaskCompletedNotification object:nil];
    }];
    
    
}

@end
