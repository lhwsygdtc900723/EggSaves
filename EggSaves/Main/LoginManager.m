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

NSString* const NSUserSignUpNotification           = @"NSUserSignUpNotification" ;
NSString* const NSUserLoginNotification            = @"NSUserLoginNotification" ;
NSString* const NSUserCommitListIdsNotification    = @"NSUserCommitListIdsNotification" ;
NSString* const NSUserDoTaskCompletedNotification  = @"NSUserDoTaskCompletedNotification" ;

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
    NSString* userIDFA = [KeychainIDFA IDFA];
    NSString* uncal = [NSString stringWithFormat:@"{\"%@\":\"%@\"}",@"IDFA",userIDFA];
    
    NSDictionary *t1 = @{@"IDFA":userIDFA} ;
    
    NSURLRequest* request = [self requestWithInterface:@"100" Data:t1 UncalData:uncal];
        
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response,NSData *data, NSError *connectionError) {
        
        if (!data) {
            NSLog(@"未获取到数据");
            return ;
        }
        
        NSDictionary *dict = [self getDataFromEncryptData:data];
        NSDictionary* responseDict = dict[@"response"];
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserSignUpNotification object:nil userInfo:responseDict];
        
        
    }];
}

- (void)login
{
    NSLog(@"用户登录") ;
    NSString* usid = [KeychainIDFA getUserId];
    
    NSDictionary *t1 = @{@"userId":usid} ;
    NSString* uncal = [NSString stringWithFormat:@"{\"%@\":\"%@\"}",@"userId",usid];
    
    NSURLRequest* request = [self requestWithInterface:@"102" Data:t1 UncalData:uncal];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response,NSData *data, NSError *connectionError) {
        if (!data) {
            NSLog(@"未获取到数据");
            return ;
        }
        
        NSDictionary* dict = [self getDataFromEncryptData:data];
        NSDictionary* responseDict = dict[@"response"];
        [[NSNotificationCenter defaultCenter] postNotificationName:NSUserLoginNotification object:nil userInfo:responseDict];
    }];
}

- (void)requestWithTaskIds:(NSArray *)ids
{
    NSLog(@"用户提交任务列表") ;
    NSString* usid = [KeychainIDFA getUserId];
//    {"taskIdList":"[\"29\"]","userId":"287"}
    NSDictionary *t1 = @{@"userId":usid, @"taskIdList":ids} ;
    NSString* uncal = [NSString stringWithFormat:@"{\"%@\":\"%@\"}",@"userId",usid];
    
    NSURLRequest* request = [self requestWithInterface:@"134" Data:t1 UncalData:uncal];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response,NSData *data, NSError *connectionError) {
        if (!data) {
            NSLog(@"未获取到数据");
            return ;
        }
        
        NSDictionary* dict = [self getDataFromEncryptData:data];
        NSDictionary* responseDict = dict[@"response"];
        [[NSNotificationCenter defaultCenter] postNotificationName:NSUserCommitListIdsNotification object:nil userInfo:responseDict];
    }];
}

- (void)requestTaskFinishedWithTaskID:(NSString*)taskid
{
    NSString* usid = [KeychainIDFA getUserId];
    NSDictionary *t1 = @{@"userId":usid,@"taskId":taskid,@"successState":@"0"} ;
    NSString* uncal = [NSString stringWithFormat:@"{\"%@\":\"%@\",\"%@\":\"%@\",\"%@\":\"%@\"}",@"successState",@"0",@"taskId",taskid,@"userId",usid];
    
    NSURLRequest* request = [self requestWithInterface:@"128" Data:t1 UncalData:uncal];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response,NSData *data, NSError *connectionError) {
        if (!data) {
            NSLog(@"未获取到数据");
            return ;
        }
        NSDictionary* dict = [self getDataFromEncryptData:data];
        NSDictionary* responseDict = dict[@"response"];
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserDoTaskCompletedNotification object:responseDict];
    }];
}

@end
