
#import "AudioManager.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioManager ()

@property(strong, nonatomic)AVAudioPlayer* audioPlayer;

@end

@implementation AudioManager

+ (AudioManager*) getInstance
{
    static AudioManager* sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc]init];
        
        [sharedManager loadMusic:@"silent"];
    });
    
    return sharedManager ;
}

- (void)play
{
    [self.audioPlayer play];
}

-(void)loadMusic:(NSString*)name {
    NSString *musicFilePath = [[NSBundle mainBundle] pathForResource:name ofType:@"mp3"]; //创建音乐文件路径
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:musicFilePath]){
        NSURL *musicURL = [[NSURL alloc] initFileURLWithPath:musicFilePath];
        NSError *error=nil;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:&error];
        //准备buffer，减少播放延时的时间
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer setVolume:1]; //设置音量大小
        self.audioPlayer.numberOfLoops = -1;//设置播放次数，0为播放一次，负数为循环播放
        if (error) {
            NSLog(@"初始化错误:%@",error.localizedDescription);
        }
    }
}

@end
