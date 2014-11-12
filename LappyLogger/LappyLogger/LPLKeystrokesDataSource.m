//
//  LPLKeystrokesDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/10/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLKeystrokesDataSource.h"
#import "LPLKeystrokesDataTranslator.h"
#import "LPLLogger.h"
#import <ApplicationServices/ApplicationServices.h>

#define kLoggingPrefix @"LPLKeystrokesDataSource"

#define kLogDataFileName @"keystrokesLog"
#define kDataSourceName @"Keystrokes"

// If we get this many consecutive data points without any keystrokes,
// tell the LappyLogger that something's wrong and it should try a restart
#define kMaxDataPointsWithoutData 150

static NSInteger keystrokesSinceLastRecord;

@implementation LPLKeystrokesDataSource

- (id)init
{
    self = [super init];
    if(self) {
        BOOL initializationSucceeded = [self initializeDataSourceWithName:kDataSourceName
                                                           andLogFileName:kLogDataFileName
                                                        andDataTranslator:[LPLKeystrokesDataSource dataTranslator]];
        if(!initializationSucceeded) {
            return nil;
        }
        
        keystrokesSinceLastRecord = -1;
        BOOL couldSetUpKeystrokeMonitoring = [self setUpKeystrokeMonitoring];
        if(!couldSetUpKeystrokeMonitoring) {
            // Something's wrong that we shouldn't ignore, request a restart
            self.restartRequested = YES;
        }
        
        self.numDataPointsWithoutData = 0;
    }
    return self;
}

CGEventRef keystrokeEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    if(type != kCGEventKeyDown) {
        return event;
    }
    
    if(keystrokesSinceLastRecord < 0) {
        keystrokesSinceLastRecord = 0;
    }
    
    keystrokesSinceLastRecord++;
    
    return event;
}

- (BOOL)setUpKeystrokeMonitoring
{
    CFMachPortRef eventTap;
    CGEventMask eventMask;
    CFRunLoopSourceRef runLoopSource;
    
    eventMask = (1 << kCGEventKeyDown);
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, keystrokeEventCallback, NULL);
    if(!eventTap) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create the event tap! Keystroke logging won't work!"];
        return NO;
    }
    
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    
    dispatch_async(dispatch_queue_create("com.boztalay.LappyLogger.keystrokeLogging", 0), ^ {
        CFRunLoopRun();
    });
    
    return YES;
}

- (void)recordDataPoint
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Recording the keystrokes data point..."];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"%ld keystrokes since the last record", keystrokesSinceLastRecord];
    
    if(keystrokesSinceLastRecord <= 0) {
        self.numDataPointsWithoutData++;
    } else {
        self.numDataPointsWithoutData = 0;
    }
    
    // If we have too many consecutive data points without data, let
    // the LappyLogger know something's wrong
    if(self.numDataPointsWithoutData >= kMaxDataPointsWithoutData) {
        self.restartRequested = YES;
    }
    
    if(keystrokesSinceLastRecord < 0) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Looks like there haven't been any recorded keystrokes!"];
        return;
    }
    
    keystrokesSinceLastRecord = 0;
    
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedShort:(unsigned short)keystrokesSinceLastRecord]];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(!writeSuccess) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't append the latest datapoint to the log file!"];
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully recorded the datapoint"];
    }
}

+ (NSString*)fileBaseName
{
    return kLogDataFileName;
}

+ (id<LPLDataTranslator>)dataTranslator
{
    return [[LPLKeystrokesDataTranslator alloc] init];
}

@end
