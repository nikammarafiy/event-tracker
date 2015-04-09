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
    L360EventTrackerScopeInstance,  // These events will reset on app background
    L360EventTrackerScopeSession,   // These events will reset on app kill
    L360EventTrackerScopeApp,       // These events will only reset on app uninstall
};

typedef BOOL (^L360EventTrackerValidationBlock)(NSString *triggerEvent, L360EventTracker *tracker);
typedef void (^L360EventTrackerExecutionBlock)(NSString *triggerEvent, L360EventTracker *tracker);

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
 *  CONCURRENCY NOTE: The triggers will execute on a serial operation Queue that runs on background threads
 *                    The evaluation blocks and execution blocks will be executed in the main thread.
 *                    If the same event is triggered simultaneously, it's ambiguous on whether the execution will run
 *                      once or multiple times even if keepAlive was no when registering the Event Execution
 */
- (void)triggerEvent:(NSString *)event;

/**
 *  This will set the value for this event (if it's registered) and trigger it
 */
- (void)setEvent:(NSString *)event withValue:(id)value;

/**
 *  This will reset all the metrics to their initially value
 */
- (void)resetEvents;

#pragma mark Event Value Getters

- (NSInteger)integerValueForEvent:(NSString *)event;
- (BOOL)boolValueForEvent:(NSString *)event;
- (NSArray *)arrayValueForEvent:(NSString *)event;
- (NSDictionary *)dictionaryValueForEvent:(NSString *)event;

#pragma mark Event Execution

/**
 *  Register execution blocks to be evaluated and fired once for the events it listens for
 *  If an execution object exists with the same executionID, this will replace it
 *
 *  @param executionBlock   Block of code to be executed (on main thread)
 *  @param executionID      Id by which it can be identified for removal later if need be
 *  @param validationBlock  Block that should return a BOOL that is determined every time any of the events below is changed (this will be executed on main thread)
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
