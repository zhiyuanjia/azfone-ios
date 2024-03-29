/* SettingsViewController.m
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

#import "SettingsViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
#import "UACellBackgroundView.h"
#import "LinphoneAppDelegate.h"
#import "DCRoundSwitch.h"
#import "keyViewController.h"

#import "ViewController.h"
#import "IASKSpecifierValuesViewController.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "IASKPSTitleValueSpecifierViewCell.h"
#import "IASKSpecifier.h"
#import "IASKTextField.h"
#include "linphone/lpconfig.h"
#define TAG_DEV 1
#define TAG_DONATE 2
#ifdef DEBUG
@interface UIDevice (debug)

- (void)_setBatteryLevel:(float)level;
- (void)_setBatteryState:(int)state;

@end
#endif

@interface SettingsViewController (private)

+ (IASKSpecifier*)filterSpecifier:(IASKSpecifier *)specifier;

@end


#pragma mark - IASKSwitchEx Class

@interface IASKSwitchEx : DCRoundSwitch {
    NSString *_key;
}

@property (nonatomic, retain) NSString *key;

@end

@implementation IASKSwitchEx

@synthesize key=_key;

- (void)dealloc {
    [_key release], _key = nil;
    
    [super dealloc];
}

@end


#pragma mark - IASKSpecifierValuesViewControllerEx Class

// Patch IASKSpecifierValuesViewController
@interface IASKSpecifierValuesViewControllerEx: IASKSpecifierValuesViewController<UIAlertViewDelegate>

@end

@implementation IASKSpecifierValuesViewControllerEx

- (void)initIASKSpecifierValuesViewControllerEx {
    [self.view setBackgroundColor:[UIColor clearColor]];
}

- (id)init {
    self = [super init];
    if(self != nil) {
        [self initIASKSpecifierValuesViewControllerEx];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self != nil) {
        [self initIASKSpecifierValuesViewControllerEx];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self != nil) {
        [self initIASKSpecifierValuesViewControllerEx];
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Background View
    UACellBackgroundView *selectedBackgroundView = [[[UACellBackgroundView alloc] initWithFrame:CGRectZero] autorelease];
    cell.selectedBackgroundView = selectedBackgroundView;
    [selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
    return cell;
}

@end


#pragma mark - IASKAppSettingsViewControllerEx Class

@interface IASKAppSettingsViewController(PrivateInterface)
- (UITableViewCell*)newCellForIdentifier:(NSString*)identifier;
@end;

@interface IASKAppSettingsViewControllerEx : IASKAppSettingsViewController

@end

@implementation IASKAppSettingsViewControllerEx

- (UITableViewCell*)newCellForIdentifier:(NSString*)identifier {
    UITableViewCell *cell = nil;
    if ([identifier isEqualToString:kIASKPSToggleSwitchSpecifier]) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kIASKPSToggleSwitchSpecifier];
        cell.accessoryView = [[[IASKSwitchEx alloc] initWithFrame:CGRectMake(0, 0, 79, 27)] autorelease];
        [((IASKSwitchEx*)cell.accessoryView) addTarget:self action:@selector(toggledValue:) forControlEvents:UIControlEventValueChanged];
        [((IASKSwitchEx*)cell.accessoryView) setOnTintColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.minimumScaleFactor = kIASKMinimumFontSize/[UIFont systemFontSize];
        cell.detailTextLabel.minimumScaleFactor = kIASKMinimumFontSize/[UIFont systemFontSize];
    } else {
        cell = [super newCellForIdentifier:identifier];
    }
    return cell;
}

- (void)toggledValue:(id)sender {
    IASKSwitchEx *toggle    = [[(IASKSwitchEx*)sender retain] autorelease];
    IASKSpecifier *spec   = [_settingsReader specifierForKey:[toggle key]];
    
    if ([toggle isOn]) {
        if ([spec trueValue] != nil) {
            [self.settingsStore setObject:[spec trueValue] forKey:[toggle key]];
        }
        else {
            [self.settingsStore setBool:YES forKey:[toggle key]];
        }
    }
    else {
        if ([spec falseValue] != nil) {
            [self.settingsStore setObject:[spec falseValue] forKey:[toggle key]];
        }
        else {
            [self.settingsStore setBool:NO forKey:[toggle key]];
        }
    }
    // Start notification after animation of DCRoundSwitch
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged
                                                            object:[toggle key]
                                                          userInfo:[NSDictionary dictionaryWithObject:[self.settingsStore objectForKey:[toggle key]]
                                                                                               forKey:[toggle key]]];
    });
}

- (void)initIASKAppSettingsViewControllerEx {
    [self.view setBackgroundColor:[UIColor clearColor]];
    
    // Force kIASKSpecifierValuesViewControllerIndex
    static int kIASKSpecifierValuesViewControllerIndex = 0;
    _viewList = [[NSMutableArray alloc] init];
    [_viewList addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"IASKSpecifierValuesView", @"ViewName",nil]];
    [_viewList addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"IASKAppSettingsView", @"ViewName",nil]];
    
    NSMutableDictionary *newItemDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [newItemDict addEntriesFromDictionary: [_viewList objectAtIndex:kIASKSpecifierValuesViewControllerIndex]];	// copy the title and explain strings
    
    IASKSpecifierValuesViewController *targetViewController = [[IASKSpecifierValuesViewControllerEx alloc] init];
    // add the new view controller to the dictionary and then to the 'viewList' array
    [newItemDict setObject:targetViewController forKey:@"viewController"];
    [_viewList replaceObjectAtIndex:kIASKSpecifierValuesViewControllerIndex withObject:newItemDict];
    [targetViewController release];
}

- (IASKSettingsReader*)settingsReader {
    IASKSettingsReader *r = [super settingsReader];
    NSMutableArray *dataSource = [NSMutableArray arrayWithArray:[r dataSource]];
    for (int i = 0; i < [dataSource count]; ++i) {
        NSMutableArray *specifiers = [NSMutableArray arrayWithArray:[dataSource objectAtIndex:i]];
        for (int j = 0; j < [specifiers count]; ++j) {
            id sp = [specifiers objectAtIndex:j];
            if ([sp isKindOfClass:[IASKSpecifier class]]) {
                sp = [SettingsViewController filterSpecifier:sp];
            }
            [specifiers replaceObjectAtIndex:j withObject:sp];
        }
        
        [dataSource replaceObjectAtIndex:i withObject:specifiers];
    }
    [r setDataSource:dataSource];
    return r;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
    [self.tableView setBackgroundView:nil]; // Can't do it in Xib: issue with ios4
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if(self != nil) {
        [self initIASKAppSettingsViewControllerEx];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    UIEdgeInsets inset = {0, 0, 10, 0};
    UIScrollView *scrollView = self.tableView;
    [scrollView setContentInset:inset];
    [scrollView setScrollIndicatorInsets:inset];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(onAboutClick:)];
    self.navigationItem.rightBarButtonItem = buttonItem;
    [buttonItem release];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if([cell isKindOfClass:[IASKPSTextFieldSpecifierViewCell class]]) {
        UITextField *field = ((IASKPSTextFieldSpecifierViewCell*)cell).textField;
        [field setTextColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
    }
    
    if([cell isKindOfClass:[IASKPSTitleValueSpecifierViewCell class]]) {
        cell.detailTextLabel.textColor = [UIColor grayColor];
    } else {
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    }
    
    // Background View
    UACellBackgroundView *selectedBackgroundView = [[[UACellBackgroundView alloc] initWithFrame:CGRectZero] autorelease];
    cell.selectedBackgroundView = selectedBackgroundView;
    [selectedBackgroundView setBackgroundColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
    return cell;
}

- (IBAction)onAboutClick: (id)sender {
    [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:TRUE];
}

@end


#pragma mark - UINavigationBarEx Class

@interface UINavigationBarEx: UINavigationBar {
    
}
@end

@implementation UINavigationBarEx


#pragma mark - Lifecycle Functions

- (void)initUINavigationBarEx {
    [self setTintColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
}

- (id)init {
    self = [super init];
    if (self) {
        [self initUINavigationBarEx];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initUINavigationBarEx];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initUINavigationBarEx];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    UIImage *img = [UIImage imageNamed:@"toolsbar_background.png"];
    [img drawInRect:rect];
}

@end


#pragma mark - UINavigationControllerEx Class

@interface UINavigationControllerEx : UINavigationController

@end

@implementation UINavigationControllerEx

- (id)initWithRootViewController:(UIViewController *)rootViewController {
    [UINavigationControllerEx removeBackground:rootViewController.view];
    return [self initWithRootViewController:rootViewController];
}

+ (void)removeBackground:(UIView*)view {
    // iOS7 transparent background is *really* transparent: with an alpha != 0
    // it messes up the transitions. Use non-transparent BG for iOS7
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
        [view setBackgroundColor:LINPHONE_SETTINGS_BG_IOS7];
    else
        [view setBackgroundColor:[UIColor clearColor]];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [UINavigationControllerEx removeBackground:viewController.view];
    UIViewController *oldTopViewController = self.topViewController;
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [oldTopViewController viewWillDisappear:animated];
    }
    [viewController viewWillAppear:animated]; // Force view
    UILabel *labelTitleView = [[UILabel alloc] init];
    labelTitleView.backgroundColor = [UIColor clearColor];
    labelTitleView.textColor = [UIColor colorWithRed:0x41/255.0f green:0x48/255.0f blue:0x4f/255.0f alpha:1.0];
    labelTitleView.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    labelTitleView.font = [UIFont boldSystemFontOfSize:20];
    labelTitleView.shadowOffset = CGSizeMake(0,1);
    labelTitleView.textAlignment = NSTextAlignmentCenter;
    labelTitleView.text = viewController.title;
    [labelTitleView sizeToFit];
    viewController.navigationItem.titleView = labelTitleView;
    [labelTitleView release];
    [super pushViewController:viewController animated:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [self.topViewController viewDidAppear:animated];
        [oldTopViewController viewDidDisappear:animated];
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [self.topViewController viewWillDisappear:animated];
        UIViewController *nextView = nil;
        NSInteger count = [self.viewControllers count];
        if(count > 1) {
            nextView = [self.viewControllers objectAtIndex:count - 2];
        }
        [nextView viewWillAppear:animated];
    }
    UIViewController * ret = [super popViewControllerAnimated:animated];
    if ([[UIDevice currentDevice].systemVersion doubleValue] < 5.0) {
        [ret viewDidDisappear:animated];
        [self.topViewController viewDidAppear:animated];
    }
    return ret;
}

- (void)setViewControllers:(NSArray *)viewControllers {
    for(UIViewController *controller in viewControllers) {
        [UINavigationControllerEx removeBackground:controller.view];
    }
    [super setViewControllers:viewControllers];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    for(UIViewController *controller in viewControllers) {
        [UINavigationControllerEx removeBackground:controller.view];
    }
    [super setViewControllers:viewControllers animated:animated];
}

@end


@implementation SettingsViewController

@synthesize settingsController;
@synthesize navigationController;

#pragma mark - Lifecycle Functions

- (id)init {
    return [super initWithNibName:@"SettingsViewController" bundle:[NSBundle mainBundle]];
}


- (void)dealloc {
    // Remove all observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [settingsStore release];
    [settingsController release];
    [navigationController release];
    [super dealloc];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Settings"
                                                                content:@"SettingsViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar: @"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
    }
    return compositeDescription;
}


#pragma mark - ViewController Functions

- (void)viewDidLoad {
    [super viewDidLoad];
    
    settingsStore = [[LinphoneCoreSettingsStore alloc] init];
    
    settingsController.showDoneButton = FALSE;
    settingsController.delegate = self;
    settingsController.showCreditsFooter = FALSE;
    settingsController.settingsStore = settingsStore;
    
    [navigationController.view setBackgroundColor:[UIColor clearColor]];
    
    navigationController.view.frame = self.view.frame;
    [navigationController pushViewController:settingsController animated:FALSE];
    [self.view addSubview: navigationController.view];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [settingsController dismiss:self];
    // Set observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kIASKAppSettingChanged
                                                  object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [settingsStore transformLinphoneCoreToKeys]; // Sync settings with linphone core settings
    settingsController.hiddenKeys = [self findHiddenKeys];
    [settingsController.tableView reloadData];
    
    // Set observer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appSettingChanged:)
                                                 name:kIASKAppSettingChanged
                                               object:nil];
}


#pragma mark - Event Functions

- (void)appSettingChanged:(NSNotification*) notif {
    if([@"enable_video_preference" compare: notif.object] == NSOrderedSame) {
        BOOL enable = [[notif.userInfo objectForKey:@"enable_video_preference"] boolValue];
        NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
        if(!enable) {
            [hiddenKeys addObject:@"video_menu"];
        } else {
            [hiddenKeys removeObject:@"video_menu"];
        }
        [settingsController setHiddenKeys:hiddenKeys animated:TRUE];
    }else if([@"mutiple_sip_preference" compare: notif.object] == NSOrderedSame) {                //hide or display sip2_menu by enable mutiple sip account. added by otis.
        BOOL enable = [[notif.userInfo objectForKey:@"mutiple_sip_preference"] boolValue];
        NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
        if(!enable) {
            [hiddenKeys addObject:@"sip2_menu"];
        } else {
            [hiddenKeys removeObject:@"sip2_menu"];
        }
        [settingsController setHiddenKeys:hiddenKeys animated:TRUE];
        
    }
    else if ([@"random_port_preference" compare: notif.object] == NSOrderedSame) {
        BOOL enable = [[notif.userInfo objectForKey:@"random_port_preference"] boolValue];
        NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
        if(enable) {
            [hiddenKeys addObject:@"port_preference"];
        } else {
            [hiddenKeys removeObject:@"port_preference"];
        }
        [settingsController setHiddenKeys:hiddenKeys animated:TRUE];
    } else if ([@"backgroundmode_preference" compare: notif.object] == NSOrderedSame) {
        BOOL enable = [[notif.userInfo objectForKey:@"backgroundmode_preference"] boolValue];
        NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
        if(!enable) {
            [hiddenKeys addObject:@"start_at_boot_preference"];
        } else {
            [hiddenKeys removeObject:@"start_at_boot_preference"];
        }
        [settingsController setHiddenKeys:hiddenKeys animated:TRUE];
    } else if ([@"stun_preference" compare: notif.object] == NSOrderedSame) {
        NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
        NSString *stun_server = [notif.userInfo objectForKey:@"stun_preference"];
        if (stun_server && ([stun_server length] > 0)) {
            [hiddenKeys removeObject:@"ice_preference"];
        } else {
            [hiddenKeys addObject:@"ice_preference"];
        }
        [settingsController setHiddenKeys:hiddenKeys animated:TRUE];
    } else if ([@"debugenable_preference" compare: notif.object] == NSOrderedSame) {
        NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
        BOOL debugEnable = [[notif.userInfo objectForKey:@"debugenable_preference"] boolValue];
        if (debugEnable) {
            [hiddenKeys removeObject:@"console_button"];
        } else {
            [hiddenKeys addObject:@"console_button"];
        }
        [settingsController setHiddenKeys:hiddenKeys animated:TRUE];
    } else if( [@"advanced_account_preference" compare:notif.object] == NSOrderedSame) {
        BOOL advanced = [[notif.userInfo objectForKey:@"advanced_account_preference"] boolValue];
        NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
        
        if( advanced ){
            [hiddenKeys removeObject:@"userid_preference"];
            [hiddenKeys removeObject:@"proxy_preference"];
            [hiddenKeys removeObject:@"outbound_proxy_preference"];
            [hiddenKeys removeObject:@"avpf_preference"];
        }
        else {
            [hiddenKeys addObject:@"userid_preference"];
            [hiddenKeys addObject:@"proxy_preference"];
            [hiddenKeys addObject:@"outbound_proxy_preference"];
            [hiddenKeys addObject:@"avpf_preference"];
        }
        [settingsController setHiddenKeys:hiddenKeys animated:TRUE];
    }
}


#pragma mark -

+ (IASKSpecifier*)disableCodecSpecifier:(IASKSpecifier *)specifier {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[specifier specifierDict]];
    
    NSMutableString *type = [NSMutableString stringWithString:[dict objectForKey:kIASKType]];
    [type setString:kIASKPSTitleValueSpecifier];
    [dict setObject:type forKey:kIASKType];
    
    NSMutableArray *values = [NSMutableArray arrayWithObjects:[NSNumber numberWithInt:0], [NSNumber numberWithInt:1], nil ];
    [dict setObject:values forKey:kIASKValues];
    
    NSString* title = NSLocalizedString(@"Disabled, build from sources to enable", nil);
    NSMutableArray *titles = [NSMutableArray arrayWithObjects:title, title, nil];
    [dict setObject:titles forKey:kIASKTitles];
    
    return [[[IASKSpecifier alloc] initWithSpecifier:dict] autorelease];
}

+ (IASKSpecifier*)filterSpecifier:(IASKSpecifier *)specifier {
#ifndef HAVE_SSL
    if ([[specifier key] isEqualToString:@"transport_preference"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[specifier specifierDict]];
        NSMutableArray *titles = [NSMutableArray arrayWithArray:[dict objectForKey:@"Titles"]];
        [titles removeObject:@"TLS"];
        [dict setObject:titles forKey:@"Titles"];
        NSMutableArray *values = [NSMutableArray arrayWithArray:[dict objectForKey:@"Values"]];
        [values removeObject:@"tls"];
        [dict setObject:values forKey:@"Values"];
        return [[[IASKSpecifier alloc] initWithSpecifier:dict] autorelease];
    }
#else
    if ([[specifier key] isEqualToString:@"media_encryption_preference"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[specifier specifierDict]];
        if(!linphone_core_media_encryption_supported([LinphoneManager getLc], LinphoneMediaEncryptionZRTP)) {
            NSMutableArray *titles = [NSMutableArray arrayWithArray:[dict objectForKey:@"Titles"]];
            [titles removeObject:@"ZRTP"];
            [dict setObject:titles forKey:@"Titles"];
            NSMutableArray *values = [NSMutableArray arrayWithArray:[dict objectForKey:@"Values"]];
            [values removeObject:@"ZRTP"];
            [dict setObject:values forKey:@"Values"];
        }
        if(!linphone_core_media_encryption_supported([LinphoneManager getLc], LinphoneMediaEncryptionSRTP)) {
            NSMutableArray *titles = [NSMutableArray arrayWithArray:[dict objectForKey:@"Titles"]];
            [titles removeObject:@"SRTP"];
            [dict setObject:titles forKey:@"Titles"];
            NSMutableArray *values = [NSMutableArray arrayWithArray:[dict objectForKey:@"Values"]];
            [values removeObject:@"SRTP"];
            [dict setObject:values forKey:@"Values"];
        }
        return [[[IASKSpecifier alloc] initWithSpecifier:dict] autorelease];
    }
    
#endif //HAVE_SSL
    
    
     //Add "build from source" if MPEG4 or H264 disabled
    if ([[specifier key] isEqualToString:@"h264_preference"] && ![LinphoneManager isCodecSupported:"h264"]) {
        return [SettingsViewController disableCodecSpecifier:specifier];
    }
    if ([[specifier key] isEqualToString:@"mp4v-es_preference"] && ![LinphoneManager isCodecSupported:"mp4v-es"]) {
        return [SettingsViewController disableCodecSpecifier:specifier];
    }
    
    return specifier;
}

- (NSSet*)findHiddenKeys {
    LinphoneManager* lm = [LinphoneManager instance];
    NSMutableSet *hiddenKeys = [NSMutableSet set];
    
#ifndef DEBUG
    [hiddenKeys addObject:@"release_button"];
    [hiddenKeys addObject:@"battery_alert_button"];
#endif
    
    if (! [[LinphoneManager instance] lpConfigBoolForKey:@"enable_log_collect"]) {
        [hiddenKeys addObject:@"send_logs_button"];
    }
    
    [hiddenKeys addObject:@"playback_gain_preference"];
    [hiddenKeys addObject:@"microphone_gain_preference"];
    
    [hiddenKeys addObject:@"network_limit_group"];
    [hiddenKeys addObject:@"upload_bandwidth_preference"];
    [hiddenKeys addObject:@"download_bandwidth_preference"];
    
    [hiddenKeys addObject:@"incoming_call_timeout_preference"];
    [hiddenKeys addObject:@"in_call_timeout_preference"];
    
    [hiddenKeys addObject:@"wifi_only_preference"];
    
    [hiddenKeys addObject:@"quit_button"]; // Hide for the moment
    [hiddenKeys addObject:@"about_button"]; // Hide for the moment
    [hiddenKeys addObject:@"wanip_preference"];//hide wanip_preferenece.
    NSString *h264 = [[LinphoneManager instance] lpConfigStringForKey:@"h264config_preference"];
    if([h264 isEqualToString:@"to_be_installed"]){
    }
    else{
        
        [hiddenKeys addObject:@"h264_preference"];
    }
    NSString *g729 = [[LinphoneManager instance] lpConfigStringForKey:@"g729config_preference"];
    if([g729 isEqualToString:@"to_be_installed"]){
    }
    else{
        
        [hiddenKeys addObject:@"g729_preference"];
    }
    
    [hiddenKeys addObject:@"h264config_preference"];
    
    [hiddenKeys addObject:@"g729config_preference"];
    
    if (!linphone_core_video_supported([LinphoneManager getLc]))
        [hiddenKeys addObject:@"video_menu"];
    [hiddenKeys addObject:@"sip2_menu"]; //hide sip2_menu default.
    NSString *documentPath = [self applicationDocumentsFileDirectory];  //check if openvpn is installed , if yes, hide download openvpn button. if no, hideb other options. by otis.
    
    
    
    NSString* fileName = [NSString stringWithFormat:@"test.ovpn"];
    NSString *currentFilePath = [documentPath stringByAppendingPathComponent:fileName];
    
    
    
    UIDocumentInteractionController *documentInteractionController = [[UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:currentFilePath]]retain];
    documentInteractionController.delegate = self;
    documentInteractionController.UTI = @"net.openvpn.formats.ovpn";
    
    BOOL isValid =[documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:nil animated:YES];
    if (!isValid)
    {
        
        NSLog(@"can not open test file.");
        [hiddenKeys addObject:@"qrcode_azfone_button"];
        [hiddenKeys addObject:@"key_azfone_button"];
        [hiddenKeys addObject:@"reconnectvpn_azfone_button"];
    }
    
    else{
        
        NSLog(@"can open test file.");
        [hiddenKeys addObject:@"download_openvpn_azfone_button"];
    }
    
    
    
    
    
    if (![LinphoneManager isNotIphone3G])
        [hiddenKeys addObject:@"silk_24k_preference"];
    
    UIDevice* device = [UIDevice currentDevice];
    if (![device respondsToSelector:@selector(isMultitaskingSupported)] || ![device isMultitaskingSupported]) {
        [hiddenKeys addObject:@"backgroundmode_preference"];
        [hiddenKeys addObject:@"start_at_boot_preference"];
    } else {
        if(![lm lpConfigBoolForKey:@"backgroundmode_preference"]) {
            [hiddenKeys addObject:@"start_at_boot_preference"];
        }
    }
    
    [hiddenKeys addObject:@"enable_first_login_view_preference"];
    
#ifndef VIDEO_ENABLED
    [hiddenKeys addObject:@"enable_video_preference"];
    
    
#endif
    
    if (!linphone_core_video_enabled([LinphoneManager getLc])) {
        [hiddenKeys addObject:@"video_menu"];
    }
    
    
    [hiddenKeys addObjectsFromArray:[[LinphoneManager unsupportedCodecs] allObjects]];
    
    BOOL random_port = [lm lpConfigBoolForKey:@"random_port_preference"];
    if(random_port) {
        [hiddenKeys addObject:@"port_preference"];
    }
    
    if(linphone_core_get_stun_server([LinphoneManager getLc]) == NULL) {
        [hiddenKeys addObject:@"ice_preference"];
    }
    
    if(![lm lpConfigBoolForKey:@"debugenable_preference"]) {
        [hiddenKeys addObject:@"console_button"];
    }
    
    if(![LinphoneManager runningOnIpad]) {
        [hiddenKeys addObject:@"preview_preference"];
    }
    if([lm lpConfigBoolForKey:@"hide_run_assistant_preference"]) {
        [hiddenKeys addObject:@"wizard_button"];
    }
    
    if (!linphone_core_tunnel_available()){
        [hiddenKeys addObject:@"tunnel_menu"];
    }
    
    if( ![lm lpConfigBoolForKey:@"advanced_account_preference"] ){
        [hiddenKeys addObject:@"userid_preference"];
        [hiddenKeys addObject:@"proxy_preference"];
        [hiddenKeys addObject:@"outbound_proxy_preference"];
        [hiddenKeys addObject:@"avpf_preference"];
    }
    
    return hiddenKeys;
}

#pragma mark - IASKSettingsDelegate Functions
- (NSURL *)applicationDocumentsDirectory   //check if openvpn is installed by otis.
{
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (NSString *)applicationDocumentsFileDirectory {  //check if openvpn is insyalled by otis.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {
}
- (void)resetField:(NSString *)field forKey:(NSString *)key
{
    
    [[NSUserDefaults standardUserDefaults] setObject:field forKey:key];
    
}
- (void)setField:(NSString *)field forKey:(NSString *)key {
    if (field != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:field forKey:key];
        [[NSUserDefaults standardUserDefaults]synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}


- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
    NSString *key = [specifier.specifierDict objectForKey:kIASKKey];
#ifdef DEBUG
    if([key isEqual:@"release_button"]) {
        
        [[LinphoneManager instance]	destroyLibLinphone];
        [[LinphoneManager instance]	startLibLinphone];
        [[PhoneMainView instance] startUp];
        
    }else  if([key isEqual:@"download_openvpn_button"]) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download OpenVPN",nil)
                                                        message:NSLocalizedString(@"Please back to AzFone and press Setting to perform other configurations",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:NSLocalizedString(@"Cancel",nil), nil];
        alert.tag = TAG_DONATE;
        [alert show];
        
        
        
    } else  if([key isEqual:@"qrcode_button"]) {
        
        UIViewController *qrcode=[ViewController alloc] ;
        
        [self.view.window.rootViewController presentViewController:qrcode animated:YES completion:nil];
    }else if([key isEqual:@"reconnectxmpp_button"]){
        
        //if there are no network ,do not reconnect xmpp just change view to xmpp list.
        if(!linphone_core_is_network_reachable([LinphoneManager getLc])){
            
            [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
        }
        else{
            [self resetField:@"" forKey:kXMPPmyJID];
            [self resetField:@"" forKey:kXMPPmyPassword];
            [self resetField:@"" forKey:kXMPPHost];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream ]disconnect];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppvCardTempModule] removeDelegate:self];
            NSString *jidField = [[LinphoneManager instance] lpConfigStringForKey:@"xmppid_preference"];
            NSString *passwordField = [[LinphoneManager instance] lpConfigStringForKey:@"xmpppsw_preference"];
            NSString *xmppdomain = [[LinphoneManager instance] lpConfigStringForKey:@"xmppdomain_preference"];
            [self setField:xmppdomain forKey:kXMPPHost];
            [self setField:jidField forKey:kXMPPmyJID];
            [self setField:passwordField forKey:kXMPPmyPassword];
            [[LinphoneAppDelegate sharedAppDelegate] connect];
            
            [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
        }
        
        
    }
    else  if([key isEqual:@"reconnectvpn_button"]) {
        
        
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Reconnect OpenVPN",nil)
                                                        message:NSLocalizedString(@"Click Next, return to the main screen, then click OpenVPN application, after the setting is completed, please return AzFone.",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Next",nil), nil];
        
        
        alert.tag = TAG_DEV;
        [alert show];
        
    }
    else  if([key isEqual:@"exit_button"]) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure to quit AzFone?",nil)
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        
        
        alert.tag = TAG_DEV;
        [alert show];
        
    }
    
    else if([key isEqual:@"key_button"]){
        
        
        UIViewController *keyview=[keyViewController alloc] ;
        [self.navigationController pushViewController:keyview animated:YES];
        [keyview release];
        
        
        
        
        
        
    }
    
    //click key generate_button and show up the form to generate the key.
#endif
    if([key isEqual:@"console_button"]) {
        [[PhoneMainView instance] changeCurrentView:[ConsoleViewController compositeViewDescription] push:TRUE];
    } else if([key isEqual:@"clear_cache_button"]) {
        
        [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:TRUE];
    }
    else if([key isEqual:@"trial_account"]){
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.yahoo.com.tw"]];
    
    }
    else if([key isEqual:@"exit_azfone_button"]) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure to quit AzFone?",nil)
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
        
        
        alert.tag = TAG_DEV;
        [alert show];
    }
    else if([key isEqual:@"download_openvpn_azfone_button"]) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download OpenVPN",nil)
                                                        message:NSLocalizedString(@"Please back to AzFone and press Setting to perform other configurations",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:NSLocalizedString(@"Cancel",nil), nil];
        alert.tag = TAG_DONATE;
        [alert show];
        
    }
    else if([key isEqual:@"qrcode_azfone_button"]) {
        
        UIViewController *qrcode=[ViewController alloc] ;
        
        [self.view.window.rootViewController presentViewController:qrcode animated:YES completion:nil];
    } else if([key isEqual:@"key_azfone_button"]) {
        
        UIViewController *keyview=[keyViewController alloc] ;
        [self.navigationController pushViewController:keyview animated:YES];
        [keyview release];
        
    } else if([key isEqual:@"reconnectvpn_azfone_button"]) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Reconnect OpenVPN",nil)
                                                        message:NSLocalizedString(@"Click Next, return to the main screen, then click OpenVPN application, after the setting is completed, please return AzFone.",nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Next",nil), nil];
        
        
        alert.tag = TAG_DEV;
        [alert show];
    } else if([key isEqual:@"release_azfone_button"]) {
        
        [[LinphoneManager instance]	destroyLibLinphone];
        [[LinphoneManager instance]	startLibLinphone];
        [[PhoneMainView instance] startUp];
        
        
    } else if([key isEqual:@"reconnectxmpp_azfone_button"]) {
        
        //if there are no network ,do not reconnect xmpp just change view to xmpp list.
        if(!linphone_core_is_network_reachable([LinphoneManager getLc])){
            
            [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
        }
        else{
            [self resetField:@"" forKey:kXMPPmyJID];
            [self resetField:@"" forKey:kXMPPmyPassword];
            [self resetField:@"" forKey:kXMPPHost];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppStream ]disconnect];
            [[[LinphoneAppDelegate sharedAppDelegate] xmppvCardTempModule] removeDelegate:self];
            NSString *jidField = [[LinphoneManager instance] lpConfigStringForKey:@"xmppid_preference"];
            NSString *passwordField = [[LinphoneManager instance] lpConfigStringForKey:@"xmpppsw_preference"];
            NSString *xmppdomain = [[LinphoneManager instance] lpConfigStringForKey:@"xmppdomain_preference"];
            [self setField:xmppdomain forKey:kXMPPHost];
            [self setField:jidField forKey:kXMPPmyJID];
            [self setField:passwordField forKey:kXMPPmyPassword];
            [[LinphoneAppDelegate sharedAppDelegate] connect];
            
            [[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
        }
        
        
    } else if([key isEqual:@"about_button"]) {
        [[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:TRUE];
    } else if ([key isEqual:@"send_logs_button"]) {
        char * filepath = linphone_core_compress_log_collection([LinphoneManager getLc]);
        if (filepath == NULL) {
            [LinphoneLogger log:LinphoneLoggerError format:@"Cannot sent logs: file is NULL"];
            return;
        }
        
        NSString *filename = [[NSString stringWithUTF8String:filepath] componentsSeparatedByString:@"/"].lastObject;
        NSString *mimeType;
        if ([filename hasSuffix:@".jpg"]) {
            mimeType = @"image/jpeg";
        } else if ([filename hasSuffix:@".png"]) {
            mimeType = @"image/png";
        } else if ([filename hasSuffix:@".pdf"]) {
            mimeType = @"application/pdf";
        } else if ([filename hasSuffix:@".txt"]) {
            mimeType = @"text/plain";
        } else if ([filename hasSuffix:@".gz"]) {
            mimeType = @"application/gzip";
        } else {
            [LinphoneLogger log:LinphoneLoggerError format:@"Unknown extension type: %@, cancelling email", filename];
            return;
        }
        [self emailAttachment:[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:filepath]] mimeType:mimeType name:filename];
        ms_free(filepath);
    }
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == TAG_DEV) { // handle the altdev
        
        
        if( buttonIndex != 1 ) return;
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        
        [NSThread sleepForTimeInterval:2.0];
        
        exit(0);
    }
    else if (alertView.tag == TAG_DONATE){ // handle the donate
        
        if( buttonIndex == 1 ) return;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download OpenVPN",nil)
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                              otherButtonTitles:nil];
        alert.tag =3;
        [alert show];
        
    }
    else if (alertView.tag ==3){
        NSString *str = @"itms-apps://itunes.apple.com/app/id590379981";
        
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:str]];
        exit(0);
    }
}



#pragma mark - Mail composer for send log
- (void)emailAttachment: (NSData*)attachment mimeType:(NSString*)type name:(NSString*)attachmentName
{
    if (attachmentName == nil || type == nil || attachmentName == nil) {
        [LinphoneLogger log:LinphoneLoggerError format:@"Trying to email attachment but mandatory field is missing"];
        return;
    }
    
#if TARGET_IPHONE_SIMULATOR
    UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Cannot send email",nil)
                                                    message:NSLocalizedString(@"Simulator cannot send emails. To test this feature, please use a real device.",nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                          otherButtonTitles:nil];
    [error show];
    [error release];
#else
    if ([MFMailComposeViewController canSendMail] == YES) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        
        [picker setSubject:NSLocalizedString(@"Linphone Logs",nil)];
        [picker setToRecipients:[NSArray arrayWithObjects:@"linphone-iphone@belledonne-communications.com", nil]];
        [picker setMessageBody:NSLocalizedString(@"Linphone logs", nil) isHTML:NO];
        [picker addAttachmentData:attachment mimeType:type fileName:attachmentName];
        
        [self presentViewController:picker animated:true completion:nil];
        [picker release];
    } else {
        UIAlertView* error = [[UIAlertView alloc]	initWithTitle:NSLocalizedString(@"Cannot send email",nil)
                                                        message:NSLocalizedString(@"Your device is not configured to send emails. Please configure mail application prior to send logs.",nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                              otherButtonTitles:nil];
        [error show];
        [error release];
    }
#endif
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if (error != nil) {
        [LinphoneLogger log:LinphoneLoggerWarning format:@"Error while sending mail: %@", error];
    } else {
        [LinphoneLogger log:LinphoneLoggerLog format:@"Mail completed with status: %d", result];
    }
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
