//
//  TasksManager.h
//  EggsSave
//
//  Created by 郭洪军 on 12/24/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TasksManager : NSObject

+ (id)getInstance;

- (void)setTasks:(NSArray *)tasks;
- (NSArray*)getTasks;

- (NSArray *)parseLoginData:(NSDictionary *)data;

@end


