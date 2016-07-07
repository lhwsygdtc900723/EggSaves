
#import "DataCenter.h"
#import "KeychainIDFA.h"
#import "ProcessManager.h"
#import "TimeHeart.h"
#import <UIKit/UIKit.h>
#import "LoginManager.h"
#import "CommonDefine.h"

#define PROCESS_REFRESH_TIME 15

@interface DataCenter ()
{
    NSTimer* _processTimer;
}

@property (copy, nonatomic)NSString* appId;
@property (copy, nonatomic)NSString* appName;
@property (copy, nonatomic)NSString* appUrl;
@property (assign, nonatomic)NSUInteger playTime;

@property (strong, nonatomic) id commitIDObserver ;

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
    
    [self setupCommitIDObserver] ;
    
    //监测做任务的情况
    _processTimer = [NSTimer scheduledTimerWithTimeInterval:PROCESS_REFRESH_TIME target:self selector:@selector(checkRunningProcess) userInfo:nil repeats:YES];
    [_processTimer fire];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_appUrl]] ;
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
//        [[LoginManager getInstance] requestTaskFinishedWithTaskID:_appId] ;
        
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

@end
