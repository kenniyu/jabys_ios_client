//
//  LoginViewController.h
//  Jabys
//
//  Created by Ken Yu on 9/28/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end
