#import "LoginManager.h"
#import "HashUtils.h"
#import "EncryptUtils.h"
#import "KeychainIDFA.h"
#import "CommonDefine.h"
#import "AFNetworking.h"
#import "DataCenter.h"
#import "NSString+MD5.h"
#import "ProcessManager.h"
#import "Task.h"

NSString* const NSUserSignUpNotification               = @"NSUserSignUpNotification" ;
NSString* const NSUserCommitAllBundleIdsNotification   = @"NSUserCommitAllBundleIdsNotification" ;
NSString* const NSUserCommitBundleIdNotification       = @"NSUserCommitBundleIdNotification" ;
NSString* const NSUserCommitListIdsNotification        = @"NSUserCommitListIdsNotification" ;
NSString* const NSUserDoTaskCompletedNotification      = @"NSUserDoTaskCompletedNotification" ;

static NSInteger signupcount = 0;
static NSInteger commitcount = 0;

@interface LoginManager ()

// 用于网络请求的Session对象
@property (nonatomic, strong) AFHTTPSessionManager *session;
@property (nonatomic, strong) NSString* userId;
@property (nonatomic, strong) NSString* password;

@end

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

#pragma mark - get methods

- (AFHTTPSessionManager *)session
{
    if (!_session) {
        _session = [AFHTTPSessionManager manager];
        _session.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"application/x-json",@"text/html", nil];
    }
    
    return _session;
}

- (NSString *)userId
{
    if (!_userId) {
        _userId = [KeychainIDFA getUserId];
    }
    
    return _userId;
}

- (NSString *)password
{
    if (!_password) {
        _password = [KeychainIDFA getPassword];
    }
    
    return _password;
}

- (void)signUp
{
    signupcount ++;
    if (signupcount > 3) {
        return;
    }
    
    //获取当前的时间
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYYMMddHHmm"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    NSString* key1     = [dateString MD5Digest];
    NSString* uns1 = [NSString stringWithFormat:@"%@%@", key1, @"717E8164FC324486B5A783754FEFE718"];
    NSString* key = [uns1 MD5Digest];
    
    NSString* userIDFA = [KeychainIDFA IDFA];
    
    __weak __typeof__(self) weakSelf = self;
    NSString* requestStr = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/60401.app?key=%@&idfa=%@", key, userIDFA];
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
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUserSignUpNotification object:nil userInfo:nil];
        }else
        {
            [weakSelf signUp];
        }
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"signup-error: %@", error);
        
        [weakSelf signUp];
    }];
}

- (void)login
{
    NSString* requestUrl = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/60402.app?playerSequenceId=%@&password=%@", self.userId, self.password];
        
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:requestUrl]] ;
}

- (void)commitAllBundleIDs
{
    NSLog(@"self.userid = %@", self.userId);
    
    commitcount ++;
    if (commitcount > 3) {
        return;
    }
    __weak __typeof__(self) weakSelf = self;
    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/60202.app";
    NSArray*  bundleIds = [[ProcessManager getInstance] getAllAppsInstalled];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:self.userId forKey:@"playerSequenceId"];
    [dict setValue:self.password forKey:@"password"];
    [dict setValue:bundleIds forKey:@"bundleIds"];

    [self.session POST:urlString parameters:dict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary* dict = responseObject;
        NSLog(@"提交所有bundle id 成功 idObject = %@", dict);
        
        BOOL suc = [dict[@"success"] boolValue];
        if (suc) {
            //将这些id存入本地列表中
            [[DataCenter getInstance] savePreBundleIds:bundleIds];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NSUserCommitAllBundleIdsNotification object:nil];
        }else
        {
            [weakSelf commitAllBundleIDs];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"提交所有bundle id 失败,error = %@", error);
        
        [weakSelf commitAllBundleIDs];
    }];
}

- (void)commitBundleID:(NSString *)bundleid
{
    NSString* bid    = bundleid;

    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/60201.app";
    NSString* requestUrl = [NSString stringWithFormat:@"%@?playerSequenceId=%@&password=%@&bundleId=%@", urlString,self.userId, self.password, bundleid];
    
    [self.session GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        //将该id存入本地列表中
        [[DataCenter getInstance] savePreBundleId:bid];
        NSDictionary* dict = responseObject;
        
        BOOL suc = [dict[@"success"] boolValue];
        if (suc) {
            
            NSLog(@"提交bundle id 成功!!!");
            /*  //从我打开，这里不需要实时监听
            NSDictionary* datadict = dict[@"data"];
            if (datadict) {
                NSString* appid = datadict[@"appid"];
                NSString* appname = datadict[@"appname"];
                NSString* appurl  = datadict[@"appurl"];
                NSString* tasktime = datadict[@"tasktime"];
                
                [[DataCenter getInstance]doTaskId:appid appName:appname appUrl:appurl playTime:[tasktime integerValue]] ;
            }
             */
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"提交bundle id失败,error = %@", error);
        
    }];
}

- (void)requestToMonitorTime:(NSString *)appid
{
    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/60302.app";
    NSString* requestUrl = [NSString stringWithFormat:@"%@?playerSequenceId=%@&password=%@&unaryId=%@", urlString,self.userId, self.password, appid];
    
    [self.session GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary* dict = responseObject;
        
        NSLog(@"开始监控时间提交成功 = %@", dict);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"开始监控时间提交失败,error = %@", error);
        
    }];
}

- (void)requestTaskFinishedWithTaskID:(NSString*)appID AppName:(NSString *)appName AppUrl:(NSString *)appUrl OtherName:(NSString *)oName Bounus:(float)bounus
{
    NSString* appurl  = appUrl;
    NSString* appname = appName;
    NSString* appid   = appID;
    
    NSString* userid  = [KeychainIDFA getUserId];
    NSString* ext     = @"062F273A70AC4138BEEE21E7EF969861";
    NSString* keystr  = [NSString stringWithFormat:@"%@%@%@%@",appurl,appname,appid,ext];
    NSString* key     = [keystr MD5Digest];
    
    NSString* requestStr = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/60301.app?playerSequenceId=%@&unaryId=%@&key=%@", userid, appid, key];
    NSURL *URL = [NSURL URLWithString:requestStr];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
    
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSDictionary* dict = responseObject;
        
        BOOL success = [dict[@"success"] boolValue];
        
        NSLog(@"任务完成提交成功-: %@", dict);
        
        if (success) {
            UILocalNotification *localNfc = [[UILocalNotification alloc] init];
            localNfc.soundName = UILocalNotificationDefaultSoundName;
            localNfc.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
            localNfc.alertBody = [NSString stringWithFormat:@"任务《%@》成功完成，获得%.1f元的奖励，已入账", oName, bounus];
            localNfc.alertTitle = @"任务成功完成";
            localNfc.applicationIconBadgeNumber = localNfc.applicationIconBadgeNumber + 1;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNfc];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:NSUserDoTaskCompletedNotification object:nil];
        }
        
        for (Task* t in [DataCenter getInstance].tasks) {
            if ([t.appid isEqualToString:appid]) {
                [[DataCenter getInstance].tasks removeObject:t];
            }
        }
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"任务完成提交失败-Error: %@", error);
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserDoTaskCompletedNotification object:nil];
    }];
}

- (void)requestAllBundleIdsNeedsToMonitor
{
    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/60203.app";
    NSString* requestUrl = [NSString stringWithFormat:@"%@?playerSequenceId=%@&password=%@", urlString,self.userId, self.password];
    
    [self.session GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary* dict = responseObject;
        
        NSLog(@"idObject = %@", dict);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"提交失败,error = %@", error);
        
    }];
}

- (void)requestUninstalledApp:(NSString *)unaryId bundleId:(NSString *)bundleId{
    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/playertTask/60303.app";
    NSString* requestUrl = [NSString stringWithFormat:@"%@?playerSequenceId=%@&unaryId=%@&password=%@&bundleId=%@", urlString,self.userId, unaryId, self.password, @"bundle id"];
    
    [self.session GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary* dict = responseObject;
        
        NSLog(@"卸载提交成功 = %@", dict);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"卸载提交失败,error = %@", error);
        
    }];
}

- (NSString*)urlEncodedString:(NSString *)string
{
    NSString * encodedString = (__bridge_transfer  NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
    return encodedString;
}

@end
