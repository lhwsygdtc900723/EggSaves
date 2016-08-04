#import "ViewController.h"
#import "ProcessManager.h"
#import "CommonDefine.h"
#import "LoginManager.h"
#import "Masonry.h"
#import "KeychainIDFA.h"
#import "BLHud.h"
#import "ProcessManager.h"
#import "DataCenter.h"
#import "AppDelegate.h"

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
    
    UIButton* jinggao;
    UILabel*  le;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
#if RECREATE_USER
    
    [KeychainIDFA deleteUSERID];
    
    [self addNotifiWarning];
    
#endif
    //加载页面...
    [self createLoadingPage] ;
    
    [AppDelegate delegate].controller = self;
    
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

- (void)addNotifiWarning{
    jinggao = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
    [jinggao setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
    [jinggao setTitle:@"警告：请点击开启推送" forState:UIControlStateNormal];
    jinggao.titleLabel.font = [UIFont systemFontOfSize:14];
    [jinggao setCenter:CGPointMake(self.view.frame.size.width/2, _clickBtn.frame.origin.y + _clickBtn.frame.size.height + 20)];
    [jinggao addTarget:self action:@selector(goToSet) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:jinggao];
    
    le = [[UILabel alloc] init];
    le.text = @"推送没有开启，将不能自动跳转商店";
    le.frame = CGRectMake(0, 0, self.view.frame.size.width, 20);
    le.textColor = [UIColor yellowColor];
    le.font = [UIFont systemFontOfSize:14];
    [le setCenter:CGPointMake(self.view.frame.size.width/2, jinggao.frame.origin.y + jinggao.frame.size.height + 10)];
    [le setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:le];
}

- (void)panduanTongzhi{
    //ios8判断是否设置了打开推送通知
    if ([[UIDevice currentDevice].systemVersion floatValue]>=8.0f) {
        UIUserNotificationSettings *setting = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (UIUserNotificationTypeNone == setting.types) {
            //未打开状态打开状态
            if (jinggao) {
                jinggao.hidden = NO;
                le.hidden = NO;
            }
        }else
        {
            if (jinggao) {
                jinggao.hidden = YES;
                le.hidden = YES;
            }
        }
    }
}

- (void)goToSet{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)setupSignupObserver
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    self.signupObserver = [center addObserverForName:NSUserSignUpNotification object:nil
                                               queue:mainQueue usingBlock:^(NSNotification *note) {
                                                   [[NSNotificationCenter defaultCenter] removeObserver:self.signupObserver] ;
                                                   
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
        
        [self panduanTongzhi];
        
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
