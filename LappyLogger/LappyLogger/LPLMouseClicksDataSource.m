//
//  LPLMouseClicksDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/11/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "LPLMouseClicksDataSource.h"
#import "LPLMouseClicksDataTranslator.h"
#import "LPLLogger.h"
#import <ApplicationServices/ApplicationServices.h>

#define kLoggingPrefix @"LPLMouseClicksDataSource"

#define kLogDataFileName @"mouseClicksLog"
#define kDataSourceName @"MouseClicks"

// If we get this many consecutive data points without any mouse clicks,
// tell the LappyLogger that something's wrong and it should try a restart.
// This is 1 day if the sample rate is 60 seconds
#define kMaxDataPointsWithoutData 1440

static NSInteger mouseClicksSinceLastRecord;

@implementation LPLMouseClicksDataSource

- (id)init
{
    self = [super init];
    if(self) {
        BOOL initializationSucceeded = [self initializeDataSourceWithName:kDataSourceName
                                                           andLogFileName:kLogDataFileName
                                                        andDataTranslator:[LPLMouseClicksDataSource dataTranslator]];
        if(!initializationSucceeded) {
            return nil;
        }
        
        mouseClicksSinceLastRecord = -1;
        BOOL couldSetUpMouseClicksMonitoring = [self setUpMouseClickMonitoring];
        if(!couldSetUpMouseClicksMonitoring) {
            // Something's wrong that we shouldn't ignore, request a restart
            self.restartRequested = YES;
        }
        
        self.numDataPointsWithoutData = 0;
    }
    return self;
}

//CGEventRef mouseClickEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
//{
//    if(type != kCGEventLeftMouseDown && type != kCGEventRightMouseDown) {
//        return event;
//    }
//    
//    if(mouseClicksSinceLastRecord < 0) {
//        mouseClicksSinceLastRecord = 0;
//    }
//    
//    mouseClicksSinceLastRecord++;
//    
//    return event;
//}
//
//- (BOOL)setUpMouseClickMonitoring
//{
//    CFMachPortRef eventTap;
//    CGEventMask eventMask;
//    CFRunLoopSourceRef runLoopSource;
//    
//    eventMask = (1 << kCGEventLeftMouseDown) | (1 << kCGEventRightMouseDown);
//    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, mouseClickEventCallback, NULL);
//    if(!eventTap) {
//        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create the event tap! Mouse click logging won't work!"];
//        return NO;
//    }
//    
//    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
//    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
//    CGEventTapEnable(eventTap, true);
//    
//    dispatch_async(dispatch_queue_create("com.boztalay.LappyLogger.mouseClickLogging", 0), ^ {
//        CFRunLoopRun();
//    });
//    
//    return YES;
//}

- (BOOL)setUpMouseClickMonitoring
{
    [NSEvent addGlobalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask)
                                           handler:^(NSEvent *event) {
        if(mouseClicksSinceLastRecord < 0) {
            mouseClicksSinceLastRecord = 0;
        }
                                               
        mouseClicksSinceLastRecord++;
    }];
    
    return YES;
}

- (void)recordDataPoint
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Recording the mouse clicks data point..."];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"%ld mouse clicks since the last record", mouseClicksSinceLastRecord];
    
    if(mouseClicksSinceLastRecord < 0) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Looks like there haven't been any recorded mouse clicks!"];
        return;
    }
    
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedShort:(unsigned short)mouseClicksSinceLastRecord]];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(!writeSuccess) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't append the latest datapoint to the log file!"];
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully recorded the datapoint"];
    }
    
    if(mouseClicksSinceLastRecord == 0) {
        self.numDataPointsWithoutData++;
    } else {
        self.numDataPointsWithoutData = 0;
    }
    
    mouseClicksSinceLastRecord = 0;
    
    // If we have too many consecutive data points without data, let
    // the LappyLogger know something's wrong
    if(self.numDataPointsWithoutData >= kMaxDataPointsWithoutData) {
        self.restartRequested = YES;
    }
}

+ (NSString*)fileBaseName
{
    return kLogDataFileName;
}

+ (id<LPLDataTranslator>)dataTranslator
{
    return [[LPLMouseClicksDataTranslator alloc] init];
}

@end
