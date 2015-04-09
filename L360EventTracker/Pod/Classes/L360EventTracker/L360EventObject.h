//
//  L360EventObject.h
//  SafetyMap
//
//  Created by Mohammed Islam on 3/18/15.
//  Copyright (c) 2015 Life360. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L360EventTracker.h"

@interface L360EventObject : NSObject

@property (nonatomic, strong) NSString *event;
@property (nonatomic, strong) id initialValue;
@property (nonatomic, strong) id value;
@property (nonatomic, assign) L360EventTrackerScope scope;

@end
