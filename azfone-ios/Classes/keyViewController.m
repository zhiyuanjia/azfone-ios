//
//  keyViewController.m
//  linphone
//
//  Created by Mini on 11/24/14.
//
//

#import "keyViewController.h"
#import "AFNetworking.h"
#import "TTOpenInAppActivity.h"
@interface keyViewController ()
@property (nonatomic, strong) UIPopoverController *activityPopoverController;
@end

@implementation keyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)send:(id)sender {
    
    NSURL *url =[NSURL URLWithString:self.url.text];
    NSString *str = [url absoluteString];
    
    NSURL *url1 =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",@"http://",str,@":8082/mobilevpn/authimage.php"]];
    
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:url1 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:3];                         //check out the image url with timeoutinterval:3 sec.
    NSURLResponse * respones = nil;
    NSError * error = nil;
    NSData * reviced = [NSURLConnection sendSynchronousRequest:request returningResponse:&respones  error:&error];
    UIImage * urlImage = [[UIImage alloc]initWithData:reviced];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:urlImage];
    imageView.frame = CGRectMake(10.0, 145.0, urlImage.size.width, urlImage.size.height);
    [self.view addSubview:imageView];
    
    
    if(urlImage == nil){    // if there are wrong image url , alert and reset ip.
        NSLog(@"invalid ipaddress");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"錯誤的IP位置" message:@"請重新輸入IP位置" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
        self.url.text = nil;
    }
}

- (IBAction)login:(id)sender {
    
    NSString *url2 =_url.text;
    NSString *acct = _accountTextField.text;
    NSString *password = _passwordTextField.text;
    NSString *authimage = _authimageTextField.text;
    NSString *lowercase = [acct lowercaseString];
    NSString *test =@""; //to test if there are no IPaddress,alert show.
    if([url2 isEqualToString:test]){
        NSLog(@"invalid ipaddress");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"錯誤的IP位置" message:@"請先輸入IP並送出" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
    }
    
    else{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURL *url =[NSURL URLWithString:self.url.text];
    NSString *str = [url absoluteString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL
                                                                        
                                                                        URLWithString:[NSString stringWithFormat:@"%@%@%@",@"http://",str,@":8082/mobilevpn/mobileKey.php"]]
                                    
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                    
                                                       timeoutInterval:60.0];
    
    [request setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"acct=%@&password=%@&authimage=%@",lowercase,password,authimage];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response)
                                              {
                                                  NSURL *documentsDirectoryPath = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
                                                  return [documentsDirectoryPath URLByAppendingPathComponent:[response suggestedFilename]];
                                              } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                  NSLog(@"show file path: %@", filePath);
                                                  
                                                  
                                                  NSString * urlStr = [filePath absoluteString];
                                                  NSString *string2 = @"mobileKey";
                                                  
                                                  NSRange range = [urlStr rangeOfString:string2];
                                                  if(range.length == 9){                        //the file is not equal to "client.ovpn" ,alert and reset account or password.
                                                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"錯誤的帳號或密碼" message:@"請重新檢查帳號或密碼" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                      
                                                      [alert show];
                                                      self.authimageTextField.text =nil;
                                                  }
                                                  else{
                                                      
                                                      NSURL *URL = [NSURL fileURLWithPath:urlStr];
                                                      TTOpenInAppActivity *openInAppActivity = [[TTOpenInAppActivity alloc] initWithView:self.view andRect:((UIButton *)sender).frame];
                                                      UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[openInAppActivity]];
                                                      
                                                      
                                                      
                                                      
                                                      if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
                                                          // Store reference to superview (UIActionSheet) to allow dismissal
                                                          openInAppActivity.superViewController = activityViewController;
                                                          // Show UIActivityViewController
                                                          [self presentViewController:activityViewController animated:YES completion:NULL];
                                                          
                                                          
                                                      } else {
                                                          // Create pop up
                                                          
                                                          self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
                                                          // Store reference to superview (UIPopoverController) to allow dismissal
                                                          
                                                          openInAppActivity.superViewController = self.activityPopoverController;
                                                          // Show UIActivityViewController in popup
                                                          [self.activityPopoverController presentPopoverFromRect:((UIButton *)sender).frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                                                          
                                                      }
                                                  }
                                                  
                                              }];
    [downloadTask resume];
    
    
    }
    
    
}



@end
