

#import "ViewController.h"
#import "ProcessManager.h"
#import "CommonDefine.h"
#import "LoginManager.h"
#import "Masonry.h"
#import "KeychainIDFA/KeychainIDFA.h"
#import "TasksManager.h"
#import "BLHud.h"

@interface ViewController ()

@property (strong, nonatomic) id signupObserver ;
@property (strong, nonatomic) id loginObserver ;
@property (strong, nonatomic) id commitIdsObserver ;

@end

@implementation ViewController
{
    UILabel* _textLabel ;
    BLHud*   _blHud ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpLoadingPage] ;
    
    [self setupLoginObserver] ;
    
    NSString* userId = [KeychainIDFA getUserId];
    if (!userId) {
        
        [self setupSignupObserver] ;
        
        [[LoginManager getInstance] signUp] ;
    }else
    {
        [[LoginManager getInstance] login] ;
    }
    
    //首先登录,获取到任务列表，查询手机哪些应用是已经安装的，发给服务端
    //登录之前 先注册（用idfa）
}

- (void)setupSignupObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    self.signupObserver = [center addObserverForName:NSUserSignUpNotification object:nil
                                               queue:mainQueue usingBlock:^(NSNotification *note) {
                                                   
                                                   NSDictionary* dict = note.userInfo;
                                                   NSInteger result = [dict[@"result"] integerValue] ;
                                                   
                                                   if (0 == result) {
                                                       
                                                       NSString* userId = [dict[@"userId"] stringValue];
                                                       [KeychainIDFA setUserID:userId];
                                                       
                                                       [[LoginManager getInstance] login] ;
                                                       
                                                       [[NSNotificationCenter defaultCenter]removeObserver:self.signupObserver] ;
                                                       
                                                   }else
                                                   {
                                                       //注册失败
                                                       //继续注册  需要给定一个重复请求次数
                                                       [[LoginManager getInstance] signUp] ;
                                                       
                                                   }
                                                   
                                               }];
}

- (void)setupLoginObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    __weak typeof(self)weakSelf = self;
    
    self.loginObserver = [center addObserverForName:NSUserLoginNotification object:nil
                                               queue:mainQueue usingBlock:^(NSNotification *note) {
                                                   
                                                   NSDictionary* dict = note.userInfo;
                                                   NSInteger result = [dict[@"result"] integerValue] ;
                                                   
                                                   NSString* userid = dict[@"userid"] ;
                                                   
                                                   if (1 == result) {
                                                       
                                                       NSArray* lists = [[TasksManager getInstance] parseLoginData:dict] ;
                                                       
                                                       [[NSNotificationCenter defaultCenter]removeObserver:self.loginObserver] ;
                                                       
                                                       if (lists.count > 0) {
                                                           [weakSelf setupCommitidsObserver] ;
                                                           [[LoginManager getInstance]requestWithTaskIds:lists];
                                                       }else
                                                       {
                                                           [_blHud hide];
                                                           _clickBtn.hidden = NO ;
                                                           _idLabel.text = [NSString stringWithFormat:@"\"外快宝%@\"已绑定，账号ID:%@",userid,userid] ;
                                                           _idLabel.hidden = NO ;
                                                       }
                                                       
                                                   }else
                                                   {
                                                       //登录失败
                                                       //继续登录  需要给定一个重复请求次数
//                                                       [[LoginManager getInstance] login] ;
                                                   }
                                                   
                                               }];
}

- (void)setupCommitidsObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    self.commitIdsObserver = [center addObserverForName:NSUserCommitListIdsNotification object:nil
                                              queue:mainQueue usingBlock:^(NSNotification *note) {
                                                  
                                                  NSDictionary* dict = note.userInfo;
                                                  NSInteger result = [dict[@"result"] integerValue] ;
                                                  
                                                  NSString* userid = [KeychainIDFA getUserId] ;
                                                  
                                                  if (-1 != result) {
                                                      
                                                      [_blHud hide] ;
                                                      _clickBtn.hidden = NO ;
                                                      _idLabel.text = [NSString stringWithFormat:@"\"外快宝%@\"已绑定，账号ID:%@",userid,userid] ;
                                                      _idLabel.hidden = NO ;
                                                      
                                                      [[NSNotificationCenter defaultCenter]removeObserver:self.commitIdsObserver] ;
                                                  }else
                                                  {
                                                      //提交失败
                                                  }
                                                  
                                              }];
}

- (void)setUpLoadingPage
{
    _blHud = [[BLHud alloc] initWithFrame:CGRectMake((CGFloat) ((self.view.frame.size.width - 90) * 0.5),
                                                     (CGFloat) ((self.view.frame.size.height + 60) * 0.5), 90, 20)];
    _blHud.hudColor = [UIColor blueColor] ;
    _clickBtn.hidden = YES ;
    _idLabel.hidden = YES ;
    
    [self.view addSubview:_blHud];
    
    [_blHud showAnimated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)goH5:(id)sender {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://123.57.85.254:8180/wz/"]] ;
    
}
@end
