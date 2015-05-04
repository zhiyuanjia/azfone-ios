//
//  FriendsListViewController.m
//  linphone
//
//  Created by Mini on 3/17/15.
//
//
#import "XMPPFramework.h"

#import "LinphoneAppDelegate.h"
#import "ChatViewController.h"
#import "PhoneMainView.h"
#import "FriendsListViewController.h"
#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
@interface FriendsListViewController ()

@end

@implementation FriendsListViewController

{
    NSMutableArray *dyItems;
    UITableView *dyTableView;
}
@synthesize roomname;

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"chat"
                                                                content:@"FriendsListViewController"
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
-(void)loadView{
    if (IS_IPHONE)
    {

    
    UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 320, 431)];
    self.view = container;
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    
    
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    navItem.title = NSLocalizedString(@"Invite friend",nil);
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back",nil) style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Invite",nil) style:UIBarButtonItemStylePlain target:self action:@selector(btnAlertTapped:)];
    navItem.leftBarButtonItem = leftButton;
    navItem.rightBarButtonItem =rightButton;
    
    
    navBar.items = @[ navItem ];
    
    [self.view addSubview:navBar];
    
    
    dyTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 50, 320, 431)];
    
  
    UITableViewCell *tableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DyDataCell"];
    
    
    [dyTableView registerClass:tableViewCell.class forCellReuseIdentifier:tableViewCell.reuseIdentifier];
    
    
    dyTableView.dataSource = self;
    
   
    dyTableView.delegate = self;
    
    
    [self.view addSubview:dyTableView];
    }
    else {
        
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 768, 960)];
        self.view = container;
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        
        
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        navItem.title = NSLocalizedString(@"Invite friend",nil);
        
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back",nil) style:UIBarButtonItemStylePlain target:self action:@selector(back)];
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Invite",nil) style:UIBarButtonItemStylePlain target:self action:@selector(btnAlertTapped:)];
        navItem.leftBarButtonItem = leftButton;
        navItem.rightBarButtonItem =rightButton;
        
        
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
-(void)btnAlertTapped:(id)sender {
    if(arSelectedRows.count==0){
        NSLog(@"please select");
    }
    else{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite friend",nil) message:[[self getSelections] componentsJoinedByString:@", "] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
    [alert show];
    }
}
-(NSArray *)getSelections {
    NSMutableArray *selections = [[NSMutableArray alloc] init];
    
    for(NSIndexPath *indexPath in arSelectedRows) {
        [selections addObject:[dyItems objectAtIndex:indexPath.row]];
    }
    
    return selections;
}
-(void)populateArray:(NSNotification *)notif
{
    [dyItems removeAllObjects]; //remove all objiect to avoid duplicate room.

    NSMutableArray *array = [notif object];
    
   for (NSArray *data in array){
       if(data.count <3){
           NSString *jid =[[data objectAtIndex:1] stringValue];
           
           NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
           
           NSRange search = [selfUserName rangeOfString:@"@"];
           
           NSString *hostname = [selfUserName substringFromIndex:search.location];
           
           NSRange tRange = [jid rangeOfString:hostname];
           if(tRange.location == NSNotFound){
               NSLog(@"not this server account");
           }
           else{
               [dyItems addObject:jid];
           }
       } else{
           NSString *jid =[[data objectAtIndex:2]stringValue];
           
           NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
           
           NSRange search = [selfUserName rangeOfString:@"@"];
           
           NSString *hostname = [selfUserName substringFromIndex:search.location];
           
           NSRange tRange = [jid rangeOfString:hostname];
           if(tRange.location == NSNotFound){
               NSLog(@"not this server account");
           }
           else{
               [dyItems addObject:jid];
           }
       }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getRosterArray" object:nil];
    [dyTableView reloadData];

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex ==1){
        NSLog(@"ok%@",[self getSelections]);
       
            XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            if (rosterstorage==nil) {
            rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
                    }
                XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:roomname] dispatchQueue:nil];
        
                [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
        
                [xmppRoom joinRoomUsingNickname:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID] history:nil];
        
                [xmppRoom fetchConfigurationForm];
        
                [xmppRoom addDelegate:[LinphoneAppDelegate sharedAppDelegate] delegateQueue:nil];
        
                NSXMLElement *roomConfigForm = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
        
                NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
        
                [xmppRoom configureRoomUsingOptions:roomConfigForm jid:myJid];
        
        NSArray *friendarray =[self getSelections];
        
            for (int i=0; i< friendarray.count; i++)
            {
                NSString *jid = [friendarray objectAtIndex:i];
                XMPPJID *xmppJID=[XMPPJID jidWithString:jid];
                [xmppRoom inviteUser:xmppJID withMessage:@"Come Join me"];
            }
            
        
        [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription] push:TRUE];
        
    

    }
    else{
        NSLog(@"Cancel button");
        [arSelectedRows removeAllObjects];
        [dyTableView reloadData];
    }
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
      [arSelectedRows removeAllObjects];
     [[NSNotificationCenter defaultCenter] removeObserver:self name:@"getRosterArray" object:nil];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateArray:) name:@"getRosterArray" object:nil];

}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
   
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    dyItems = [[NSMutableArray array] retain];
   
     arSelectedRows = [[NSMutableArray alloc] init];
    
    }
-(void)back{
    [dyItems removeAllObjects];
    [arSelectedRows removeAllObjects];
    
    [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription] push:TRUE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [arSelectedRows addObject:indexPath];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [arSelectedRows removeObject:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    if([arSelectedRows containsObject:indexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    
    return cell;
    
}
- (void)configurePhotoForCell:(UITableViewCell *)cell
{
    cell.imageView.image = [UIImage imageNamed:@"defaultPerson"];
    
    
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
