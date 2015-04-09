//
//  L360EventObject.m
//  SafetyMap
//
//  Created by Mohammed Islam on 3/18/15.
//  Copyright (c) 2015 Life360. All rights reserved.
//

#import "L360EventObject.h"

@implementation L360EventObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"name: %@\ninital value: %@\ncurrent value: %@", self.event, self.initialValue, self.value];
}

@end
