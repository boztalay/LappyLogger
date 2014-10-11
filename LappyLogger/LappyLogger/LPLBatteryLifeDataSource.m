//
//  LPLBatteryLifeDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/9/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLBatteryLifeDataSource.h"
#import "LPLBatteryLifeDataTranslator.h"
#import "LPLLogger.h"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

#define kLoggingPrefix @"LPLBatteryLifeDataSource"

#define kLogDataFileName @"batteryLifeLog"
#define kDataSourceName @"BatteryLife"

@implementation LPLBatteryLifeDataSource

- (id)init
{
    self = [super init];
    if(self) {
        BOOL initializationSucceeded = [self initializeDataSourceWithName:kDataSourceName
                                                           andLogFileName:kLogDataFileName
                                                        andDataTranslator:[[LPLBatteryLifeDataTranslator alloc] init]];
        if(!initializationSucceeded) {
            return nil;
        }
        
        self.lastBatteryLife = -1;
    }
    return self;
}

- (void)recordDataPoint
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Recording the battery life data point..."];
    
    NSInteger batteryLife = [self getBatteryLife];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Minutes to empty: %d", batteryLife];
    
    if(batteryLife < 0) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Getting the battery life failed!"];
        return;
    }
    
    if(self.lastBatteryLife < 0 || self.lastBatteryLife != batteryLife) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Battery life changed, recording it"];
        
        [[LPLLogger sharedInstance] incrementIndent];
        BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedShort:(unsigned short)batteryLife]];
        [[LPLLogger sharedInstance] decrementIndent];
        
        if(!writeSuccess) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't append the latest datapoint to the log file!"];
        } else {
            self.lastBatteryLife = batteryLife;
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully recorded the datapoint"];
        }
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Battery life hasn't changed, not recording it"];
    }
}

- (NSInteger)getBatteryLife
{
    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
    
    CFDictionaryRef powerSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, 0));
    if(!powerSource) {
        return -1;
    }
    
    const void *powerSourceValue;
    NSInteger currentTimeToEmpty = 0;
    powerSourceValue = CFDictionaryGetValue(powerSource, CFSTR(kIOPSTimeToEmptyKey));
    CFNumberGetValue((CFNumberRef)powerSourceValue, kCFNumberSInt32Type, &currentTimeToEmpty);
    
    if(currentTimeToEmpty > INT_MAX) {
        return -1;
    }
    
    return currentTimeToEmpty;
}

@end
