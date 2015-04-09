//
//  L360EventTracker.m
//  SafetyMap
//
//  Created by Mohammed Islam on 12/10/14.
//  Copyright (c) 2014 Life360. All rights reserved.
//

#import "L360EventTracker.h"
#import <objc/runtime.h>
#import "L360ExecutionObject.h"
#import "L360SwrveManager.h"
#import "Appirater.h"
#import "L360EventObject.h"

static NSString * const keyPrefix = @"kL360EventTracker";
@interface L360EventTracker ()
{
    NSMutableArray *_executionObjects;
    NSMutableArray *_eventObjects;
}

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
        // Setup the User Defaults Store
        [self setupDefaults];
//        [self setupPropertiesFromDefaults];
//        
//        [self setupPropertyObservation];
        
        _executionObjects = [NSMutableArray array];
        _eventObjects = [NSMutableArray array];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
//    [self tearDownObservation];
    
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
    // If event's scope is app level, update userdefaults
    if (eventObject.scope == L360EventTrackerScopeApp) {
        [[NSUserDefaults standardUserDefaults] setObject:eventObject.value
                                                  forKey:[keyPrefix stringByAppendingString:eventObject.event]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Then see if we need to execute anything that's listening on this event
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
    L360EventObject *eventObject = [self eventObjectForEvent:event];
    
    if (eventObject &&
        [eventObject.value isKindOfClass:[NSNumber class]]) {
        eventObject.value = @(((NSNumber *)eventObject.value).integerValue + 1);
        
        [self eventObjectDidChange:eventObject];
    }
}

- (void)setEvent:(NSString *)event withValue:(id)value
{
    L360EventObject *eventObject = [self eventObjectForEvent:event];
    
    if (eventObject) {
        eventObject.value = value;
        
        [self eventObjectDidChange:eventObject];
    }
}

- (NSArray *)executionObjects
{
    return _executionObjects.copy;
}

- (void)resetEventsForLogout
{
    // If user has logged out then
    [self setEvent:EVENT_START_NEW_SESSION withValue:@(1)];
    [self setEvent:EVENT_START_NEW_INSTANCE withValue:@(1)];
    
    [self setEvent:EVENT_ALL_PLACES_UPDATED withValue:@(0)];
    [self setEvent:EVENT_ALL_CIRCLES_UPDATED withValue:@(0)];
    [self setEvent:EVENT_MAP_HAS_BEEN_DISPLAYED withValue:@(0)];
    [self setEvent:EVENT_CIRCLE_HAS_CHANGED withValue:@(0)];
    [self setEvent:EVENT_PROFILE_IMAGE_HAS_CHANGED withValue:@(0)];
    [self setEvent:EVENT_HAS_JUST_FINISHED_ONBOARDING withValue:@(0)];
    
    [self setEvent:EVENT_DISPLAY_PROGRESS withValue:@(NO)];
    [self setEvent:EVENT_HAS_DISPLAYED_PROGRESS withValue:@(YES)];
    [self setEvent:EVENT_CIRCLES_WITH_COMPLETED_PROGRESS withValue:@[]];
    
    [self setEvent:EVENT_DISPLAY_MESSAGE_REMINDER withValue:@(NO)];
    [self setEvent:EVENT_HAS_DISPLAYED_MESSAGE_REMINDER withValue:@(NO)];
    
    [_executionObjects removeAllObjects];
}

#pragma mark -
#pragma mark Event Execution

- (L360ExecutionObject *)addExecutionBlock:(L360EventTrackerExecutionBlock)executionBlock
                             whenValidated:(L360EventTrackerValidationBlock)validationBlock
                           withExecutionID:(NSString *)executionID
                         listeningToEvents:(NSArray *)eventNames
                                 keepAlive:(BOOL)keepAlive
{
    if (eventNames.count == 0) {
        return nil;
    }
    
    // See if there are other execution objects with the same id already in the stack. If so, then just replace it with this
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
    
    return executionObject;
}

- (void)addAndRunExecutionBlock:(L360EventTrackerExecutionBlock)executionBlock
                  whenValidated:(L360EventTrackerValidationBlock)validationBlock
                withExecutionID:(NSString *)executionID
              listeningToEvents:(NSArray *)eventNames
                      keepAlive:(BOOL)keepAlive
{
    if (eventNames.count == 0) {
        return;
    }
    
    // Add it as a block
    L360ExecutionObject *executionObject = [self addExecutionBlock:executionBlock
                                                     whenValidated:validationBlock
                                                   withExecutionID:executionID
                                                 listeningToEvents:eventNames
                                                         keepAlive:keepAlive];
    
    // And then evaluate it with the first eventName in the list
    [self validateAndExecuteObject:executionObject forEvent:eventNames.firstObject];
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
    NSLock *lock = [[NSLock alloc] init];
    [lock lock]; {
        // First validate the block and if valid then execute it
        if (executionObject.validationBlock) {
            BOOL validated = executionObject.validationBlock(eventName, self);
            
            // Run the execution if validated
            if (validated && executionObject.executionBlock) {
                executionObject.executionBlock(eventName, self);
                
                // Remove the block from the stack
                if (!executionObject.keepAlive) {
                    [_executionObjects removeObject:executionObject];
                }
            }
        }
    } [lock unlock];
}

#pragma mark -
#pragma mark User Defaults Store

// These run through all the properties in this class (private and public) and creates an userDefaults for each property (with a keyPrefix appended to it)
// As well as KVO those properties so that any change will be updated onto the userDefaults.

// This is unfortunately the only MANUAL PART of this process. You need to add the string version of your property and the initial state for this to
// initialize the userDefaults properly
- (void)setupDefaults
{
    // Add newer properties into this dictionary with the initial state
    NSDictionary *defaultDictionary = @{[keyPrefix stringByAppendingString:EVENT_DISPLAY_PROGRESS] : @(NO),
                                        [keyPrefix stringByAppendingString:EVENT_ALL_CIRCLES_UPDATED] : @(0),
                                        [keyPrefix stringByAppendingString:EVENT_ALL_PLACES_UPDATED] : @(0),
                                        [keyPrefix stringByAppendingString:EVENT_CIRCLE_HAS_CHANGED] : @(0),
                                        [keyPrefix stringByAppendingString:EVENT_MAP_HAS_BEEN_DISPLAYED] : @(0),
                                        [keyPrefix stringByAppendingString:EVENT_START_NEW_SESSION] : @(0),
                                        [keyPrefix stringByAppendingString:EVENT_HAS_JUST_FINISHED_ONBOARDING] : @(NO),
                                        [keyPrefix stringByAppendingString:EVENT_START_NEW_INSTANCE] : @(0),
                                        [keyPrefix stringByAppendingString:EVENT_HAS_DISPLAYED_PROGRESS] : @(YES), // Initialize this to YES because this works differently to support older users
                                        [keyPrefix stringByAppendingString:EVENT_DISPLAY_MESSAGE_REMINDER] : @(NO),
                                        [keyPrefix stringByAppendingString:EVENT_HAS_DISPLAYED_MESSAGE_REMINDER] : @(NO),
                                        [keyPrefix stringByAppendingString:EVENT_CIRCLES_WITH_COMPLETED_PROGRESS] : @[],
                                        [keyPrefix stringByAppendingString:EVENT_PROFILE_IMAGE_HAS_CHANGED] : @(0),
                                        };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDictionary];
}

- (void)setupPropertiesFromDefaults
{
    uint count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        NSString *name = [NSString stringWithUTF8String:property_getName(propertyList[i])];
        [self setValue:[[NSUserDefaults standardUserDefaults] objectForKey:[keyPrefix stringByAppendingString:name]] forKey:name];
    }
    free(propertyList);
}

- (void)setupPropertyObservation
{
    uint count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        NSString *name = [NSString stringWithUTF8String:property_getName(propertyList[i])];
        [self addObserver:self forKeyPath:name options:NSKeyValueObservingOptionNew context:NULL];
    }
    free(propertyList);
}

- (void)tearDownObservation
{
    uint count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        NSString *name = [NSString stringWithUTF8String:property_getName(propertyList[i])];
        [self removeObserver:self forKeyPath:name];
    }
    free(propertyList);
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id newValue = change[NSKeyValueChangeNewKey];
    
    [self evaluateObjectsForEvent:keyPath];
    
    // Update the userDefaults with the prefixedPropertyName with the newValue
    NSString *prefixedPropertyName = [keyPrefix stringByAppendingString:keyPath];
    [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:prefixedPropertyName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Notifications

- (void)appWillResignActive
{
    // Need to reset the Instance scoped events
    // Don't trigger the event for this change of value though
    for (L360EventObject *eventObject in _eventObjects) {
        if (eventObject.scope == L360EventTrackerScopeInstance) {
            eventObject.value = eventObject.initialValue;
        }
    }
}

@end
