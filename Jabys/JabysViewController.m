//
//  JabysViewController.m
//  Jabys
//
//  Created by Ken Yu on 9/27/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "JabysViewController.h"
#import "RoomViewController.h"

@interface JabysViewController ()
@property (nonatomic, strong) id client; // of NSDictionary
@property (nonatomic, strong) NSString *authToken;
@end

@implementation JabysViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // store the auth token
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.authToken = [defaults objectForKey:@"authToken"];
    
    if (self.authToken) {
        [self performSegueWithIdentifier:@"Skip To Rooms" sender:self];
    }
}

// We want to hide the nav bar on the first page
- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

@end
