//
//  LPLBatteryPercentageDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLBatteryPercentageDataSource.h"
#import "LPLBatteryPercentageDataTranslator.h"
#import "LPLLogger.h"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

#define kLoggingPrefix @"LPLBatteryPercentageDataSource"

#define kLogDataFileName @"batteryPercentageLog"
#define kDataSourceName @"BatteryPercentage"

@implementation LPLBatteryPercentageDataSource

- (id)init
{
    self = [super init];
    if(self) {
        BOOL initializationSucceeded = [self initializeDataSourceWithName:kDataSourceName
                                                           andLogFileName:kLogDataFileName
                                                        andDataTranslator:[LPLBatteryPercentageDataSource dataTranslator]];
        if(!initializationSucceeded) {
            return nil;
        }
        
        self.lastBatteryPercentage = -1.0f;
    }
    return self;
}

- (void)recordDataPoint
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Recording the battery percentage data point..."];
    
    CGFloat batteryPercentage = [self getBatteryPercentage];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Battery percentage: %d", (int)batteryPercentage];
    
    if(batteryPercentage < 0.0f) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Getting the battery percentage failed!"];
        return;
    }
    
    if(self.lastBatteryPercentage < 0.0f || self.lastBatteryPercentage != batteryPercentage) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Battery percentage changed, recording it"];
        
        [[LPLLogger sharedInstance] incrementIndent];
        BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedChar:(unsigned char)batteryPercentage]];
        [[LPLLogger sharedInstance] decrementIndent];
        
        if(!writeSuccess) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't append the latest datapoint to the log file!"];
        } else {
            self.lastBatteryPercentage = batteryPercentage;
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully recorded the datapoint"];
        }
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Battery percentage hasn't changed, not recording it"];
    }
}

- (CGFloat)getBatteryPercentage
{
    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
    
    CFDictionaryRef powerSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, 0));
    if(!powerSource) {
        return -1.0f;
    }
    
    const void *powerSourceValue;
    
    NSInteger currentLevel = 0;
    NSInteger capacity = 0;
    
    powerSourceValue = CFDictionaryGetValue(powerSource, CFSTR(kIOPSCurrentCapacityKey));
    CFNumberGetValue((CFNumberRef)powerSourceValue, kCFNumberSInt32Type, &currentLevel);
    
    powerSourceValue = CFDictionaryGetValue(powerSource, CFSTR(kIOPSMaxCapacityKey));
    CFNumberGetValue((CFNumberRef)powerSourceValue, kCFNumberSInt32Type, &capacity);
    
    CGFloat currentPercentage = (((CGFloat)currentLevel / (CGFloat)capacity) * 100.0f);
    
    if(currentPercentage < 0.0f || currentPercentage > 100.0f) {
        return -1.0f;
    }
    
    return currentPercentage;
}

+ (NSString*)fileBaseName
{
    return kLogDataFileName;
}

+ (id<LPLDataTranslator>)dataTranslator
{
    return [[LPLBatteryPercentageDataTranslator alloc] init];
}

@end
