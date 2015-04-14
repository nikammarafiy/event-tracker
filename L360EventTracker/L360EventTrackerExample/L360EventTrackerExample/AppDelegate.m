//
//  AppDelegate.m
//  L360EventTrackerExample
//
//  Created by Mohammed Islam on 4/9/15.
//  Copyright (c) 2015 Life360. All rights reserved.
//

#import "AppDelegate.h"
#import "L360EventTracker.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Step 1. You have to register the events
    [[L360EventTracker sharedInstance] registerEvent:@"backgroundedCount" withInitialValue:@0 andScope:L360EventTrackerScopeSession];
    [[L360EventTracker sharedInstance] registerEvent:@"buttonTapCount" withInitialValue:@0 andScope:L360EventTrackerScopeSession];
    
    // Step 2. Add a piece of execution block to run when events are triggered
    [[L360EventTracker sharedInstance] addExecutionBlock:^(NSString *triggerEvent, L360EventTracker *tracker) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You did it!"
                                                        message:@"Yay!!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
                                           whenValidated:^BOOL(NSString *triggerEvent, L360EventTracker *tracker) {
                                               NSInteger backgroundedCount = [tracker integerValueForEvent:@"backgroundedCount"];
                                               NSInteger buttonTapCount = [tracker integerValueForEvent:@"buttonTapCount"];
                                               
                                               // If the last action was the button tap
                                               if ([triggerEvent isEqualToString:@"buttonTapCount"]) {
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
                                       listeningToEvents:@[@"backgroundedCount", @"buttonTapCount"]
                                               keepAlive:NO
                                     validateImmediately:NO];
    
    // And this will stay alive and regulate the order of the taps and backgrounds
    [[L360EventTracker sharedInstance] addExecutionBlock:^(NSString *triggerEvent, L360EventTracker *tracker) {
        NSInteger backgroundedCount = [tracker integerValueForEvent:@"backgroundedCount"];
        NSInteger buttonTapCount = [tracker integerValueForEvent:@"buttonTapCount"];
        
        NSLog(@"backgrounded: %i, button tapped: %i", backgroundedCount, buttonTapCount);
        
        if ([triggerEvent isEqualToString:@"buttonTapCount"]) {
            // If the user taps the button too many times without backgrounding, then just reset the value
            if (backgroundedCount == 1) {
                if (buttonTapCount > 3) {
                    [tracker resetEvent:@"buttonTapCount"];
                }
            } else {
                if (buttonTapCount > 1) {
                    [tracker resetEvent:@"buttonTapCount"];
                }
            }
        } else if ([triggerEvent isEqualToString:@"backgroundedCount"]) {
            // If the user backgrounds the app more than once or backgrounds at the wrong buttonTapCount then reset the value
            if (backgroundedCount > 1 || buttonTapCount != 1) {
                [tracker resetEvent:@"backgroundedCount"];
            }
        }
    }
                                           whenValidated:nil
                                         withExecutionID:@"alertActionRegulator"
                                       listeningToEvents:@[@"backgroundedCount", @"buttonTapCount"]
                                               keepAlive:YES
                                     validateImmediately:NO];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Step 3. Trigger the event
    [[L360EventTracker sharedInstance] triggerEvent:@"backgroundedCount"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
