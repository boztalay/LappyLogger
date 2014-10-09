//
//  LappyLogger.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLappyLogger.h"
#import "LPLConfigManager.h"
#import "LPLDataSource.h"
#import "LPLBatteryPercentageDataSource.h"
#import "LPLLogger.h"

#define kLoggingPrefix @"LPLLappyLogger"

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
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the configuration..."];
    
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL isConfigCorrect = [[LPLConfigManager sharedInstance] readConfigAndReturnSuccess];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(!isConfigCorrect) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Something's wrong with the configuration! Exiting."];
        return;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Configuration was good! Creating the data sources..."];
    [[LPLLogger sharedInstance] incrementIndent];
    
    LPLBatteryPercentageDataSource* batteryPercentageDataSource = [[LPLBatteryPercentageDataSource alloc] init];
    if(batteryPercentageDataSource != nil) {
        [self.dataSources addObject:batteryPercentageDataSource];
    }
    
    [[LPLLogger sharedInstance] decrementIndent];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@" "];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Starting data recording"];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@" "];
    
    [self startRecording];
}

#pragma mark - Recording

- (void)startRecording
{
    [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityBackground reason:@"Needs to log measurements in the background"];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:[[LPLConfigManager sharedInstance].configValues[LPLConfigTimedDataSourceIntervalKey] floatValue]
                                                  target:self
                                                selector:@selector(recordDataPoints)
                                                userInfo:nil
                                                 repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
    [self recordDataPoints];
}

- (void)recordDataPoints
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Recording data points..."];
    [[LPLLogger sharedInstance] incrementIndent];
    
    for(LPLDataSource* dataSource in self.dataSources) {
        [dataSource recordDataPoint];
    }
    
    [[LPLLogger sharedInstance] decrementIndent];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Finished recording data points"];
}

@end
