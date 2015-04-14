//
//  ViewController.m
//  L360EventTrackerExample
//
//  Created by Mohammed Islam on 4/9/15.
//  Copyright (c) 2015 Life360. All rights reserved.
//

#import "ViewController.h"
#import "L360EventTracker.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Step 1. You have to register the events
    [self registerEventTrackerEvents];
    
    // Step 2. Add a piece of execution block to run when events are triggered
    [self registerEventTrackerExecutions];
    
    [self updateStatus];
    
    // Instead of having logic in the app delegate, just use notifications to know when the app is being backgrounded
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)appWillResignActive
{
    // Step 3. Part 2 - Trigger the event for backgrounded app
    [[L360EventTracker sharedInstance] triggerEvent:EVENT_BACKGROUND];
}

- (void)updateStatus
{
    NSInteger backgroundedCount = [[L360EventTracker sharedInstance] integerValueForEvent:EVENT_BACKGROUND];
    NSInteger buttonTapCount = [[L360EventTracker sharedInstance] integerValueForEvent:EVENT_BUTTON_PRESS];
    
    self.lblStatus.text = [NSString stringWithFormat:@"backgrounds: %li\nbuttonPresses: %li", (long)backgroundedCount, (long)buttonTapCount];
}

- (void)registerEventTrackerEvents
{
    [[L360EventTracker sharedInstance] registerEvent:EVENT_BACKGROUND withInitialValue:@0 andScope:L360EventTrackerScopeSession];
    [[L360EventTracker sharedInstance] registerEvent:EVENT_BUTTON_PRESS withInitialValue:@0 andScope:L360EventTrackerScopeSession];
}

- (void)registerEventTrackerExecutions
{
    __weak ViewController *weakSelf = self;
    
    // This will popup the alert when the instructions have been met by the user.
    [[L360EventTracker sharedInstance] addExecutionBlock:^(NSString *triggerEvent, L360EventTracker *tracker) {
        [weakSelf displaySuccessAlert];
    }
                                           whenValidated:^BOOL(NSString *triggerEvent, L360EventTracker *tracker) {
                                               NSInteger backgroundedCount = [tracker integerValueForEvent:EVENT_BACKGROUND];
                                               NSInteger buttonTapCount = [tracker integerValueForEvent:EVENT_BUTTON_PRESS];
                                               
                                               // If the last action was the button tap
                                               if ([triggerEvent isEqualToString:EVENT_BUTTON_PRESS]) {
                                                   // And it meets the criteria of counts:
                                                   /*
                                                    Tap the button
                                                    Then Background the app
                                                    Come back to the app
                                                    Tap the button again twice
                                                    EQUALS: 3 button taps and one background
                                                    */
                                                   if (backgroundedCount == 1 &&
                                                       buttonTapCount == 3)
                                                       return YES;
                                               }
                                               
                                               return NO;
                                           }
                                         withExecutionID:@"alertActionCompleted"
                                       listeningToEvents:@[EVENT_BACKGROUND, EVENT_BUTTON_PRESS]
                                               keepAlive:NO
                                     validateImmediately:NO];
    
    // And this will stay alive and regulate the order of the taps and backgrounds
    [[L360EventTracker sharedInstance] addExecutionBlock:^(NSString *triggerEvent, L360EventTracker *tracker) {
        [weakSelf regulateOrderForEvent:triggerEvent];
        
        [weakSelf updateStatus];
    }
                                           whenValidated:nil
                                         withExecutionID:@"alertActionRegulator"
                                       listeningToEvents:@[EVENT_BACKGROUND, EVENT_BUTTON_PRESS]
                                               keepAlive:YES
                                     validateImmediately:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(id)sender
{
    // Step 3. Part 1 - Trigger the event for backgrounded app
    [[L360EventTracker sharedInstance] triggerEvent:EVENT_BUTTON_PRESS];
}

- (void)displaySuccessAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You did it!"
                                                    message:@"Yay!!"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)regulateOrderForEvent:(NSString *)triggerEvent
{
    L360EventTracker *tracker = [L360EventTracker sharedInstance];
    
    NSInteger backgroundedCount = [tracker integerValueForEvent:EVENT_BACKGROUND];
    NSInteger buttonTapCount = [tracker integerValueForEvent:EVENT_BUTTON_PRESS];
    
    if ([triggerEvent isEqualToString:EVENT_BUTTON_PRESS]) {
        // If the user taps the button too many times without backgrounding, then just reset the value
        if (backgroundedCount == 1) {
            if (buttonTapCount > 3) {
                [tracker resetEvent:EVENT_BUTTON_PRESS];
            }
        } else {
            if (buttonTapCount > 1) {
                [tracker resetEvent:EVENT_BUTTON_PRESS];
            }
        }
    } else if ([triggerEvent isEqualToString:EVENT_BACKGROUND]) {
        // If the user backgrounds the app more than once or backgrounds at the wrong buttonTapCount then reset the value
        if (backgroundedCount > 1 || buttonTapCount != 1) {
            [tracker resetEvent:EVENT_BACKGROUND];
        }
    }
}

@end
