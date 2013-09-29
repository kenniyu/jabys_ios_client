//
//  LoginViewController.m
//  Jabys
//
//  Created by Ken Yu on 9/28/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "LoginViewController.h"
#import "RoomViewController.h"

@interface LoginViewController ()
- (IBAction)loginBtn:(UIButton *)sender;
@property (strong, nonatomic) NSDictionary *signInResponse;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UITableView *formTableView;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.navigationController setNavigationBarHidden:NO];
    
    CGRect frame = self.formTableView.tableHeaderView.frame;
    frame.size.height = 0;
    
    self.formTableView.tableHeaderView = [[UIView alloc] initWithFrame:frame];
}

- (IBAction)loginBtn:(UIButton *)sender {
    [self signIn];
}

/* Some text field helpers below */

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.passwordTextField) {
        [theTextField resignFirstResponder];
    } else if (theTextField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    return YES;
}


- (void)signIn
{
    // sign in with the user
    NSString *passwordText = self.passwordTextField.text;
    NSString *emailText = self.emailTextField.text;
    self.loginBtn.hidden = YES;
    [self.spinner startAnimating];
    dispatch_queue_t loginQueue = dispatch_queue_create("Log In", NULL);
    dispatch_async(loginQueue, ^{
        NSString *bodyData = [NSString stringWithFormat:@"email=%@&password=%@", emailText, passwordText];
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://jabys.t.proxylocal.com/users/sign_in.json?"]];
        [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [postRequest setHTTPMethod:@"POST"];
        [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:[bodyData length]]];
        
        
        NSError *error;
        NSURLResponse *response;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSData *urlData = [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response error:&error];
        NSString *serverOutput = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"%@",serverOutput);
        
        NSData* responseData = [serverOutput dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *results = responseData ? [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.signInResponse = results;
            if (results[@"auth_token"]) {
                // success
                [self afterSignIn];
            } else {
                [self displayErrors];
            }
            [self.spinner stopAnimating];
            self.loginBtn.hidden = NO;
        });
    });
}

- (void)afterSignIn
{
    NSLog(@"%@", self.signInResponse);
    // store the auth token
    NSString *authToken = self.signInResponse[@"auth_token"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:authToken forKey:@"authToken"];
    [defaults synchronize];
    NSLog(@"Auth token saved");
    
    [self performSegueWithIdentifier:@"ShowRoomsFromLoginSegue" sender:self];
}

// [TODO]
- (void)displayErrors
{
    NSString *errorCode = self.signInResponse[@"error_code"];
}




@end
