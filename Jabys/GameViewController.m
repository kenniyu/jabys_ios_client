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
/* Pusher shit */
@property (nonatomic, strong) id client; // of NSDictionary


/* our NSUserDefaults shit */
@property (nonatomic, strong) NSString *requestedRoomId;
@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSString *userId;

/* Targets and outlets */
- (IBAction)leaveGameBtn:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIButton *startGameBtn;
- (IBAction)startGameBtn:(UIButton *)sender;
- (IBAction)showPlayers:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

/* Cards shit */
@property (strong, nonatomic) NSMutableArray *myCards;
@property (strong, nonatomic) NSMutableDictionary *otherPlayerCards;
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
- (void)viewWillDisappear:(BOOL)animated
{
    [_client disconnect];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // get the room that we requested for
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.requestedRoomId = [defaults objectForKey:@"requestedRoomId"];
    self.authToken = [defaults objectForKey:@"authToken"];
    self.userId = [defaults objectForKey:@"userId"];

    

    // pusher shit
    _client = [PTPusher pusherWithKey:@PUSHER_KEY delegate:self encrypted:YES];
    NSString *channelName = [[NSString alloc] initWithFormat: @"room_%@_channel", self.requestedRoomId];
    
    PTPusherChannel *channel = [_client subscribeToChannelNamed:channelName];
    [channel bindToEventNamed:@"update_start_game_btn" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        [self updateStartGameBtn:channelEvent.data];
    }];
    [channel bindToEventNamed:@"player_join" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
    }];
    [channel bindToEventNamed:@"player_leave" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
    }];
    [channel bindToEventNamed:@"update_hand" handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        [self updateHand:channelEvent.data];
    }];

    
    
    
    /* Hide the button */
    self.startGameBtn.hidden = YES;
    
    // make a request to server to see if we can join
    [self joinRoom];
}

- (void)refreshHostStatus
{
    dispatch_queue_t refreshHostStatus = dispatch_queue_create("Request Get Host Status", NULL);
    dispatch_async(refreshHostStatus, ^{
        [NSThread sleepForTimeInterval:1];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSString *baseUrl = @"http://jabys.t.proxylocal.com/api/rooms/refresh_host.json";
        NSString *url = [NSString stringWithFormat:@"%@?room_id=%@&auth_token=%@", baseUrl, self.requestedRoomId, self.authToken];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
    if ([results[@"status"] isEqualToString:@"success"]) {
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

- (void)leaveGame
{
    // make a request to leave the game
    dispatch_queue_t requestLeaveGame = dispatch_queue_create("Request Leave Game", NULL);
    dispatch_async(requestLeaveGame, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        NSString *baseUrl = @"http://jabys.t.proxylocal.com/api/rooms/leave.json";
        NSString *url = [NSString stringWithFormat:@"%@?room_id=%@&auth_token=%@", baseUrl, self.requestedRoomId, self.authToken];
        url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData *jsonData = [[NSString stringWithContentsOfURL:[NSURL URLWithString:url] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSMutableDictionary *results = jsonData ? [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleLeaveGame:results];
        });
    });
}

- (void)handleLeaveGame:(NSMutableDictionary *)results
{
    // navigate back to room list if success
    if ([results[@"status"] isEqualToString:@"success"]) {
         [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)updateStartGameBtn:(NSDictionary *)channelData
{
    NSString *userId = [self.userId description];
    NSString *hostId = [channelData[@"host_id"] description];
    NSString *enoughPlayers = [channelData[@"has_enough_players"] description];
    
    BOOL isHost = [hostId isEqualToString:userId];
    BOOL hasEnoughPlayers = [enoughPlayers isEqualToString:@"1"];
    if ([enoughPlayers isEqualToString:@"1"]) {
        hasEnoughPlayers = YES;
        NSLog(@"%@", @"Has enough players");
    }
    
    NSLog(@"my user id = %@ and host id = %@ and desc of enough players = %@ and hasEnoughPlayers = %hhd", userId, hostId, enoughPlayers, hasEnoughPlayers);
    
    self.startGameBtn.hidden = !isHost || !hasEnoughPlayers;
}

- (IBAction)leaveGameBtn:(UIButton *)sender {
    [self leaveGame];
}

- (IBAction)startGameBtn:(UIButton *)sender {
    // when this is clicked, send the server start game message
    // server will need to sanity check if this is the proper host
    [self startGame];
}

- (IBAction)showPlayers:(UIButton *)sender {
    // when the player icon is clicked, show modal of players
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UITabBarController *controller = (UITabBarController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"GameDetails"];
    [self presentViewController:controller animated:YES completion: nil];
}

- (void)startGame{
    // make a request to start the game
    dispatch_queue_t requestStartGame = dispatch_queue_create("Request Start Game", NULL);
    dispatch_async(requestStartGame, ^{
        NSString *bodyData = [NSString stringWithFormat:@"auth_token=%@&room_id=%@", self.authToken, self.requestedRoomId];
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://jabys.t.proxylocal.com/api/rooms/start_game.json?"]];
        [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [postRequest setHTTPMethod:@"POST"];
        [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:[bodyData length]]];
        
        
        NSError *error;
        NSURLResponse *response;
        [self.spinner startAnimating];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSData *urlData = [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response error:&error];
        NSString *serverOutput = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"%@",serverOutput);
        
        NSData* responseData = [serverOutput dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *results = responseData ? [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves error:&error] : nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleStartGame:results];
            [self.spinner stopAnimating];
        });
    });
}

- (void)handleStartGame:(NSDictionary *)results
{
    if ([results[@"status"] isEqualToString:@"success"]) {
        self.startGameBtn.hidden = YES;
    }
}

- (void)updateHand:(NSDictionary *)channelData
{
    NSLog(@"%@", channelData);
    NSString *playerId = [channelData[@"player_id"] description];
    if ([playerId isEqualToString:self.userId]) {
        // these are my cards
        self.myCards = channelData[@"cards"];
    } else {
        // these are not my cards
        int numCards = [[channelData[@"cards"] componentsSeparatedByString:@","] count];
        [self.otherPlayerCards setObject:@(numCards) forKey:playerId];
    }
}

- (NSMutableDictionary *)otherPlayerCards
{
    if (!_otherPlayerCards) {
        _otherPlayerCards = [[NSMutableDictionary alloc] init];
    }
    return _otherPlayerCards;
}
@end
