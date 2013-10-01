//
//  PlayersViewController.m
//  
//
//  Created by Ken Yu on 9/30/13.
//
//

#import "PlayersViewController.h"
#import <libPusher/PTPusher.h>
#import <libPusher/PTPusherChannel.h>
#import <libPusher/PTPusherEvent.h>
#import <libPusher/PTPusherAPI.h>
#import "Globals.h"


@interface PlayersViewController ()
/* Pusher shit */
@property (nonatomic, strong) id client; // of NSDictionary

@property (weak, nonatomic) IBOutlet UITableView *playersList;
- (IBAction)closePlayersBtn:(UIBarButtonItem *)sender;

/* our NSUserDefaults shit */
@property (nonatomic, strong) NSString *requestedRoomId;
@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSString *userId;
@property (weak, nonatomic) NSString *baseUrl;

@end

@implementation PlayersViewController

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
    
    // get the room that we requested for
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.requestedRoomId = [defaults objectForKey:@"requestedRoomId"];
    self.authToken = [defaults objectForKey:@"authToken"];
    self.userId = [defaults objectForKey:@"userId"];
    
    [self getAllPlayers];
    
    _client = [PTPusher pusherWithKey:@PUSHER_KEY delegate:self encrypted:YES];
    NSString *channelName = [[NSString alloc] initWithFormat: @"room_%@_channel", self.requestedRoomId];
    
    PTPusherChannel *channel = [_client subscribeToChannelNamed:channelName];
    [channel bindToEventNamed:@"player_join" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        [self getAllPlayers];
    }];
    [channel bindToEventNamed:@"player_leave" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        [self getAllPlayers];
    }];
}

// Setter
- (void)setPlayers:(NSMutableArray *)players
{
    _players = players;
    [self.playersList reloadData];
}

- (void)getAllPlayers
{
    // make a request for all players in the room
    dispatch_queue_t requestGetAllPlayers = dispatch_queue_create("Request Get All Players", NULL);
    dispatch_async(requestGetAllPlayers, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSString *urlString = [[NSString alloc] initWithFormat: @"%@/api/rooms/all_players.json", self.baseUrl];
        NSString *url = [NSString stringWithFormat:@"%@?room_id=%@&auth_token=%@", urlString, self.requestedRoomId, self.authToken];
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

/* Table View Data Source setup */
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.players count];
}

- (NSString *)titleForRow:(NSUInteger)row
{
    return [self.players[row][@"name"] description];
}

- (NSString *)subtitleForRow:(NSUInteger)row
{
    return [self.players[row][@"subtitle"] description];
}

- (UIColor *)colorForRow:(NSUInteger)row
{
    NSString *userId = [self.players[row][@"id"] description];
    NSString *myUserId = [self.userId description];
    if ([userId isEqualToString:myUserId]) {
        return [UIColor orangeColor];
    } else {
        return [UIColor blackColor];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Player Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    cell.textLabel.text = [self titleForRow:indexPath.row];
    cell.detailTextLabel.text = [self subtitleForRow:indexPath.row];
    cell.textLabel.textColor = [self colorForRow:indexPath.row];
    return cell;
}

- (IBAction)closePlayersBtn:(UIBarButtonItem *)sender {
    [_client disconnect];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
