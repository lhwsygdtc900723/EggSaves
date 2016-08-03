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
 * 查询所有的任务
 * 此方法请求服务器端所有的任务，
 * 暂时废弃，改为服务器端判断。
 */
/*
- (void)requestAllTasks;
 */

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
- (void)requestTaskFinishedWithTaskID:(NSString*)taskid;

/**
 *  向服务器提交开始计时。
 */
- (void)requestToMonitorTime;

@end




