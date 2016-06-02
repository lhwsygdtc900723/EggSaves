

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel  *idLabel;
@property (weak, nonatomic) IBOutlet UILabel  *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *clickBtn;

- (IBAction)goH5:(id)sender;

@end

