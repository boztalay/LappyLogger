//
//  LappyLogger.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLappyLogger.h"
#import "LPLLogger.h"
#import "LPLConfigManager.h"
#import "LPLDataSource.h"
#import "LPLBatteryPercentageDataSource.h"
#import "LPLBatteryLifeDataSource.h"
#import "LPLACConnectionStatusDataSource.h"
#import "LPLKeystrokesDataSource.h"
#import "LPLMouseClicksDataSource.h"
#import "LPLStartUpsDataSource.h"

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

- (BOOL)start
{
    if([self isAlreadyRunning]) {
        return NO;
    }
    
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL isConfigCorrect = [[LPLConfigManager sharedInstance] readConfigAndReturnSuccess];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(!isConfigCorrect) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Something's wrong with the configuration! Exiting."];
        return NO;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Configuration was good! Creating the data sources..."];
    [[LPLLogger sharedInstance] incrementIndent];
    
    LPLBatteryPercentageDataSource* batteryPercentageDataSource = [[LPLBatteryPercentageDataSource alloc] init];
    if(batteryPercentageDataSource != nil) {
        [self.dataSources addObject:batteryPercentageDataSource];
    }
    
    LPLBatteryLifeDataSource* batteryLifeDataSource = [[LPLBatteryLifeDataSource alloc] init];
    if(batteryLifeDataSource != nil) {
        [self.dataSources addObject:batteryLifeDataSource];
    }

    LPLACConnectionStatusDataSource* acConnectionStatusDataSource = [[LPLACConnectionStatusDataSource alloc] init];
    if(acConnectionStatusDataSource != nil) {
        [self.dataSources addObject:acConnectionStatusDataSource];
    }

    LPLKeystrokesDataSource* keystrokesDataSource = [[LPLKeystrokesDataSource alloc] init];
    if(keystrokesDataSource != nil) {
        [self.dataSources addObject:keystrokesDataSource];
    }

    LPLMouseClicksDataSource* mouseClicksDataSource = [[LPLMouseClicksDataSource alloc] init];
    if(mouseClicksDataSource != nil) {
        [self.dataSources addObject:mouseClicksDataSource];
    }
    
    LPLStartUpsDataSource* startUpsDataSource = [[LPLStartUpsDataSource alloc] init];
    if(startUpsDataSource != nil) {
        [startUpsDataSource recordDataPoint];
    }
    
    [[LPLLogger sharedInstance] decrementIndent];
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@" "];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Starting data recording"];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@" "];
    
    [self startRecording];
    return YES;
}

- (BOOL)isAlreadyRunning {
    NSPipe* psPipe = [NSPipe pipe];
    NSPipe* grepPipe = [NSPipe pipe];
    NSFileHandle* file = grepPipe.fileHandleForReading;
    
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/bin/ps";
    task.arguments = @[@"-exo", @"comm"];
    task.standardOutput = psPipe;
    
    [task launch];
    
    task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/grep";
    task.arguments = @[@"LappyLogger"];
    task.standardInput = psPipe;
    task.standardOutput = grepPipe;
    
    [task launch];
    
    NSData* data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString* grepOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray* grepLines = [grepOutput componentsSeparatedByString:@"\n"];
    
    // If more than one LappyLogger process is running, we'll get at least 3 lines
    // (1 for this process, 1 for the other, and 1 empty newline because of componentsSeparated)
    return grepLines.count >= 3;
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
