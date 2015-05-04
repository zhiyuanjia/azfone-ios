#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PersonEntity.h"
#import "ChatTableViewController.h"
#import "SWTableViewCell.h"

@interface RootViewController : UIViewController <UITableViewDelegate,NSFetchedResultsControllerDelegate,UITableViewDataSource,UIAlertViewDelegate,UIActionSheetDelegate,SWTableViewCellDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    NSFetchedResultsController *fetchResultController;
	NSFetchedResultsController *fetchedResultsController;
    PersonEntity *friendEntity;
    NSMutableArray *personArray;
     UITableView *DataTable;
    UITableView *test;
    NSMutableArray *textLabel_MArray;
}


@end
