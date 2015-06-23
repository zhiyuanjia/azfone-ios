//
//  ChatController.h


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PersonEntity.h"
#import "MessageListController.h"

#import "UICompositeViewController.h"
@interface ChatController : UIViewController<UITextViewDelegate,NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource,UIAlertViewDelegate,UICompositeViewDelegate>{
    CGRect keyboardEndFrame;
    IBOutlet UIImageView *inputContainer;
    IBOutlet UITableView *DataTable;
    IBOutlet UITextView *inputView;
   
    CGFloat previousContentHeight;
    PersonEntity *selfEntity;
    PersonEntity *friendEntity;
    
   XMPPUserCoreDataStorageObject *friendEn;
    NSMutableArray *messageArray;
    NSFetchedResultsController *fetchController;
    BOOL firstTime;
    
}

@property(nonatomic,retain) XMPPUserCoreDataStorageObject *friendEn;
-(void)sendButtonClick:(id)sender;

- (IBAction)back:(id)sender;

- (IBAction)invite:(id)sender;


@property (retain, nonatomic) IBOutlet UILabel *displayname;


@end
