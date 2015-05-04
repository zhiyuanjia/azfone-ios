/* ChatViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ChatViewController.h"
#import "PhoneMainView.h"
#import "MessageEntity.h"
#import "PersonEntity.h"
#import "ChatController.h"
#define kNumViewTag 100
#define kNumLabelTag 101

#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone


@interface ChatViewController ()
@end
@implementation ChatViewController

//after viewdidload and before view appear , reload the datatable to fetch the latest data by otis.

- (LinphoneAppDelegate *)appDelegate
{
    return (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [DataTable reloadData];
    
    
    
}


-(void)loadView{
    if (IS_IPHONE)
    {
        
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 320, 416)];
        self.view = container;
        
        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 50, 320, 416)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        [self.view addSubview:DataTable];
    }
    else {
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 768, 960)];
        self.view = container;
        
        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 50, 768, 960)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        [self.view addSubview:DataTable];
    }
    
    
}
static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"chat"
                                                                content:@"RootViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar:@"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:false
                                                           portraitMode:true];
    }
    return compositeDescription;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
  
    // Do any additional setup after loading the view.
    //显示和每个聊天的人的头像
    //查询所有的联系人，取出其中有发送消息的
    //对Entity里面的数组属性操作时需要@
    
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sendedMessages.@count>0 and name!=%@",selfUserName];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonEntity"];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
    fetchResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest
                                                               managedObjectContext:[LinphoneAppDelegate sharedAppDelegate].managedObjectContext
                                                                 sectionNameKeyPath:nil cacheName:nil];
    //设置了delegate才能动态监测数据库变化
    fetchResultController.delegate = self;
    [fetchResultController performFetch:NULL];
    personArray = [[NSMutableArray alloc]initWithArray:[fetchResultController fetchedObjects]];
    for (PersonEntity *personEntity in personArray) {
        NSLog(@"name:%@,msg count:%d",personEntity.name,personEntity.sendedMessages.count);
        
    }
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if ([anObject isKindOfClass:[PersonEntity class]]) {
        PersonEntity *personEntity = (PersonEntity*)anObject;
        if (type==NSFetchedResultsChangeInsert) {
            [personArray addObject:personEntity];
            [DataTable insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationLeft];
            
            //reload the list when insert new messeage by otis.
            [DataTable reloadData];
            [self.view addSubview:DataTable];
            
            
        }else if (type==NSFetchedResultsChangeUpdate) {
            [DataTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [DataTable reloadData];
            [self.view addSubview:DataTable];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return personArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *personCell = [DataTable dequeueReusableCellWithIdentifier:@"personCell"];
    if (personCell==nil) {
        personCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:@"personCell"];
        //联系人头像
        personCell.imageView.image = [UIImage imageNamed:@"defaultPerson.png"];
        //用一个红圈显示消息数量,不要显示太多的数字，一般不超过99
        UIImage *numImage = [[UIImage imageNamed:@"com_number_single"]stretchableImageWithLeftCapWidth:12 topCapHeight:12];
        UIImageView *numView = [[UIImageView alloc]initWithImage:numImage];
        numView.tag = kNumViewTag;
        [personCell.contentView addSubview:numView];
        UILabel *numLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 3, 20, 20)];
        numLabel.backgroundColor = [UIColor clearColor];
        numLabel.font = [UIFont systemFontOfSize:14];
        numLabel.textColor = [UIColor whiteColor];
        numLabel.tag = kNumLabelTag;
        [numView addSubview:numLabel];
    }
    PersonEntity *personEntity = [personArray objectAtIndex:indexPath.row];
    personCell.textLabel.text = personEntity.name;
    //在subTitle显示联系人发送的最后一条消息
    //取出这个联系人发送的所有消息，按照发送日期排序,取最新一条
    NSArray *sendedMessageArray = [personEntity.sendedMessages allObjects];
    //判断sendedMessageArray是否为空
    //按照升序排列，时间最晚的消息在最后
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
    sendedMessageArray = [sendedMessageArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
    MessageEntity *lastMessageEntity = [sendedMessageArray lastObject];
    personCell.detailTextLabel.text = lastMessageEntity.content;
    
    //snededmesseage - readmesseage , and show the numStr by otis
    NSString *numStr = [NSString stringWithFormat:@"%d",sendedMessageArray.count-(NSInteger)personEntity.readcount];
    
    NSLog(@"%@ unread messeages :%@",personEntity.name,numStr);
    
    CGSize numSize = [numStr sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.0f]}];
    //因为红圈比文字大一圈
    //红圈显示在联系人头像的右上角
    UIImageView *numView = (UIImageView*)[personCell.contentView viewWithTag:kNumViewTag];
    
    numView.frame = CGRectMake(50-numSize.width, 0, numSize.width+20, numSize.height+10);
    UILabel *numLabel = (UILabel*)[numView viewWithTag:kNumLabelTag];
    numLabel.frame = CGRectMake(10, 3, numSize.width, numSize.height);
    numLabel.text = numStr;
    //after user checkout the lastest messeage ,hide the notification label and number by otis.
    if([numStr isEqualToString:@"0"]){
        [numView setHidden:YES];
    }
    else {
        [numView setHidden:NO];
    }
    
    
    
    
    return personCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    PersonEntity *friendEntity1 = [personArray objectAtIndex:indexPath.row];
    
    NSArray *sendedMessageArray = [friendEntity1.sendedMessages allObjects];
    
    
    //add readcount as sendedmessage.count by otis.
    friendEntity1.readcount = sendedMessageArray.count;
    
    
    ChatController *chatController = [[ChatController alloc]init];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:chatController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
   
    navigationController.view.frame = CGRectOffset(navigationController.view.frame, 0.0, -20.0);
    navigationController.navigationBar.topItem.title = friendEntity1.name;
    
    navigationController.navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(Done)];
    
 
    
    NSLog(@"personEntiry = %@",friendEntity1);
    
    
  //  [chatController setFriendEntity:friendEntity1]; //set friendEntity to ChatController by otis.
    
    
}
- (void)Done {
    
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}



@end
