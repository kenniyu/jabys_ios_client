//
//  ScoreboardViewController.m
//  Jabys
//
//  Created by Ken Yu on 9/30/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "ScoreboardViewController.h"

@interface ScoreboardViewController ()
@property (weak, nonatomic) IBOutlet UITableView *scoresList;
- (IBAction)closeScoreboardBtn:(UIBarButtonItem *)sender;

@end

@implementation ScoreboardViewController

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
}

// Setter
- (void)setScores:(NSMutableArray *)scores
{
    _scores = scores;
    [self.scoresList reloadData];
}

/* Table View Data Source setup */
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.scores count];
}

- (NSString *)titleForRow:(NSUInteger)row
{
    return [self.scores[row][@"name"] description];
}

- (NSString *)subtitleForRow:(NSUInteger)row
{
    return [self.scores[row][@"created_at"] description];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Score Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.textLabel.text = [self titleForRow:indexPath.row];
    cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
    
    return cell;
}
- (IBAction)closeScoreboardBtn:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];

}
@end
