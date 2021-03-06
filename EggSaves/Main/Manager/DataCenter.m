
#import "DataCenter.h"
#import "KeychainIDFA.h"
#import "ProcessManager.h"
#import <UIKit/UIKit.h>
#import "LoginManager.h"
#import "CommonDefine.h"
#import "Task.h"

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

- (NSMutableArray *)tasks
{
    if (!_tasks) {
        _tasks = [NSMutableArray new];
    }
    
    return _tasks;
}

- (void)doTaskId:(NSString *)appid appName:(NSString *)name appUrl:(NSString *)url playTime:(NSUInteger)ptime bundleId:(NSString *)bundleid
       otherName:(NSString *)othername bounus:(float)bounus
{
//    if ([[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.url]]) {
    Task* task = TaskMake(appid, name, url, ptime, bundleid, othername, bounus);
    
//    //先判断有没有相同的任务存在
    BOOL isExist = NO;
    for (Task* t in self.tasks) {
        if ([t.appid isEqualToString:appid]) {
            //任务已经存在
            [t stopTimer];
            [t start];
            
            isExist = YES;
        }
    }
    
    if (!isExist) {
        [task start];
        [self.tasks addObject:task];
    }
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

- (NSArray *)getPreBundleId
{
    return _pre_installedApps;
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
    
    //监测正在进行中的任务是否卸载 默认未卸载
    
    NSMutableArray*  xiezia = [NSMutableArray new];
    for (Task* t in self.tasks) {
        BOOL isuninstalled = YES;  //挨个检查
        for (NSString* buid in array) {
            if ([t.bundleid isEqualToString:buid]) {
                isuninstalled = NO;
            }
        }
        if (isuninstalled) {
            //卸载了
            [t stopTimer];
            [[LoginManager getInstance] requestUninstalledApp:t.appid bundleId:t.bundleid];
            [xiezia addObject:t];
        }
    }
    if (xiezia.count > 0) {
        for (Task* t in xiezia) {
            [self.tasks removeObject:t];
        }
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
