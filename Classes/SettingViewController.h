//
//  SettingViewController.h


#import <UIKit/UIKit.h>



@interface SettingViewController : UIViewController
{
    UITextField *jidField;
    UITextField *passwordField;
}

@property (nonatomic,strong) IBOutlet UITextField *jidField;
@property (nonatomic,strong) IBOutlet UITextField *passwordField;

- (IBAction)done:(id)sender;
@end
