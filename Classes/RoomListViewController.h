//
//  RoomListViewController.h
//  linphone
//
//  Created by Mini on 3/13/15.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "UICompositeViewController.h"
@interface RoomListViewController : UIViewController <UITableViewDataSource,UICompositeViewDelegate,UITableViewDelegate>
{
    NSString *fullroomjid;
 
}

@property(nonatomic,retain) NSString *friendname;
@property(nonatomic,retain) NSString *fullroomjid;

@end
