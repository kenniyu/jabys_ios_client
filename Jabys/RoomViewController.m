//
//  RoomViewController.m
//  Jabys
//
//  Created by Ken Yu on 9/28/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "RoomViewController.h"
#import <libPusher/PTPusher.h>
#import <libPusher/PTPusherChannel.h>
#import <libPusher/PTPusherEvent.h>
#import <libPusher/PTPusherAPI.h>
#import "Globals.h"


@interface RoomViewController ()
@property (nonatomic, strong) id client; // of NSDictionary
@property (weak, nonatomic) IBOutlet UITableView *roomList;
@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic, weak) NSString *baseUrl;

@end

@implementation RoomViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSString *)authToken
{
    return _authToken;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   	// Do any additional setup after loading the view.
    
    self.baseUrl = [Globals baseUrl];

    // load the auth token
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.authToken = [defaults objectForKey:@"authToken"];
    
    [self.roomList registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Room"];
    [self requestRooms];
    
    // pusher shit
    _client = [PTPusher pusherWithKey:@PUSHER_KEY delegate:self encrypted:YES];
    
    // subscribe
    PTPusherChannel *channel = [_client subscribeToChannelNamed:@"rooms_channel"];
    [channel bindToEventNamed:@"room_created" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        [self.rooms addObject:@{@"name": channelEvent.data[@"name"]}];
        [self.roomList reloadData];
    }];
    
    // make refresh control, since we dont have a table view controller
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshRooms) forControlEvents:UIControlEventValueChanged];
    [self.roomList addSubview:self.refreshControl];
    
    // hide the navigation back button
    [self.navigationItem setHidesBackButton:YES];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self requestRooms];
}

// Makes the request for getting the room data. This fetches all rooms
- (NSMutableArray *)getRoomData
{
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@/rooms.json", self.baseUrl];
    NSString *url = [NSString stringWithFormat:@"%@?auth_token=%@", urlString, self.authToken];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSMutableArray *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
    return results;
}

// Table View calls this when pulled down
- (void)refreshRooms
{
    [self.refreshControl beginRefreshing];
    dispatch_queue_t q = dispatch_queue_create("Room List Loading Queue", NULL);
    dispatch_async(q, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSMutableArray *results = [self getRoomData];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rooms = results;
            [self.refreshControl endRefreshing];
        });
    });
}

// App calls this when Pusher sends a message for new room
- (void)requestRooms
{
    dispatch_queue_t requestRoomsQueue = dispatch_queue_create("Request Rooms", NULL);
    dispatch_async(requestRoomsQueue, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSMutableArray *results = [self getRoomData];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rooms = results;
        });
    });
}

// When a room is selected, segue, so prepare first
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.roomList indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Game Segue"]) {
                //[segue.destinationViewController performSelector:@selector(setImageUrl:) withObject:url];
                [segue.destinationViewController setTitle:[self titleForRow:indexPath.row]];
                
                NSString *requestedRoomId = [self roomIdForRow:indexPath.row];
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:requestedRoomId forKey:@"requestedRoomId"];
                [defaults synchronize];
            }
        }
    }
}

// Setter
- (void)setRooms:(NSMutableArray *)rooms
{
    _rooms = rooms;
    [self.roomList reloadData];
}

/* Table View Data Source setup */
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.rooms count];
}

- (NSString *)titleForRow:(NSUInteger)row
{
    return [self.rooms[row][@"name"] description];
}

- (NSString *)subtitleForRow:(NSUInteger)row
{
    return [self.rooms[row][@"created_at"] description];
}

- (NSString *)roomIdForRow:(NSUInteger)row
{
    return [self.rooms[row][@"id"] description];
}

- (BOOL)isInRoom:(NSUInteger)row
{
    NSString *status = [self.rooms[row][@"status"] description];
    BOOL isInRoom = [status isEqualToString:@"1"];
    return isInRoom;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Game Room";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.textLabel.text = [self titleForRow:indexPath.row];
    cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
    
    if ([self isInRoom:indexPath.row]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

@end
