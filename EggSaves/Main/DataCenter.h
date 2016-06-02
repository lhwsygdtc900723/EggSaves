

#import <Foundation/Foundation.h>

@interface DataCenter : NSObject

+ (DataCenter *)getInstance;

/**
 *  h5调起此程序，用于监控进程下载试玩完成 情况
 *  param : appid 任务id
 *  param : name  要试玩应用的进程号
 *  param : url   打开应用的url
 *  param : time  需要试玩应用的时间
 */
- (void)doTaskId:(NSString *)appid appName:(NSString *)name appUrl:(NSString *)url playTime:(NSUInteger)ptime ;

@end
