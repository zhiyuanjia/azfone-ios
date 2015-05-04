//
//  MessageListController.m

#import "LinphoneAppDelegate.h"
#import "MessageListController.h"
#import "MessageEntity.h"
#import "PersonEntity.h"
#import "ChatController.h"
#define kNumViewTag 100
#define kNumLabelTag 101
#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone

@interface MessageListController ()

@end
@implementation MessageListController
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
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 416)];
        self.view = container;
        
        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 320, 416)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        [self.view addSubview:DataTable];
    }
    else {
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 768, 960)];
        self.view = container;
        
        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 768, 960)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        [self.view addSubview:DataTable];
    }
    
    
    
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
   
    NSArray *sendedMessageArray = [personEntity.sendedMessages allObjects];
  
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
        sendedMessageArray = [sendedMessageArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
        MessageEntity *lastMessageEntity = [sendedMessageArray lastObject];
        personCell.detailTextLabel.text = lastMessageEntity.content;
        
                    //snededmesseage - readmesseage , and show the numStr by otis
        NSString *numStr = [NSString stringWithFormat:@"%d",sendedMessageArray.count-(NSInteger)personEntity.readcount];
   
        NSLog(@"%@ unread messeages :%@",personEntity.name,numStr);
        CGSize numSize = [numStr sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(CGFLOAT_MAX, 20)];
    
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
   
    ChatController *chatController = [ChatController alloc];
    [self.navigationController pushViewController:chatController animated:YES];
    //set navigation to creat back button to return MesseageListController by otis.
   
    NSLog(@"personEntiry = %@",friendEntity1);

   
   // [chatController setFriendEn:friendEntity1]; //set friendEntity to ChatController by otis.
    
    
}

    



@end
