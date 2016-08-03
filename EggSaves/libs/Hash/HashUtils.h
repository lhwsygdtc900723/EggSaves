//
//  HashUtils.h
//  EggsSave
//
//  Created by 郭洪军 on 12/22/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HashUtils : NSObject

+ (int) calculateHashKey: (Byte*) data;

+ (int) hash:(Byte*)data offset:(int)offset len:(int)len seed:(int)seed;

@end
