//
//  RoomListViewController.m
//  linphone
//
//  Created by Mini on 3/13/15.
//
//

#import "XMPPFramework.h"
#import "LinphoneAppDelegate.h"
#import "ChatViewController.h"
#import "PhoneMainView.h"
#import "RoomListViewController.h"

#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
@interface RoomListViewController ()

@end

@implementation RoomListViewController


{
    int count;
    NSMutableArray *dyItems;
    UITableView *dyTableView;
}
@synthesize friendname;
@synthesize fullroomjid;
static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"chat"
                                                                content:@"RoomListViewController"
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



-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"arrayFromSecondVC" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getRosterArray" object:nil];

    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateArray:) name:@"arrayFromSecondVC" object:nil];
    
}
    

-(void)loadView{
    if (IS_IPHONE)
    {
    
    UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 320, 431)];
    self.view = container;
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    
    
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    navItem.title = NSLocalizedString(@"Conference List",nil);
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back",nil) style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    navItem.leftBarButtonItem = leftButton;
    
    
    
    navBar.items = @[ navItem ];
    
    [self.view addSubview:navBar];
    
    
    dyTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 50, 320, 431)];
    
  
    UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DyDataCell"];
    
    
    [dyTableView registerClass:tableViewCell.class forCellReuseIdentifier:tableViewCell.reuseIdentifier];
    
    
    dyTableView.dataSource = self;
    
    
    dyTableView.delegate = self;
    
   
    [self.view addSubview:dyTableView];
    }
    else{
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 768, 960)];
        self.view = container;
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        
        
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        navItem.title = NSLocalizedString(@"Conference List",nil);
        
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back",nil) style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        navItem.leftBarButtonItem = leftButton;
        
        
        
        navBar.items = @[ navItem ];
        
        [self.view addSubview:navBar];
        
        
        dyTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 50, 768, 960)];
        
        
        UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DyDataCell"];
        
        
        [dyTableView registerClass:tableViewCell.class forCellReuseIdentifier:tableViewCell.reuseIdentifier];
        
        
        dyTableView.dataSource = self;
        
        
        dyTableView.delegate = self;
        
        
        [self.view addSubview:dyTableView];
    }

}

-(void)populateArray:(NSNotification *)notif
{
    [dyItems removeAllObjects]; //remove all objiect to avoid duplicate room.
    
  NSMutableArray *array = [notif object];
    for (NSArray *data  in array){
           NSString *roomname = [[data objectAtIndex:1] stringValue];
       
        [dyItems addObject:roomname];
        
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"arrayFromSecondVC" object:nil];

    [dyTableView reloadData];
}
-(void)populateArray1:(NSNotification *)notif
{
    
    NSMutableArray *array =[notif object];
    NSArray *password = [array objectAtIndex:7];
    NSString * resultString = [[password valueForKey:@"description"] componentsJoinedByString:@""];
    NSRange tRange = [resultString rangeOfString:@"passwordprotected"];
    if(tRange.location ==NSNotFound){
                NSString *nickname = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        
                XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
                if (rosterstorage==nil) {
                    NSLog(@"nil");
                    rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
                }
                XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:fullroomjid] dispatchQueue:nil];
        
                [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
      
                [xmppRoom joinRoomUsingNickname:nickname history:nil password:nil];
        
        
        
        
                NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
                [xmppRoom fetchConfigurationForm];
                [xmppRoom configureRoomUsingOptions:nil jid:myJid];
        if(friendname!=nil){
        [xmppRoom inviteUser:[XMPPJID jidWithString:friendname] withMessage:@"Come Join me"];
            
        }
        
        [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription] push:TRUE];
            
        

    }
    else{
        NSLog(@"this room is protect by password");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:fullroomjid
                                                        message:NSLocalizedString(@"Enter the password",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        
        
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        alert.tag=1;
        // Pop UIAlertView
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getRosterArray" object:nil];
        
        [alert show];
        
}
    
}
-(void)populateArray2:(NSNotification *)notif
{
    
    
    
    NSMutableArray *array =[notif object];
    if(array.count ==0){
        NSLog(@"no error%@",array);
        count++;
        if(count>3){
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"errorArray" object:nil];
            
            [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription] push:TRUE];
        }
    }
    else if(array.count>0){
   
       [[NSNotificationCenter defaultCenter] removeObserver:self name:@"errorArray" object:nil];
       NSLog(@"some error%@",array);
       
       [self showerroralert];
   }
 
    }

-(void)showerroralert{
    NSNumber *zero =[NSNumber numberWithInt:0];
    count = [zero intValue];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Incorrect password",nil)
                                                    message:NSLocalizedString(@"Enter the password again",nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
    
    
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    alert.tag=1;
    // Pop UIAlertView
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getRosterArray" object:nil];
    
    [alert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag ==1 && buttonIndex ==0){
        NSLog(@"cancel");
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        NSRange search = [selfUserName rangeOfString:@"@"];
        
        NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        NSString* server = [@"conference." stringByAppendingFormat:@"%@",hostname]; //or whatever the server address for muc is
        XMPPJID *servrJID = [XMPPJID jidWithString:server];
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:servrJID];
        
        [iq addAttributeWithName:@"from" stringValue:selfUserName];
        
        NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
        [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#items"];
        [iq addChild:query];
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
        
        [dyTableView reloadData];
    }
    else if(alertView.tag==1 &&buttonIndex ==1){
        NSLog(@"ok");
        NSLog(@"password%@",[alertView textFieldAtIndex:0].text);
        NSString *nickname = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        
        XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        if (rosterstorage==nil) {
            NSLog(@"nil");
            rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        }
        XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:fullroomjid] dispatchQueue:nil];
        
        [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
   
        [xmppRoom joinRoomUsingNickname:nickname history:nil password:[alertView textFieldAtIndex:0].text];
        
        
        
        
        NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
        [xmppRoom fetchConfigurationForm];
        [xmppRoom configureRoomUsingOptions:nil jid:myJid];
        if(friendname!=nil){
            [xmppRoom inviteUser:[XMPPJID jidWithString:friendname] withMessage:@"Come Join me"];
        }

        
          [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateArray2:) name:@"errorArray" object:nil];
        
       
        
    }
}





- (void)viewDidLoad {
    [super viewDidLoad];
   
    dyItems = [[NSMutableArray array] retain];
   
    
// Do any additional setup after loading the view, typically from a nib.

    
}



-(void)back{
  
    [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription] push:TRUE];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *zero =[NSNumber numberWithInt:0];
    count = [zero intValue];
    self.fullroomjid =@"test";
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        NSRange search = [selfUserName rangeOfString:@"@"];
         NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        NSString * room = dyItems[indexPath.row];
        NSRange search1 = [room rangeOfString:@" "];
        NSString *roomname = [room substringWithRange:NSMakeRange(0,search1.location)];
    
    
        NSString *roomid = [roomname stringByAppendingFormat:@"%@%@%@",@"@",@"conference.", hostname];
    
    self.fullroomjid=roomid;
    XMPPJID *servrJID = [XMPPJID jidWithString:roomid];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:servrJID];
    
    [iq addAttributeWithName:@"from" stringValue:selfUserName];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query"];
    [query addAttributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/disco#info"];
    [iq addChild:query];
    [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateArray1:) name:@"getRosterArray" object:nil];
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dyItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    

    // 取得tableView目前使用的cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DyDataCell" forIndexPath: indexPath];
    
    // 將指定資料顯示於tableview提供的text
    cell.textLabel.text = dyItems[indexPath.row];
    
   
     [self configurePhotoForCell:cell];
    return cell;

}
- (void)configurePhotoForCell:(UITableViewCell *)cell
{
   cell.imageView.image = [UIImage imageNamed:@"conference"];
            
        
    
    
}


@end