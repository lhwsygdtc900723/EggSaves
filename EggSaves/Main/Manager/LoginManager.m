#import "LoginManager.h"
#import "HashUtils.h"
#import "EncryptUtils.h"
#import "KeychainIDFA.h"
#import "CommonDefine.h"
#import "AFNetworking.h"
#import "DataCenter.h"
#import "NSString+MD5.h"
#import "ProcessManager.h"

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
            [weakSelf signUp];
        }
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"signup-error: %@", error);
        
        [weakSelf signUp];
    }];
}

- (void)login
{
    NSString* requestUrl = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/login.app?playerSequenceId=%@&password=%@", self.userId, self.password];
        
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
    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/playertTask/addBundleIDs2LoadedApps.app";
    NSArray*  bundleIds = [[ProcessManager getInstance] getAllAppsInstalled];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:self.userId forKey:@"playerSequenceId"];
    [dict setValue:self.password forKey:@"password"];
    [dict setValue:bundleIds forKey:@"bundleIds"];

    [self.session POST:urlString parameters:dict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary* dict = responseObject;
        NSLog(@"idObject = %@", dict);
        
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
        NSLog(@"提交失败,error = %@", error);
        
        [weakSelf commitAllBundleIDs];
    }];
}

- (void)commitBundleID:(NSString *)bundleid
{
    NSString* bid    = bundleid;

    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/playertTask/addBundleID2LoadedApps.app";
    NSString* requestUrl = [NSString stringWithFormat:@"%@?playerSequenceId=%@&password=%@&bundleId=%@", urlString,self.userId, self.password, bundleid];
    
    [self.session GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        //将该id存入本地列表中
        [[DataCenter getInstance] savePreBundleId:bid];
        NSDictionary* dict = responseObject;
        
        BOOL suc = [dict[@"success"] boolValue];
        if (suc) {
            NSDictionary* datadict = dict[@"data"];
            if (datadict) {
                NSString* appid = datadict[@"appid"];
                NSString* appname = datadict[@"appname"];
                NSString* appurl  = datadict[@"appurl"];
                NSString* tasktime = datadict[@"tasktime"];
                
                [[DataCenter getInstance]doTaskId:appid appName:appname appUrl:appurl playTime:[tasktime integerValue]] ;
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"提交失败,error = %@", error);
        
    }];
}

- (void)requestToMonitorTime
{
    NSString* urlString = @"http://112.74.206.78:8080/wangzhuanClient/playertTask/startMonitTask.app";
    NSString* requestUrl = [NSString stringWithFormat:@"%@?playerSequenceId=%@&password=%@", urlString,self.userId, self.password];
    
    [self.session GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary* dict = responseObject;
        
        NSLog(@"idObject = %@", dict);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"提交失败,error = %@", error);
        
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
    
    NSString* requestStr = [NSString stringWithFormat:@"http://112.74.206.78:8080/wangzhuanClient/playerTask/complateTask.app?playerSequenceId=%@&key=%@", userid, key];
    NSURL *URL = [NSURL URLWithString:requestStr];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", nil];
    
    [manager GET:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        
        NSDictionary* dict = responseObject;
        
        NSLog(@"dict = %@",dict);
        
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserDoTaskCompletedNotification object:nil];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"任务完成提交失败-Error: %@", error);
        [[NSNotificationCenter defaultCenter]postNotificationName:NSUserDoTaskCompletedNotification object:nil];
    }];
}

- (NSString*)urlEncodedString:(NSString *)string
{
    NSString * encodedString = (__bridge_transfer  NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
    return encodedString;
}

@end
