//  ChatController.m

#import "ChatController.h"
#import "MessageEntity.h"
#import "ChatViewController.h"
#import "PhoneMainView.h"
#import "LinphoneAppDelegate.h"
#import "RoomListViewController.h"
#import "FriendsListViewController.h"
#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
#define kBallonImageViewTag 100

#define kChatContentLabelTag 101

#define kDateLabelTag 102

#define kLoadingViewTag 103
#define sender_name 104
#define sender_photo 105
#define sender_date 106
#define kSendfailViewTag 107
@implementation ChatController
#pragma mark - View lifecycle

@synthesize friendEn;
static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"ChatRoom"
                                                                content:@"ChatController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar:/*@"UIMainBar"*/nil
                                                          tabBarEnabled:false /*to keep room for chat*/
                                                             fullscreen:false
                                                          landscapeMode:false
                                                           portraitMode:true];
        
    }
    return compositeDescription;
}
- (LinphoneAppDelegate *)appDelegate
{
    return (LinphoneAppDelegate *)[[UIApplication sharedApplication] delegate];
}
- (void)viewDidAppear:(BOOL)animated{
   [super viewDidAppear:animated];
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    
    PersonEntity *senderUserEntity = [appDelegate fetchPerson:_displayname.text];
    
    NSManagedObjectContext *context = nil;
    
    id delegate = [[UIApplication sharedApplication] delegate];
    
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        
        context = [delegate managedObjectContext];
        
    }
    NSFetchRequest *fetch =[[NSFetchRequest alloc]init];
    
    NSEntityDescription * entity =[NSEntityDescription entityForName:@"MessageEntity" inManagedObjectContext:appDelegate.managedObjectContext];
    
    [fetch setEntity:entity];
    
    NSPredicate *predicate =[NSPredicate  predicateWithFormat:@"sender ==%@ and flag_readed == %@",senderUserEntity,[NSNumber numberWithBool:NO]];
    
    [fetch setPredicate:predicate];
    
    NSArray *all = [appDelegate.managedObjectContext executeFetchRequest:fetch error:nil];
    
    
    
    if(all.count ==0){
        
        NSLog(@"no unread message %i",all.count);
        
    }
    
    else if(all.count != 0){
        
        for(int i =0 ;i<all.count ;i++){
            
            NSManagedObject *board = all[i];
            
            [board setValue:[NSNumber numberWithBool:YES] forKey:@"flag_readed"];
            
            [context save:nil];
            
        }
        
        
        
    }
    

    if(firstTime == true){ //if it's firsttime ,run viewdidappear and set firsttime equal to false by otis.
        
        _displayname.text = friendEn.jidStr;
        
        _displayname.textAlignment = NSTextAlignmentCenter;
        LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
        
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        
        selfEntity = [appDelegate fetchPerson:selfUserName];
        friendEntity =[appDelegate fetchPerson:friendEn.jidStr];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sender.name=%@ || receiver.name=%@",_displayname.text,_displayname.text];
        
        NSFetchRequest *fetechRequest = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
        
        
        [fetechRequest setPredicate:predicate];
        
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
        
        
        [fetechRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
        
        
        fetchController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequest
                                                             managedObjectContext:appDelegate.managedObjectContext
                                                               sectionNameKeyPath:nil cacheName:nil];
        
        
        fetchController.delegate = self;
        
        [fetchController performFetch:NULL];
        
        
        NSArray *contentArray = [fetchController fetchedObjects];
        
        messageArray = [[NSMutableArray alloc]init];
        
        
        for (NSInteger i=0; i<contentArray.count; i++) {
          
            MessageEntity *messageEntity = [contentArray objectAtIndex:i];
            
            NSDate *messageDate = messageEntity.sendDate;
            
            if (i==0) {
                
                [messageArray addObject:messageDate];
                
            }else {
                
                
                MessageEntity *previousEntity = [contentArray objectAtIndex:i-1];
                
                
                NSTimeInterval timeIntervalBetween = [messageDate timeIntervalSinceDate:previousEntity.sendDate];
                
                
                if (timeIntervalBetween>15*60) {
                    
                    [messageArray addObject:messageDate];
                    
                }
                
            }
            
            [messageArray addObject:messageEntity];
            
        }
        
        [DataTable reloadData];
        if (messageArray.count>0) {
            [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                             atScrollPosition:UITableViewScrollPositionBottom
                                     animated:NO];
        }
        firstTime = false; //to make viewdidappear just run once by otis.
    }
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    PersonEntity *senderUserEntity = [appDelegate fetchPerson:_displayname.text];
    
    NSManagedObjectContext *context = nil;
    
    id delegate = [[UIApplication sharedApplication] delegate];
    
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        
        context = [delegate managedObjectContext];
        
    }
    NSFetchRequest *fetch =[[NSFetchRequest alloc]init];
    
    NSEntityDescription * entity =[NSEntityDescription entityForName:@"MessageEntity" inManagedObjectContext:appDelegate.managedObjectContext];
    
    [fetch setEntity:entity];
    
    NSPredicate *predicate =[NSPredicate  predicateWithFormat:@"sender ==%@ and flag_readed == %@",senderUserEntity,[NSNumber numberWithBool:NO]];
    
    [fetch setPredicate:predicate];
    
    NSArray *all = [appDelegate.managedObjectContext executeFetchRequest:fetch error:nil];
    
    
    
    if(all.count ==0){
        
        NSLog(@"no unread message %i",all.count);
        
    }
    
    else if (all.count !=0){
        
        for(int i =0 ;i<all.count ;i++){
            
            NSManagedObject *board = all[i];
            
            [board setValue:[NSNumber numberWithBool:YES] forKey:@"flag_readed"];
            
            [context save:nil];
            
        }
        
        
        
    }
    fetchController.delegate = nil;
    firstTime = true; //to make viewdidappear just run once by otis.
    
}
    

    

- (void)viewDidLoad
{
    [super viewDidLoad];
  
   
    firstTime = true; //to make viewdidappear just run once by otis.
    [self setUpForDismissKeyboard]; //dissmiss keyboard when touch the screen by otis.
    
    DataTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Do any additional setup after loading the view from its nib.
    
 
    if (IS_IPHONE)
    {
    inputContainer.userInteractionEnabled = YES;
    
    UIImage *chatBgImage = [UIImage imageNamed:@"ChatBar.png"];
    
    chatBgImage = [chatBgImage stretchableImageWithLeftCapWidth:18 topCapHeight:20];
    
    inputContainer.image = chatBgImage;
    
    inputView = [[UITextView alloc]initWithFrame:CGRectMake(40, 10, 220, 30)];
    
    inputView.delegate = self;
    
    inputView.backgroundColor = [UIColor clearColor];
    
    inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    inputView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0);
    
    inputView.showsHorizontalScrollIndicator = NO;
    
   
    
    //inputView.returnKeyType = UIReturnKeyNext;
    
    [inputContainer addSubview:inputView];
    
    inputView.font = [UIFont systemFontOfSize:16];
    
    //inputView.contentStretch = uiviewcont
        UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        sendButton.frame = CGRectMake(270, 5, 40, 45);
        [sendButton addTarget:self
         
                       action:@selector(sendButtonClick:)
         
             forControlEvents:UIControlEventTouchUpInside];
        
        [sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        
        [inputContainer addSubview:sendButton];
        

    
    }
    else{
        inputContainer.userInteractionEnabled = YES;
        
        UIImage *chatBgImage = [UIImage imageNamed:@"ChatBar.png"];
        
        chatBgImage = [chatBgImage stretchableImageWithLeftCapWidth:90 topCapHeight:20];
        
        inputContainer.image = chatBgImage;
        
        inputView = [[UITextView alloc]initWithFrame:CGRectMake(40, 10, 660, 30)];
        
        inputView.delegate = self;
        
        inputView.backgroundColor = [UIColor clearColor];
        
        inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        inputView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0);
        
        inputView.showsHorizontalScrollIndicator = NO;
        
        
        
        //inputView.returnKeyType = UIReturnKeyNext;
        
        [inputContainer addSubview:inputView];
        
        inputView.font = [UIFont systemFontOfSize:16];
        
        //inputView.contentStretch = uiviewcont
        UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        sendButton.frame = CGRectMake(715, 7, 40, 45);
        [sendButton addTarget:self
         
                       action:@selector(sendButtonClick:)
         
             forControlEvents:UIControlEventTouchUpInside];
        
        [sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        
        [inputContainer addSubview:sendButton];
        

    }
    
  
    
    [[NSNotificationCenter defaultCenter]addObserver:self
     
                                            selector:@selector(keyboardWillShow:)
     
                                                name:UIKeyboardWillShowNotification
     
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
     
                                            selector:@selector(keyboardWillHide:)
     
                                                name:UIKeyboardWillHideNotification
     
                                              object:nil];
    
    
  
    
     }


//dissmiss keyboard when touch the screen by otis.
- (void)setUpForDismissKeyboard {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    UITapGestureRecognizer *singleTapGR =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(tapAnywhereToDismissKeyboard:)];
    NSOperationQueue *mainQuene =[NSOperationQueue mainQueue];
    [nc addObserverForName:UIKeyboardWillShowNotification
                    object:nil
                     queue:mainQuene
                usingBlock:^(NSNotification *note){
                    [self.view addGestureRecognizer:singleTapGR];
                }];
    [nc addObserverForName:UIKeyboardWillHideNotification
                    object:nil
                     queue:mainQuene
                usingBlock:^(NSNotification *note){
                    [self.view removeGestureRecognizer:singleTapGR];
                }];
}

- (void)tapAnywhereToDismissKeyboard:(UIGestureRecognizer *)gestureRecognizer {
    
    [self.view endEditing:YES];
   //friendEntity.readcount = friendEntity.sendedMessages.count;// when user touch the screen, reset the notification icon by otis.

}



- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self
            name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
            name:UIKeyboardWillHideNotification object:nil];
   
    [_displayname release];
   
    [super dealloc];
}

#pragma mark keybord
// Prepare to resize for keyboard.
- (void)keyboardWillShow:(NSNotification *)notification
{
   
    //NSLog(@"keyboardWillShow");
 	NSDictionary *userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
  
    CGRect inputFrame = inputContainer.frame;
   
    inputFrame.origin.y = keyboardEndFrame.origin.y - inputFrame.size.height-20;
    [UIView animateWithDuration:0.2
                     animations:^{
                         inputContainer.frame = inputFrame;
                         
                         CGRect tableFrame = DataTable.frame;
                         tableFrame.size.height = inputFrame.origin.y-44;
                         DataTable.frame = tableFrame;
                     }completion:^(BOOL finish){
                         if (messageArray.count>0) {
                             [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                                              atScrollPosition:UITableViewScrollPositionBottom
                                                      animated:YES];
                         }

                     }];

//	keyboardIsShowing = YES;
    
//    [self slideFrame:YES 
//               curve:animationCurve 
//            duration:animationDuration];
    
}

// Expand textview on keyboard dismissal
- (void)keyboardWillHide:(NSNotification *)notification 
{
    
	//NSLog(@"keyboardWillHide");
 	NSDictionary *userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
   
    CGRect inputFrame = inputContainer.frame;
    
    inputFrame.origin.y = keyboardEndFrame.origin.y - inputFrame.size.height-20;
    [UIView animateWithDuration:0.2
                     animations:^{
                         inputContainer.frame = inputFrame;
                         
                         CGRect tableFrame = DataTable.frame;
                         tableFrame.size.height = inputFrame.origin.y-44;
                         DataTable.frame = tableFrame;
                     }completion:^(BOOL finish){
                         if (messageArray.count>0) {
                             [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                                              atScrollPosition:UITableViewScrollPositionBottom
                                                      animated:YES];
                         }
                     }];
    
  
}



- (void)textViewDidChange:(UITextView *)textView{
    if (inputView.contentSize.height< 50 && inputView.contentSize.height>29) {

        
    }else {
        inputView.scrollEnabled = YES;
        
        
    }
    
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    
    if ([scrollView isKindOfClass:[UITextView class]]) {
        if (inputView.contentSize.height<50 && inputView.contentSize.height>29) {
            [inputView setContentOffset:CGPointMake(0, 6)];
        }
    }else {
        //[inputView resignFirstResponder];
    }
}

-(void)sendButtonClick:(id)sender{
    
    
  
    
    NSString *content = [inputView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(content.length ==0){
      
        NSLog(@"enter empty message ");
    }
    else{
    
    
    
    
    inputView.text = @"";
    
    
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    
    [body setStringValue:content];
    
    
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    
    //need to show the type when send messeage to other devieces by otis.
    
   
    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
    if (tRange.location == NSNotFound){
        
        [message addAttributeWithName:@"type" stringValue:@"chat"];
    }
    
    else {
        
        [message addAttributeWithName:@"type" stringValue:@"groupchat"];
        
    }
    

    [message addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
    
    
    
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    NSRange search = [selfUserName rangeOfString:@"@"];
    NSString *hostname = [selfUserName substringFromIndex:search.location+1];
    
    if([hostname isEqualToString:_displayname.text]){
        NSLog(@"can't send message to system.");
    }
    else{
        

    
 
        [message addAttributeWithName:@"to" stringValue:_displayname.text];
    
    [message addChild:body];
    
    
    
    NSLog(@"friendEntity.name:%@",_displayname.text);
    
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    
    
    MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                    
                                                                 inManagedObjectContext:appDelegate.managedObjectContext];
    
    messageEntity.content = content;
    
    messageEntity.sendDate = [NSDate date];
    
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    PersonEntity *senderUserEntity = [appDelegate fetchPerson:selfUserName];
    
    messageEntity.sender = senderUserEntity;

    [senderUserEntity addSendedMessagesObject:messageEntity];
    
    messageEntity.receiver = [appDelegate fetchPerson:_displayname.text];
    [appDelegate saveContext];
    //sssloading
    XMPPElementReceipt *receipt;
    
    [[[LinphoneAppDelegate sharedAppDelegate] xmppStream]sendElement:message andGetReceipt:&receipt];
    NSLog(@"message ready to send:%@",[[NSDate alloc]init]);
    
    if ([receipt wait:20]) {
        //会延迟几秒
        NSLog(@"message sended:%@",[[NSDate alloc]init]);
        [self performSelector:@selector(messageSendedDelay:)
                   withObject:messageEntity
                   afterDelay:0.5];
    }else {
        NSLog(@"sendedFail");
        [self performSelector:@selector(animationFinished:) withObject:messageEntity afterDelay:5];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Message send failure ",nil) message:NSLocalizedString(@"Please check your server and VPN connection status",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    
        [alert show];

    }
    }
    }
    
}
-(void)messageSendedDelay:(MessageEntity*)messageEntity{
    //sssloading.
    messageEntity.flag_sended = [NSNumber numberWithBool:YES];
    [[LinphoneAppDelegate sharedAppDelegate] saveContext];
}

-(void)animationFinished:(MessageEntity*)messageEntity {
    messageEntity.flag_sended =[NSNumber numberWithBool:YES];
    messageEntity.content = [messageEntity.content stringByAppendingString:@" "];
    
    [[LinphoneAppDelegate sharedAppDelegate]saveContext];
   
}
//back button.
- (IBAction)back:(id)sender {
    
  [[PhoneMainView instance] popCurrentView];
   
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag==1 && buttonIndex==2){
        NSLog(@"Invite other user");
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite friend",nil)
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Add",nil), nil];
        
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].placeholder = @"Example@azblink.com";
        alert.tag=4;
        
        
        
        [alert show];
        
     
    }
    else if (alertView.tag ==1 && buttonIndex ==1){
        NSLog(@"invite exist friend");
                NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
                NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
        
        
                [iq addAttributeWithName:@"type" stringValue:@"get"];
                [iq addChild:query];
                [[[LinphoneAppDelegate sharedAppDelegate] xmppStream] sendElement:iq];
                sleep(0.5);
                FriendsListViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[FriendsListViewController compositeViewDescription] push:TRUE], FriendsListViewController);
             
                [controller setRoomname:_displayname.text];

        
    }
    else if(alertView.tag ==2 && buttonIndex ==2){
        NSLog(@"select conference");
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Select conference type",nil)
                                                       message:nil delegate:self
                                                       cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                    otherButtonTitles:NSLocalizedString(@"Persistent Conference",nil) , NSLocalizedString(@"Non-Persistent Conference",nil) ,nil];
        
        
        
        alert.tag = 3;
        
        
        
        [alert show];

    }
    else if (alertView.tag ==2 && buttonIndex ==1){
        NSLog(@"join exist room");
        [self getListOfGroups];
        RoomListViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RoomListViewController compositeViewDescription] push:TRUE], RoomListViewController);
        
        [controller setFriendname:_displayname.text];
        
    }   else if(alertView.tag ==3 && buttonIndex==1){
        
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
        alert.tag=6;
        // Pop UIAlertView
        
        [alert show];
    }
    else if(alertView.tag ==5 && buttonIndex ==1){
        
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
                sleep(0.5); //set password after 0.5 sec when room is created.
                
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

            XMPPJID *xmppJID=[XMPPJID jidWithString:_displayname.text];
            
            [xmppRoom inviteUser:xmppJID  withMessage:@"Come Join me"];
        }
        
    }
    
    else if(alertView.tag ==6 &&buttonIndex ==1){
        
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
                sleep(0.5); //set password after 0.5 sec when room is created.
                
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
            
            XMPPJID *xmppJID=[XMPPJID jidWithString:_displayname.text];
            
            [xmppRoom inviteUser:xmppJID  withMessage:@"Come Join me"];
        }
    }
    else if(alertView.tag ==4 && buttonIndex ==1){
        NSLog(@"invite XXX to room");
        NSRange tRange = [[alertView textFieldAtIndex:0].text rangeOfString:@"@"]; //check if user enter the full conference room id or not.
        if (tRange.location == NSNotFound){
            XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            if (rosterstorage==nil) {
                rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
            }
            XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:_displayname.text] dispatchQueue:nil];
            
            [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
            
            [xmppRoom joinRoomUsingNickname:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID] history:nil];
            
            [xmppRoom fetchConfigurationForm];
            
            [xmppRoom addDelegate:[LinphoneAppDelegate sharedAppDelegate] delegateQueue:nil];
            
            NSXMLElement *roomConfigForm = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
            
            NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
            
            [xmppRoom configureRoomUsingOptions:roomConfigForm jid:myJid];
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            NSRange search = [selfUserName rangeOfString:@"@"];
            
            NSString *hostname = [selfUserName substringFromIndex:search.location];
            NSString* friend = [[alertView textFieldAtIndex:0].text stringByAppendingFormat:@"%@",hostname];
            XMPPJID *xmppJID=[XMPPJID jidWithString:friend];
            
            [xmppRoom inviteUser:xmppJID  withMessage:@"Come Join me"];
        }
        
        else{
        XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        if (rosterstorage==nil) {
            rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        }
        XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:_displayname.text] dispatchQueue:nil];
        
        [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
        
        [xmppRoom joinRoomUsingNickname:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID] history:nil];
        
        [xmppRoom fetchConfigurationForm];
        
        [xmppRoom addDelegate:[LinphoneAppDelegate sharedAppDelegate] delegateQueue:nil];
        
        NSXMLElement *roomConfigForm = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
        
        NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
        
        [xmppRoom configureRoomUsingOptions:roomConfigForm jid:myJid];
        XMPPJID *xmppJID=[XMPPJID jidWithString:[alertView textFieldAtIndex:0].text];

        [xmppRoom inviteUser:xmppJID  withMessage:@"Come Join me"];
        

      }
    }
    else{
        NSLog(@"Cancal the alert view.");
    }
    
}

- (IBAction)invite:(id)sender {
    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
    if (tRange.location == NSNotFound){
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Invite friend to conference:",nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Join exist conference",nil), NSLocalizedString(@"Create new conference",nil), nil];
        
        
        alert.tag=2;
        [alert show];

       

    }
    else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invite friend",nil)
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Invite exist friend",nil), NSLocalizedString(@"Invite other user",nil), nil];
        
     
        alert.tag=1;
        
        
        
        [alert show];
    
    }
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

//let message in each row can be copy to device pasteboard.
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath

{
    return YES;
}
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender

{
   return (action == @selector(copy:));
    
}
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender

{
        if (action == @selector(copy:)) {
            id messageObject = [messageArray objectAtIndex:indexPath.row];
            
            if ([messageObject isKindOfClass:[MessageEntity class]]) {
                
                MessageEntity *messageEntity = (MessageEntity*)messageObject;
              
                [UIPasteboard generalPasteboard].string = messageEntity.content;
    }
  
}
}





-(void)dismissButtonClick{
    [inputView resignFirstResponder];
}

#pragma mark chat
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if ([anObject isKindOfClass:[MessageEntity class]]&&type==NSFetchedResultsChangeInsert) {
        MessageEntity *messageEntity = (MessageEntity*)anObject;
        NSIndexPath *dateIndexPath = nil;
        
        if (messageArray.count>0) {
            
            MessageEntity *previousEntity = [messageArray objectAtIndex:messageArray.count-1];
            
            NSTimeInterval timeIntervalBetween = [messageEntity.sendDate timeIntervalSinceDate:previousEntity.sendDate];
            
            if (timeIntervalBetween>15*60) {
                [messageArray addObject:messageEntity.sendDate];
                dateIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
            }
        }else {
           
            [messageArray addObject:messageEntity.sendDate];
            dateIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
        }
        [messageArray addObject:anObject];
        
        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
        
        NSMutableArray *indexPathArray = [NSMutableArray array];
        if (dateIndexPath!=nil) {
            [indexPathArray addObject:dateIndexPath];
        }
        [indexPathArray addObject:insertIndexPath];
        [DataTable insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationBottom];
        
        [DataTable scrollToRowAtIndexPath:insertIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }else if (type==NSFetchedResultsChangeUpdate) {
        NSIndexPath *messageIndexPath = [NSIndexPath indexPathForRow:[messageArray indexOfObject:anObject] inSection:0];
        [DataTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:messageIndexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return messageArray.count;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CGFloat rowHeight = 0;
    id messageObject = [messageArray objectAtIndex:indexPath.row];
   
    if ([messageObject isKindOfClass:[MessageEntity class]]) {
        MessageEntity *messageEntity = (MessageEntity*)messageObject;
        NSString *msg = [messageEntity.content stringByAppendingString:@"\n displayname"];
        CGRect contentSize = [msg boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                             context:nil];
        rowHeight = contentSize.size.height+30;
    }else if ([messageObject isKindOfClass:[NSDate class]]) {
        
        rowHeight = 30;
    }
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = nil;
    NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
//if not in conference ,don't hide self message.
    if (tRange.location == NSNotFound){
        id messageObject = [messageArray objectAtIndex:indexPath.row];
        
        if ([messageObject isKindOfClass:[MessageEntity class]]) {
            
            MessageEntity *messageEntity = (MessageEntity*)messageObject;
            
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            
            if ([messageEntity.sender.name isEqualToString:selfUserName]) {
                //sender is self ,insert message in right cell.
                UITableViewCell *rightCell = [DataTable dequeueReusableCellWithIdentifier:@"rightCell"];
                if (rightCell==nil) {
                    
                    rightCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                      reuseIdentifier:@"rightCell"];
                    
                    rightCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGreen"]resizableImageWithCapInsets:UIEdgeInsetsMake(19, 8, 8, 16)];
                    
                    
                    UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    ballonImageView.image = ballonImageRight;
                    ballonImageView.tag = kBallonImageViewTag;
                    [rightCell.contentView addSubview:ballonImageView];
                    
                    UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                    contentLabel.backgroundColor = [UIColor clearColor];
                    contentLabel.font = [UIFont systemFontOfSize:14];
                    contentLabel.numberOfLines = NSIntegerMax;
                    contentLabel.tag = kChatContentLabelTag;
                    [rightCell.contentView addSubview:contentLabel];
                    
                    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    loadingView.tag = kLoadingViewTag;
                    [rightCell.contentView addSubview:loadingView];
                    
                    //send date label
                    UILabel *date =[[UILabel alloc]init];
                    date.tag =sender_date;
                    date.font =[UIFont systemFontOfSize:11];
                    [rightCell.contentView addSubview:date];
                    
                    //send fail image
                    UIImageView *sendfailview = [[UIImageView alloc]initWithFrame:CGRectZero];
                    UIImage *sendfailimage = [UIImage imageNamed:@"list_delete_default"];
                    sendfailview.image = sendfailimage;
                    sendfailview.tag = kSendfailViewTag;
                    [rightCell.contentView addSubview:sendfailview];
                    
                    
                }
                if (IS_IPHONE)
                {
                    UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                    
                    
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                                                             context:nil];
                    
                    CGRect ballonFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                    ballonImageView.frame = ballonFrame;
                    
                    UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                    
                    CGRect contentFrame = CGRectMake(307-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                    contentLabel.frame = contentFrame;
                    contentLabel.text = messageEntity.content;
                    
                    UIImageView *sendfailview = (UIImageView*)[rightCell.contentView viewWithTag:kSendfailViewTag];
                    CGRect sendfailframe = CGRectMake(277-contentSize.size.width, 13, 20, 20);
                    sendfailview.frame = sendfailframe;
                    NSString *lastChar = [contentLabel.text substringFromIndex:[contentLabel.text length] - 1];
                  
                    if([lastChar isEqualToString:@" "]){
                       //send failure red text.
                        contentLabel.textColor =[UIColor redColor];
                       //hide date label when send failure.
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        date.text = @"";
                       //show send failure image.
                        [sendfailview setHidden:NO];
                        
                       
                    }
                    else{
                        [sendfailview setHidden:YES];
                        contentLabel.textColor =[UIColor blackColor];
                        //sender date label
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        [dateFormatter release];
                        
                        date.text = strDate;
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        if(date.text.length>5){
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height-85, 200, 200);
                            date.frame =dataFrame;
                        }
                        else{
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height-85, 200, 200);
                            date.frame =dataFrame;
                        }

                    }
                    UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
                    
                    loadingView.center = CGPointMake(280-contentSize.size.width, 25);
                    
                    if ([messageEntity.flag_sended boolValue]) {
                        
                        [loadingView stopAnimating];
                    }
                    
                    else {
                        
                        [loadingView startAnimating];
                        
                        
                    }
                                   }
                else{
                    UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                    
                    
                    CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                                                             context:nil];
                    
                    CGRect ballonFrame = CGRectMake(750-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                    ballonImageView.frame = ballonFrame;
                    
                    UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                    
                    CGRect contentFrame = CGRectMake(757-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                    contentLabel.frame = contentFrame;
                    contentLabel.text = messageEntity.content;
                    
                    UIImageView *sendfailview = (UIImageView*)[rightCell.contentView viewWithTag:kSendfailViewTag];
                    CGRect sendfailframe = CGRectMake(727-contentSize.size.width, 13, 20, 20);
                    sendfailview.frame = sendfailframe;
                    NSString *lastChar = [contentLabel.text substringFromIndex:[contentLabel.text length] - 1];
                    
                    if([lastChar isEqualToString:@" "]){
                        //send failure red text.
                        contentLabel.textColor =[UIColor redColor];
                        //hide date label when send failure.
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        date.text = @"";
                        //show send failure image.
                        [sendfailview setHidden:NO];
                        
                    }
                    else{
                         [sendfailview setHidden:YES];
                        contentLabel.textColor =[UIColor blackColor];
                        
                        //sender date label
                        UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                        
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"ahh:mm"];
                        [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                        [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                        NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                        
                        [dateFormatter release];
                        
                        date.text = strDate;
                        // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                        if(date.text.length>5){
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height-85, 200, 200);
                            date.frame =dataFrame;
                        }
                        else{
                            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height-85, 200, 200);
                            date.frame =dataFrame;
                        }
                        
                    }
                    UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
                    
                    loadingView.center = CGPointMake(730-contentSize.size.width, 25);
                    
                    if ([messageEntity.flag_sended boolValue]) {
                        
                        [loadingView stopAnimating];
                    }
                    
                    else {
                        
                        [loadingView startAnimating];
                        }
                   
                }
                
                cell = rightCell;
                
            }
            else{
                //left message
                
                UITableViewCell *leftCell = [DataTable dequeueReusableCellWithIdentifier:@"leftCell"];
                if (leftCell==nil) {
                    leftCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"leftCell"];
                    
                    leftCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    //left ballonimage
                    UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGray"]resizableImageWithCapInsets:UIEdgeInsetsMake(19.0f, 16.0f, 8.0f, 8.0f)];
                    UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                    ballonImageView.image = ballonImageRight;
                    ballonImageView.tag = kBallonImageViewTag;
                    [leftCell.contentView addSubview:ballonImageView];
                    //message label
                    UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                    contentLabel.backgroundColor = [UIColor clearColor];
                    contentLabel.font = [UIFont systemFontOfSize:14];
                    contentLabel.numberOfLines = NSIntegerMax;
                    contentLabel.tag = kChatContentLabelTag;
                    [leftCell.contentView addSubview:contentLabel];
                    
                    //sender name label
                    UILabel *name =[[UILabel alloc]init];
                    name.tag = sender_name;
                    name.font = [UIFont systemFontOfSize:11];
                    [leftCell.contentView addSubview:name];
                    
                    //sender photoimage
                    UIImageView *photo = [[UIImageView alloc] init];
                    photo.frame = CGRectMake(3, 0, 35, 35);
                    photo.tag = sender_photo;
                    [leftCell.contentView addSubview:photo];
                    
                    //sender date label
                    UILabel *date =[[UILabel alloc]init];
                    date.tag =sender_date;
                    date.font =[UIFont systemFontOfSize:11];
                    [leftCell.contentView addSubview:date];
                    
                }
                //sender photoimage
                UIImageView * photo =(UIImageView*)[leftCell.contentView viewWithTag:sender_photo];
                CGRect photoFrame= CGRectMake(3, 0, 35, 35);
                photo.frame =photoFrame;
                NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:friendEn.jid];
                if (photoData != nil){
                    
                    photo.image =[UIImage imageWithData:photoData];
                }
                else if(friendEn.photo!= nil){
                    photo.image = friendEn.photo;
                }
                
                else{
                    if([friendEn.displayName isEqualToString:@" System"]){
                        photo.image = [UIImage imageNamed:@"System"];
                    }
                    else{
                        photo.image = [UIImage imageNamed:@"defaultPerson"];
                    }
                }
                
                //left ballonimage
                UIImageView *ballonImageView = (UIImageView*)[leftCell.contentView viewWithTag:kBallonImageViewTag];
                
                CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                      
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      
                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                      
                                                                         context:nil];
                
                
                
                CGRect ballonFrame = CGRectMake(37, 15, contentSize.size.width+20, contentSize.size.height+20);
                
                
                
                ballonImageView.frame = ballonFrame;
                
                
                
                
                
                //message label
                
                UILabel *contentLabel = (UILabel*)[leftCell.contentView viewWithTag:kChatContentLabelTag];
                
                CGRect contentFrame = CGRectMake(50, 17, contentSize.size.width, contentSize.size.height+10);
                
                contentLabel.frame = contentFrame;
                
                contentLabel.text =messageEntity.content;
                
                
                
                //sender name label
                
                UILabel *name = (UILabel*)[leftCell.contentView viewWithTag:sender_name];
                
                CGRect nameFrame = CGRectMake(45, -43, 200, 100);
                
                name.frame = nameFrame;
                
                
                
                NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
                
                if (tRange.location == NSNotFound){
                    
                    
                    
                    name.text =friendEn.displayName;
                    
                }
                
                else{
                    
                    NSRange search = [messageEntity.accessibilityValue rangeOfString:@"/"];
                    
                    
                    
                    NSString *subString = [messageEntity.accessibilityValue substringFromIndex:search.location+1];
                    
                    name.text =subString;
                    
                }
                
                
                
                //sender date label
                
                UILabel *date =(UILabel*)[leftCell.contentView viewWithTag:sender_date];
                
                CGRect dataFrame =CGRectMake(contentSize.size.width+60, contentSize.size.height-77, 200, 200);
                
                date.frame =dataFrame;
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                
                [dateFormatter setDateFormat:@"ahh:mm"];
                
                [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                
                [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                
                NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                
                
                
                [dateFormatter release];
                
                
                
                date.text = strDate;
                
                
                
                cell = leftCell;
                
                
            }
            
        }else if ([messageObject isKindOfClass:[NSDate class]]) {
            if (IS_IPHONE)
            {
                UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
                if (dateCell==nil) {
                    dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:@"dateCell"];
                    dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(80, 5, 160, 20)];
                    dateLabel.backgroundColor = [UIColor clearColor];
                    dateLabel.font = [UIFont systemFontOfSize:14];
                    dateLabel.textColor = [UIColor lightGrayColor];
                    dateLabel.textAlignment = UITextAlignmentCenter;
                    dateLabel.tag = kDateLabelTag;
                    [dateCell.contentView addSubview:dateLabel];
                }
                UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
                NSDate *messageSendDate = (NSDate*)messageObject;
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
                cell = dateCell;
                
            }
            else{
                UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
                if (dateCell==nil) {
                    dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                     reuseIdentifier:@"dateCell"];
                    dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(300, 5, 160, 20)];
                    dateLabel.backgroundColor = [UIColor clearColor];
                    dateLabel.font = [UIFont systemFontOfSize:14];
                    dateLabel.textColor = [UIColor lightGrayColor];
                    dateLabel.textAlignment = UITextAlignmentCenter;
                    dateLabel.tag = kDateLabelTag;
                    [dateCell.contentView addSubview:dateLabel];
                }
                UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
                NSDate *messageSendDate = (NSDate*)messageObject;
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
                dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
                cell = dateCell;
                
            }
        }
        
        if (cell==nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:@"cell"];
        }
        
    }
//if conference,hide self's message.
else{
    id messageObject = [messageArray objectAtIndex:indexPath.row];
    
    if ([messageObject isKindOfClass:[MessageEntity class]]) {
        
        MessageEntity *messageEntity = (MessageEntity*)messageObject;
       
        NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        NSRange search = [messageEntity.accessibilityValue rangeOfString:@"/"];
        
        NSString *subString = [messageEntity.accessibilityValue substringFromIndex:search.location+1];
        if([selfUserName isEqualToString:subString]){
            
            //otis hide double message when groupchat.
        }
        

      
      else if ([messageEntity.sender.name isEqualToString:selfUserName]) {
            //sender is self ,insert message in right cell.
            UITableViewCell *rightCell = [DataTable dequeueReusableCellWithIdentifier:@"rightCell"];
            if (rightCell==nil) {
                
                rightCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:@"rightCell"];
               
                rightCell.selectionStyle = UITableViewCellSelectionStyleNone;
                UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGreen"]resizableImageWithCapInsets:UIEdgeInsetsMake(19, 8, 8, 16)];
               
                
                UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                ballonImageView.image = ballonImageRight;
                ballonImageView.tag = kBallonImageViewTag;
                [rightCell.contentView addSubview:ballonImageView];
               
                UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                contentLabel.backgroundColor = [UIColor clearColor];
                contentLabel.font = [UIFont systemFontOfSize:14];
                contentLabel.numberOfLines = NSIntegerMax;
                contentLabel.tag = kChatContentLabelTag;
                [rightCell.contentView addSubview:contentLabel];
                
                UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                loadingView.tag = kLoadingViewTag;
                [rightCell.contentView addSubview:loadingView];
                
                //send date label
                UILabel *date =[[UILabel alloc]init];
                date.tag =sender_date;
                date.font =[UIFont systemFontOfSize:11];
                [rightCell.contentView addSubview:date];
                
            }
            if (IS_IPHONE)
            {
            UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
      
          
            CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                                   context:nil];
            
            CGRect ballonFrame = CGRectMake(300-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
            ballonImageView.frame = ballonFrame;
            
            UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
            
            CGRect contentFrame = CGRectMake(307-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
            contentLabel.frame = contentFrame;
            contentLabel.text = messageEntity.content;
            UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
            
            loadingView.center = CGPointMake(280-contentSize.size.width, 25);
            
            if ([messageEntity.flag_sended boolValue]) {
                
                [loadingView stopAnimating];
            }
           
            else {
                
                [loadingView startAnimating];
            
             
            }
            //sender date label
            UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
           
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"ahh:mm"];
            [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
            [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
            NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
            
            [dateFormatter release];
            
            date.text = strDate;
            // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
            if(date.text.length>5){
            CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height-85, 200, 200);
            date.frame =dataFrame;
            }
            else{
                CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height-85, 200, 200);
                date.frame =dataFrame;
            }
            }
            else{
                UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
                
                
                CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                                      attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                                                         context:nil];
                
                CGRect ballonFrame = CGRectMake(750-contentSize.size.width, 5, contentSize.size.width+20, contentSize.size.height+20);
                ballonImageView.frame = ballonFrame;
                
                UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
                
                CGRect contentFrame = CGRectMake(757-contentSize.size.width, 7, contentSize.size.width, contentSize.size.height+10);
                contentLabel.frame = contentFrame;
                contentLabel.text = messageEntity.content;
                UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
                
                loadingView.center = CGPointMake(730-contentSize.size.width, 25);
                
                if ([messageEntity.flag_sended boolValue]) {
                    
                    [loadingView stopAnimating];
                }
                
                else {
                    
                    [loadingView startAnimating];
                    
                    
                }
                //sender date label
                UILabel *date =(UILabel*)[rightCell.contentView viewWithTag:sender_date];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"ahh:mm"];
                [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
                [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
                NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
                
                [dateFormatter release];
                
                date.text = strDate;
                // if date.text.length <5 , System use 24 hour clock ,do not show AM.PM.
                if(date.text.length>5){
                    CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-73, contentSize.size.height-85, 200, 200);
                    date.frame =dataFrame;
                }
                else{
                    CGRect dataFrame =CGRectMake([[UIScreen mainScreen]bounds].size.width-contentSize.size.width-51, contentSize.size.height-85, 200, 200);
                    date.frame =dataFrame;
                }
            }
            cell = rightCell;

        }
        else{
            //left message
          
            UITableViewCell *leftCell = [DataTable dequeueReusableCellWithIdentifier:@"leftCell"];
            if (leftCell==nil) {
                leftCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"leftCell"];
         
                leftCell.selectionStyle = UITableViewCellSelectionStyleNone;
               
                //left ballonimage
                UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGray"]resizableImageWithCapInsets:UIEdgeInsetsMake(19.0f, 16.0f, 8.0f, 8.0f)];
                UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                ballonImageView.image = ballonImageRight;
                ballonImageView.tag = kBallonImageViewTag;
                [leftCell.contentView addSubview:ballonImageView];
                //message label
                UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                contentLabel.backgroundColor = [UIColor clearColor];
                contentLabel.font = [UIFont systemFontOfSize:14];
                contentLabel.numberOfLines = NSIntegerMax;
                contentLabel.tag = kChatContentLabelTag;
                [leftCell.contentView addSubview:contentLabel];
                
                //sender name label
                UILabel *name =[[UILabel alloc]init];
                name.tag = sender_name;
                name.font = [UIFont systemFontOfSize:11];
                [leftCell.contentView addSubview:name];
                
                //sender photoimage
              UIImageView *photo = [[UIImageView alloc] init];
              photo.frame = CGRectMake(3, 0, 35, 35);
              photo.tag = sender_photo;
              [leftCell.contentView addSubview:photo];
           
                //sender date label
                UILabel *date =[[UILabel alloc]init];
                date.tag =sender_date;
                date.font =[UIFont systemFontOfSize:11];
                [leftCell.contentView addSubview:date];
                
            }
            //sender photoimage
            UIImageView * photo =(UIImageView*)[leftCell.contentView viewWithTag:sender_photo];
            CGRect photoFrame= CGRectMake(3, 0, 35, 35);
            photo.frame =photoFrame;
            NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:friendEn.jid];
            if (photoData != nil){
                
                photo.image =[UIImage imageWithData:photoData];
            }
            else if(friendEn.photo!= nil){
                 photo.image = friendEn.photo;
             }
            
             else{
                 if([friendEn.displayName isEqualToString:@" System"]){
                 photo.image = [UIImage imageNamed:@"System"];
                 }
                 else{
                 photo.image = [UIImage imageNamed:@"defaultPerson"];
                 }
             }
            
            //left ballonimage
            UIImageView *ballonImageView = (UIImageView*)[leftCell.contentView viewWithTag:kBallonImageViewTag];
            
            CGRect contentSize = [messageEntity.content boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                  
                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  
                                                                  attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                  
                                                                     context:nil];
            
            
            
            CGRect ballonFrame = CGRectMake(37, 15, contentSize.size.width+20, contentSize.size.height+20);
            
            
            
            ballonImageView.frame = ballonFrame;
            
            
            
            
            
            //message label
            
            UILabel *contentLabel = (UILabel*)[leftCell.contentView viewWithTag:kChatContentLabelTag];
            
            CGRect contentFrame = CGRectMake(50, 17, contentSize.size.width, contentSize.size.height+10);
            
            contentLabel.frame = contentFrame;
            
            contentLabel.text =messageEntity.content;
            
            
            
            //sender name label
            
            UILabel *name = (UILabel*)[leftCell.contentView viewWithTag:sender_name];
            
            CGRect nameFrame = CGRectMake(45, -43, 200, 100);
            
            name.frame = nameFrame;
            
            
            
            NSRange tRange = [_displayname.text rangeOfString:@"@conference"];
            
            if (tRange.location == NSNotFound){
                
                
                
                name.text =friendEn.displayName;
                
            }
            
            else{
                
                NSRange search = [messageEntity.accessibilityValue rangeOfString:@"/"];
                
                
                
                NSString *subString = [messageEntity.accessibilityValue substringFromIndex:search.location+1];
                
                name.text =subString;
                
            }
            
            
            
            //sender date label
            
            UILabel *date =(UILabel*)[leftCell.contentView viewWithTag:sender_date];
            
            CGRect dataFrame =CGRectMake(contentSize.size.width+60, contentSize.size.height-77, 200, 200);
            
            date.frame =dataFrame;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            
            [dateFormatter setDateFormat:@"ahh:mm"];
            
            [dateFormatter setAMSymbol:NSLocalizedString(@"AM", nil)];
            
            [dateFormatter setPMSymbol:NSLocalizedString(@"PM", nil)];
            
            NSString *strDate = [dateFormatter stringFromDate:messageEntity.sendDate];
            
            
            
            [dateFormatter release];
            
            
            
            date.text = strDate;
            
            
            
            cell = leftCell;
            
            
        }
        
    }else if ([messageObject isKindOfClass:[NSDate class]]) {
        if (IS_IPHONE)
        {
        UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
        if (dateCell==nil) {
            dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                             reuseIdentifier:@"dateCell"];
            dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(80, 5, 160, 20)];
            dateLabel.backgroundColor = [UIColor clearColor];
            dateLabel.font = [UIFont systemFontOfSize:14];
            dateLabel.textColor = [UIColor lightGrayColor];
            dateLabel.textAlignment = UITextAlignmentCenter;
            dateLabel.tag = kDateLabelTag;
            [dateCell.contentView addSubview:dateLabel];
        }
        UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
        NSDate *messageSendDate = (NSDate*)messageObject;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
        cell = dateCell;
    
        }
        else{
            UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
            if (dateCell==nil) {
                dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:@"dateCell"];
                dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(300, 5, 160, 20)];
                dateLabel.backgroundColor = [UIColor clearColor];
                dateLabel.font = [UIFont systemFontOfSize:14];
                dateLabel.textColor = [UIColor lightGrayColor];
                dateLabel.textAlignment = UITextAlignmentCenter;
                dateLabel.tag = kDateLabelTag;
                [dateCell.contentView addSubview:dateLabel];
            }
            UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
            NSDate *messageSendDate = (NSDate*)messageObject;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
            cell = dateCell;

        }
    }
    
    if (cell==nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:@"cell"];
    }
    }
    return cell;
    
}

@end
