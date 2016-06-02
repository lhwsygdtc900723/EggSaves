//
//  HashUtils.m
//  EggsSave
//
//  Created by 郭洪军 on 12/22/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import "HashUtils.h"

@implementation HashUtils

static int HASH_LIMIT = 1;

+ (int) calculateHashKey: (Byte*) data
{
    return [HashUtils hash:data offset:5 len:5 seed:6];
}

+ (int) hash:(Byte*)data offset:(int)offset len:(int)len seed:(int)seed
{
    if (data == nil) {
        return 0;
    }
    long h = seed ^ (long)len;
    int step = (len >> HASH_LIMIT) + 1;
    int end = offset + len ;
    int start = offset + step;
    for (int l1 = end; l1 >= start; l1 -= step) {
        h = h ^ ((h << 5) + (h >> 2) + (data[l1 - 1] & 0xFF));
    }
    
    return  (int)h;
}


@end
