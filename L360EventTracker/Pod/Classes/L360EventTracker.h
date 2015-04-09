//
//  L360EventTracker.h
//  SafetyMap
//
//  Created by Mohammed Islam on 12/10/14.
//  Copyright (c) 2014 Life360. All rights reserved.
//

#import <Foundation/Foundation.h>

@class L360EventTracker, L360ExecutionObject;

typedef NS_ENUM(NSInteger, L360EventTrackerScope)
{
    L360EventTrackerScopeInstance, // These events will reset on app background
    L360EventTrackerScopeSession, // These events will reset on app kill
    L360EventTrackerScopeApp, // These events will only reset on app uninstall
};

typedef BOOL (^L360EventTrackerValidationBlock)(NSString *triggerEvent, L360EventTracker *tracker);
typedef void (^L360EventTrackerExecutionBlock)(NSString *triggerEvent, L360EventTracker *tracker);

static NSString *const EVENT_START_NEW_SESSION = @"startNewSession";
static NSString *const EVENT_DISPLAY_PROGRESS = @"displayProgress";
static NSString *const EVENT_HAS_DISPLAYED_PROGRESS = @"hasDisplayedProgress";
static NSString *const EVENT_CIRCLES_WITH_COMPLETED_PROGRESS = @"circlesWithCompletedProgress";
static NSString *const EVENT_DISPLAY_MESSAGE_REMINDER = @"displayMessageReminder";
static NSString *const EVENT_HAS_DISPLAYED_MESSAGE_REMINDER = @"hasDisplayedMessageReminder";
static NSString *const EVENT_ALL_PLACES_UPDATED = @"allPlacesUpdated";
static NSString *const EVENT_ALL_CIRCLES_UPDATED = @"allCirclesUpdated";
static NSString *const EVENT_START_NEW_INSTANCE = @"startNewInstance";
static NSString *const EVENT_MAP_HAS_BEEN_DISPLAYED = @"mapHasBeenDisplayed";
static NSString *const EVENT_CIRCLE_HAS_CHANGED = @"circleHasChanged";
static NSString *const EVENT_PROFILE_IMAGE_HAS_CHANGED = @"profileImageHasChanged";
static NSString *const EVENT_HAS_JUST_FINISHED_ONBOARDING = @"hasJustFinishedOnboarding";

@interface L360EventTracker : NSObject

+ (instancetype)sharedInstance;

/**
 *  Make sure to call this on every app session (when the app was in killed state and then starts)
 */
- (void)registerEvent:(NSString *)event withInitialValue:(id)initialValue andScope:(L360EventTrackerScope)scope;

#pragma mark Event Value Setters

/**
 *  This will increment the value of the event by 1 IFF it's an NSNumber and its registered.
 *  Otherwise it will not do anything
 */
- (void)triggerEvent:(NSString *)event;

/**
 *  This will set the value for this event (if it's registered) and trigger it
 */
- (void)setEvent:(NSString *)event withValue:(id)value;

#pragma mark Event Value Getters

- (NSInteger)integerValueForEvent:(NSString *)event;
- (BOOL)boolValueForEvent:(NSString *)event;
- (NSArray *)arrayValueForEvent:(NSString *)event;
- (NSDictionary *)dictionaryValueForEvent:(NSString *)event;

/**
 *  Return a copy of the list of executionObjects
 *  (but the objects within are the real objects so careful what you change!)
 */
- (NSArray *)executionObjects;

/**
 *  This will reset all the metrics to a proper logout state. As if the user just downloaded it and is fresh in the app
 */
- (void)resetEventsForLogout;

/**
 *  Register execution blocks to be evaluated and fired once for the events it listens for
 *  If an execution object exists with the same executionID, this will replace it
 *
 *  @param executionBlock   Block of code to be executed
 *  @param executionID      Id by which it can be identified for removal later if need be
 *  @param validationBlock  Block that should return a BOOL that is determined every time any of the events below is changed
 *                          TODO: I wonder if we could use NSPredicate instead so that users don't have to access the actual properties to do logic on.
 *  @param eventNames       These are a list of events by which the validationBlock will be evaluated
 *  @param keepAlive        Keeps this execution alive so it will never leave the system.
 *
 *  @return L360ExecutionObject This will return the object it added to the stack for execution.
 *
 */
- (L360ExecutionObject *)addExecutionBlock:(L360EventTrackerExecutionBlock)executionBlock
                             whenValidated:(L360EventTrackerValidationBlock)validationBlock
                           withExecutionID:(NSString *)executionID
                         listeningToEvents:(NSArray *)eventNames
                                 keepAlive:(BOOL)keepAlive;

/**
 *  This is exactly the same as above except it will be tested right away
 */
- (void)addAndRunExecutionBlock:(L360EventTrackerExecutionBlock)executionBlock
                  whenValidated:(L360EventTrackerValidationBlock)validationBlock
                withExecutionID:(NSString *)executionID
              listeningToEvents:(NSArray *)eventNames
                      keepAlive:(BOOL)keepAlive;

@end
