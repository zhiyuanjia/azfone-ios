//
//  FriendsListViewController.h
//  linphone
//
//  Created by Mini on 3/17/15.
//
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

#import "UICompositeViewController.h"
@interface FriendsListViewController : UIViewController <UITableViewDataSource,UICompositeViewDelegate,UITableViewDelegate>
{
    NSMutableArray *arSelectedRows;
}

@property(nonatomic,retain) NSString *roomname;
@property(nonatomic,retain) NSMutableArray *yyy;

@end
