//
//  LappyLogger.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "LPLLappyLogger.h"
#import "LPLLogger.h"
#import "LPLConfigManager.h"
#import "LPLLogDataExporter.h"
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

- (BOOL)startWithArgc:(int)argc andArgv:(const char*[])argv
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the configuration..."];
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL isConfigCorrect = [[LPLConfigManager sharedInstance] readConfigAndReturnSuccess];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(!isConfigCorrect) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Something's wrong with the configuration! Exiting."];
        return NO;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Configuration was good!"];
    
    if(argc == 1) {
        return [self startBackgroundProcess];
    } else if(argc == 2 && [@"export" isEqualToString:[NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding]]) {
        return [self exportData];
    } else {
        return NO;
    }
}

#pragma mark - Starting the background process

- (BOOL)startBackgroundProcess
{
    if([self isAlreadyRunning]) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"LappyLogger is already running!"];
        return NO;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Creating the data sources..."];
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
    
    // Check if none of the data sources could be created
    
    if(self.dataSources.count == 0) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create any data sources! Trying a reset"];
        return NO;
    }
    
    // Check if any data source requested a restart
    
    for(LPLDataSource* dataSource in self.dataSources) {
        if(dataSource.restartRequested) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"A data source requested a restart! Restarting"];
            return NO;
        }
    }
    
    // If they're all good, go ahead with the background process
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@" "];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Starting data recording"];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@" "];
    
    [self startRecording];
    return YES;
}

- (BOOL)isAlreadyRunning {
    // This is a little hacky
    
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
    NSArray* grepLines = [grepOutput componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Grep output:\n%@", grepOutput];
    
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
   
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
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
    
    for(LPLDataSource* dataSource in self.dataSources) {
        if(dataSource.restartRequested) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"A data source requested a restart! Restarting"];
            [[NSApplication sharedApplication] terminate:self];
        }
    }
}

#pragma mark - Exporting data

- (BOOL)exportData
{
    LPLLogDataExporter* exporter = [[LPLLogDataExporter alloc] init];
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Exporting data..."];
    [[LPLLogger sharedInstance] incrementIndent];
    
    BOOL wasExportSuccessful = [exporter exportData];
    
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(wasExportSuccessful) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully exported (at least some) data! You'll find it in %@", [LPLConfigManager sharedInstance].configValues[LPLConfigExportDirectoryKey]];
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Failed to export any data!"];
    }
    
    // This is a little weird, but return NO so it doesn't start
    // the run loop in main.m
    return NO;
}

@end
