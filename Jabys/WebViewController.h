//
//  WebViewController.h
//  Jabys
//
//  Created by Ken Yu on 9/27/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController
@property (nonatomic, retain) NSURL *loadURL;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end
