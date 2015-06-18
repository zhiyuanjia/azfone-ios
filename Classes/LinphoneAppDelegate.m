/* LinphoneAppDelegate.m
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
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

#import "PhoneMainView.h"
#import "linphoneAppDelegate.h"
#import "AddressBook/ABPerson.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "ConsoleViewController.h"
#import "LinphoneCoreSettingsStore.h"

#include "LinphoneManager.h"
#include "linphone/linphonecore.h"
#import "RootViewController.h"
#import "SettingViewController.h"

#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPvCardCoreDataStorage.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import <CFNetwork/CFNetwork.h>
#import "ChatController.h"
#import "MessageEntity.h"
#import "ChatViewController.h"
#define TAG_DONATE 2
// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface LinphoneAppDelegate()

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;

@end


@implementation LinphoneAppDelegate

@synthesize configURL;

@synthesize window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;

@synthesize settingViewController;
@synthesize loginButton;
+(LinphoneAppDelegate*)sharedAppDelegate{
    LinphoneAppDelegate *appDelegate = (LinphoneAppDelegate*)[[UIApplication sharedApplication]delegate];
    return appDelegate;
}

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super init];
    if(self != nil) {
        self->startedInBackground = FALSE;
    }
    return self;
}

- (void)dealloc {
	[super dealloc];
    
    [self teardownStream];
}


#pragma mark - 


- (void)applicationDidEnterBackground:(UIApplication *)application{
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
	Linphone_log(@"%@", NSStringFromSelector(_cmd));
	[[LinphoneManager instance] enterBackgroundMode];
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
#if TARGET_IPHONE_SIMULATOR
    DDLogError(@"The iPhone simulator does not process background network traffic. "
               @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif
    
//    if ([application respondsToSelector:@selector(setKeepAliveTimeout:handler:)])
//    {
//        [application setKeepAliveTimeout:600 handler:^{
//            
//            DDLogVerbose(@"KeepAliveHandler");
//            
//            // Do other keep alive stuff here.
//        }];
//    }

}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
[UIApplication sharedApplication].idleTimerDisabled = NO;
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}


- (void)applicationWillResignActive:(UIApplication *)application {
    [self.window.rootViewController dismissViewControllerAnimated:NO completion:nil];
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
	
    if (call){
		/* save call context */
		LinphoneManager* instance = [LinphoneManager instance];
		instance->currentCallContextBeforeGoingBackground.call = call;
		instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);
    
		const LinphoneCallParams* params = linphone_call_get_current_params(call);
		if (linphone_call_params_video_enabled(params)) {
			linphone_call_enable_camera(call, false);
		}
	}
    
    if (![[LinphoneManager instance] resignActive]) {

    }
    
}
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    if (allowSelfSignedCertificates)
    {
        [settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
    }
    
    if (allowSSLHostNameMismatch)
    {
        [settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
    }
    else
    {
        // Google does things incorrectly (does not conform to RFC).
        // Because so many people ask questions about this (assume xmpp framework is broken),
        // I've explicitly added code that shows how other xmpp clients "do the right thing"
        // when connecting to a google server (gmail, or google apps for domains).
        
        NSString *expectedCertName = nil;
        
        NSString *serverDomain = xmppStream.hostName;
        NSString *virtualDomain = [xmppStream.myJID domain];
        
        if ([serverDomain isEqualToString:@"talk.google.com"])
        {
            if ([virtualDomain isEqualToString:@"gmail.com"])
            {
                expectedCertName = virtualDomain;
            }
            else
            {
                expectedCertName = serverDomain;
            }
        }
        else if (serverDomain == nil)
        {
            expectedCertName = virtualDomain;
        }
        else
        {
            expectedCertName = serverDomain;
        }
        
        if (expectedCertName)
        {
            [settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
        }
    }
}



- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    isXmppConnected = YES;
    
    NSError *error = nil;
    
    if (![[self xmppStream] authenticateWithPassword:password error:&error])
    {
        DDLogError(@"Error authenticating: %@", error);
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]disconnect];
    [[[LinphoneAppDelegate sharedAppDelegate]xmppStream]connect:nil];
    
    
}
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
}


- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    _friendlist =[NSMutableArray array];
    _array = [NSMutableArray array];
    _errorarray =[NSMutableArray array];
    
    for (DDXMLElement *element in iq.children) {
        if ([element.name isEqualToString:@"query"]) {
            for (DDXMLElement *item in element.children) {
                if ([item.name isEqualToString:@"item"]) {
                    [_array addObject:item.attributes];
                    [_friendlist addObject:item.attributes];
                
                }
                else if([item.name isEqualToString:@"feature"]){
                    [_friendlist addObject:item.attributes];
                }
                
                
            }
            
            }
      
        }
   
    
     [[NSNotificationCenter defaultCenter] postNotificationName:@"arrayFromSecondVC" object:_array];
      [[NSNotificationCenter defaultCenter] postNotificationName:@"getRosterArray" object:_friendlist];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"errorArray" object:_errorarray];
    return YES;

}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    // A simple example of inbound message handling.
    
    // if ([message isChatMessageWithBody])
   
    NSString *body = [[message elementForName:@"body"] stringValue];

    NSString *displayName = [[message from]bare];
    
    NSString *roomname = [[message attributeForName:@"from"] stringValue];
    
    NSString *type = [[message attributeForName:@"type"] stringValue];


    
        NSLog(@"displayName:%@",displayName);
        if([type isEqualToString:@"normal"]){
            NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
            
        
            NSRange search = [selfUserName rangeOfString:@"@"];
                
            NSString *hostname = [selfUserName substringFromIndex:search.location];

        NSRange search1 = [body rangeOfString:hostname];
            
        NSString *invitername = [body substringWithRange:NSMakeRange(0, search1.location)];
            NSString *title =[invitername stringByAppendingString:NSLocalizedString(@" invite you to:",nil)];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:displayName
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Decline",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Accept",nil), nil];
        
        
        alertView.tag =5;
        [alertView show];
        [alertView release];
    }

     else if (body != NULL) {
//         [[PhoneMainView instance] addInhibitedEvent:kLinphoneTextReceived]; //add notification to uimainbar by otis.
        
            MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                                                         inManagedObjectContext:self.managedObjectContext];
            messageEntity.content = body;
           messageEntity.accessibilityValue =roomname;
            messageEntity.sendDate = [NSDate date];
            PersonEntity *senderUserEntity = [self fetchPerson:displayName];
            messageEntity.sender = senderUserEntity;
            //把这条消息加入到联系人发送的消息中
            messageEntity.flag_readed =[NSNumber numberWithBool:NO];
            [senderUserEntity addSendedMessagesObject:messageEntity];
            messageEntity.receiver = [self fetchPerson:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
            NSLog(@"sender:%@,receiver:%@",messageEntity.sender.name,messageEntity.receiver.name);
            [self saveContext];
            
            
            if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
            {
                
                
                if([[[PhoneMainView instance]currentView].content isEqualToString:@"RootViewController"]||[[[PhoneMainView instance]currentView].content isEqualToString:@"ChatController"]){
                    NSLog(@"Applications are in active state");
                 
                }
                else{
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                    
                }
                
            }
            else
            {
            
                // We are not active, so use a local notification instead
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.alertAction = @"Ok";
                localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@",displayName,body];
                localNotification.soundName =UILocalNotificationDefaultSoundName;
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
            }
        }
                   }


- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
    _errorarray =[NSMutableArray array];
                 

    for (DDXMLElement *element in presence.children) {
    
        if([element.name isEqualToString:@"error"]){
            for(DDXMLElement *item in element.children){
                    [_errorarray addObject:item];
                
            
        }
        
        
        }
    
    }
    [[NSNotificationCenter defaultCenter]postNotificationName:@"errorArray" object:_errorarray];
    
}
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}



- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
      if (!isXmppConnected)
    {
        DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
        
    }
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
                                                             xmppStream:xmppStream
                                                   managedObjectContext:[self managedObjectContext_roster]];
 
  
    NSString *displayName = [user displayName];
    NSString *jidStrBare = [presence fromStr];
    NSString *body = nil;
    
    if (![displayName isEqualToString:jidStrBare])
    {
        if(displayName ==nil){
            displayName = NSLocalizedString(@"Unknown user",nil);
        }
        body = [NSString stringWithFormat:@"%@ <%@>", displayName, jidStrBare];
    }
    else
    {
        body = [NSString stringWithFormat:@"%@", displayName];
    }
    
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
      
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Friend Request",nil)
                                                            message:body
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Decline",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Accept",nil), nil];
        
        alertView.tag =TAG_DONATE;
        [alertView show];
        [alertView release];
    } 
    else 
    {
        // We are not active, so use a local notification instead
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = @"Not implemented";
        localNotification.alertBody = body;
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));

    if( startedInBackground ){
        startedInBackground = FALSE;
        [[PhoneMainView instance] startUp];
        [[PhoneMainView instance] updateStatusBar:nil];
    }
    LinphoneManager* instance = [LinphoneManager instance];
    
    [instance becomeActive];
    
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneCall* call = linphone_core_get_current_call(lc);
    
    if (call){
        if (call == instance->currentCallContextBeforeGoingBackground.call) {
            const LinphoneCallParams* params = linphone_call_get_current_params(call);
            if (linphone_call_params_video_enabled(params)) {
                linphone_call_enable_camera(
                                            call,
                                            instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
            }
            instance->currentCallContextBeforeGoingBackground.call = 0;
        } else if ( linphone_call_get_state(call) == LinphoneCallIncomingReceived ) {
            [[PhoneMainView  instance ] displayIncomingCall:call];
            // in this case, the ringing sound comes from the notification.
            // To stop it we have to do the iOS7 ring fix...
            [self fixRing];
        }
    }
}

- (UIUserNotificationCategory*)getMessageNotificationCategory {
    
    UIMutableUserNotificationAction* reply = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    reply.identifier = @"reply";
    reply.title = NSLocalizedString(@"Reply", nil);
    reply.activationMode = UIUserNotificationActivationModeForeground;
    reply.destructive = NO;
    reply.authenticationRequired = YES;
    
    UIMutableUserNotificationAction* mark_read = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    mark_read.identifier = @"mark_read";
    mark_read.title = NSLocalizedString(@"Mark Read", nil);
    mark_read.activationMode = UIUserNotificationActivationModeBackground;
    mark_read.destructive = NO;
    mark_read.authenticationRequired = NO;
    
    NSArray* localRingActions = @[mark_read, reply];
    
    UIMutableUserNotificationCategory* localRingNotifAction = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
    localRingNotifAction.identifier = @"incoming_msg";
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

    return localRingNotifAction;
}

- (UIUserNotificationCategory*)getCallNotificationCategory {
    UIMutableUserNotificationAction* answer = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    answer.identifier = @"answer";
    answer.title = NSLocalizedString(@"Answer", nil);
    answer.activationMode = UIUserNotificationActivationModeForeground;
    answer.destructive = NO;
    answer.authenticationRequired = YES;
    
    UIMutableUserNotificationAction* decline = [[[UIMutableUserNotificationAction alloc] init] autorelease];
    decline.identifier = @"decline";
    decline.title = NSLocalizedString(@"Decline", nil);
    decline.activationMode = UIUserNotificationActivationModeBackground;
    decline.destructive = YES;
    decline.authenticationRequired = NO;
    
    
    NSArray* localRingActions = @[decline, answer];
    
    UIMutableUserNotificationCategory* localRingNotifAction = [[[UIMutableUserNotificationCategory alloc] init] autorelease];
    localRingNotifAction.identifier = @"incoming_call";
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
    [localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

    return localRingNotifAction;
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
   [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Setup the XMPP stream
    NSString *documentPath = [self applicationDocumentsFileDirectory];
    NSLog(@"documentPath:%@",documentPath);
    
    NSURL *storeURL = nil;
    NSString* fileName = [NSString stringWithFormat:@"test.ovpn"];
    NSString *currentFilePath = [documentPath stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager]fileExistsAtPath:currentFilePath]) {
        NSLog(@"test.ovpn is exist");
        NSLog(@"%@",currentFilePath);
    }
    else{
        NSString *resourceFilePath = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"test"]
                                                                    ofType:@"ovpn"];
        [[NSFileManager defaultManager]copyItemAtPath:resourceFilePath toPath:currentFilePath error:NULL];
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:fileName];
      
    }

    [self setupStream];
  
 
    NSString *myJID = [[LinphoneManager instance] lpConfigStringForKey:@"xmppid_preference"];
    NSString *myPassword = [[LinphoneManager instance] lpConfigStringForKey:@"xmpppsw_preference"];
    [[NSUserDefaults standardUserDefaults]setObject:myJID forKey:kXMPPmyJID];
    [[NSUserDefaults standardUserDefaults]setObject:myPassword forKey:kXMPPmyPassword];
    [[NSUserDefaults standardUserDefaults]synchronize];
    if (![self connect])
    {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            NSLog(@"did not connect xmpp");
            
            
        });
    }
   
 
    UIApplication* app= [UIApplication sharedApplication];
    UIApplicationState state = app.applicationState;
    
    if( [app respondsToSelector:@selector(registerUserNotificationSettings:)] ){
        /* iOS8 notifications can be actioned! Awesome: */
        UIUserNotificationType notifTypes = UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert;
       
        NSSet* categories = [NSSet setWithObjects:[self getCallNotificationCategory], [self getMessageNotificationCategory], nil];
        UIUserNotificationSettings* userSettings = [UIUserNotificationSettings settingsForTypes:notifTypes categories:categories];
        [app registerUserNotificationSettings:userSettings];
        [app registerForRemoteNotifications];
    } else {
        NSUInteger notifTypes = UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeNewsstandContentAvailability;
        [app registerForRemoteNotificationTypes:notifTypes];
    }

	LinphoneManager* instance = [LinphoneManager instance];
    BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
    BOOL start_at_boot   = [instance lpConfigBoolForKey:@"start_at_boot_preference"];
    



    if (state == UIApplicationStateBackground)
    {
        // we've been woken up directly to background;
        if( !start_at_boot || !background_mode ) {
            // autoboot disabled or no background, and no push: do nothing and wait for a real launch
			/*output a log with NSLog, because the ortp logging system isn't activated yet at this time*/
			NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated.", NULL);
            return YES;
        }

    }
	bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		[LinphoneLogger log:LinphoneLoggerWarning format:@"Background task for application launching expired."];
		[[UIApplication sharedApplication] endBackgroundTask:bgStartId];
	}];

    [[LinphoneManager instance]	startLibLinphone];
    // initialize UI
    [self.window makeKeyAndVisible];
    [RootViewManager setupWithPortrait:(PhoneMainView*)self.window.rootViewController];
    [[PhoneMainView instance] startUp];
    [[PhoneMainView instance] updateStatusBar:nil];



	NSDictionary *remoteNotif =[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif){
		[LinphoneLogger log:LinphoneLoggerLog format:@"PushNotification from launch received."];
		[self processRemoteNotification:remoteNotif];
	}
    if (bgStartId!=UIBackgroundTaskInvalid) [[UIApplication sharedApplication] endBackgroundTask:bgStartId];

    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    [self saveContext];
}
- (void)saveContext
{
    NSError *error = nil;
    BOOL isSaveSuccess = [[self managedObjectContext] save:&error];
    if (!isSaveSuccess) {
        NSLog(@"save message fail: %@,%@",error,[error userInfo]);
    }else {
        NSLog(@"save message success");
    }
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ChatDataModel" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

- (NSString *)applicationDocumentsFileDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        
        return __persistentStoreCoordinator;
    }
    
    NSString *documentPath = [self applicationDocumentsFileDirectory];
    NSLog(@"documentPath:%@",documentPath);
    NSString *version = @"2";
    NSURL *storeURL = nil;
    NSString *currentFileName = [NSString stringWithFormat:@"ChatDemo%@.sqlite",version];
    NSString *currentFilePath = [documentPath stringByAppendingPathComponent:currentFileName];
    if ([[NSFileManager defaultManager]fileExistsAtPath:currentFilePath]) {
        
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ChatDemo.sqlite"];
    }else {
        //因为用户安装了老的版本，其中sqlite文件和最新版本不一致，从资源目录把最新的sqlite文件拷贝到document里面
        //一定要拷贝到document目录下面，因为resouce目录是只读的
        //会丢失用户在老版本中所有的数据
        //可以运行一段sql脚本，把数据从老的sqlite文件中迁移到新的sqlite
        NSString *resourceFilePath = [[NSBundle mainBundle]pathForResource:[NSString stringWithFormat:@"ChatDemo%@",version]
                                                                    ofType:@"sqlite"];
        [[NSFileManager defaultManager]copyItemAtPath:resourceFilePath toPath:currentFilePath error:NULL];
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:currentFileName];
    }
       NSLog(@"ssspath:%@",[[NSBundle mainBundle]resourcePath]);
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return __persistentStoreCoordinator;
}
- (NSURL *)applicationDocumentsDirectory
{
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
#pragma mark XMPP
-(PersonEntity*)fetchPerson:(NSString*)userName{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@",userName];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonEntity"];
    [fetchRequest setPredicate:predicate];
    LinphoneAppDelegate *appDelegate = [LinphoneAppDelegate sharedAppDelegate];
    NSArray *fetchedPersonArray = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    PersonEntity *fetchedPerson = nil;
    if (fetchedPersonArray.count>0) {
        fetchedPerson = [fetchedPersonArray objectAtIndex:0];
    }else {
        fetchedPerson = [NSEntityDescription insertNewObjectForEntityForName:@"PersonEntity"
                                                      inManagedObjectContext:appDelegate.managedObjectContext];
        fetchedPerson.name = userName;
        [appDelegate saveContext];
    }
    return fetchedPerson;
}


#pragma mark Core Data
- (NSManagedObjectContext *)managedObjectContext_roster
{
    return [xmppRosterStorage mainThreadManagedObjectContext];
    
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
    return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

- (void)setupStream
{
    NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
    
    // Setup xmpp stream
    //
    // The XMPPStream is the base class for all activity.
    // Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
    xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
    {
        // Want xmpp to run in the background?
        //
        // P.S. - The simulator doesn't support backgrounding yet.
        //        When you try to set the associated property on the simulator, it simply fails.
        //        And when you background an app on the simulator,
        //        it just queues network traffic til the app is foregrounded again.
        //        We are patiently waiting for a fix from Apple.
        //        If you do enableBackgroundingOnSocket on the simulator,
        //        you will simply see an error message from the xmpp stack when it fails to set the property.
        
        xmppStream.enableBackgroundingOnSocket = YES;
    }
#endif
    
    // Setup reconnect
    //
    // The XMPPReconnect module monitors for "accidental disconnections" and
    // automatically reconnects the stream for you.
    // There's a bunch more information in the XMPPReconnect header file.
    
    xmppReconnect = [[XMPPReconnect alloc] init];
    [xmppReconnect activate:xmppStream];
    [xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // Setup roster
    //
    // The XMPPRoster handles the xmpp protocol stuff related to the roster.
    // The storage for the roster is abstracted.
    // So you can use any storage mechanism you want.
    // You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
    // or setup your own using raw SQLite, or create your own storage mechanism.
    // You can do it however you like! It's your application.
    // But you do need to provide the roster with some storage facility.
   
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
    
    xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
    
    xmppRoster.autoFetchRoster = YES;
    xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    // Setup vCard support
    //
    // The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
    // The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
    
    xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
    
    xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
    
    // Setup capabilities
    //
    // The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
    // Basically, when other clients broadcast their presence on the network
    // they include information about what capabilities their client supports (audio, video, file transfer, etc).
    // But as you can imagine, this list starts to get pretty big.
    // This is where the hashing stuff comes into play.
    // Most people running the same version of the same client are going to have the same list of capabilities.
    // So the protocol defines a standardized way to hash the list of capabilities.
    // Clients then broadcast the tiny hash instead of the big list.
    // The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
    // and also persistently storing the hashes so lookups aren't needed in the future.
    //
    // Similarly to the roster, the storage of the module is abstracted.
    // You are strongly encouraged to persist caps information across sessions.
    //
    // The XMPPCapabilitiesCoreDataStorage is an ideal solution.
    // It can also be shared amongst multiple streams to further reduce hash lookups.
    
    xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
    
    xmppCapabilities.autoFetchHashedCapabilities = YES;
    xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    // Activate xmpp modules
    
    [xmppReconnect         activate:xmppStream];
    [xmppRoster            activate:xmppStream];
    [xmppvCardTempModule   activate:xmppStream];
    [xmppvCardAvatarModule activate:xmppStream];
    [xmppCapabilities      activate:xmppStream];
    
    // Add ourself as a delegate to anything we may be interested in
    
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // Optional:
    //
    // Replace me with the proper domain and port.
    // The example below is setup for a typical google talk account.
    //
    // If you don't supply a hostName, then it will be automatically resolved using the JID (below).
    // For example, if you supply a JID like 'user@quack.com/rsrc'
    // then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
    //
    // If you don't specify a hostPort, then the default (5222) will be used.
    
    NSString *xmppdomain = [[LinphoneManager instance] lpConfigStringForKey:@"xmppdomain_preference"];
    [xmppStream setHostName:xmppdomain];
    [xmppStream setHostPort:5222];
    
    
    // You may need to alter these settings depending on the server you're connecting to
    allowSelfSignedCertificates = NO;
    allowSSLHostNameMismatch = NO;
}

- (void)teardownStream
{
    [xmppStream removeDelegate:self];
    [xmppRoster removeDelegate:self];
    
    [xmppReconnect         deactivate];
    [xmppRoster            deactivate];
    [xmppvCardTempModule   deactivate];
    [xmppvCardAvatarModule deactivate];
    [xmppCapabilities      deactivate];
    
    [xmppStream disconnect];
    
    xmppStream = nil;
    xmppReconnect = nil;
    xmppRoster = nil;
    xmppRosterStorage = nil;
    xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
    xmppvCardAvatarModule = nil;
    xmppCapabilities = nil;
    xmppCapabilitiesStorage = nil;
    
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

- (void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
    
    [[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    
    [[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect
{
    if (![xmppStream isDisconnected]) {
        return YES;
    }
    

    
    NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];

    //
    // If you don't want to use the Settings view to set the JID,
    // uncomment the section below to hard code a JID and password.
    //
    // myJID = @"user@gmail.com/xmppframework";
    // myPassword = @"";
    
    if (myJID == nil || myPassword == nil) {
        return NO;
    }
    
    [xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    password = myPassword;
    
    NSError *error = nil;
    if (![xmppStream connect:&error])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
                                                            message:@"See console for error details." 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"Ok" 
                                                  otherButtonTitles:nil];
        [alertView show];
        
        DDLogError(@"Error connecting: %@", error);
        
        return NO;
    }
    
    return YES;
}

- (void)disconnect
{
    [self goOffline];
    [xmppStream disconnect];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *scheme = [[url scheme] lowercaseString];
    if ([scheme isEqualToString:@"linphone-config-http"] || [scheme isEqualToString:@"linphone-config-https"]) {
        configURL = [[NSString alloc] initWithString:[[url absoluteString] stringByReplacingOccurrencesOfString:@"linphone-config-" withString:@""]];
        UIAlertView* confirmation = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remote configuration",nil)
                                                        message:NSLocalizedString(@"This operation will load a remote configuration. Continue ?",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"No",nil)
                                              otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        confirmation.tag = 1;
        [confirmation show];
        [confirmation release];
    } else {
        if([[url scheme] isEqualToString:@"sip"]) {
            // Go to Dialer view
            DialerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]], DialerViewController);
            if(controller != nil) {
                [controller setAddress:[url absoluteString]];
            }
        }
    }
	return YES;
}

- (void)fixRing{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        // iOS7 fix for notification sound not stopping.
        // see http://stackoverflow.com/questions/19124882/stopping-ios-7-remote-notification-sound
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    }
}

- (void)processRemoteNotification:(NSDictionary*)userInfo{
	if ([LinphoneManager instance].pushNotificationToken==Nil){
		[LinphoneLogger log:LinphoneLoggerLog format:@"Ignoring push notification we did not subscribed."];
		return;
	}
	
	NSDictionary *aps = [userInfo objectForKey:@"aps"];
	
    if(aps != nil) {
        NSDictionary *alert = [aps objectForKey:@"alert"];
        if(alert != nil) {
            NSString *loc_key = [alert objectForKey:@"loc-key"];
			/*if we receive a remote notification, it is probably because our TCP background socket was no more working.
			 As a result, break it and refresh registers in order to make sure to receive incoming INVITE or MESSAGE*/
			LinphoneCore *lc = [LinphoneManager getLc];
			if (linphone_core_get_calls(lc)==NULL){ //if there are calls, obviously our TCP socket shall be working
				linphone_core_set_network_reachable(lc, FALSE);
				[LinphoneManager instance].connectivity=none; /*force connectivity to be discovered again*/
                [[LinphoneManager instance] refreshRegisters];
				if(loc_key != nil) {
					if([loc_key isEqualToString:@"IM_MSG"]) {
						[[PhoneMainView instance] addInhibitedEvent:kLinphoneTextReceived];
						[[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
					} else if([loc_key isEqualToString:@"IC_MSG"]) {
						//it's a call
						NSString *callid=[userInfo objectForKey:@"call-id"];
						if (callid)
							[[LinphoneManager instance] enableAutoAnswerForCallId:callid];
						else
							[LinphoneLogger log:LinphoneLoggerError format:@"PushNotification: does not have call-id yet, fix it !"];

						[self fixRing];
					}
				}
			}
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);

	[self processRemoteNotification:userInfo];
}

- (LinphoneChatRoom*)findChatRoomForContact:(NSString*)contact {
    MSList* rooms = linphone_core_get_chat_rooms([LinphoneManager getLc]);
    const char* from = [contact UTF8String];
    while (rooms) {
        const LinphoneAddress* room_from_address = linphone_chat_room_get_peer_address((LinphoneChatRoom*)rooms->data);
        char* room_from = linphone_address_as_string_uri_only(room_from_address);
        if( room_from && strcmp(from, room_from)== 0){
            return rooms->data;
        }
        rooms = rooms->next;
    }
    return NULL;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    Linphone_log(@"%@ - state = %d", NSStringFromSelector(_cmd), application.applicationState);

    [self fixRing];

    if([notification.userInfo objectForKey:@"callId"] != nil) {
        BOOL auto_answer = TRUE;

        // some local notifications have an internal timer to relaunch themselves at specified intervals
        if( [[notification.userInfo objectForKey:@"timer"] intValue] == 1 ){
            [[LinphoneManager instance] cancelLocalNotifTimerForCallId:[notification.userInfo objectForKey:@"callId"]];
            auto_answer = [[LinphoneManager instance] lpConfigBoolForKey:@"autoanswer_notif_preference"];
        }
        if(auto_answer)
        {
            [[LinphoneManager instance] acceptCallForCallId:[notification.userInfo objectForKey:@"callId"]];
        }
    } else if([notification.userInfo objectForKey:@"from"] != nil) {
        NSString *remoteContact = (NSString*)[notification.userInfo objectForKey:@"from"];
        // Go to ChatRoom view
        [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
        ChatRoomViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE], ChatRoomViewController);
        if(controller != nil) {
            LinphoneChatRoom*room = [self findChatRoomForContact:remoteContact];
            [controller setChatRoom:room];
        }
    } else if([notification.userInfo objectForKey:@"callLog"] != nil) {
        NSString *callLog = (NSString*)[notification.userInfo objectForKey:@"callLog"];
        // Go to HistoryDetails view
        [[PhoneMainView instance] changeCurrentView:[HistoryViewController compositeViewDescription]];
        HistoryDetailsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[HistoryDetailsViewController compositeViewDescription] push:TRUE], HistoryDetailsViewController);
        if(controller != nil) {
            [controller setCallLogId:callLog];
        }
    }
}

// this method is implemented for iOS7. It is invoked when receiving a push notification for a call and it has "content-available" in the aps section.
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);
    LinphoneManager* lm = [LinphoneManager instance];
	
	if (lm.pushNotificationToken==Nil){
		[LinphoneLogger log:LinphoneLoggerLog format:@"Ignoring push notification we did not subscribed."];
		return;
	}

    // save the completion handler for later execution.
    // 2 outcomes:
    // - if a new call/message is received, the completion handler will be called with "NEWDATA"
    // - if nothing happens for 15 seconds, the completion handler will be called with "NODATA"
    lm.silentPushCompletion = completionHandler;
    [NSTimer scheduledTimerWithTimeInterval:15.0 target:lm selector:@selector(silentPushFailed:) userInfo:nil repeats:FALSE];

	LinphoneCore *lc=[LinphoneManager getLc];
	// If no call is yet received at this time, then force Linphone to drop the current socket and make new one to register, so that we get
	// a better chance to receive the INVITE.
	if (linphone_core_get_calls(lc)==NULL){
		linphone_core_set_network_reachable(lc, FALSE);
		lm.connectivity=none; /*force connectivity to be discovered again*/
		[lm refreshRegisters];
	}
}


#pragma mark - PushNotification Functions
/* ----- disabled by khc; we do not need Apple Push Notification
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), deviceToken);
    [[LinphoneManager instance] setPushNotificationToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    Linphone_log(@"%@ : %@", NSStringFromSelector(_cmd), [error localizedDescription]);
    [[LinphoneManager instance] setPushNotificationToken:nil];
}
*/
#pragma mark - User notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    if( [[UIDevice currentDevice].systemVersion floatValue] >= 8){

        LinphoneCore* lc = [LinphoneManager getLc];
        [LinphoneLogger log:LinphoneLoggerLog format:@"%@", NSStringFromSelector(_cmd)];
        if( [notification.category isEqualToString:@"incoming_call"]) {
            if( [identifier isEqualToString:@"answer"] ){
                // use the standard handler
                [self application:application didReceiveLocalNotification:notification];
            } else if( [identifier isEqualToString:@"decline"] ){
                LinphoneCall* call = linphone_core_get_current_call(lc);
                if( call ) linphone_core_decline_call(lc, call, LinphoneReasonDeclined);
            }
        } else if( [notification.category isEqualToString:@"incoming_msg"] ){
            if( [identifier isEqualToString:@"reply"] ){
                // use the standard handler
                [self application:application didReceiveLocalNotification:notification];
            } else if( [identifier isEqualToString:@"mark_read"] ){
                NSString* from = [notification.userInfo objectForKey:@"from"];
                LinphoneChatRoom* room = linphone_core_get_or_create_chat_room(lc, [from UTF8String]);
                if( room ){
                    linphone_chat_room_mark_as_read(room);
                    [[PhoneMainView instance] updateApplicationBadgeNumber];
                }
            }
        }
    }
    completionHandler();
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    Linphone_log(@"%@", NSStringFromSelector(_cmd));
    completionHandler();
}

#pragma mark - Remote configuration Functions (URL Handler)


- (void)ConfigurationStateUpdateEvent: (NSNotification*) notif {
    LinphoneConfiguringState state = [[notif.userInfo objectForKey: @"state"] intValue];
       if (state == LinphoneConfiguringSuccessful) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneConfiguringStateUpdate
                                                  object:nil];
        [_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];

        UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success",nil)
                                                        message:NSLocalizedString(@"Remote configuration successfully fetched and applied.",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [error show];
        [error release];
        [[PhoneMainView instance] startUp];
    }
    if (state == LinphoneConfiguringFailed) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneConfiguringStateUpdate
                                                  object:nil];
        [_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure",nil)
                                                        message:NSLocalizedString(@"Failed configuring from the specified URL." ,nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        [error show];
        [error release];
        
    }
}


- (void) showWaitingIndicator {
    _waitingIndicator = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fetching remote configuration...",nil) message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView *progress= [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 60, 30, 30)];
    progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0){
        [_waitingIndicator setValue:progress forKey:@"accessoryView"];
        [progress setColor:[UIColor blackColor]];
    } else {
        [_waitingIndicator addSubview:progress];
    }
    [progress startAnimating];
    [progress release];
    [_waitingIndicator show];

}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((alertView.tag == 1) && (buttonIndex==1))  {
        [self showWaitingIndicator];
        [self attemptRemoteConfiguration];
    }
    else if ((alertView.tag == TAG_DONATE)&&(buttonIndex==1)){
       
        NSString* str1 = alertView.message;
        
        NSRange search = [str1 rangeOfString:@"<"];
        
        NSString *subString = [str1 substringFromIndex:search.location+1];
        NSRange search2 = [subString rangeOfString:@">"];
        
        NSString *str3 = [[subString substringToIndex:search2.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(@"xmppjid:%@",str3);
        XMPPJID *jid = [XMPPJID jidWithString:str3];
        [xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:str3 message:NSLocalizedString(@"Set nickname",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil)otherButtonTitles:NSLocalizedString(@"confirm",nil), nil];
        
        
        
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        
        
        alert.tag = 3;
        
        [alert show];
    }
    else if(alertView.tag ==3 &&(buttonIndex==1)){
        
        NSString *jidstr = alertView.title;
        XMPPJID *jid = [XMPPJID jidWithString:jidstr];
        NSString *nickname = [alertView textFieldAtIndex:0].text;
        if([[alertView textFieldAtIndex:0].text isEqualToString:@" System"]){
            [xmppRoster setNickname:jidstr forUser:jid];
        }
        else{
            [xmppRoster setNickname:nickname forUser:jid];
        }
    }
    else if ((alertView.tag == TAG_DONATE)&&(buttonIndex !=1)){
            NSLog(@"hello");
       
        NSString* str1 = alertView.message;
        
        NSRange search = [str1 rangeOfString:@"<"];
        
        NSString *subString = [str1 substringFromIndex:search.location+1];
        NSRange search2 = [subString rangeOfString:@">"];
        
        NSString *str3 = [[subString substringToIndex:search2.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSLog(@"xmppjid:%@",str3);
        XMPPJID *jid = [XMPPJID jidWithString:str3];
        [[[LinphoneAppDelegate sharedAppDelegate] xmppRoster] removeUser:jid];
      
       }
    else if((alertView.tag ==5)&&(buttonIndex ==1)){
         NSString *roomid = alertView.message;
        NSString *nickname = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
        XMPPRoomCoreDataStorage *rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        if (rosterstorage==nil) {
            NSLog(@"nil");
            rosterstorage = [[XMPPRoomCoreDataStorage alloc] init];
        }
        XMPPRoom *xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:rosterstorage jid:[XMPPJID jidWithString:roomid] dispatchQueue:dispatch_get_main_queue()];
        
        [xmppRoom activate:[[LinphoneAppDelegate sharedAppDelegate] xmppStream]];
        [xmppRoom joinRoomUsingNickname:nickname history:nil];
            
       
        [xmppRoom fetchConfigurationForm];
        [xmppRoom addDelegate:[LinphoneAppDelegate sharedAppDelegate] delegateQueue:dispatch_get_main_queue()];
        NSXMLElement *roomConfigForm = [NSXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
        NSString *myJid = [NSString stringWithFormat:@"%@",[[[LinphoneAppDelegate sharedAppDelegate]xmppStream]myJID]];
        [xmppRoom configureRoomUsingOptions:roomConfigForm jid:myJid];
        
        [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];

    }
  
  
}

- (void)attemptRemoteConfiguration {

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ConfigurationStateUpdateEvent:)
                                                 name:kLinphoneConfiguringStateUpdate
                                               object:nil];
    linphone_core_set_provisioning_uri([LinphoneManager getLc] , [configURL UTF8String]);
    [[LinphoneManager instance] destroyLibLinphone];
    [[LinphoneManager instance] startLibLinphone];

}


@end
