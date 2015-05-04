//
//  MessageListController.h


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MessageListController : UIViewController<UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate>{
    UITableView *DataTable;
    NSMutableArray *personArray;
    NSFetchedResultsController *fetchResultController;
     
}


@end
