//
//  ViewController.m
//  QRCodeReader
//
//  Created by Gabriel Theodoropoulos on 27/11/13.
//  Copyright (c) 2013 Gabriel Theodoropoulos. All rights reserved.
//

#import "SettingsViewController.h"
#import "PhoneMainView.h"
#import "keyViewController.h"
#import "ViewController.h"
@interface ViewController ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isReading;

-(BOOL)startReading;
-(void)stopReading;
-(void)loadBeepSound;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Initially make the captureSession object nil.
    _captureSession = nil;
    
    // Set the initial value of the flag to NO.
    _isReading = NO;
    
    // Begin loading the sound effect so to have it ready for playback when it's needed.
    [self loadBeepSound];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBAction method implementation

- (IBAction)startStopReading:(id)sender {
    if (!_isReading) {
        // This is the case where the app should read a QR code when the start button is tapped.
        if ([self startReading]) {
            // If the startReading methods returns YES and the capture session is successfully
            // running, then change the start button title and the status message.
            [_bbitemStart setTitle:@"Stop"];
        }
    }
    else{
        // In this case the app is currently reading a QR code and it should stop doing so.
        [self stopReading];
        // The bar button item's title should change again.
       
    }
    
    // Set to the flag the exact opposite value of the one that currently has.
    _isReading = !_isReading;
}

- (IBAction)back:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Private method implementation

- (BOOL)startReading {
    NSError *error;
    
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
    // as the media type parameter.
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Get an instance of the AVCaptureDeviceInput class using the previous device object.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        // If any error occurs, simply log the description of it and don't continue any more.
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    // Initialize the captureSession object.
    _captureSession = [[AVCaptureSession alloc] init];
    // Set the input device on the capture session.
    [_captureSession addInput:input];
    
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    // Create a new serial dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    
    // Start video capture.
    [_captureSession startRunning];
    
    return YES;
}


-(void)stopReading{
    // Stop video capture and make the capture session object nil.
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_videoPreviewLayer removeFromSuperlayer];
}


-(void)loadBeepSound{
    // Get the path to the beep.mp3 file and convert it to a NSURL object.
//    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
//    NSURL *beepURL = [NSURL URLWithString:beepFilePath];
//    
//    NSError *error;
//    
//    // Initialize the audio player object using the NSURL object previously set.
//    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
//    if (error) {
//        // If the audio player cannot be initialized then log a message.
//        NSLog(@"Could not play beep file.");
//        NSLog(@"%@", [error localizedDescription]);
//    }
//    else{
//        // If the audio player was successfully initialized then load it in memory.
//        [_audioPlayer prepareToPlay];
//    }
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
#pragma mark - AVCaptureMetadataOutputObjectsDelegate method implementation

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.\
           
            NSString* qrstring = metadataObj.stringValue;
            NSRange tRange = [qrstring rangeOfString:@"wanip:"];
            if (tRange.location == NSNotFound){
                NSLog(@"this is not our system qrcode.");
               
                [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
                [_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
                
                _isReading = NO;
                
            
            }
            else{
        
            NSRange search = [qrstring rangeOfString:@"wanip:"];
                              
                              NSString *subString = [qrstring substringFromIndex:search.location+6];
                              NSRange search2 = [subString rangeOfString:@"vAccount:"];
            
                              NSString *str_wanip = [[subString substringToIndex:search2.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                              NSLog(@"wanip:%@",str_wanip);
            
            NSRange search3 = [qrstring rangeOfString:@"vAccount:"];
           
            
        
                              NSString *subString2 = [qrstring substringFromIndex:search3.location+9];
                              NSRange search4 = [subString2 rangeOfString:@"vPass:"];
           
                              NSString *str_vaccount = [[subString2 substringToIndex:search4.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
                              NSLog(@"vaccount:%@",str_vaccount);
            
            NSRange search5 = [qrstring rangeOfString:@"vPass:"];
                               
                               
                               
                               NSString *subString3 = [qrstring substringFromIndex:search5.location+6];
                               NSRange search6 = [subString3 rangeOfString:@"sAccount:"];
                                                  
                               NSString *str_vpass = [[subString3 substringToIndex:search6.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                                  
                               NSLog(@"vpassword:%@",str_vpass);
            NSRange search7 = [qrstring rangeOfString:@"sAccount:"];
                               
                               
                               
                               NSString *subString4 = [qrstring substringFromIndex:search7.location+9];
                               NSRange search8 = [subString4 rangeOfString:@"sPass:"];
                               
                               NSString *str_saccount = [[subString4 substringToIndex:search8.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                               
                               NSLog(@"saccount:%@",str_saccount);
            NSRange search9 = [qrstring rangeOfString:@"sPass:"];
                               
                               
                               
                               NSString *subString5 = [qrstring substringFromIndex:search9.location+6];
                               NSRange search10 = [subString5 rangeOfString:@"vpnip:"];
                                                   
                                                   NSString *str_spass = [[subString5 substringToIndex:search10.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                                   
                                                   NSLog(@"spassword:%@",str_spass);
            NSRange search11 = [qrstring rangeOfString:@"vpnip:"];
                                
                                
                                
                                NSString *subString6 = [qrstring substringFromIndex:search11.location+6];
                                NSRange search12 = [subString6 rangeOfString:@"xmppDomain:"];
                                                    
                                                    NSString *str_vpnip = [[subString6 substringToIndex:search12.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                                    
                                                    NSLog(@"vpnip:%@",str_vpnip);
            NSRange search13 = [qrstring rangeOfString:@"xmppDomain:"];
            
            
            
             NSString *subString7 = [qrstring substringFromIndex:search13.location+11];
              NSRange search14 = [subString7 rangeOfString:@"email:"];
            
              NSString *str_xmppdomain = [[subString7 substringToIndex:search14.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
              NSLog(@"xmppdomain:%@",str_xmppdomain);
            NSRange search15 = [qrstring rangeOfString:@"email:"];
                                
                                
                                
              NSString *subString8 = [qrstring substringFromIndex:search15.location+6];
            NSRange search16 = [subString8 rangeOfString:@"h264:"];
            
            NSString *str_email = [[subString8 substringToIndex:search16.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                                    
                                                    NSLog(@"email:%@",str_email);
            NSRange search17 = [qrstring rangeOfString:@"h264:"];
                                
                                
                                
                                NSString *subString9 = [qrstring substringFromIndex:search17.location+5];
            NSRange search18 = [subString9 rangeOfString:@"g729:"];
            
                                                    NSString *str_h264
                                                    = [[subString9 substringToIndex:search18.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                                    
                                                    NSLog(@"h264:%@",str_h264);
            NSRange search19 = [qrstring rangeOfString:@"g729:"];
            
            
            
            NSString *subString10 = [qrstring substringFromIndex:search19.location+5];
            NSRange search20 = [subString10 rangeOfString:@"xmppvpn:"];
            
            NSString *str_g729= [[subString10 substringToIndex:search20.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            NSLog(@"g729:%@",str_g729);
            NSRange search21 = [qrstring rangeOfString:@"xmppvpn:"];
                                
                                
                                
                                NSString *txmppvpn = [qrstring substringFromIndex:search21.location+8];
                                 NSString *str_xmppvpn =[txmppvpn stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                                
                                NSLog(@"xmppvpn:%@",str_xmppvpn);
            NSString *xmppaccount =[str_vaccount stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
           NSString *xmppid = [NSString stringWithFormat:@"%@%@%@", xmppaccount,@"@",str_xmppdomain];
            
            NSLog(@"xmppid:%@",xmppid);
    [[LinphoneManager instance] lpConfigSetString:xmppid forKey:@"xmppid_preference"];
            
    [[LinphoneManager instance] lpConfigSetString:str_vpass forKey:@"xmpppsw_preference"];
            //if xmppvpn is equal to 1, xmppdomain is vpnip ,else xmppdomain is wanip.
            if([str_xmppvpn isEqualToString:@"1"]){
    [[LinphoneManager instance] lpConfigSetString:str_vpnip forKey:@"xmppdomain_preference"];
                
                [[LinphoneManager instance] lpConfigSetString:str_wanip forKey:@"wanip_preference"];
                NSLog(@"xmppvpn is equal to 1 , use vpnip as xmppdomain");
            }else{
                
                [[LinphoneManager instance] lpConfigSetString:str_wanip forKey:@"xmppdomain_preference"];
                
                [[LinphoneManager instance] lpConfigSetString:str_wanip forKey:@"wanip_preference"];
            }
    [[LinphoneManager instance] lpConfigSetString:str_saccount forKey:@"username_preference"];
            
    [[LinphoneManager instance] lpConfigSetString:str_spass forKey:@"password_preference"];
            
    [[LinphoneManager instance] lpConfigSetString:str_vpnip forKey:@"domain_preference"];
            
    [[LinphoneManager instance] lpConfigSetString:str_vpnip forKey:@"proxy_preference"];
             [[LinphoneManager instance] lpConfigSetString:str_g729 forKey:@"g729config_preference"];
             [[LinphoneManager instance] lpConfigSetString:str_h264 forKey:@"h264config_preference"];
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
           
            //to config new accont after scan qrcode by otis.
    [self addProxyConfig:str_saccount password:str_spass domain:str_vpnip];
         
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            [_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
            
            _isReading = NO;
            
            // If the audio player is not nil, then play the sound effect.
            if (_audioPlayer) {
                [_audioPlayer play];
                
            }
           
            
            UIViewController *keyview=[keyViewController alloc] ;

            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:keyview];
            
            [self presentViewController:nav animated:YES completion:NULL];
            nav.view.frame = CGRectOffset(nav.view.frame, 0.0, -20.0);
            nav.navigationBar.topItem.title = @"Setting Completed";
            
           nav.navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(Done)];
            
        }
    
    }
    
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
    
  //  LinphoneTransportType type = LinphoneTransportTcp;
  //  linphone_address_set_transport(linphoneAddress, type);
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
    
   // NSString* tname = @"tcp_port";
   // linphone_core_set_sip_transports(lc,(__bridge const LCSipTransports *)(tname));
 
    
  linphone_core_set_default_proxy(lc, proxyCfg);
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
- (void)Done {
   
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
    
}
@end
