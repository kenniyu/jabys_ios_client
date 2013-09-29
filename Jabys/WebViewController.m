//
//  WebViewController.m
//  Jabys
//
//  Created by Ken Yu on 9/27/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()
- (IBAction)closeWebView:(UIButton *)sender;

@end

@implementation WebViewController

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
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:self.loadURL];
    [self.webView loadRequest:urlRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)closeWebView:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
