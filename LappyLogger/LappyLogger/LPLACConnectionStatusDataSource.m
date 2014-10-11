//
//  LPLACConnectionStatusDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/9/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLACConnectionStatusDataSource.h"
#import "LPLACConnectionStatusDataTranslator.h"
#import "LPLLogger.h"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

#define kLoggingPrefix @"LPLACConnectionStatusDataSource"

#define kLogDataFileName @"acConnectionStatusLog"
#define kDataSourceName @"ACConnectionStatus"

@implementation LPLACConnectionStatusDataSource

- (id)init
{
    self = [super init];
    if(self) {
        BOOL initializationSucceeded = [self initializeDataSourceWithName:kDataSourceName
                                                           andLogFileName:kLogDataFileName
                                                        andDataTranslator:[[LPLACConnectionStatusDataTranslator alloc] init]];
        if(!initializationSucceeded) {
            return nil;
        }
        
        self.lastAcConnectionStatus = -1;
    }
    return self;
}

- (void)recordDataPoint
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Recording the AC connection status data point..."];
    
    NSInteger acConnectionStatus = [self getACConnectionStatus];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"AC connection status: %d", acConnectionStatus];
    
    if(acConnectionStatus < 0) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Getting the AC connection status failed!"];
        return;
    }
    
    if(self.lastAcConnectionStatus < 0 || self.lastAcConnectionStatus != acConnectionStatus) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"AC connection status changed, recording it"];
        
        [[LPLLogger sharedInstance] incrementIndent];
        BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedChar:(unsigned char)acConnectionStatus]];
        [[LPLLogger sharedInstance] decrementIndent];
        
        if(!writeSuccess) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't append the latest datapoint to the log file!"];
        } else {
            self.lastAcConnectionStatus = acConnectionStatus;
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully recorded the datapoint"];
        }
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"AC connection status hasn't changed, not recording it"];
    }
}

- (NSInteger)getACConnectionStatus
{
    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
    
    CFDictionaryRef powerSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, 0));
    if(!powerSource) {
        return -1;
    }
    
    NSString* powerSourceState = CFDictionaryGetValue(powerSource, CFSTR(kIOPSPowerSourceStateKey));
    if([powerSourceState isEqualToString:@"AC Power"]) {
        return 1;
    } else {
        return 0;
    }
}

@end
