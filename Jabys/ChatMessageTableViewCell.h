//
//  ChatMessageTableViewCell.h
//  Jabys
//
//  Created by Ken Yu on 10/1/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatMessageTableViewCell : UITableViewCell

@property (nonatomic,strong) UILabel *senderAndTimeLabel;
@property (nonatomic,strong) UITextView *messageContentView;
@property (nonatomic,strong) UIImageView *bgImageView;

@end
