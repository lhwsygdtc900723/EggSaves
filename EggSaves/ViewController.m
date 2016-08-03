#import "ViewController.h"
#import "ProcessManager.h"
#import "CommonDefine.h"
#import "LoginManager.h"
#import "Masonry.h"
#import "KeychainIDFA.h"
#import "BLHud.h"
#import "ProcessManager.h"
#import "DataCenter.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel  *idLabel;
@property (weak, nonatomic) IBOutlet UILabel  *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *clickBtn;

- (IBAction)goH5:(id)sender;

@property (strong, nonatomic) id signupObserver ;
@property (strong, nonatomic) id commitIdsObserver ;

@end

@implementation ViewController
{
    UILabel* _textLabel ;
    BLHud*   _blHud ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if RECREATE_USER
    
    [KeychainIDFA deleteUSERID];
    
#endif
    //加载页面...
    [self createLoadingPage] ;
    
    NSString* userId = [KeychainIDFA getUserId];
    if (!userId) {  //未注册，先进行注册
        
        [self setupSignupObserver] ;
        
        [[LoginManager getInstance] signUp] ;
    }else
    {
        [[LoginManager getInstance] commitAllBundleIDs];
    }
    [self setupCommitIdsObserver] ;
}

- (void)setupSignupObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    self.signupObserver = [center addObserverForName:NSUserSignUpNotification object:nil
                                               queue:mainQueue usingBlock:^(NSNotification *note) {
                                                   [[NSNotificationCenter defaultCenter]removeObserver:self.signupObserver] ;
                                                   
                                                   //将本地所有已经下载的应用的bundle id列表发送给服务器
                                                   [[LoginManager getInstance] commitAllBundleIDs];
                                               }];
}

- (void)setupCommitIdsObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    self.commitIdsObserver = [center addObserverForName:NSUserCommitAllBundleIdsNotification object:nil queue:mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        NSString* userID = [KeychainIDFA getUserId];
        [[NSNotificationCenter defaultCenter]removeObserver:self.commitIdsObserver] ;
        
        [_blHud hide];
        _clickBtn.hidden = NO ;
        _idLabel.text = [NSString stringWithFormat:@"\"外快宝%@\"已绑定，账号ID:%@",userID,userID] ;
        _idLabel.hidden = NO ;
        
    }];
}

- (void)createLoadingPage
{
    _blHud = [[BLHud alloc] initWithFrame:CGRectMake((CGFloat) ((self.view.frame.size.width - 90) * 0.5),
                                                     (CGFloat) ((self.view.frame.size.height + 60) * 0.5), 90, 20)];
    _blHud.hudColor = [UIColor blueColor] ;
    _clickBtn.hidden = YES ;
    _idLabel.hidden = YES ;
    [self.view addSubview:_blHud];
    
    [_blHud showAnimated:YES];
    
}

- (IBAction)goH5:(id)sender {
    
    [[DataCenter getInstance] startMonitorBundleID];
    
    [[LoginManager getInstance] login] ;
        
}
@end
