//
//  LPLMouseClicksDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/11/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLMouseClicksDataSource.h"
#import "LPLMouseClicksDataTranslator.h"
#import "LPLLogger.h"
#import <ApplicationServices/ApplicationServices.h>

#define kLoggingPrefix @"LPLMouseClicksDataSource"

#define kLogDataFileName @"mouseClicksLog"
#define kDataSourceName @"MouseClicks"

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
        BOOL couldSetUpMouseClicksMonitoring = [self setUpKeystrokeMonitoring];
        if(!couldSetUpMouseClicksMonitoring) {
            return nil;
        }
    }
    return self;
}

CGEventRef mouseClickEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon)
{
    if(type != kCGEventLeftMouseDown && type != kCGEventRightMouseDown) {
        return event;
    }
    
    if(mouseClicksSinceLastRecord < 0) {
        mouseClicksSinceLastRecord = 0;
    }
    
    mouseClicksSinceLastRecord++;
    
    return event;
}

- (BOOL)setUpKeystrokeMonitoring
{
    CFMachPortRef eventTap;
    CGEventMask eventMask;
    CFRunLoopSourceRef runLoopSource;
    
    eventMask = (1 << kCGEventLeftMouseDown) | (1 << kCGEventRightMouseDown);
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, eventMask, mouseClickEventCallback, NULL);
    if(!eventTap) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create the event tap! Mouse click logging won't work!"];
        return NO;
    }
    
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    
    dispatch_async(dispatch_queue_create("com.boztalay.LappyLogger.mouseClickLogging", 0), ^ {
        CFRunLoopRun();
    });
    
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
    
    mouseClicksSinceLastRecord = 0;
    
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
    return [[LPLMouseClicksDataTranslator alloc] init];
}

@end
