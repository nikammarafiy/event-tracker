//
//  L360EventTracker.m
//  SafetyMap
//
//  Created by Mohammed Islam on 12/10/14.
//  Copyright (c) 2014 Life360. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L360EventTracker.h"
#import "L360ExecutionObject.h"
#import "L360EventObject.h"

static NSString * const keyPrefix = @"kL360EventTracker";
@interface L360EventTracker ()
{
    NSMutableArray *_eventObjects;
    NSOperationQueue *_serialOperationQueue;
}

@property (nonatomic, strong) NSMutableArray *executionObjects;

@end

@implementation L360EventTracker

#pragma mark -
#pragma mark Initialization

+ (instancetype)sharedInstance
{
    static L360EventTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _executionObjects = [NSMutableArray array];
        _eventObjects = [NSMutableArray array];
        _serialOperationQueue = [[NSOperationQueue alloc] init];
        _serialOperationQueue.maxConcurrentOperationCount = 1; // This turns it into a serial queue
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerEvent:(NSString *)event withInitialValue:(id)initialValue andScope:(L360EventTrackerScope)scope
{
    // First check if this is a duplicate event being registered
    // If it does exist then return from this method
    if ([self eventObjectForEvent:event]) {
        return;
    }
    
    L360EventObject *eventObject = [[L360EventObject alloc] init];
    eventObject.event = event;
    eventObject.initialValue = initialValue;
    eventObject.value = initialValue;
    eventObject.scope = scope;
    
    // If it matches any of the scopes below, add it and also do the inital setup for that scope
    // Otherwise don't add this to the list if the user gave an undefined scope value
    switch (scope) {
        case L360EventTrackerScopeInstance:
            [_eventObjects addObject:eventObject];
            break;
            
        case L360EventTrackerScopeSession:
            [_eventObjects addObject:eventObject];
            break;
            
        case L360EventTrackerScopeApp:
        {
            [_eventObjects addObject:eventObject];
            // Initialize the userDefaults
            [[NSUserDefaults standardUserDefaults] registerDefaults:@{[keyPrefix stringByAppendingString:event] : initialValue}];
            
            break;
        }
            
        default:
            break;
    }
}

- (L360EventObject *)eventObjectForEvent:(NSString *)event
{
    for (L360EventObject *existingEventObject in _eventObjects) {
        if ([existingEventObject.event isEqualToString:event]) {
            return existingEventObject;
        }
    }
    
    return nil;
}

- (void)eventObjectDidChange:(L360EventObject *)eventObject
{
    // See if we need to execute anything that's listening on this event
    // First we need to find all the executionObjects that are listening to this device
    // TODO: Later maybe this can be optimized into a hash table or something. But right now this piece of code doesn't happen often enough to warrant it
    NSMutableArray *objectsToValidate = [NSMutableArray array];
    
    [_executionObjects enumerateObjectsUsingBlock:^(L360ExecutionObject *executionObject, NSUInteger idx, BOOL *stop) {
        if ([executionObject.triggerEvents containsObject:eventObject.event]) {
            [objectsToValidate addObject:executionObject];
        }
    }];
    
    if (objectsToValidate.count == 0) {
        return;
    }
    
    // Now validate and execute every block that passes validation
    // Also if they pass validation, remove them from the _executionObjects
    [objectsToValidate enumerateObjectsUsingBlock:^(L360ExecutionObject *executionObject, NSUInteger idx, BOOL *stop) {
        [self validateAndExecuteObject:executionObject forEvent:eventObject.event];
    }];
}

#pragma mark Event Value Getters

- (NSInteger)integerValueForEvent:(NSString *)event
{
    L360EventObject *eventObject = [self eventObjectForEvent:event];
    
    if (eventObject &&
        [eventObject.value isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)eventObject.value).integerValue;
    }
    
    return 0;
}

- (BOOL)boolValueForEvent:(NSString *)event
{
    L360EventObject *eventObject = [self eventObjectForEvent:event];
    
    if (eventObject &&
        [eventObject.value isKindOfClass:[NSNumber class]]) {
        return ((NSNumber *)eventObject.value).boolValue;
    }
    
    return NO;
}

- (NSArray *)arrayValueForEvent:(NSString *)event
{
    L360EventObject *eventObject = [self eventObjectForEvent:event];
    
    if (eventObject &&
        [eventObject.value isKindOfClass:[NSArray class]]) {
        return (NSArray *)eventObject.value;
    }
    
    return nil;
}

- (NSDictionary *)dictionaryValueForEvent:(NSString *)event
{
    L360EventObject *eventObject = [self eventObjectForEvent:event];
    
    if (eventObject &&
        [eventObject.value isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)eventObject.value;
    }
    
    return nil;
}

#pragma mark Event Value Setters

- (void)triggerEvent:(NSString *)event
{
    // Add the trigger to a serial operation queue to run on another thread
    // This is necessary because the main flow of logic (and it could get expensive) is run
    // On this calling thread and it could be the main thread and halt animations and graphics
    // While this is running.
    __weak L360EventTracker *weakSelf = self;
    [_serialOperationQueue addOperationWithBlock:^{
        L360EventObject *eventObject = [weakSelf eventObjectForEvent:event];
        
        if (eventObject &&
            [eventObject.value isKindOfClass:[NSNumber class]]) {
            eventObject.value = @(((NSNumber *)eventObject.value).integerValue + 1);
            
            // If event's scope is app level, update userdefaults
            if (eventObject.scope == L360EventTrackerScopeApp) {
                [[NSUserDefaults standardUserDefaults] setObject:eventObject.value
                                                          forKey:[keyPrefix stringByAppendingString:eventObject.event]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf eventObjectDidChange:eventObject];
        }
    }];
}

- (void)setEvent:(NSString *)event withValue:(id)value
{
    // Add the trigger to a serial operation queue to run on another thread
    // This is necessary because the main flow of logic (and it could get expensive) is run
    // On this calling thread and it could be the main thread and halt animations and graphics
    // While this is running.
    __weak L360EventTracker *weakSelf = self;
    [_serialOperationQueue addOperationWithBlock:^{
        L360EventObject *eventObject = [weakSelf eventObjectForEvent:event];
        
        if (eventObject) {
            eventObject.value = value;
            
            // If event's scope is app level, update userdefaults
            if (eventObject.scope == L360EventTrackerScopeApp) {
                [[NSUserDefaults standardUserDefaults] setObject:eventObject.value
                                                          forKey:[keyPrefix stringByAppendingString:eventObject.event]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf eventObjectDidChange:eventObject];
        }
    }];
}

- (void)resetEvents
{
    // Need to reset the Instance scoped events
    // Don't trigger the event for this change of value though
    for (L360EventObject *eventObject in _eventObjects) {
        eventObject.value = eventObject.initialValue;
        
        // If event's scope is app level, update userdefaults
        if (eventObject.scope == L360EventTrackerScopeApp) {
            [[NSUserDefaults standardUserDefaults] setObject:eventObject.value
                                                      forKey:[keyPrefix stringByAppendingString:eventObject.event]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)resetEvent:(NSString *)event
{
    L360EventObject *eventObject = [self eventObjectForEvent:event];
    
    if (eventObject) {
        eventObject.value = eventObject.initialValue;
        
        // If event's scope is app level, update userdefaults
        if (eventObject.scope == L360EventTrackerScopeApp) {
            [[NSUserDefaults standardUserDefaults] setObject:eventObject.value
                                                      forKey:[keyPrefix stringByAppendingString:eventObject.event]];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

#pragma mark -
#pragma mark Event Execution

- (void)addExecutionBlock:(L360EventTrackerExecutionBlock)executionBlock
            whenValidated:(L360EventTrackerValidationBlock)validationBlock
          withExecutionID:(NSString *)executionID
        listeningToEvents:(NSArray *)eventNames
                keepAlive:(BOOL)keepAlive
      validateImmediately:(BOOL)validateImmediately
{
    if (eventNames.count == 0 ||
        executionBlock == nil) {
        return;
    }
    
    // See if there are other execution objects with the same id already in the stack. If so, then just replace it with this one
    __block L360ExecutionObject *executionObject = nil;
    
    [_executionObjects enumerateObjectsUsingBlock:^(L360ExecutionObject *existingExecutionObject, NSUInteger idx, BOOL *stop) {
        if ([executionID isEqualToString:existingExecutionObject.executionID]) {
            executionObject = existingExecutionObject;
            *stop = YES;
        }
    }];
    
    if (!executionObject) {
        executionObject = [[L360ExecutionObject alloc] init];
    }
    
    executionObject.executionID = executionID;
    executionObject.executionBlock = executionBlock;
    executionObject.validationBlock = validationBlock;
    executionObject.triggerEvents = eventNames;
    executionObject.keepAlive = keepAlive;
    
    [_executionObjects addObject:executionObject];
    
    // Validate and execute the object if requested to run immediately
    if (validateImmediately) {
        // This is necessary because the main flow of logic (and it could get expensive) is run
        // On this calling thread and it could be the main thread and halt animations and graphics
        // While this is running.
        __weak L360EventTracker *weakSelf = self;
        [_serialOperationQueue addOperationWithBlock:^{
            [weakSelf validateAndExecuteObject:executionObject forEvent:eventNames.firstObject];
        }];
    }
}

#pragma mark Private Helpers

- (void)evaluateObjectsForEvent:(NSString *)eventName
{
    // First we need to find all the executionObjects that are listening to this device
    // TODO: Later maybe this can be optimized into a hash table or something. But right now this piece of code doesn't happen often enough to warrant it
    NSMutableArray *objectsToValidate = [NSMutableArray array];
    
    [_executionObjects enumerateObjectsUsingBlock:^(L360ExecutionObject *executionObject, NSUInteger idx, BOOL *stop) {
        if ([executionObject.triggerEvents containsObject:eventName]) {
            [objectsToValidate addObject:executionObject];
        }
    }];
    
    if (objectsToValidate.count == 0) {
        return;
    }
    
    // Now validate and execute every block that passes validation
    // Also if they pass validation, remove them from the _executionObjects
    [objectsToValidate enumerateObjectsUsingBlock:^(L360ExecutionObject *executionObject, NSUInteger idx, BOOL *stop) {
        [self validateAndExecuteObject:executionObject forEvent:eventName];
    }];
}

- (void)validateAndExecuteObject:(L360ExecutionObject *)executionObject forEvent:(NSString *)eventName
{
    // This is executing inside the OperationQueue and so need to dispatch to main thread for
    __weak L360EventTracker *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        // First validate the block and if valid then execute it
        // Default to YES if validationBlock is nil
        BOOL validated = YES;
        if (executionObject.validationBlock) {
            validated = executionObject.validationBlock(eventName, self);
        }
        
        // Run the execution if validated
        if (validated &&
            executionObject.executionBlock) {
            executionObject.executionBlock(eventName, self);
            
            // Remove the block from the stack
            if (!executionObject.keepAlive) {
                [weakSelf.executionObjects removeObject:executionObject];
            }
        }
    });
}

#pragma mark Notifications

- (void)appWillResignActive
{
    for (L360EventObject *eventObject in _eventObjects) {
        if (eventObject.scope == L360EventTrackerScopeInstance) {
            eventObject.value = eventObject.initialValue;
        }
    }
}

@end
