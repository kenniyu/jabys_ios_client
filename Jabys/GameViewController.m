//
//  GameViewController.m
//  Jabys
//
//  Created by Ken Yu on 9/28/13.
//  Copyright (c) 2013 Ken Yu. All rights reserved.
//

#import "GameViewController.h"
#import <libPusher/PTPusher.h>
#import <libPusher/PTPusherChannel.h>
#import <libPusher/PTPusherEvent.h>
#import <libPusher/PTPusherAPI.h>

@interface GameViewController ()
@property (nonatomic, strong) id client; // of NSDictionary
@property (nonatomic, strong) NSString *requestedRoomId;
@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSMutableArray *players;
@property (weak, nonatomic) IBOutlet UITableView *playersList;

@end

@implementation GameViewController

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
    
    // get the room that we requested for
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.requestedRoomId = [defaults objectForKey:@"requestedRoomId"];
    self.authToken = [defaults objectForKey:@"authToken"];

    
    // make a request to server to see if we can join
    [self joinRoom];
    
    // pusher shit
    _client = [PTPusher pusherWithKey:@PUSHER_KEY delegate:self encrypted:YES];
    NSString *channelName = [[NSString alloc] initWithFormat: @"room_%@_channel", self.requestedRoomId];
    
    PTPusherChannel *channel = [_client subscribeToChannelNamed:channelName];
    [channel bindToEventNamed:@"show_start_btn" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        NSLog(@"Message received: %@", [channelEvent.data description]);
        [self showStartBtn:channelEvent.data];
    }];
    [channel bindToEventNamed:@"player_join" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        NSLog(@"Message received: %@", [channelEvent.data description]);
        [self getAllPlayers];
    }];
    [channel bindToEventNamed:@"player_leave" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        NSLog(@"Message received: %@", [channelEvent.data description]);
        [self getAllPlayers];
    }];
}

- (void)getAllPlayers
{
    // make a request for all players in the room
    dispatch_queue_t requestGetAllPlayers = dispatch_queue_create("Request Get All Players", NULL);
    dispatch_async(requestGetAllPlayers, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSString *baseUrl = @"http://jabys.t.proxylocal.com/api/rooms/all_players.json";
        NSString *url = [NSString stringWithFormat:@"%@?room_id=%@&auth_token=%@", baseUrl, self.requestedRoomId, self.authToken];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSMutableArray *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.players = results;
            [self.playersList reloadData];
        });
    });
}

- (void)setRoomId:(int)roomId
{
    _roomId = roomId;
}

- (void)joinRoom
{
    // join room with requestedRoomId
    dispatch_queue_t requestJoinRoomQueue = dispatch_queue_create("Request Join Room", NULL);
    dispatch_async(requestJoinRoomQueue, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        NSString *baseUrl = @"http://jabys.t.proxylocal.com/api/rooms/join.json";
        NSString *url = [NSString stringWithFormat:@"%@?room_id=%@&auth_token=%@", baseUrl, self.requestedRoomId, self.authToken];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSMutableDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleJoinRoom:results];
        });
    });
    
}

- (void)handleJoinRoom:(NSMutableDictionary *)results
{
    NSLog(@"%@", results);
    if ([results[@"status"] isEqualToString:@"success"]) {
        [self getAllPlayers];
        // append this room id to the array of rooms this user is in
        // then store in the user defaults so RoomViewController can access it
        // when displaying table of rooms, because we want to put a checkmark
        // for cells that indicate rooms that the user is in
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *currentRoomIdsStore = [defaults objectForKey:@"currentRoomIds"];
        NSMutableArray *currentRoomIds = [currentRoomIdsStore mutableCopy];
        
        if (!currentRoomIds) {
            currentRoomIds = [[NSMutableArray alloc] init];
        }
        
        if (![currentRoomIds containsObject:self.requestedRoomId]) {
            [currentRoomIds addObject:self.requestedRoomId];
        }
        
        [defaults setObject:currentRoomIds forKey:@"currentRoomIds"];
        [defaults synchronize];
        
    } else {
        
    }
}

- (void)showStartBtn:(NSDictionary *)channelData
{
    NSLog(@"%@", channelData);
}

/* Table View Data Source setup */
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.players count];
}

- (NSString *)titleForRow:(NSUInteger)row
{
    NSString *email = [self.players[row][@"email"] description];
    NSArray *array = [email componentsSeparatedByString:@"@"];
    return array[0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Player";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.textLabel.text = [self titleForRow:indexPath.row];
    return cell;
}
@end
