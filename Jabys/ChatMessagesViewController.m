//
//  ChatMessagesViewController.m
//  Jabys
//
//  Created by Ken Yu on 10/1/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "ChatMessagesViewController.h"
#import "Globals.h"
#import <libPusher/PTPusher.h>
#import <libPusher/PTPusherChannel.h>
#import <libPusher/PTPusherEvent.h>
#import <libPusher/PTPusherAPI.h>


@interface ChatMessagesViewController ()
@property (nonatomic, strong) NSMutableArray *messages;
@property (weak, nonatomic) IBOutlet UITextField *chatTextField;
- (IBAction)closeChatBtn:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (strong, nonatomic) NSString *baseUrl;
@property (nonatomic, strong) id client; // of NSDictionary
- (IBAction)sendMessageBtn:(UIButton *)sender;


@property (nonatomic, strong) NSString *requestedRoomId;
@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSString *userId;

// active field
@property (strong, nonatomic) UIView *activeField;
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
    self.baseUrl = [Globals baseUrl];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    // get the room that we requested for
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.requestedRoomId = [defaults objectForKey:@"requestedRoomId"];
    self.authToken = [defaults objectForKey:@"authToken"];
    self.userId = [defaults objectForKey:@"userId"];
    
    [self getAllMessages];
    
    
    // pusher shit
    _client = [PTPusher pusherWithKey:@PUSHER_KEY delegate:self encrypted:YES];
    
    NSString *channelName = [[NSString alloc] initWithFormat: @"room_%@_channel", self.requestedRoomId];
    
    PTPusherChannel *channel = [_client subscribeToChannelNamed:channelName];
    [channel bindToEventNamed:@"update_messages" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        [self updateMessages:channelEvent.data];
    }];
    
    [self registerForKeyboardNotifications];

}

- (void)updateMessages:(NSDictionary *)channelData
{
    NSLog(@"%@", channelData);
    NSMutableArray *messages = channelData[@"messages"];
    self.messages = messages;
}

#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.messages count];
}

- (NSString *)titleForRow:(NSUInteger)row
{
    NSString *message = [self.messages[row][@"message"] description];
    NSString *userName = [self.messages[row][@"name"] description];
    NSString *chatCellContents = [[NSString alloc] initWithFormat:@"%@: %@", userName, message];
    return chatCellContents;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        static NSString *CellIdentifier = @"Chat Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.textLabel.text = [self titleForRow:indexPath.row];
    return cell;
    
}

- (void)setMessages:(NSMutableArray *)messages
{
    _messages = messages;
    [self.chatTableView reloadData];
    if (self.messages.count > 0) {
    [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }

}

- (IBAction)closeChatBtn:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)getAllMessages
{
    dispatch_queue_t requestAllMessages = dispatch_queue_create("Request Get All Messages", NULL);
    dispatch_async(requestAllMessages, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSString *urlString = [[NSString alloc] initWithFormat: @"%@/api/rooms/messages.json", self.baseUrl];
        NSString *url = [NSString stringWithFormat:@"%@?room_id=%@&auth_token=%@", urlString, self.requestedRoomId, self.authToken];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSMutableArray *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.messages = results;
        });
    });
}

- (void)sendMessage:(NSString *)message
{
    dispatch_queue_t requestSendMessage = dispatch_queue_create("Request Send Message", NULL);
    dispatch_async(requestSendMessage, ^{
        
        NSString *bodyData = [NSString stringWithFormat:@"room_id=%@&auth_token=%@&message=%@", self.requestedRoomId, self.authToken, message];
        NSString *urlString = [[NSString alloc] initWithFormat:@"%@/api/rooms/send_message.json", self.baseUrl];
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
    });
}

/* Some text field helpers below */

- (BOOL)textFieldShouldReturn:(UITextField *)targetTextField
{
    //[targetTextField resignFirstResponder];
    // send the message, clear the input
    [self sendMessage:targetTextField.text];
    targetTextField.text = @"";
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}


/*
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    CGRect kbRawRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect scrollViewFrame = [self.chatTableView.window convertRect:self.scrollView.frame fromView:self.scrollView.superview];
    
    // Calculate the area that is covered by the keyboard
    CGRect coveredFrame = CGRectIntersection(scrollViewFrame, kbRawRect);
    // Convert again to window coordinates to take rotations into account
    coveredFrame = [self.chatTableView.window convertRect:self.chatTableView.frame fromView:self.chatTableView.superview];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, coveredFrame.size.height, 0.0);
    self.chatTableView.contentInset = contentInsets;
    self.chatTableView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    //UIView *activeField = [self getActiveTextField];
    CGRect activeFieldRect = [self.activeField convertRect:self.activeField.bounds toView:self.chatTableView];
    [self.chatTableView scrollRectToVisible:activeFieldRect animated:YES];
}

- (UIView *)getActiveTextField
{
    for (UIView *view in self.view.subviews) {
        if (view.isFirstResponder) {
            return view;
        }
    }
    return nil;
}*/

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}


- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    /*
     CGRect bkgndRect = self.activeField.superview.frame;
    bkgndRect.size.height += kbSize.height;
    NSLog(@"bkgndRect %f", bkgndRect.size.height);
    NSLog(@"kbSize %f", kbSize.height);

    [self.activeField.superview setFrame:bkgndRect];
    [self.chatTableView setContentOffset:CGPointMake(0.0, self.activeField.frame.origin.y+kbSize.height) animated:YES];*/
    NSLog(@"kbSize %f", kbSize.height);

    CGRect bounds = [self.chatTableView bounds];
    NSLog(@"origin.y %f", bounds.origin.y);
    self.chatTableView.frame = CGRectMake(0,
                                          65,
                                          bounds.size.width,
                                          bounds.size.height - kbSize.height);
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.chatTableView.contentInset = contentInsets;
    self.chatTableView.scrollIndicatorInsets = contentInsets;
}

- (void)dismissKeyboard {
    [self.chatTextField resignFirstResponder];
}


- (IBAction)sendMessageBtn:(UIButton *)sender {
    [self sendMessage:self.chatTextField.text];
    self.chatTextField.text = @"";
}
@end
