

#import <Foundation/Foundation.h>

@interface AudioManager : NSObject

+ (AudioManager*) getInstance;

- (void)play;

@end
