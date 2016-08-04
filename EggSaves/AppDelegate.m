#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioManager.h"
#import "DataCenter.h"

//test
//#import "Task.h"

@interface AppDelegate ()



@end

@implementation AppDelegate

+ (AppDelegate *)delegate
{
    return [UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    //此为h5调用时候的入口 , 会传入进程号，以及要打开的app的url， 以及任务需要试玩的时间  (时间以分钟为单位)
    //wangzhuan?appid=%@&appname=%@&appurl=%@&tasktime=%d&bundleid=%@&otherName=%@&bonus=%d
    //进来之后就要记录试玩的时间, 以及试玩时间结束后通知服务器，任务已经完成
    
    NSString* urlString = [url absoluteString];
    
    NSLog(@"absoluteString = %@", urlString);
    
    NSArray*  a1        = [urlString componentsSeparatedByString:@"?"] ;
    
    if (a1.count < 2) {
        return NO;
    }
    
    NSString* str1      = a1[1] ;
    NSArray*  a2        = [str1 componentsSeparatedByString:@"&"] ;
    
    if (a2.count < 7) {
        return NO;
    }
    
    NSString* appid   = [a2[0] componentsSeparatedByString:@"="][1] ;
    NSString* appname = [a2[1] componentsSeparatedByString:@"="][1] ;
    NSString* appurl  = [a2[2] componentsSeparatedByString:@"="][1] ;
    NSString* timestr = [a2[3] componentsSeparatedByString:@"="][1] ;
    NSString* bdid    = [a2[4] componentsSeparatedByString:@"="][1] ;
    NSString* otname  = [a2[5] componentsSeparatedByString:@"="][1] ;
    NSString* bonusstr= [a2[6] componentsSeparatedByString:@"="][1] ;
    
    NSUInteger time   = [timestr integerValue] ;
    float      bounus = [bonusstr floatValue];
    
    [[DataCenter getInstance] doTaskId:appid appName:appname appUrl:appurl playTime:time bundleId:bdid otherName:otname bounus:bounus] ;
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    //播放音乐
    [[AudioManager getInstance] play];
        
    // 注册通知
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    UIApplication*   app = [UIApplication sharedApplication];
    __block    UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    if (self.controller) {
        [self.controller panduanTongzhi];
    }
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
//    [[FMDBManager defaultManager] selectTargets];
}

@end
