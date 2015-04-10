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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(id)sender
{
    [[L360EventTracker sharedInstance] triggerEvent:@"buttonTapCount"];
}

@end
