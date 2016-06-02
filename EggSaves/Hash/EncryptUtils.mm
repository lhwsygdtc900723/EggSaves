//
//  EncryptUtils.m
//  EggsSave
//
//  Created by 郭洪军 on 12/22/15.
//  Copyright © 2015 Adwan. All rights reserved.
//

#import "EncryptUtils.h"

@implementation EncryptUtils

static int seed[] = { static_cast<int>(0xD83EFCAB), static_cast<int>(0xB34CABE6), static_cast<int>(0xF74ECAB8),
    static_cast<int>(0xCABBC2A3), static_cast<int>(0xBACF0CD9), static_cast<int>(0xDFBB07F9), static_cast<int>(0xC66FACB8), static_cast<int>(0xB1F9DE96),
    static_cast<int>(0xAB95CCAB) };


+ (Byte* )xorString:(Byte*) data len:(int)len
{
    Byte* b1 = (Byte*)malloc(len);
    memset(b1, 0, len);
    for (int x = 0; x < len; x++) {
        b1[x] = (Byte) (data[x] ^ seed[x % 9]);
    }
    
    return b1;
}

@end
