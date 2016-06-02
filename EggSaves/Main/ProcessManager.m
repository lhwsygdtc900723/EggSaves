//
//  ProcessManager.m
//  EggsSave
//
//  Created by 郭洪军 on 4/5/16.
//  Copyright © 2016 Adwan. All rights reserved.
//

#import "ProcessManager.h"
#import "ELLIOKitNodeInfo.h"
#import "ELLIOKitDumper.h"
#include <objc/runtime.h>

#define WHITE_LIST_KEY   @"whiteListKey"

@interface ProcessManager ()

@property(nonatomic, strong) ELLIOKitNodeInfo *root;
@property(nonatomic, strong) ELLIOKitNodeInfo *locationInTree;
@property(nonatomic, strong) ELLIOKitDumper *dumper;

@property(nonatomic, strong) NSMutableArray* processes;  //存放所有的进程名称

@end

@implementation ProcessManager

+ (ProcessManager *)getInstance
{
    static ProcessManager* sharedmanager = nil;
    
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedmanager = [[self alloc]init];
        sharedmanager.dumper = [ELLIOKitDumper new];
        sharedmanager.processes = [[NSMutableArray alloc]init];
    });
    
    return sharedmanager;
}

- (void)loadIOKit {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.root = [_dumper dumpIOKitTree];
        self.locationInTree = _root;
        
        ELLIOKitNodeInfo* info = self.locationInTree.children[0];
        self.locationInTree = info ;
        
        ELLIOKitNodeInfo* info1 = self.locationInTree.children[1];
        self.locationInTree = info1;
        
        for (ELLIOKitNodeInfo* info2 in self.locationInTree.children) {
            if ([info2.name isEqual:@"IOCoreSurfaceRoot"]) {
                self.locationInTree = info2;
            }
        }
        
        if (self.processes.count != 0) {
            [_processes removeAllObjects];
        }
        
        for (NSUInteger i = 0; i<self.locationInTree.children.count; ++i) {
            
            ELLIOKitNodeInfo* inf = self.locationInTree.children[i];
            
            NSArray* props = inf.properties;
            
            NSString* prop = props[0];
            
            NSArray *array = [prop componentsSeparatedByString:@","];
            
            NSString* string1 = array[1];
            
            NSString *str = [string1 stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            NSLog(@"process id = %@", str);
            
            [_processes addObject:str];
        }
    });
}

- (BOOL)processIsRunning:(NSString *)name
{
    BOOL bRet = NO;
    
    for (NSUInteger i = 0; i<_processes.count; ++i) {
        NSString* pStr = _processes[i];
        
        if ([pStr isEqual:name]) {
            return YES;
        }
    }
    
    return bRet;
}

- (NSArray *)getAllAppsInstalled
{
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
    NSArray* arr = [workspace performSelector:@selector(allApplications)] ;
    
    NSMutableArray* apps = [[NSMutableArray alloc]initWithCapacity:arr.count];
    for (NSUInteger i=0; i<arr.count; ++i) {
        NSObject *app = arr[i];
        NSString *identifier = [app performSelector:@selector(applicationIdentifier)];
        
        if (![identifier hasPrefix:@"com.apple"]) {
            [apps addObject:identifier];
        }
    }
    
    return apps;
}

- (NSArray *)getWhiteList
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSArray* whiteList = [userDefaults objectForKey:WHITE_LIST_KEY];
    
    return whiteList;
}

- (void)writeToWhiteList:(NSString *)bundleId
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *whiteList = [NSMutableArray arrayWithArray:[userDefaults objectForKey:WHITE_LIST_KEY]];
    
    BOOL isExist = NO;
    for (NSUInteger i = 0; i<whiteList.count; ++i) {
        if ([whiteList[i] isEqualToString:bundleId]) {
            isExist = YES;
        }
    }
    
    if (!isExist) {
        [whiteList addObject:bundleId];
    }

    NSMutableArray* newWhiteList = whiteList;
    
    [userDefaults setObject:newWhiteList forKey:WHITE_LIST_KEY];
}

- (void)applicationIdentifier
{
}

- (void)defaultWorkspace
{
}

- (void)allApplications
{
}

@end
