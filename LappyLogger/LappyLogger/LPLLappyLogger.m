//
//  LappyLogger.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLappyLogger.h"
#import "LPLDataSource.h"
#import "LPLBatteryPercentageDataSource.h"

#define CAPTURE_INTERVAL_IN_SECONDS 60.0f

@implementation LPLLappyLogger

#pragma mark - Init

+ (LPLLappyLogger*)sharedInstance
{
    static LPLLappyLogger* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LPLLappyLogger alloc] init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if(self) {
        self.dataSources = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)start
{
    [self.dataSources addObject:[[LPLBatteryPercentageDataSource alloc] init]];
    
    [self startRecording];
}

#pragma mark - Recording

- (void)startRecording
{
    self.timer = [NSTimer timerWithTimeInterval:CAPTURE_INTERVAL_IN_SECONDS target:self selector:@selector(recordDataPoints) userInfo:nil repeats:YES];
}

- (void)recordDataPoints
{
    for(LPLDataSource* dataSource in self.dataSources) {
        [dataSource recordDataPoint];
    }
}

@end
