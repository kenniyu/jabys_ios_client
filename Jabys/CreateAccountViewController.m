//
//  CreateAccountViewController.m
//  Jabys
//
//  Created by Ken Yu on 9/27/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "CreateAccountViewController.h"
#import "RoomViewController.h"
#import "Globals.h"

@interface CreateAccountViewController ()
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) NSString *baseUrl;

@property (strong, nonatomic) NSDictionary *createAccountResponse;
@property (strong, nonatomic) NSDictionary *signInResponse;

@end

#define PASSWORD_SHIFT_Y 50
#define CONFIRM_PASSWORD_SHIFT_Y 80

#define EMAIL_BLANK @"EMAIL_BLANK"
#define EMAIL_EXISTS @"EMAIL_EXISTS"
#define EMAIL_INVALID @"EMAIL_INVALID"
#define PASSWORD_INVALID @"PASSWORD_INVALID"
#define CONFIRM_PASSWORD_MISMATCH @"CONFIRM_PASSWORD_MISMATCH"
#define CONFIRM_PASSWORD_BLANK @"CONFIRM_PASSWORD_BLANK"

@implementation CreateAccountViewController

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

    [self showDoneButton];
    
    self.scrollView.scrollEnabled = YES;
    CGSize scrollViewContentSize = CGSizeMake(320, 400);
    [self.scrollView setContentSize:scrollViewContentSize];
    
    self.baseUrl = [Globals baseUrl];
}

- (void)showDoneButton
{
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(createAccount)];
    self.navigationItem.rightBarButtonItem = anotherButton;
}

- (void)createAccount
{
    NSString *passwordText = self.passwordTextField.text;
    NSString *confirmPasswordText = self.confirmPasswordTextField.text;
    NSString *emailText = self.emailTextField.text;
    
    [self.spinner startAnimating];
    // no errors, send to server to see if OK
    dispatch_queue_t createAccountQueue = dispatch_queue_create("createAccount", NULL);
    dispatch_async(createAccountQueue, ^{
        NSString *bodyData = [NSString stringWithFormat:@"user[email]=%@&user[password]=%@&user[password_confirmation]=%@", emailText, passwordText, confirmPasswordText];
        NSString *urlString = [[NSString alloc] initWithFormat:@"%@/users.json", self.baseUrl];
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
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
            self.createAccountResponse = results;
            if ([results valueForKeyPath:@"user.id"]) {
                // success
                [self signIn];
            } else {
                [self displayErrors];
                [self.spinner stopAnimating];
            }
        });
    });
}

- (void)signIn
{
    // sign in with the user
    NSString *passwordText = self.passwordTextField.text;
    NSString *emailText = self.emailTextField.text;
    dispatch_queue_t createAccountQueue = dispatch_queue_create("createAccount", NULL);
    dispatch_async(createAccountQueue, ^{
        NSString *bodyData = [NSString stringWithFormat:@"email=%@&password=%@", emailText, passwordText];
        NSString *urlString = [[NSString alloc] initWithFormat:@"%@/users/sign_in.json", self.baseUrl];
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
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
        });
    });
}

- (void)afterSignIn
{
    NSLog(@"%@", self.signInResponse);
    // store the auth token
    NSString *authToken = self.signInResponse[@"auth_token"];
    NSString *userId = self.signInResponse[@"id"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:authToken forKey:@"authToken"];
    [defaults setObject:userId forKey:@"userId"];
    [defaults synchronize];
    NSLog(@"Auth token saved");
    
    [self performSegueWithIdentifier:@"ShowRoomsSegue" sender:self];

}

// [TODO]
- (void)displayErrors
{
    NSString *errorCode = self.signInResponse[@"error_code"];
    
    if ([errorCode isEqualToString:EMAIL_BLANK]) {
        // show error
    } else if ([errorCode isEqualToString:EMAIL_EXISTS]) {
        // show error
    } else if ([errorCode isEqualToString:EMAIL_INVALID]) {
        // show error
    } else if ([errorCode isEqualToString:PASSWORD_INVALID]) {
        // show error
    } else if ([errorCode isEqualToString:CONFIRM_PASSWORD_MISMATCH]) {
        // show error
    } else if ([errorCode isEqualToString:CONFIRM_PASSWORD_BLANK]) {
        // show error
    }
}

/* Some text field helpers below */

- (BOOL)textFieldShouldReturn:(UITextField *)targetTextField
{
    [targetTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    int movementDistance = 40; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (UIView *)getActiveTextField
{
    for (UIView *view in self.view.subviews) {
        if (view.isFirstResponder) {
            return view;
        }
    }
    return nil;
}

@end