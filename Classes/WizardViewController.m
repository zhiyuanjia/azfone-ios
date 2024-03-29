/* WizardViewController.m
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
 *  GNU Library General Public License for more details.                
 *                                                                      
 *  You should have received a copy of the GNU General Public License   
 *  along with this program; if not, write to the Free Software         
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */ 

#import "WizardViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

#import <XMLRPCConnection.h>
#import <XMLRPCConnectionManager.h>
#import <XMLRPCResponse.h>
#import <XMLRPCRequest.h>

typedef enum _ViewElement {
    ViewElement_Username            = 100,
    ViewElement_Password            = 101,
    ViewElement_Password2           = 102,
    ViewElement_Email               = 103,
    ViewElement_Domain              = 104,
    ViewElement_Label               = 200,
    ViewElement_Error               = 201,
    ViewElement_Username_Error      = 404
} ViewElement;

@implementation WizardViewController

@synthesize contentView;

@synthesize welcomeView;
@synthesize choiceView;
@synthesize createAccountView;
@synthesize connectAccountView;
@synthesize externalAccountView;
@synthesize validateAccountView;
@synthesize provisionedAccountView;
@synthesize waitView;

@synthesize backButton;
@synthesize startButton;
@synthesize createAccountButton;
@synthesize connectAccountButton;
@synthesize externalAccountButton;
@synthesize remoteProvisioningButton;

@synthesize provisionedDomain, provisionedPassword, provisionedUsername;

@synthesize choiceViewLogoImageView;

@synthesize viewTapGestureRecognizer;


#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"WizardViewController" bundle:[NSBundle mainBundle]];
    if (self != nil) {
        [[NSBundle mainBundle] loadNibNamed:@"WizardViews"
                                      owner:self
                                    options:nil];
        self->historyViews = [[NSMutableArray alloc] init];
        self->currentView = nil;
        self->viewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewTap:)];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [contentView release];
    
    [welcomeView release];
    [choiceView release];
    [createAccountView release];
    [connectAccountView release];
    [externalAccountView release];
    [validateAccountView release];
    
    [waitView release];
    
    [backButton release];
    [startButton release];
    [createAccountButton release];
    [connectAccountButton release];
    [externalAccountButton release];

    [choiceViewLogoImageView release];
    
    [historyViews release];
    
    [viewTapGestureRecognizer release];
    
    [remoteProvisioningButton release];
    [provisionedAccountView release];
    [provisionedUsername release];
    [provisionedPassword release];
    [provisionedDomain release];
    [super dealloc];
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if(compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Wizard" 
                                                                content:@"WizardViewController" 
                                                               stateBar:nil 
                                                        stateBarEnabled:false 
                                                                 tabBar:nil 
                                                          tabBarEnabled:false 
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
        compositeDescription.darkBackground = true;
    }
    return compositeDescription;
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configuringUpdate:)
                                                 name:kLinphoneConfiguringStateUpdate
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneConfiguringStateUpdate
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [viewTapGestureRecognizer setCancelsTouchesInView:FALSE];
    [viewTapGestureRecognizer setDelegate:self];
    [contentView addGestureRecognizer:viewTapGestureRecognizer];
    
    if([LinphoneManager runningOnIpad]) {
        [LinphoneUtils adjustFontSize:welcomeView mult:2.22f];
        [LinphoneUtils adjustFontSize:choiceView mult:2.22f];
        [LinphoneUtils adjustFontSize:createAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:connectAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:externalAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:validateAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:provisionedAccountView mult:2.22f];
    }
}


#pragma mark -

+ (void)cleanTextField:(UIView*)view {
    if([view isKindOfClass:[UITextField class]]) {
        [(UITextField*)view setText:@""];
    } else {
        for(UIView *subview in view.subviews) {
            [WizardViewController cleanTextField:subview];
        }
    }
}

- (void)fillDefaultValues {

    LinphoneCore* lc = [LinphoneManager getLc];
    [self resetTextFields];

    LinphoneProxyConfig* current_conf = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &current_conf);
    if( current_conf != NULL ){
        const char* proxy_addr = linphone_proxy_config_get_identity(current_conf);
        if( proxy_addr ){
            LinphoneAddress *addr = linphone_address_new( proxy_addr );
            if( addr ){
                const LinphoneAuthInfo *auth = linphone_core_find_auth_info(lc, NULL, linphone_address_get_username(addr), linphone_proxy_config_get_domain(current_conf));
                linphone_address_destroy(addr);
                if( auth ){
                    [LinphoneLogger log:LinphoneLoggerLog format:@"A proxy config was set up with the remote provisioning, skip wizard"];
                    [self onCancelClick:nil];
                }
            }
        }
    }

    LinphoneProxyConfig* default_conf = linphone_core_create_proxy_config([LinphoneManager getLc]);
    const char* identity = linphone_proxy_config_get_identity(default_conf);
    if( identity ){
        LinphoneAddress* default_addr = linphone_address_new(identity);
        if( default_addr ){
            const char* domain = linphone_address_get_domain(default_addr);
            const char* username = linphone_address_get_username(default_addr);
            if( domain && strlen(domain) > 0){
                //UITextField* domainfield = [WizardViewController findTextField:ViewElement_Domain view:externalAccountView];
                [provisionedDomain setText:[NSString stringWithUTF8String:domain]];
            }

            if( username && strlen(username) > 0 && username[0] != '?' ){
                //UITextField* userField = [WizardViewController findTextField:ViewElement_Username view:externalAccountView];
                [provisionedUsername setText:[NSString stringWithUTF8String:username]];
            }
        }
    }

    [self changeView:provisionedAccountView back:FALSE animation:TRUE];

    linphone_proxy_config_destroy(default_conf);

}

- (void)resetTextFields {
    [WizardViewController cleanTextField:welcomeView];
    [WizardViewController cleanTextField:choiceView];
    [WizardViewController cleanTextField:createAccountView];
    [WizardViewController cleanTextField:connectAccountView];
    [WizardViewController cleanTextField:externalAccountView];
    [WizardViewController cleanTextField:validateAccountView];
    [WizardViewController cleanTextField:provisionedAccountView];
}

- (void)reset {
    [self clearProxyConfig];
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"pushnotification_preference"];
    
    LinphoneCore *lc = [LinphoneManager getLc];
    LCSipTransports transportValue={5060,5060,-1,-1};

    if (linphone_core_set_sip_transports(lc, &transportValue)) {
        [LinphoneLogger logc:LinphoneLoggerError format:"cannot set transport"];
    }
    
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"sharing_server_preference"];
    [[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"ice_preference"];
    [[LinphoneManager instance] lpConfigSetString:@"" forKey:@"stun_preference"];
    linphone_core_set_stun_server(lc, NULL);
    linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
    [self resetTextFields];
    if ([[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_welcome_view_preference"] == true) {
        [self changeView:choiceView back:FALSE animation:FALSE];
    } else {
        [self changeView:welcomeView back:FALSE animation:FALSE];
    }
    [waitView setHidden:TRUE];
}

+ (UIView*)findView:(ViewElement)tag view:(UIView*)view {
    for(UIView *child in [view subviews]) {
        if([child tag] == tag){
            return (UITextField*)child;
        } else {
            UIView *o = [WizardViewController findView:tag view:child];
            if(o)
                return o;
        }
    }
    return nil;
}

+ (UITextField*)findTextField:(ViewElement)tag view:(UIView*)view {
    UIView *aview = [WizardViewController findView:tag view:view];
    if([aview isKindOfClass:[UITextField class]])
        return (UITextField*)aview;
    return nil;
}

+ (UILabel*)findLabel:(ViewElement)tag view:(UIView*)view {
    UIView *aview = [WizardViewController findView:tag view:view];
    if([aview isKindOfClass:[UILabel class]])
        return (UILabel*)aview;
    return nil;
}

- (void)clearHistory {
    [historyViews removeAllObjects];
}

- (void)changeView:(UIView *)view back:(BOOL)back animation:(BOOL)animation {

    static BOOL placement_done = NO; // indicates if the button placement has been done in the wizard choice view

    // Change toolbar buttons following view
    if (view == welcomeView) {
        [startButton setHidden:false];
        [backButton setHidden:true];
    } else {
        [startButton setHidden:true];
        [backButton setHidden:false];
    }
    
    if (view == validateAccountView) {
        [backButton setEnabled:FALSE];
    } else if (view == choiceView) {
        if ([[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_welcome_view_preference"] == true) {
            [backButton setEnabled:FALSE];
        } else {
            [backButton setEnabled:TRUE];
        }
    } else {
        [backButton setEnabled:TRUE];
    }

    if (view == choiceView) {
        // layout is this:
        // [ Logo         ]
        // [ Create Btn   ]
        // [ Connect Btn  ]
        // [ External Btn ]
        // [ Remote Prov  ]

        BOOL show_logo   =  [[LinphoneManager instance] lpConfigBoolForKey:@"show_wizard_logo_in_choice_view_preference"];
        BOOL show_extern = ![[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_custom_account"];
        BOOL show_new    = ![[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_create_account"];

        if( !placement_done ) {
            // visibility
            choiceViewLogoImageView.hidden = !show_logo;
            externalAccountButton.hidden   = !show_extern;
            createAccountButton.hidden     = !show_new;

            // placement
            if (show_logo && show_new && !show_extern) {
                // lower both remaining buttons
                [createAccountButton  setCenter:[connectAccountButton  center]];
                [connectAccountButton setCenter:[externalAccountButton center]];

            } else if (!show_logo && !show_new && show_extern ) {
                // move up the extern button
                [externalAccountButton setCenter:[createAccountButton center]];
            }
            placement_done = YES;
        }
        if (!show_extern && !show_logo) {
            // no option to create or specify a custom account: go to connect view directly
            view = connectAccountView;
        }
    }
    
    // Animation
    if(animation && [[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == true) {
      CATransition* trans = [CATransition animation];
      [trans setType:kCATransitionPush];
      [trans setDuration:0.35];
      [trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
      if(back) {
          [trans setSubtype:kCATransitionFromLeft];
      }else {
          [trans setSubtype:kCATransitionFromRight];
      }
      [contentView.layer addAnimation:trans forKey:@"Transition"];
    }
    
    // Stack current view
    if(currentView != nil) {
        if(!back)
            [historyViews addObject:currentView];
        [currentView removeFromSuperview];
    }
    
    // Set current view
    currentView = view;
    [contentView insertSubview:view atIndex:0];
    [view setFrame:[contentView bounds]];
    [contentView setContentSize:[view bounds].size];
}

- (void)clearProxyConfig {
	linphone_core_clear_proxy_config([LinphoneManager getLc]);
	linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}

- (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    LinphoneManager* lm = [LinphoneManager instance];

    BOOL pushnotification = [lm lpConfigBoolForKey:@"pushnotification_preference"];
    if(pushnotification) {
        [lm addPushTokenToProxyConfig:proxyCfg];
    }
}

- (void)addProxyConfig:(NSString*)username password:(NSString*)password domain:(NSString*)domain {
    LinphoneCore* lc = [LinphoneManager getLc];
	LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config(lc);

    char normalizedUserName[256];
    linphone_proxy_config_normalize_number(proxyCfg, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));

    const char* identity = linphone_proxy_config_get_identity(proxyCfg);
    if( !identity || !*identity ) identity = "sip:user@example.com";

    LinphoneAddress* linphoneAddress = linphone_address_new(identity);
    linphone_address_set_username(linphoneAddress, normalizedUserName);

    if( domain && [domain length] != 0) {
        // when the domain is specified (for external login), take it as the server address
        linphone_proxy_config_set_server_addr(proxyCfg, [domain UTF8String]);
        linphone_address_set_domain(linphoneAddress, [domain UTF8String]);
    }

    identity = linphone_address_as_string_uri_only(linphoneAddress);

    linphone_proxy_config_set_identity(proxyCfg, identity);



    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String]
													, NULL, [password UTF8String]
													, NULL
													, NULL
													,linphone_proxy_config_get_domain(proxyCfg));

    [self setDefaultSettings:proxyCfg];

    [self clearProxyConfig];

    linphone_proxy_config_enable_register(proxyCfg, true);
	linphone_core_add_auth_info(lc, info);
    linphone_core_add_proxy_config(lc, proxyCfg);
	linphone_core_set_default_proxy(lc, proxyCfg);
}

- (void)addProvisionedProxy:(NSString*)username withPassword:(NSString*)password withDomain:(NSString*)domain {
    [self clearProxyConfig];

	LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config([LinphoneManager getLc]);

    const char *addr= linphone_proxy_config_get_domain(proxyCfg);
    char normalizedUsername[256];
    LinphoneAddress* linphoneAddress = linphone_address_new(addr);

    linphone_proxy_config_normalize_number(proxyCfg,
                                           [username cStringUsingEncoding:[NSString defaultCStringEncoding]],
                                           normalizedUsername,
                                           sizeof(normalizedUsername));

    linphone_address_set_username(linphoneAddress, normalizedUsername);
    linphone_address_set_domain(linphoneAddress, [domain UTF8String]);

    const char* identity = linphone_address_as_string_uri_only(linphoneAddress);
	linphone_proxy_config_set_identity(proxyCfg, identity);

    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String], NULL, [password UTF8String], NULL, NULL, [domain UTF8String]);

    linphone_proxy_config_enable_register(proxyCfg, true);
	linphone_core_add_auth_info([LinphoneManager getLc], info);
    linphone_core_add_proxy_config([LinphoneManager getLc], proxyCfg);
	linphone_core_set_default_proxy([LinphoneManager getLc], proxyCfg);
}

- (NSString*)identityFromUsername:(NSString*)username {
    char normalizedUserName[256];
    LinphoneAddress* linphoneAddress = linphone_address_new("sip:user@domain.com");
    linphone_proxy_config_normalize_number(NULL, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));
    linphone_address_set_username(linphoneAddress, normalizedUserName);
    linphone_address_set_domain(linphoneAddress, [[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"] UTF8String]);
    NSString* uri = [NSString stringWithUTF8String:linphone_address_as_string_uri_only(linphoneAddress)];
    NSString* scheme = [NSString stringWithUTF8String:linphone_address_get_scheme(linphoneAddress)];
    return [uri substringFromIndex:[scheme length] + 1];
}

- (void)checkUserExist:(NSString*)username {
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC check_account %@", username];
    
    NSURL *URL = [NSURL URLWithString:[[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL: URL];
    [request setMethod: @"check_account" withParameters:[NSArray arrayWithObjects:username, nil]];
    
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest: request delegate: self];
    
    [request release];
    [waitView setHidden:false];
}

- (void)createAccount:(NSString*)identity password:(NSString*)password email:(NSString*)email {
    NSString *useragent = [LinphoneManager getUserAgent];
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC create_account_with_useragent %@ %@ %@ %@", identity, password, email, useragent];
    
    NSURL *URL = [NSURL URLWithString: [[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL: URL];
    [request setMethod: @"create_account_with_useragent" withParameters:[NSArray arrayWithObjects:identity, password, email, useragent, nil]];
    
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest: request delegate: self];
    
    [request release];
    [waitView setHidden:false];
}

- (void)checkAccountValidation:(NSString*)identity {
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC check_account_validated %@", identity];
    
    NSURL *URL = [NSURL URLWithString: [[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
    XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL: URL];
    [request setMethod: @"check_account_validated" withParameters:[NSArray arrayWithObjects:identity, nil]];
    
    XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
    [manager spawnConnectionWithXMLRPCRequest: request delegate: self];
    
    [request release];
    [waitView setHidden:false];
}

- (void)registrationUpdate:(LinphoneRegistrationState)state message:(NSString*)message{
    switch (state) {
        case LinphoneRegistrationOk: {
            [waitView setHidden:true];
            [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
            break;
        }
        case LinphoneRegistrationNone:
        case LinphoneRegistrationCleared:  {
            [waitView setHidden:true];
            break;
        }
        case LinphoneRegistrationFailed: {
            [waitView setHidden:true];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure", nil)
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            break;
        }
        case LinphoneRegistrationProgress: {
            [waitView setHidden:false];
            break;
        }
        default:
            break;
    }
}

- (void)loadWizardConfig:(NSString*)rcFilename {
    NSString* fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
    linphone_core_set_provisioning_uri([LinphoneManager getLc], [fullPath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    [[LinphoneManager instance] lpConfigSetInt:1 forKey:@"transient_provisioning" forSection:@"misc"];
    [[LinphoneManager instance] resetLinphoneCore];
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeTextField = textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // only validate the username when creating a new account
    if( (textField.tag == ViewElement_Username) && (currentView == createAccountView) ){
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:@"^[a-z0-9-_\\.]*$"
                                      options:NSRegularExpressionCaseInsensitive
                                      error:nil];
        NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        if ([matches count] == 0) {
            UILabel* error = [WizardViewController findLabel:ViewElement_Username_Error view:contentView];

            // show error with fade animation
            [error setText:[NSString stringWithFormat:NSLocalizedString(@"Illegal character in username: %@", nil), string]];
            error.alpha = 0;
            error.hidden = NO;
            [UIView animateWithDuration:0.3 animations:^{
                error.alpha = 1;
            }];

            // hide again in 2s
            [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(hideError:) userInfo:nil repeats:NO];


            return NO;
        }
    }
    return YES;
}
- (void)hideError:(NSTimer*)timer {
    UILabel* error_label =[WizardViewController findLabel:ViewElement_Username_Error view:contentView];
    if( error_label ) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             error_label.alpha = 0;
                         }
                         completion: ^(BOOL finished) {
                             error_label.hidden = YES;
                         }
         ];
    }
}

#pragma mark - Action Functions

- (IBAction)onStartClick:(id)sender {
    [self changeView:choiceView back:FALSE animation:TRUE];
}

- (IBAction)onBackClick:(id)sender {
    if ([historyViews count] > 0) {
        UIView * view = [historyViews lastObject];
        [historyViews removeLastObject];
        [self changeView:view back:TRUE animation:TRUE];
    }
}

- (IBAction)onCancelClick:(id)sender {
    [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
}

- (IBAction)onCreateAccountClick:(id)sender {
    nextView = createAccountView;
    [self loadWizardConfig:@"wizard_linphone_create.rc"];
}

- (IBAction)onConnectAccountClick:(id)sender {
    nextView = connectAccountView;
    [self loadWizardConfig:@"wizard_linphone_existing.rc"];
}

- (IBAction)onExternalAccountClick:(id)sender {
    nextView = externalAccountView;
    [self loadWizardConfig:@"wizard_external_sip.rc"];
}

- (IBAction)onCheckValidationClick:(id)sender {
    NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
    NSString *identity = [self identityFromUsername:username];
    [self checkAccountValidation:identity];
}

- (IBAction)onRemoteProvisioningClick:(id)sender {
    UIAlertView* remoteInput = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter provisioning URL", @"")
                                                          message:@""
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                otherButtonTitles:NSLocalizedString(@"Fetch", @""), nil];
    remoteInput.alertViewStyle = UIAlertViewStylePlainTextInput;

    UITextField* prov_url = [remoteInput textFieldAtIndex:0];
    prov_url.keyboardType = UIKeyboardTypeURL;
    prov_url.text = [[LinphoneManager instance] lpConfigStringForKey:@"config-uri" forSection:@"misc"];
    prov_url.placeholder  = @"URL";

    [remoteInput show];
    [remoteInput release];
}

- (IBAction)onSignInExternalClick:(id)sender {
    NSString *username = [WizardViewController findTextField:ViewElement_Username  view:contentView].text;
    NSString *password = [WizardViewController findTextField:ViewElement_Password  view:contentView].text;
    NSString *domain = [WizardViewController findTextField:ViewElement_Domain  view:contentView].text;
    
    
    NSMutableString *errors = [NSMutableString string];
    if ([username length] == 0) {
        
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a username.\n", nil)]];
    }
    
    if ([domain length] == 0) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a domain.\n", nil)]];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else {
        [self.waitView setHidden:false];
        [self addProxyConfig:username password:password domain:domain];
    }
}

- (IBAction)onSignInClick:(id)sender {
    NSString *username = [WizardViewController findTextField:ViewElement_Username  view:contentView].text;
    NSString *password = [WizardViewController findTextField:ViewElement_Password  view:contentView].text;
    
    NSMutableString *errors = [NSMutableString string];
    if ([username length] == 0) {
        
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a username.\n", nil)]];
    }
    
    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else {
        [self.waitView setHidden:false];
        // domain and server will be configured from the default proxy values
        [self addProxyConfig:username password:password domain:nil];
    }
}

- (IBAction)onRegisterClick:(id)sender {
    UITextField* username_tf = [WizardViewController findTextField:ViewElement_Username  view:contentView];
    NSString *username = username_tf.text;
    NSString *password = [WizardViewController findTextField:ViewElement_Password  view:contentView].text;
    NSString *password2 = [WizardViewController findTextField:ViewElement_Password2  view:contentView].text;
    NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;
    NSMutableString *errors = [NSMutableString string];

    int username_length = [[LinphoneManager instance] lpConfigIntForKey:@"username_length" forSection:@"wizard"];
    int password_length = [[LinphoneManager instance] lpConfigIntForKey:@"password_length" forSection:@"wizard"];
    
    if ([username length] < username_length) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"The username is too short (minimum %d characters).\n", nil), username_length]];
    }
    
    if ([password length] < password_length) {
        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"The password is too short (minimum %d characters).\n", nil), password_length]];
    }
    
    if (![password2 isEqualToString:password]) {
        [errors appendString:NSLocalizedString(@"The passwords are different.\n", nil)];
    }
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\.[A-Za-z]{2}[A-Za-z]*"];
    if(![emailTest evaluateWithObject:email]) {
        [errors appendString:NSLocalizedString(@"The email is invalid.\n", nil)];
    }

    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                        message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                              otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];

    } else {
        username = [username lowercaseString];
        [username_tf setText:username];
        NSString *identity = [self identityFromUsername:username];
        [self checkUserExist:identity];
    }
}

- (IBAction)onProvisionedLoginClick:(id)sender {
    NSString *username = provisionedUsername.text;
    NSString *password = provisionedPassword.text;

    NSMutableString *errors = [NSMutableString string];
    if ([username length] == 0) {

        [errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a username.\n", nil)]];
    }

    if([errors length]) {
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)",nil)
                                                            message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else {
        [self.waitView setHidden:false];
        [self addProvisionedProxy:username withPassword:password withDomain:provisionedDomain.text];
    }
}

- (IBAction)onViewTap:(id)sender {
    [LinphoneUtils findAndResignFirstResponder:currentView];
}

#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { /* fetch */
        NSString* url = [alertView textFieldAtIndex:0].text;
        if( [url length] > 0 ){
            // missing prefix will result in http:// being used
            if( [url rangeOfString:@"://"].location == NSNotFound )
                url = [NSString stringWithFormat:@"http://%@", url];

            [LinphoneLogger log:LinphoneLoggerLog format:@"Should use remote provisioning URL %@", url];
            linphone_core_set_provisioning_uri([LinphoneManager getLc], [url UTF8String]);

            [waitView setHidden:false];
            [[LinphoneManager instance] resetLinphoneCore];
        }
    } else {
        [LinphoneLogger log:LinphoneLoggerLog format:@"Canceled remote provisioning"];
    }
}

- (void)configuringUpdate:(NSNotification *)notif {
    LinphoneConfiguringState status = (LinphoneConfiguringState)[[notif.userInfo valueForKey:@"state"] integerValue];

    [waitView setHidden:true];

    switch (status) {
        case LinphoneConfiguringSuccessful:
            if( nextView == nil ){
            [self fillDefaultValues];
            } else {
                [self changeView:nextView back:false animation:TRUE];
                nextView = nil;
            }
            break;
        case LinphoneConfiguringFailed:
        {
            NSString* error_message = [notif.userInfo valueForKey:@"message"];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Provisioning Load error", nil)
                                                            message:error_message
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles: nil];
            [alert show];
            [alert release];
            break;
        }

        case LinphoneConfiguringSkipped:
        default:
            break;
    }
}


#pragma mark - Event Functions

- (void)registrationUpdateEvent:(NSNotification*)notif {
    NSString* message = [notif.userInfo objectForKey:@"message"];
    [self registrationUpdate:[[notif.userInfo objectForKey: @"state"] intValue] message:message];
}


#pragma mark - Keyboard Event Functions

- (void)keyboardWillHide:(NSNotification *)notif {
    //CGRect beginFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    //CGRect endFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:@"resize" context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    
    // Move view
    UIEdgeInsets inset = {0, 0, 0, 0};
    [contentView setContentInset:inset];
    [contentView setScrollIndicatorInsets:inset];
    [contentView setShowsVerticalScrollIndicator:FALSE];
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notif {
    //CGRect beginFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = [[[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    NSTimeInterval duration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:@"resize" context:nil];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:TRUE];
    
    if(([[UIDevice currentDevice].systemVersion floatValue] < 8) &&
       UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        int width = endFrame.size.height;
        endFrame.size.height = endFrame.size.width;
        endFrame.size.width = width;
    }
    
    // Change inset
    {
        UIEdgeInsets inset = {0,0,0,0};
        CGRect frame = [contentView frame];
        CGRect rect = [PhoneMainView instance].view.bounds;
        CGPoint pos = {frame.size.width, frame.size.height};
        CGPoint gPos = [contentView convertPoint:pos toView:[UIApplication sharedApplication].keyWindow.rootViewController.view]; // Bypass IOS bug on landscape mode
        inset.bottom = -(rect.size.height - gPos.y - endFrame.size.height);
        if(inset.bottom < 0) inset.bottom = 0;
        
        [contentView setContentInset:inset];
        [contentView setScrollIndicatorInsets:inset];
        CGRect fieldFrame = activeTextField.frame;
        fieldFrame.origin.y += fieldFrame.size.height;
        [contentView scrollRectToVisible:fieldFrame animated:TRUE];
        [contentView setShowsVerticalScrollIndicator:TRUE];
    }
    [UIView commitAnimations];
}


#pragma mark - XMLRPCConnectionDelegate Functions

- (void)request:(XMLRPCRequest *)request didReceiveResponse:(XMLRPCResponse *)response {
    [LinphoneLogger log:LinphoneLoggerLog format:@"XMLRPC %@: %@", [request method], [response body]];
    [waitView setHidden:true];
    if ([response isFault]) {
        NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Communication issue (%@)", nil), [response faultString]];
        UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Communication issue",nil)
                                                            message:errorString
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                  otherButtonTitles:nil,nil];
        [errorView show];
        [errorView release];
    } else if([response object] != nil) { //Don't handle if not object: HTTP/Communication Error
        if([[request method] isEqualToString:@"check_account"]) {
            if([response object] == [NSNumber numberWithInt:1]) {
                UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check issue",nil)
                                                                message:NSLocalizedString(@"Username already exists", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                      otherButtonTitles:nil,nil];
                [errorView show];
                [errorView release];
            } else {
                NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
                NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
                NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;
                NSString* identity = [self identityFromUsername:username];
                [self createAccount:identity password:password email:email];
            }
        } else if([[request method] isEqualToString:@"create_account_with_useragent"]) {
            if([response object] == [NSNumber numberWithInt:0]) {
                NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
                NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
                [self changeView:validateAccountView back:FALSE animation:TRUE];
                [WizardViewController findTextField:ViewElement_Username view:contentView].text = username;
                [WizardViewController findTextField:ViewElement_Password view:contentView].text = password;
            } else {
                UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account creation issue",nil)
                                                                    message:NSLocalizedString(@"Can't create the account. Please try again.", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                          otherButtonTitles:nil,nil];
                [errorView show];
                [errorView release];
            }
        } else if([[request method] isEqualToString:@"check_account_validated"]) {
             if([response object] == [NSNumber numberWithInt:1]) {
                 NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
                 NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
                [self addProxyConfig:username password:password domain:nil];
             } else {
                 UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account validation issue",nil)
                                                                     message:NSLocalizedString(@"Your account is not validate yet.", nil)
                                                                    delegate:nil
                                                           cancelButtonTitle:NSLocalizedString(@"Continue",nil)
                                                           otherButtonTitles:nil,nil];
                 [errorView show];
                 [errorView release];
             }
        }
    }
}

- (void)request:(XMLRPCRequest *)request didFailWithError:(NSError *)error {
    NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Communication issue (%@)", nil), [error localizedDescription]];
    UIAlertView* errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Communication issue", nil)
                                                    message:errorString
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                          otherButtonTitles:nil,nil];
    [errorView show];
    [errorView release];
    [waitView setHidden:true];
}

- (BOOL)request:(XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return FALSE;
}

- (void)request:(XMLRPCRequest *)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)request:(XMLRPCRequest *)request didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary*)attributesForView:(UIView*)view {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
    [attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
    if([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
    }
    [attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
    return attributes;
}

- (void)applyAttributes:(NSDictionary*)attributes toView:(UIView*)view {
    view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
    view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
    if([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        [LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
    }
    view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}


#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]]) { //Avoid tap gesture on Button
        if([LinphoneUtils findAndResignFirstResponder:currentView]) {
            [(UIButton*)touch.view sendActionsForControlEvents:UIControlEventTouchUpInside];
            return NO;
        }
    }
    return YES;
}

@end
