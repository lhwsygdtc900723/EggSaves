#import <UIKit/UIKit.h>
#import "ViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic)ViewController* controller;

/**
 *  获取app代理
 */
+ (AppDelegate *)delegate;

@end

