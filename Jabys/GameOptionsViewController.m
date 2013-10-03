//
//  GameOptionsViewController.m
//  Jabys
//
//  Created by Ken Yu on 10/2/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "GameOptionsViewController.h"

@interface GameOptionsViewController ()
@property (strong, nonatomic) UIViewController *controllerOne;
@property (strong, nonatomic) UIViewController *controllerTwo;
@property (strong, nonatomic) UIViewController *controllerThree;
@property (strong, nonatomic) NSArray *controllerArray;
@property (strong, nonatomic) UIViewController *currentController;
@property (strong, nonatomic) IBOutlet UIView *containerView;
- (IBAction)gameOptionsSegmentedControl:(UISegmentedControl *)sender;

@end

@implementation GameOptionsViewController

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
 
    
    self.controllerOne = [self.storyboard instantiateViewControllerWithIdentifier:@"PlayersViewController"];
    
    self.controllerTwo = [self.storyboard instantiateViewControllerWithIdentifier:@"ScoreboardViewController"];
    
    self.controllerThree = [self.storyboard instantiateViewControllerWithIdentifier:@"ChatViewController"];
    
    self.controllerArray = @[self.controllerOne, self.controllerTwo, self.controllerThree];
    
}

- (void)switchToController:(UIViewController *)newController
{
    if(newController == self.currentController)
        return;
    
    if([self.currentController isViewLoaded])
        [self.currentController.view removeFromSuperview];
    
    if(newController != nil)
        [self.containerView addSubview:newController.view];
    
    self.currentController = newController;
}


- (IBAction)gameOptionsSegmentedControl:(UISegmentedControl *)sender {
    int selectedSegmentIndex = sender.selectedSegmentIndex;
    UIViewController *newController = self.controllerArray[selectedSegmentIndex];
    [self switchToController:newController];
}
@end
