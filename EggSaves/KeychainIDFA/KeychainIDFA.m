//
//  KeychainIDFA.m
//  KeychainIDFA
//
//  Created by Qixin on 14/12/18.
//  Copyright (c) 2014年 Qixin. All rights reserved.
//

#import "KeychainIDFA.h"
#import "KeychainHelper.h"
@import AdSupport;

#define kIsStringValid(text) (text && text!=NULL && text.length>0)


@implementation KeychainIDFA


+ (void)deleteIDFA
{
    [KeychainHelper delete:IDFA_STRING];
}

+ (void)deleteUSERID
{
    [KeychainHelper delete:USERID_STRING];
}

+ (NSString*)IDFA
{
    //0.读取keychain的缓存
    NSString *deviceID = [KeychainIDFA getIdfaString];
    
    NSLog(@"deviceID = %@",deviceID);
    
    if (kIsStringValid(deviceID))
    {
        return deviceID;
    }
    else
    {
        //1.取IDFA,可能会取不到,如用户关闭IDFA
        if ([ASIdentifierManager sharedManager].advertisingTrackingEnabled)
        {
            deviceID = [[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString] lowercaseString];
            [KeychainIDFA setIdfaString:deviceID];
            return deviceID;
        }
        else
        {
            //2.如果取不到,就生成UUID,当成IDFA
            deviceID = [KeychainIDFA getUUID];
            [KeychainIDFA setIdfaString:deviceID];
            if (kIsStringValid(deviceID))
            {
                return deviceID;
            }
        }
    }
    //3.再取不到尼玛我也没办法了,你牛B.
    return nil;
}


#pragma mark - Keychain
+ (NSString*)getIdfaString
{
    NSString *idfaStr = [KeychainHelper load:IDFA_STRING];
    if (kIsStringValid(idfaStr))
    {
        return idfaStr;
    }
    else
    {
        return nil;
    }
}

+ (BOOL)setIdfaString:(NSString *)secValue
{
    if (kIsStringValid(secValue))
    {
        [KeychainHelper save:IDFA_STRING data:secValue];
        return YES;
    }
    else
    {
        return NO;
    }
}

+ (NSString*)getUserId
{
    NSString *useridStr = [KeychainHelper load:USERID_STRING];
    if (kIsStringValid(useridStr))
    {
        return useridStr;
    }
    else
    {
        return nil;
    }
}

+ (BOOL)setUserID:(NSString *)userID
{
    if (kIsStringValid(userID))
    {
        [KeychainHelper save:USERID_STRING data:userID];
        return YES;
    }
    else
    {
        return NO;
    }
}

+ (void)deletePassword
{
    [KeychainHelper delete:PASWORD_STRING];
}

+ (NSString *)getPassword
{
    NSString *passwordStr = [KeychainHelper load:PASWORD_STRING];
    if (kIsStringValid(passwordStr))
    {
        return passwordStr;
    }
    else
    {
        return nil;
    }
}

+ (BOOL)setPassword:(NSString *)password
{
    if (kIsStringValid(password))
    {
        [KeychainHelper save:PASWORD_STRING data:password];
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - UUID
+ (NSString*)getUUID
{
    CFUUIDRef uuid_ref = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuid_string_ref= CFUUIDCreateString(kCFAllocatorDefault, uuid_ref);
    
    CFRelease(uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString*)uuid_string_ref];
    if (!kIsStringValid(uuid))
    {
        uuid = @"";
    }
    CFRelease(uuid_string_ref);
    return [uuid lowercaseString];
}


@end
