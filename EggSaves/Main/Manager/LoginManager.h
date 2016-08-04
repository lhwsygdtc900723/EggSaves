#import <Foundation/Foundation.h>


@interface LoginManager : NSObject

+ (id)getInstance;

/**
 *  注册接口
 */
- (void)signUp;

/**
 *  登录接口
 */
- (void)login;

/**
 *  向服务器提交本地已经下载的应用的bundle id列表
 */
- (void)commitAllBundleIDs;

/**
 *  向服务器提交新安装应用的bundle id
 */
- (void)commitBundleID:(NSString *)bundleid;

/**
 *  向服务器请求任务已经完成
 */
- (void)requestTaskFinishedWithTaskID:(NSString*)appID AppName:(NSString *)appName AppUrl:(NSString *)appUrl OtherName:(NSString *)oName Bounus:(float)bounus;

/**
 *  向服务器提交开始计时。
 */
- (void)requestToMonitorTime:(NSString *)appid;

/**
 *  查询需要监听的BundleIds 暂时不需要了
 */
/*
- (void)requestAllBundleIdsNeedsToMonitor;
 */

/**
 *  卸载了某一正在进行中的任务的应用
 */
- (void)requestUninstalledApp:(NSString *)unaryId bundleId:(NSString *)bundleId;

@end




