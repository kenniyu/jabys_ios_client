//
//  ChatMessagesViewController.m
//  Jabys
//
//  Created by Ken Yu on 10/1/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "ChatMessagesViewController.h"
#import "ChatMessageTableViewCell.h"

@interface ChatMessagesViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@end

@implementation ChatMessagesViewController

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



#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    int padding = 10;
    
    NSDictionary *s = (NSDictionary *) [self.messages objectAtIndex:indexPath.row];
    static NSString *CellIdentifier = @"Chat Cell";
    ChatMessageTableViewCell *cell = (ChatMessageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ChatMessageTableViewCell alloc] initWithFrame:CGRectZero];
    }
    
    NSString *sender = [s objectForKey:@"sender"];
    NSString *message = [s objectForKey:@"msg"];
    NSString *time = [s objectForKey:@"time"];
    
    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:message
     attributes:@
     {
     NSFontAttributeName: [UIFont systemFontOfSize:13]
     }];
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){260, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGSize size = rect.size;
    size.width += (padding/2);
    cell.messageContentView.text = message;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.userInteractionEnabled = NO;
    UIImage *bgImage = nil;
    
    
    if ([sender isEqualToString:@"you"]) { // left aligned
        bgImage = [[UIImage imageNamed:@"orange.png"] stretchableImageWithLeftCapWidth:24  topCapHeight:15];
        [cell.messageContentView setFrame:CGRectMake(padding, padding*2, size.width, size.height)];
        [cell.bgImageView setFrame:CGRectMake( cell.messageContentView.frame.origin.x - padding/2,
                                              cell.messageContentView.frame.origin.y - padding/2,
                                              size.width+padding,
                                              size.height+padding)];
    } else {
        bgImage = [[UIImage imageNamed:@"aqua.png"] stretchableImageWithLeftCapWidth:24  topCapHeight:15];
        [cell.messageContentView setFrame:CGRectMake(320 - size.width - padding,
                                                     padding*2,
                                                     size.width,
                                                     size.height)];
        [cell.bgImageView setFrame:CGRectMake(cell.messageContentView.frame.origin.x - padding/2,
                                              cell.messageContentView.frame.origin.y - padding/2,
                                              size.width+padding,
                                              size.height+padding)];
    }
    cell.bgImageView.image = bgImage;
    cell.senderAndTimeLabel.text = [NSString stringWithFormat:@"%@ %@", sender, time];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *) indexPath {
    int padding = 10;
    NSDictionary *s = (NSDictionary *) [self.messages objectAtIndex:indexPath.row];
    NSString *message = [s objectForKey:@"msg"];
    
    NSAttributedString *attributedText =
    [[NSAttributedString alloc]
     initWithString:message
     attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:13] }];
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){260, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGSize size = rect.size;
    
    size.height += padding*2;
    CGFloat height = size.height < 65 ? 65 : size.height;
    return height;
}


@end
