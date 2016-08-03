
#import "DataCenter.h"
#import "KeychainIDFA.h"
#import "ProcessManager.h"
#import "TimeHeart.h"
#import <UIKit/UIKit.h>
#import "LoginManager.h"
#import "CommonDefine.h"

#define PROCESS_REFRESH_TIME 5
#define BUNDLE_REFRESH_TIMER 1

@interface DataCenter ()
{
    NSTimer* _processTimer;
    NSTimer* _bundleidTimer;
    NSTimer* _openappTimer;
    BOOL     _firstRun;
}

@property (copy, nonatomic)NSString* appId;
@property (copy, nonatomic)NSString* appName;
@property (copy, nonatomic)NSString* appUrl;
@property (assign, nonatomic)NSUInteger playTime;

@property (strong, nonatomic) id commitIDObserver ;

//存放上一次扫描后手机中装的app的bundle id
@property (strong, nonatomic)NSMutableArray* pre_installedApps;

@end

@implementation DataCenter

+ (DataCenter *)getInstance
{
    static DataCenter* sharedInstance = nil;
    
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [[self alloc] init];
    }) ;
    
    return sharedInstance;
}

- (void)doTaskId:(NSString *)appid appName:(NSString *)name appUrl:(NSString *)url playTime:(NSUInteger)ptime
{
    self.appId = appid ;
    self.appName = name ;
    self.appUrl = url ;
    self.playTime = ptime ;
    
    _firstRun = YES;
    
    [self setupCommitIDObserver] ;
    
    //监测做任务的情况
    _processTimer = [NSTimer scheduledTimerWithTimeInterval:PROCESS_REFRESH_TIME target:self selector:@selector(checkRunningProcess) userInfo:nil repeats:YES];
    [_processTimer fire];
    
}

- (void)savePreBundleId:(NSString *)bid
{
    [self.pre_installedApps addObject:bid];
}

- (void)savePreBundleIds:(NSArray *)ids
{
    for (NSString* bid in ids) {
        
//        if (![bid isEqualToString:@"com.meelive.ingkee"]) {
            [self.pre_installedApps addObject:bid];
//        }
    }
}

- (void)startMonitorBundleID
{
    //监测新安装应用的bundle id
    _bundleidTimer = [NSTimer scheduledTimerWithTimeInterval:BUNDLE_REFRESH_TIMER target:self selector:@selector(checkNewInstallAppid) userInfo:nil repeats:YES];
    [_bundleidTimer fire];
}

- (NSString *)getappurl
{
    return _appUrl;
}

- (NSString *)getappname
{
    return _appName;
}

- (NSString *)getappid
{
    return _appId;
}

- (void)checkNewInstallAppid
{
    NSArray* array = [[ProcessManager getInstance] getAllAppsInstalled];
    
    BOOL isExist = NO;
    for (NSString* aid in array) {
        
        isExist = NO;
        for (NSString* bid in self.pre_installedApps) {
            if ([bid isEqualToString:aid]) {
                //存在
                isExist = YES;
                break;
            }
        }
        
        if (! isExist) {
            
            NSLog(@"the new app is %@", aid);
            //不存在
            [self.pre_installedApps addObject:aid];
            //发给服务器
            [[LoginManager getInstance] commitBundleID:aid];
        }
    }
}

- (void)checkRunningProcess
{
    static int countnum = 0 ;
    
    //扫描手机内正在运行的进程
    [[ProcessManager getInstance] loadIOKit];
    
    //判断任务进程是否开启，开启开始计时，否则不计时
    BOOL iscunzai = [[ProcessManager getInstance]processIsRunning:_appName];
    
    if (iscunzai) {
        NSLog(@"应用正在运行");
        [TimeHeart getInstance].isDownloaded = YES;
        
        if (_firstRun) {
            [[LoginManager getInstance] requestToMonitorTime];
            _firstRun = NO;
        }
        
    }else
    {
        NSLog(@"应用未运行");
        [TimeHeart getInstance].isDownloaded = NO;
    }
    
    if (countnum < 2) {
        [TimeHeart getInstance].isDownloaded = YES ;
    }
    
    countnum += 1 ;
    
    if ([TimeHeart getInstance].isDownloaded) {
        [TimeHeart getInstance].swTime += PROCESS_REFRESH_TIME ;   //累计试玩时间
    }else
    {
        [TimeHeart getInstance].swTime = 0;    //中途，如果退出了任务进程，则计时归零，重新来
    }
    
    //判断试玩时间是否达到了任务要求的时间
    if ([TimeHeart getInstance].swTime >= _playTime * 60) {
        //任务完成 无需再进行监控
        [_processTimer invalidate];
        
        [TimeHeart getInstance].swTime = 0 ;
        
        //向服务器发请求任务已经完成
        [[LoginManager getInstance] requestTaskFinishedWithTaskID:_appId] ;
        
        NSLog(@"任务完成") ;
        
        countnum = 0 ;
    }
}

- (void)setupCommitIDObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    self.commitIDObserver = [center addObserverForName:NSUserDoTaskCompletedNotification object:nil
                                               queue:mainQueue usingBlock:^(NSNotification *note) {
                                                   
                                                   NSDictionary* dict = note.userInfo;
                                                   NSInteger result = [dict[@"result"] integerValue] ;
                                                   
                                                   if (0 == result) {
                                                       
                                                       [[NSNotificationCenter defaultCenter]removeObserver:self.commitIDObserver] ;
                                                       
                                                   }else
                                                   {
                                                       //任务成功后提交失败
                                                       
                                                   }
                                                   
                                               }];
}

#pragma mark - getter methods
- (NSMutableArray *)pre_installedApps
{
    if (!_pre_installedApps) {
        _pre_installedApps = [[NSMutableArray alloc] init];
    }
    
    return _pre_installedApps;
}

@end
