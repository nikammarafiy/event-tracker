//
//  L360ExecutionObject.h
//  SafetyMap
//
//  Created by Mohammed Islam on 2/9/15.
//  Copyright (c) 2015 Life360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L360EventTracker.h"

@interface L360ExecutionObject : NSObject

@property (nonatomic, strong) NSArray *triggerEvents;
@property (nonatomic, strong) NSString *executionID;
@property (nonatomic, copy) L360EventTrackerValidationBlock validationBlock;
@property (nonatomic, copy) L360EventTrackerExecutionBlock executionBlock;
@property (nonatomic, assign) BOOL keepAlive;

// Sometimes due to threading, multiple execution blocks are setup to run on the same ExecutionObject
// Even though it's been marked as keepAlive = NO
// So to mitigate this multi-threading issue, this flag will be used and before evaluation this will be checked
@property (nonatomic, assign) BOOL markForDeletion;

@end
