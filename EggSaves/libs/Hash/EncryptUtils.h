//
//  EncryptUtils.h
//  EggsSave
//
//  Created by 郭洪军 on 12/22/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EncryptUtils : NSObject

+ (Byte* )xorString:(Byte*) data len:(int)len;

@end
