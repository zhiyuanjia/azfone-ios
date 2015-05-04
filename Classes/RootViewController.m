#import "RootViewController.h"
#import "LinphoneAppDelegate.h"
#import "SettingViewController.h"
#import "ChatController.h"
#import "XMPPFramework.h"
#import "DDLog.h"
#import "PhoneMainView.h"
#import "MessageEntity.h"
#import "RoomListViewController.h"
#define kNumViewTag 100
#define kNumLabelTag 101
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
@interface RootViewController()
@end
@implementation RootViewController

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (LinphoneAppDelegate *)appDelegate
{
    return (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View lifecycle
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   
    if(!linphone_core_is_network_reachable([LinphoneManager getLc])){
        
        [[self.view viewWithTag:1] removeFromSuperview];
        [[self.view viewWithTag:2] removeFromSuperview];
        [[self.view viewWithTag:3] removeFromSuperview];
        
        [self setpresence:[UIImage imageNamed:@"led_error"]];
        
        UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
        presencetext.backgroundColor = [UIColor clearColor];
        presencetext.font = [UIFont systemFontOfSize:18];
        [presencetext setTag:2];
        presencetext.text =NSLocalizedString(@"Disconnect",nil);
        [self.view addSubview:presencetext];
       

        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Network down",nil)
                              
                                                       message:@""
                              
                                                      delegate:self
                              
                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
                              
                                             otherButtonTitles:nil,nil];
        

        [alert show];
        
        [alert autorelease];
        
    }
  
    
//   else if([[[LinphoneAppDelegate sharedAppDelegate]xmppStream]connect:nil]){
//       
//       [[self.view viewWithTag:1] removeFromSuperview];
//       [[self.view viewWithTag:2]removeFromSuperview];
//       [[self.view viewWithTag:3] removeFromSuperview];
//       [self setpresence:[UIImage imageNamed:@"led_error"]];
//
//       UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
//       presencetext.backgroundColor = [UIColor clearColor];
//       presencetext.font = [UIFont systemFontOfSize:18];
//       presencetext.text =NSLocalizedString(@"Disconnect",nil);
//       [presencetext setTag:2];
//       [self.view addSubview:presencetext];
//
//       UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"XMPP disconnect",nil)
//                              
//                                                       message:@""
//                              
//                                                      delegate:self
//                              
//                                             cancelButtonTitle:NSLocalizedString(@"OK",nil)
//                              
//                                             otherButtonTitles:nil,nil];
//        
//        
//        [alert show];
//        
//        [alert autorelease];
//       
//
//    }
 

   else if([[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID] == NULL){
           
           [[self.view viewWithTag:1] removeFromSuperview];
           [[self.view viewWithTag:2]removeFromSuperview];
           [[self.view viewWithTag:3] removeFromSuperview];
           [self setpresence:[UIImage imageNamed:@"led_error"]];
           
           UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
           presencetext.backgroundColor = [UIColor clearColor];
           presencetext.font = [UIFont systemFontOfSize:18];
           presencetext.text =NSLocalizedString(@"Disconnect",nil);
           [presencetext setTag:2];
           [self.view addSubview:presencetext];
       }
    else{
        [self loadView];
        [self viewDidLoad];
       [[self.view viewWithTag:1] removeFromSuperview];
       [[self.view viewWithTag:2] removeFromSuperview];
       [[self.view viewWithTag:3] removeFromSuperview];
       //uibuttom.
       UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoLight];
       selfbutton.frame = CGRectMake(150, 61, 280, 30);
       selfbutton.backgroundColor = [UIColor clearColor];
       [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
       [selfbutton setTag:3];
       [self.view addSubview:selfbutton];
       [self setpresence:[UIImage imageNamed:@"led_connected"]];
    
       UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
       presencetext.backgroundColor = [UIColor clearColor];
       presencetext.font = [UIFont systemFontOfSize:18];
       presencetext.text =NSLocalizedString(@"Online",nil);
       [presencetext setTag:2];
       [self.view addSubview:presencetext];
        

       [DataTable reloadData];
       }
    
   }

-(void)butClick{
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    UIActionSheet *action = [[UIActionSheet alloc]
                             initWithTitle:selfUserName
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                             destructiveButtonTitle:nil
                             otherButtonTitles:NSLocalizedString(@"Change photo",nil),NSLocalizedString(@"Change presence",nil),nil];
    action.tag = 2;
    if (IS_IPHONE)
    {
        [action showInView:[[UIApplication sharedApplication] keyWindow]];
        
    }
    else{
        [action showInView:self.view];
        
    }
    [action release];
}
- (void)setpresence:(UIImage *)mainImage {
    
    UIImage* presence =[mainImage stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    UIImageView * presenceview =[[UIImageView alloc]initWithImage:presence];
    presenceview.frame =CGRectMake(92, 82, 15, 15);
    [presenceview setTag:1];
    [self.view addSubview:presenceview];
    

}


-(void)loadView{
    if (IS_IPHONE)
    {
        
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 320, 431)];
        self.view = container;
         NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        
        
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        navItem.title = selfUserName;
        
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add",nil) style:UIBarButtonItemStylePlain target:self action:@selector(addfriend)];
        navItem.leftBarButtonItem = leftButton;
        
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Chat",nil)  style:UIBarButtonItemStylePlain target:self action:@selector(setchatroom)];
        navItem.rightBarButtonItem = rightButton;
        
        navBar.items = @[ navItem ];
        
        [self.view addSubview:navBar];
        //self name label.
        UILabel *selfname = [[UILabel alloc]initWithFrame:CGRectMake(91, 41, 150, 50)];
        selfname.backgroundColor = [UIColor clearColor];
        selfname.font = [UIFont systemFontOfSize:19];
        selfname.text =[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        [self.view addSubview:selfname];
        
        //self photo label.
        
        XMPPJID *xmppJID=[XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        XMPPUserCoreDataStorageObject *user = [[[self appDelegate] xmppRosterStorage]
                                               userForJID:xmppJID
                                               xmppStream:[[self appDelegate] xmppStream]
                                               managedObjectContext:[[self appDelegate] managedObjectContext_roster]];
        

        
        NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:xmppJID];
        if (photoData != nil){
            UIImage *selfimage = [UIImage imageWithData:photoData];
            UIImageView *imageview = [[UIImageView alloc]initWithImage:selfimage];
            imageview.frame = CGRectMake(14,46,61.5,61.5);
            
           [self.view addSubview:imageview];
        }
        else if(user.photo !=nil){
            UIImage *selfimage =user.photo;
            UIImageView *imageview =[[UIImageView alloc]initWithImage:selfimage];
            imageview.frame = CGRectMake(14,46,61.5,61.5);
            
            [self.view addSubview:imageview];

            
        }
        else{
        UIImage *selfimage = [[UIImage imageNamed:@"defaultPerson"]stretchableImageWithLeftCapWidth:100 topCapHeight:100];
        UIImageView *imageview = [[UIImageView alloc]initWithImage:selfimage];
        imageview.frame = CGRectMake(14,46,61.5,61.5);
        
        [self.view addSubview:imageview];
        }
        
        
        //table view.
        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 109, 320, 371)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        
        [self.view addSubview:DataTable];
        
     
    }
    else {
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 50, 768, 960)];
        self.view = container;
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
       
        
        UINavigationItem *navItem = [[UINavigationItem alloc] init];
        navItem.title = selfUserName;
        
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add",nil) style:UIBarButtonItemStylePlain target:self action:@selector(addfriend)];
         navItem.leftBarButtonItem = leftButton;
         
         UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Chat",nil) style:UIBarButtonItemStylePlain target:self action:@selector(setchatroom)];
         navItem.rightBarButtonItem = rightButton;
         
        navBar.items = @[ navItem ];
        
        [self.view addSubview:navBar];
        //self name label.
        UILabel *selfname = [[UILabel alloc]initWithFrame:CGRectMake(91, 41, 150, 50)];
        selfname.backgroundColor = [UIColor clearColor];
        selfname.font = [UIFont systemFontOfSize:19];
        selfname.text =[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        [self.view addSubview:selfname];
        
        //self photo label.
        
        XMPPJID *xmppJID=[XMPPJID jidWithString:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
        XMPPUserCoreDataStorageObject *user = [[[self appDelegate] xmppRosterStorage]
                                               userForJID:xmppJID
                                               xmppStream:[[self appDelegate] xmppStream]
                                               managedObjectContext:[[self appDelegate] managedObjectContext_roster]];
        
        
        
        NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:xmppJID];
        if (photoData != nil){
            UIImage *selfimage = [UIImage imageWithData:photoData];
            UIImageView *imageview = [[UIImageView alloc]initWithImage:selfimage];
            imageview.frame = CGRectMake(14,46,61.5,61.5);
            
            [self.view addSubview:imageview];
        }
        else if(user.photo !=nil){
            UIImage *selfimage =user.photo;
            UIImageView *imageview =[[UIImageView alloc]initWithImage:selfimage];
            imageview.frame = CGRectMake(14,46,61.5,61.5);
            
            [self.view addSubview:imageview];
            
            
        }
        else{
            UIImage *selfimage = [[UIImage imageNamed:@"defaultPerson"]stretchableImageWithLeftCapWidth:100 topCapHeight:100];
            UIImageView *imageview = [[UIImageView alloc]initWithImage:selfimage];
            imageview.frame = CGRectMake(14,46,61.5,61.5);
            
            [self.view addSubview:imageview];
        }
        

        DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 109, 768, 960)];
        DataTable.delegate = self;
        DataTable.dataSource = self;
        [self.view addSubview:DataTable];
    }
    
    
}
-(void)addfriend{ //left button.
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add friend",nil)
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                          otherButtonTitles:NSLocalizedString(@"Add",nil), nil];
    
    
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
  
    [alert textFieldAtIndex:0].placeholder = @"Example@azblink.com";
    [alert textFieldAtIndex:1].placeholder = NSLocalizedString(@"Alias",nil);
    [alert textFieldAtIndex:1].secureTextEntry = NO;
    alert.tag=1;
    // Pop UIAlertView
    
    [alert show];
    

}

-(void)setchatroom{ //right button.
    UIActionSheet *action = [[UIActionSheet alloc]
                             initWithTitle:NSLocalizedString(@"Conference Room",nil)
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                             destructiveButtonTitle:nil
                             otherButtonTitles:NSLocalizedString(@"Conference List",nil),NSLocalizedString(@"Create Conference",nil),nil];
    action.tag=1;
    
    if (IS_IPHONE)
    {
    [action showInView:[[UIApplication sharedApplication] keyWindow]];
    
    }
    else{
        [action showInView:self.view];
       
    }
        [action release];
}
- (void) getListOfGroups
{
    
    NSLog(@"send request to server to get room list");
    
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
    
    
    
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //alertview, tag1 is add xmpp friend ,tag 2 is modify friend ,tag3 is create room.
    
    
    if(alertView.tag==1 && buttonIndex ==1){
        NSLog(@"xmpp account : %@",[alertView textFieldAtIndex:0].text);
        
        NSLog(@"user displayname : %@",[alertView textFieldAtIndex:1].text);
        
        if([[alertView textFieldAtIndex:1].text isEqualToString:@" System"]){
            NSLog(@"display name can't be System");
        }
        else{
            XMPPJID *jid = [XMPPJID jidWithString:[alertView textFieldAtIndex:0].text];
           
        [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] addUser:jid withNickname:[alertView textFieldAtIndex:1].text];
          }
        }
    else if(alertView.tag==2 && buttonIndex ==1){
        
        if([[alertView textFieldAtIndex:0].text isEqualToString:@" System"]){
            NSLog(@"display name can't be System");
        }
        else{
        XMPPJID *jid = [XMPPJID jidWithString:alertView.title];
        [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] addUser:jid withNickname:[alertView textFieldAtIndex:0].text];
        }
    }
    else if(alertView.tag ==3 && buttonIndex==1){
        
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Create Conference",nil)
                                                                message:@""
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                      otherButtonTitles:NSLocalizedString(@"Add",nil), nil];
        
        
                alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        
                [alert textFieldAtIndex:0].placeholder =NSLocalizedString(@"Conference name",nil);
                [alert textFieldAtIndex:1].placeholder =NSLocalizedString(@"Password(optional)",nil) ;
                [alert textFieldAtIndex:1].secureTextEntry = NO;
                alert.tag=4;
                // Pop UIAlertView
                
                [alert show];
    }
    else if(alertView.tag ==3 && buttonIndex ==2){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Create Conference",nil)
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Add",nil), nil];
        
        
        alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        
        [alert textFieldAtIndex:0].placeholder =NSLocalizedString(@"Conference name",nil);
        [alert textFieldAtIndex:1].placeholder =NSLocalizedString(@"Password(optional)",nil) ;
        [alert textFieldAtIndex:1].secureTextEntry = NO;
        alert.tag=5;
        // Pop UIAlertView
        
        [alert show];
    }
    else if(alertView.tag ==4 && buttonIndex ==1){
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        NSRange search = [selfUserName rangeOfString:@"@"];
        
        NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        if([[alertView textFieldAtIndex:0].text isEqualToString:@""]){
            
            NSLog(@"room name is nil");
            
        }
        
        else{
            
            NSString *roomname = [alertView textFieldAtIndex:0].text;
            NSString *nickname = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            
            NSString *roomid = [roomname stringByAppendingFormat:@"%@%@%@",@"@",@"conference.", hostname];
            NSLog(@"%@",roomid);
            XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            if (rosterstorage==nil) {
                NSLog(@"nil");
                rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            }
            XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:roomid] dispatchQueue:nil];
            
            [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
            
            [xmppRoom joinRoomUsingNickname:nickname history:nil password:[alertView textFieldAtIndex:1].text];
            
            
            
            
            NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
            [xmppRoom fetchConfigurationForm];
            [xmppRoom configureRoomUsingOptions:nil jid:myJid];
            
            
            if([[alertView textFieldAtIndex:1].text isEqualToString:@""]){
                NSLog(@"there are no password");
                
                sleep(1); //set password after 0.5 sec when room is created.
                NSLog(@"config password for room ");
                NSXMLElement *x = [NSXMLElement elementWithName:@"x"];
                
                [x addAttributeWithName:@"xmlns" stringValue:@"jabber:x:data"];
                
                [x addAttributeWithName:@"type" stringValue:@"submit"];
                NSXMLElement *fielda =[NSXMLElement elementWithName:@"field"];
                [fielda addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];
                [fielda addAttributeWithName:@"type"stringValue:@"boolean"];
                
                [fielda addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
                [x addChild:fielda];
                NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#owner"];
                
                NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
                
                
                [iq addAttributeWithName:@"to" stringValue:roomid];
                
                [iq addAttributeWithName:@"from" stringValue:myJid];
                
                [iq addAttributeWithName:@"type" stringValue:@"set"];
                
                [query addChild:x];
                
                [iq addChild:query];
                
                [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
                
                
                
            }
            else{
                
                sleep(1); //set password after 0.5 sec when room is created.
                NSLog(@"config password for room ");
                NSXMLElement *x = [NSXMLElement elementWithName:@"x"];
                
                [x addAttributeWithName:@"xmlns" stringValue:@"jabber:x:data"];
                
                [x addAttributeWithName:@"type" stringValue:@"submit"];
                NSXMLElement *fielda =[NSXMLElement elementWithName:@"field"];
                [fielda addAttributeWithName:@"var" stringValue:@"muc#roomconfig_persistentroom"];
                
                [fielda removeChildAtIndex:0];
                [fielda addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
                [x addChild:fielda];
                
                NSXMLElement *field = [NSXMLElement elementWithName:@"field"];
                [field addAttributeWithName:@"type"stringValue:@"boolean"];
                [field addAttributeWithName:@"var"stringValue:@"muc#roomconfig_passwordprotectedroom"];
                [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
                
                [x addChild:field];
                
                
                NSXMLElement *fields = [NSXMLElement elementWithName:@"field"];
                [fields addAttributeWithName:@"type"stringValue:@"text-private"];
                [fields addAttributeWithName:@"var"stringValue:@"muc#roomconfig_roomsecret"];
                [fields addChild:[NSXMLElement elementWithName:@"value" stringValue:[alertView textFieldAtIndex:1].text]];
                [x addChild:fields];
                NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#owner"];
                
                NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
                
                
                [iq addAttributeWithName:@"to" stringValue:roomid];
                
                [iq addAttributeWithName:@"from" stringValue:myJid];
                
                [iq addAttributeWithName:@"type" stringValue:@"set"];
                
                [query addChild:x];
                
                [iq addChild:query];
                
                [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
            }
            
        }
        
    }
    else if(alertView.tag ==5 &&buttonIndex ==1){
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        NSRange search = [selfUserName rangeOfString:@"@"];
        
        NSString *hostname = [selfUserName substringFromIndex:search.location+1];
        if([[alertView textFieldAtIndex:0].text isEqualToString:@""]){
            
            NSLog(@"room name is nil");
            
        }
        
        else{
            
            NSString *roomname = [alertView textFieldAtIndex:0].text;
            NSString *nickname = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            
            NSString *roomid = [roomname stringByAppendingFormat:@"%@%@%@",@"@",@"conference.", hostname];
            NSLog(@"%@",roomid);
            XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            if (rosterstorage==nil) {
                NSLog(@"nil");
                rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            }
            XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:roomid] dispatchQueue:nil];
            
            [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
//sss            NSXMLElement *history = [NSXMLElement elementWithName:@"history"];
//            [history addAttributeWithName:@"maxchars" stringValue:@"50"];
            [xmppRoom joinRoomUsingNickname:nickname history:nil password:[alertView textFieldAtIndex:1].text];
            
            
            
            
            NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
            [xmppRoom fetchConfigurationForm];
            [xmppRoom configureRoomUsingOptions:nil jid:myJid];
            
            
            if([[alertView textFieldAtIndex:1].text isEqualToString:@""]){
                
            }
            else{
                
                sleep(1); //set password after 0.5 sec when room is created.
                NSLog(@"config password for room ");
                NSXMLElement *x = [NSXMLElement elementWithName:@"x"];
                
                [x addAttributeWithName:@"xmlns" stringValue:@"jabber:x:data"];
                
                [x addAttributeWithName:@"type" stringValue:@"submit"];
                NSXMLElement *field = [NSXMLElement elementWithName:@"field"];
                [field addAttributeWithName:@"type"stringValue:@"boolean"];
                [field addAttributeWithName:@"var"stringValue:@"muc#roomconfig_passwordprotectedroom"];
                [field addChild:[NSXMLElement elementWithName:@"value" stringValue:@"1"]];
                
                [x addChild:field];
                
                
                NSXMLElement *fields = [NSXMLElement elementWithName:@"field"];
                [fields addAttributeWithName:@"type"stringValue:@"text-private"];
                [fields addAttributeWithName:@"var"stringValue:@"muc#roomconfig_roomsecret"];
                [fields addChild:[NSXMLElement elementWithName:@"value" stringValue:[alertView textFieldAtIndex:1].text]];
                [x addChild:fields];
                NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#owner"];
                
                NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
                
                
                [iq addAttributeWithName:@"to" stringValue:roomid];
                
                [iq addAttributeWithName:@"from" stringValue:myJid];
                
                [iq addAttributeWithName:@"type" stringValue:@"set"];
                
                [query addChild:x];
                
                [iq addChild:query];
                
                [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
            }
            
        }
        
    }
    else if(alertView.tag ==6){
        if(buttonIndex ==1){
            XMPPPresence *presence = [XMPPPresence presence];
            NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"online"];
            
            NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Online"];
            [presence addChild:show];
            [presence addChild:status];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
            [[self.view viewWithTag:3] removeFromSuperview];
            //uibuttom.
            UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            selfbutton.frame = CGRectMake(150, 61, 280, 30);
            selfbutton.backgroundColor = [UIColor clearColor];
            [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
            [selfbutton setTag:3];
            [self.view addSubview:selfbutton];
            [self setpresence:[UIImage imageNamed:@"led_connected"]];
            
            UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
            presencetext.backgroundColor = [UIColor clearColor];
            presencetext.font = [UIFont systemFontOfSize:18];
            presencetext.text =NSLocalizedString(@"Online",nil);
            [presencetext setTag:2];
            [self.view addSubview:presencetext];
            
        }
        else if(buttonIndex ==2){
            XMPPPresence *presence = [XMPPPresence presence];
            NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"offline"];
            
            NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Offline"];
            [presence addChild:show];
            [presence addChild:status];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
            [[self.view viewWithTag:3] removeFromSuperview];
            //uibuttom.
            UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            selfbutton.frame = CGRectMake(150, 61, 280, 30);
            selfbutton.backgroundColor = [UIColor clearColor];
            [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
            [selfbutton setTag:3];
            [self.view addSubview:selfbutton];
            [self setpresence:[UIImage imageNamed:@"led_disconnected"]];
            
            UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
            presencetext.backgroundColor = [UIColor clearColor];
            presencetext.font = [UIFont systemFontOfSize:18];
            presencetext.text =NSLocalizedString(@"Offline",nil);
            [presencetext setTag:2];
            [self.view addSubview:presencetext];

        }
        else if(buttonIndex ==3){
            XMPPPresence *presence = [XMPPPresence presence];
            NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"dnd"];
            
            NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Busy"];
            [presence addChild:show];
            [presence addChild:status];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
            [[self.view viewWithTag:3] removeFromSuperview];
            //uibuttom.
            UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            selfbutton.frame = CGRectMake(150, 61, 280, 30);
            selfbutton.backgroundColor = [UIColor clearColor];
            [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
            [selfbutton setTag:3];
            [self.view addSubview:selfbutton];
            [self setpresence:[UIImage imageNamed:@"led_inprogress"]];
            
            UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
            presencetext.backgroundColor = [UIColor clearColor];
            presencetext.font = [UIFont systemFontOfSize:18];
            presencetext.text =NSLocalizedString(@"Busy",nil);
            [presencetext setTag:2];
            [self.view addSubview:presencetext];

        }
    }
    else if(buttonIndex ==0){
    
        [DataTable reloadData];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"%d", buttonIndex);
    //actionsheet ,tag =1 ,button 0  is roomlist, button1 is create room.
    if(actionSheet.tag ==1 && buttonIndex == 0){
        [self getListOfGroups];
          [[PhoneMainView instance] changeCurrentView:[RoomListViewController compositeViewDescription] push:TRUE];
        
    }
    else if(actionSheet.tag ==1 && buttonIndex ==1){
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Select conference type",nil)  message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil)  otherButtonTitles:NSLocalizedString(@"Persistent Conference",nil) , NSLocalizedString(@"Non-Persistent Conference",nil) ,nil];
        
    alert.tag = 3;
        
        [alert show];
        
        
              }
    else if (actionSheet.tag ==2 && buttonIndex ==0){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [[[[UIApplication sharedApplication].delegate window] rootViewController] presentModalViewController:picker animated:YES];
        
    }
    else if(actionSheet.tag ==2 &&buttonIndex ==1){
        if (IS_IPHONE)
        {
            UIActionSheet *action = [[UIActionSheet alloc]
                                     initWithTitle:NSLocalizedString(@"Change presence",nil)                                 delegate:self
                                     cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                     destructiveButtonTitle:nil
                                     otherButtonTitles:NSLocalizedString(@"Online",nil),NSLocalizedString(@"Offline",nil),NSLocalizedString(@"Busy",nil),nil];
            action.tag = 3;

            [action showInView:[[UIApplication sharedApplication] keyWindow]];
             [action release];
        }
        else{
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Change presence",nil)   message:nil
                                                    delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Online",nil),NSLocalizedString(@"Offline",nil),NSLocalizedString(@"Busy",nil),nil];
            
         
          
            
            alert.tag =6;
            // Pop UIAlertView
            
            [alert show];
          
        }
       
        
    }
    else if(actionSheet.tag ==4 && buttonIndex ==0){
        NSLog(@"leave room");
        
        
        XMPPPresence *presence = [XMPPPresence presence];
       
        [presence addAttributeWithName:@"to" stringValue:actionSheet.title];
        [presence addAttributeWithName:@"type" stringValue:@"unavailable"];
        
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
        
        XMPPJID *xmppjid = [XMPPJID jidWithString:actionSheet.title];
        sleep(1);
        [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] removeUser:xmppjid];
       
    }
    else if(actionSheet.tag ==4 && buttonIndex ==1){
        NSLog(@"destroy room");
        XMPPPresence *presence = [XMPPPresence presence];
        
        [presence addAttributeWithName:@"to" stringValue:actionSheet.title];
        [presence addAttributeWithName:@"type" stringValue:@"unavailable"];
        
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
        
        

                        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
                        NSXMLElement *x = [NSXMLElement elementWithName:@"destroy"];
        
                        [x addAttributeWithName:@"xmlns" stringValue:@"jabber:x:data"];
        
                        [x addAttributeWithName:@"type" stringValue:@"submit"];
                        NSXMLElement *fielda =[NSXMLElement elementWithName:@"destroy"];
                        [fielda addAttributeWithName:@"jid" stringValue:actionSheet.title];
                        [fielda addAttributeWithName:@"reason" stringValue:@"this room is over."];
                        [x addChild:fielda];
                        NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#owner"];
        
                        NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
        
                        [iq addAttributeWithName:@"to" stringValue:actionSheet.title];
        
                        [iq addAttributeWithName:@"from" stringValue:selfUserName];
        
                        [iq addAttributeWithName:@"type" stringValue:@"set"];
        
                        [query addChild:x];
        
                        [iq addChild:query];
                        XMPPJID *xmppjid = [XMPPJID jidWithString:actionSheet.title];
                        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
        

                        sleep(1);
        
                        [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] removeUser:xmppjid];
                        NSLog(@"destroy room");
        
        
    }
    else if(actionSheet.tag ==3){
        if(buttonIndex ==2){
        XMPPPresence *presence = [XMPPPresence presence];
        NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"dnd"];
        
        NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Busy"];
        [presence addChild:show];
        [presence addChild:status];
        [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
            [[self.view viewWithTag:3] removeFromSuperview];
            //uibuttom.
            UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            selfbutton.frame = CGRectMake(150, 61, 280, 30);
            selfbutton.backgroundColor = [UIColor clearColor];
            [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
            [selfbutton setTag:3];
            [self.view addSubview:selfbutton];
            [self setpresence:[UIImage imageNamed:@"led_inprogress"]];
            
            UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
            presencetext.backgroundColor = [UIColor clearColor];
            presencetext.font = [UIFont systemFontOfSize:18];
            presencetext.text =NSLocalizedString(@"Busy",nil);
            [presencetext setTag:2];
            [self.view addSubview:presencetext];
        }
        else if(buttonIndex ==1){
            XMPPPresence *presence = [XMPPPresence presence];
            NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"offline"];
            
            NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Offline"];
            [presence addChild:show];
            [presence addChild:status];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
            [[self.view viewWithTag:3] removeFromSuperview];
            //uibuttom.
            UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            selfbutton.frame = CGRectMake(150, 61, 280, 30);
            selfbutton.backgroundColor = [UIColor clearColor];
            [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
            [selfbutton setTag:3];
            [self.view addSubview:selfbutton];
            [self setpresence:[UIImage imageNamed:@"led_disconnected"]];
            
            UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
            presencetext.backgroundColor = [UIColor clearColor];
            presencetext.font = [UIFont systemFontOfSize:18];
            presencetext.text =NSLocalizedString(@"Offline",nil);
            [presencetext setTag:2];
            [self.view addSubview:presencetext];
        }
        else if(buttonIndex ==0){
            
            XMPPPresence *presence = [XMPPPresence presence];
            NSXMLElement *show = [NSXMLElement elementWithName:@"show" stringValue:@"online"];
            
            NSXMLElement *status = [NSXMLElement elementWithName:@"status" stringValue:@"Online"];
            [presence addChild:show];
            [presence addChild:status];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:presence];
            [[self.view viewWithTag:1] removeFromSuperview];
            [[self.view viewWithTag:2] removeFromSuperview];
            [[self.view viewWithTag:3] removeFromSuperview];
            //uibuttom.
            UIButton *selfbutton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            selfbutton.frame = CGRectMake(150, 61, 280, 30);
            selfbutton.backgroundColor = [UIColor clearColor];
            [selfbutton addTarget:self action:@selector(butClick) forControlEvents:UIControlEventTouchUpInside];
            [selfbutton setTag:3];
            [self.view addSubview:selfbutton];
            [self setpresence:[UIImage imageNamed:@"led_connected"]];
            
            UILabel *presencetext = [[UILabel alloc]initWithFrame:CGRectMake(112, 65, 150, 50)];
            presencetext.backgroundColor = [UIColor clearColor];
            presencetext.font = [UIFont systemFontOfSize:18];
            presencetext.text =NSLocalizedString(@"Online",nil);
            [presencetext setTag:2];
            [self.view addSubview:presencetext];
        }
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (IS_IPHONE)
    {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    CGSize sacleSize = CGSizeMake(40, 40);
    UIGraphicsBeginImageContextWithOptions(sacleSize, NO, 0.0);
    [chosenImage drawInRect:CGRectMake(0, 0, sacleSize.width, sacleSize.height)];
   
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *imageview = [[UIImageView alloc]initWithImage:chosenImage];
    imageview.frame = CGRectMake(14,46,61.5,61.5);
    
    [self.view addSubview:imageview];

    NSXMLElement *vCardXML = [NSXMLElement elementWithName:@"vCard" xmlns:
                              @"vcard-temp"];
    NSXMLElement *photoXML = [NSXMLElement elementWithName:@"PHOTO"];
    NSXMLElement *typeXML = [NSXMLElement elementWithName:@"TYPE"
                                              stringValue:@"image/jpeg"];
    
  
    UIImageJPEGRepresentation(image, 0.7f);
    NSData *dataFromImage =UIImagePNGRepresentation(image);
    NSXMLElement *binvalXML = [NSXMLElement elementWithName:@"BINVAL"
                                                stringValue:[dataFromImage base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
    [photoXML addChild:typeXML];
    [photoXML addChild:binvalXML];
    [vCardXML addChild:photoXML];
    XMPPvCardTemp *myvCardTemp = [[[self appDelegate] xmppvCardTempModule]
                                  myvCardTemp];
    if (myvCardTemp) {
        [myvCardTemp setPhoto:dataFromImage];
        [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
         :myvCardTemp];
    }
    else{
        XMPPvCardTemp *newvCardTemp = [XMPPvCardTemp vCardTempFromElement
                                       :vCardXML];
        [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
         :newvCardTemp];
    }

    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    }
    else{
        UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
        CGSize sacleSize = CGSizeMake(80, 80);
        UIGraphicsBeginImageContextWithOptions(sacleSize, NO, 0.0);
        [chosenImage drawInRect:CGRectMake(0, 0, sacleSize.width, sacleSize.height)];
        
        UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIImageView *imageview = [[UIImageView alloc]initWithImage:chosenImage];
        imageview.frame = CGRectMake(14,46,61.5,61.5);
        
        [self.view addSubview:imageview];
        
        NSXMLElement *vCardXML = [NSXMLElement elementWithName:@"vCard" xmlns:
                                  @"vcard-temp"];
        NSXMLElement *photoXML = [NSXMLElement elementWithName:@"PHOTO"];
        NSXMLElement *typeXML = [NSXMLElement elementWithName:@"TYPE"
                                                  stringValue:@"image/jpeg"];
        
        
        UIImageJPEGRepresentation(image, 0.7f);
        NSData *dataFromImage =UIImagePNGRepresentation(image);
        NSXMLElement *binvalXML = [NSXMLElement elementWithName:@"BINVAL"
                                                    stringValue:[dataFromImage base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
        [photoXML addChild:typeXML];
        [photoXML addChild:binvalXML];
        [vCardXML addChild:photoXML];
        XMPPvCardTemp *myvCardTemp = [[[self appDelegate] xmppvCardTempModule]
                                      myvCardTemp];
        if (myvCardTemp) {
            [myvCardTemp setPhoto:dataFromImage];
            [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
             :myvCardTemp];
        }
        else{
            XMPPvCardTemp *newvCardTemp = [XMPPvCardTemp vCardTempFromElement
                                           :vCardXML];
            [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp
             :newvCardTemp];
        }
        
        [picker dismissViewControllerAnimated:YES completion:NULL];
        
    
    }
}





- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //let tableview can be edit.
    return YES;
}
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    //swip left to delete or modify row.
    switch (index) {
        case 0:
            NSLog(@"More button was pressed");
            NSIndexPath *cellIndexPath = [DataTable indexPathForCell:cell];
            XMPPUserCoreDataStorageObject *user = [fetchedResultsController objectAtIndexPath:cellIndexPath];
            
            NSRange tRange = [user.jidStr rangeOfString:@"@conference"];
            if([user.displayName isEqualToString:@" System"]){
                NSLog(@"System can't be modify");
            }
            else if(tRange.location == NSNotFound){
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:user.jidStr   message:NSLocalizedString(@"Enter alias",nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Edit",nil), nil];
            
            
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            
          
            alert.tag =2;
            // Pop UIAlertView
            
            [alert show];
            }
            else{
                
                UIActionSheet *action = [[UIActionSheet alloc]
                                         initWithTitle:user.jidStr
                                         delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                         destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Leave conference",nil),NSLocalizedString(@"Destroy conference",nil),nil];
                action.tag = 4;
                if (IS_IPHONE)
                {
                    [action showInView:[[UIApplication sharedApplication] keyWindow]];
                    
                }
                else{
                    [action showInView:self.view];
                    
                }
                [action release];


//                NSXMLElement *x = [NSXMLElement elementWithName:@"x"];
//                
//                [x addAttributeWithName:@"xmlns" stringValue:@"jabber:x:data"];
//                
//                [x addAttributeWithName:@"type" stringValue:@"submit"];
//                NSXMLElement *fielda =[NSXMLElement elementWithName:@"field"];
//                [fielda addAttributeWithName:@"var" stringValue:@"muc#roomconfig_roomname"];
//                [fielda addAttributeWithName:@"type"stringValue:@"text-single"];
//                
//                [fielda addChild:[NSXMLElement elementWithName:@"value" stringValue:@"sdfdsdf123"]];
//                [x addChild:fielda];
//                NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/muc#owner"];
//                
//                NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
//                
//                
//                [iq addAttributeWithName:@"to" stringValue:user.jidStr];
//                                NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
//                [iq addAttributeWithName:@"from" stringValue:selfUserName];
//                
//                [iq addAttributeWithName:@"type" stringValue:@"set"];
//                
//                [query addChild:x];
//                
//                [iq addChild:query];
//                
//                [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
                

            }
            break;
        case 1:
        {
            
             NSIndexPath *cellIndexPath = [DataTable indexPathForCell:cell];
            XMPPUserCoreDataStorageObject *user = [fetchedResultsController objectAtIndexPath:cellIndexPath];
            NSRange tRange = [user.jidStr rangeOfString:@"@conference"];
          
            if([user.displayName isEqualToString:@" System"]){
                NSLog(@"System can't be delete");
            }
            else if(tRange.location == NSNotFound){
                [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] removeUser:user.jid];
                NSLog(@"remove jid");
             
                
            }
            else{
                UIActionSheet *action = [[UIActionSheet alloc]
                                         initWithTitle:user.jidStr
                                         delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                         destructiveButtonTitle:nil
                                         otherButtonTitles:NSLocalizedString(@"Leave conference",nil),NSLocalizedString(@"Destroy conference",nil),nil];
                action.tag = 4;
                if (IS_IPHONE)
                {
                    [action showInView:[[UIApplication sharedApplication] keyWindow]];
                    
                }
                else{
                    [action showInView:self.view];
                    
                }
                [action release];


                
            
            }
            break;
        }
        default:
            break;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{

    
    
    [super viewWillDisappear:animated];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
  
    [super viewDidLoad];
    
    
     NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    
    if(selfUserName !=nil){                              //add hostname account as friend to receive Emergency Messages from iguardian.
    NSRange search = [selfUserName rangeOfString:@"@"];
    
    NSString *hostname = [selfUserName substringFromIndex:search.location+1];
    
    XMPPJID *jid = [XMPPJID jidWithString:hostname];
    [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] addUser:jid withNickname:@" System"];
    }
    
         NSPredicate *predicate = [NSPredicate predicateWithFormat:@"jidStr!=%@",selfUserName];
        NSManagedObjectContext *moc = [[self appDelegate] managedObjectContext_roster];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
                                                  inManagedObjectContext:moc];
        
        NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
        NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
        
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setSortDescriptors:sortDescriptors];
        [fetchRequest setFetchBatchSize:10];
        [fetchRequest setPredicate:predicate];
        fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                       managedObjectContext:moc
                                                                         sectionNameKeyPath:@"sectionNum"
                                                                                  cacheName:nil];
        [fetchedResultsController setDelegate:self];
        
        
        NSError *error = nil;
        if (![fetchedResultsController performFetch:&error])
        {
            DDLogError(@"Error performing fetch: %@", error);
        }
 
    

    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"sendedMessages.@count>0 and name!=%@",selfUserName];
    NSFetchRequest *fetchRequest1 = [NSFetchRequest fetchRequestWithEntityName:@"PersonEntity"];
    [fetchRequest1 setPredicate:predicate1];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [fetchRequest1 setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
    fetchResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest1
                                                               managedObjectContext:[LinphoneAppDelegate sharedAppDelegate].managedObjectContext
                                                                 sectionNameKeyPath:nil cacheName:nil];
    
    fetchResultController.delegate = self;
    [fetchResultController performFetch:NULL];
    personArray = [[NSMutableArray alloc]initWithArray:[fetchResultController fetchedObjects]];
  


}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if ([anObject isKindOfClass:[PersonEntity class]]) {
        PersonEntity *personEntity = (PersonEntity*)anObject;
        if (type==NSFetchedResultsChangeInsert) {
            [personArray addObject:personEntity];
    
            [DataTable reloadData];
            [self.view addSubview:DataTable];
            
            
        }else if (type==NSFetchedResultsChangeUpdate) {
         
            [DataTable reloadData];
            [self.view addSubview:DataTable];
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
   
        
        [DataTable reloadData];
      
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewCell helpers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//  
//    cell.imageView.layer.masksToBounds = YES;
//    cell.imageView.layer.cornerRadius = cell.imageView.frame.size.width / 2.0f;
//    cell.imageView.frame = CGRectMake(0.0f, 0.0f, 100, 100);
//    
//    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
//  
//
//}
- (void)configurePhotoForCell:(UITableViewCell *)cell user:(XMPPUserCoreDataStorageObject *)user
{
    // Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
    // We only need to ask the avatar module for a photo, if the roster doesn't have it.
    
    if (user.photo != nil)
    {
        cell.imageView.image = user.photo;
       
    }
   
    else
    {
        NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];
        NSRange tRange = [user.displayName rangeOfString:@"@conference"];
       
        if (photoData != nil){
            cell.imageView.image = [UIImage imageWithData:photoData];
        }
        else if (tRange.location != NSNotFound){
            cell.imageView.image = [UIImage imageNamed:@"conference"];

        }
        else if ([user.displayName isEqualToString:@" System"]){
            cell.imageView.image = [UIImage imageNamed:@"System"];
        }
        else{
            cell.imageView.image = [UIImage imageNamed:@"defaultPerson"];
       
                }
    }
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    NSArray *sections = [fetchedResultsController sections];
   if (sectionIndex < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
        int section = [sectionInfo.name intValue];
        switch (section)
        {
            case 0  : return NSLocalizedString(@"Online",nil);
            case 1  : return NSLocalizedString(@"Busy",nil);
            default : return NSLocalizedString(@"Offline",nil);
        }
    }
    
    return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    NSArray *sections = [fetchedResultsController sections];
    
    if (sectionIndex < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        return sectionInfo.numberOfObjects;
    }
    
    return 0;
    
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
       SWTableViewCell *cell = [DataTable dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        
        cell = [[SWTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"cell"];
        UIImage *numImage = [[UIImage imageNamed:@"com_number_single"]stretchableImageWithLeftCapWidth:12 topCapHeight:12];
        UIImageView *numView = [[UIImageView alloc]initWithImage:numImage];
        
        numView.tag = kNumViewTag;
        [cell.contentView addSubview:numView];
        UILabel *numLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 20, 20, 20)];
        numLabel.backgroundColor = [UIColor clearColor];
        numLabel.font = [UIFont systemFontOfSize:14];
        numLabel.textColor = [UIColor whiteColor];
        numLabel.tag = kNumLabelTag;
        
        [numView addSubview:numLabel];
        cell.rightUtilityButtons = [self rightButtons];
        cell.delegate = self;
        
    }
  
    UIImageView *numView = (UIImageView*)[cell.contentView viewWithTag:kNumViewTag];
    
    numView.frame = CGRectMake(280,15,30,30);
    UILabel *numLabel = (UILabel*)[numView viewWithTag:kNumLabelTag];
    numLabel.frame = CGRectMake(5,7,20,15);
    
    XMPPUserCoreDataStorageObject *user = [fetchedResultsController objectAtIndexPath:indexPath];
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    friendEntity =[appDelegate fetchPerson:user.jidStr];
        NSArray *sendedMessageArray = [friendEntity.sendedMessages allObjects];
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
    
        sendedMessageArray = [sendedMessageArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
        sendedMessageArray = [sendedMessageArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(flag_readed == %@)", [NSNumber numberWithBool:NO]]];
  
    
    NSString *numStr = [NSString stringWithFormat:@"%d",sendedMessageArray.count];
    
    numLabel.text = numStr;
    numLabel.textAlignment = NSTextAlignmentCenter;
    
    NSRange tRange = [user.displayName rangeOfString:@"@conference"];
    if (tRange.location == NSNotFound){
        
        cell.textLabel.text = user.displayName;
    }
    else {
        NSRange search = [user.displayName  rangeOfString:@"@"];
        
        NSString *room = [user.displayName substringToIndex:search.location];
        
        cell.textLabel.text =[room stringByAppendingString:@"@Conference"];
    }
    
    NSArray *msg = [friendEntity.sendedMessages allObjects];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
    msg = [msg sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];
    MessageEntity *lastMessageEntity = [msg lastObject];
    cell.detailTextLabel.text = lastMessageEntity.content;

        
    
//online:black ,offline:gray , system:red.
    if(user.section!=0 && [user.displayName isEqualToString:@" System"]){
    cell.textLabel.textColor =[UIColor redColor];
        
    }
    else if (user.section ==0){
        cell.textLabel.textColor =[UIColor blackColor];
       
    }
    else if(user.section !=0){
        cell.textLabel.textColor =[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        NSRange tRange = [user.jidStr rangeOfString:@"@conference"];
        
        if(tRange.location == NSNotFound){
        }
        else {
            [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] removeUser:user.jid];
        }
    }
    

    if([numStr isEqualToString:@"0"]){
        [numView setHidden:YES];
    }
    else {
        [numView setHidden:NO];
    }

    [self configurePhotoForCell:cell user:user];
    return cell;
    
}
- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
                                                title:NSLocalizedString(@"Edit",nil)];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
                                                title:NSLocalizedString(@"Delete",nil)];
    
    return rightUtilityButtons;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
    XMPPUserCoreDataStorageObject *friendEntity1 = [fetchedResultsController objectAtIndexPath:indexPath];

    ChatController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatController compositeViewDescription] push:TRUE], ChatController);
    [controller setFriendEn:friendEntity1];
 
    
 }


@end
