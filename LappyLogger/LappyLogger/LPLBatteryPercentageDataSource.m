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

#define kLogDataFileName @"batteryPercentageLog.ll"
#define kDataSourceName @"BatteryPercentage"
#define kDataPointLength 1

@implementation LPLBatteryPercentageDataSource

- (id)init
{
    self = [super init];
    if(self) {
        self.dataTranslator = [[LPLBatteryPercentageDataTranslator alloc] init];
        
        self.logFileWriter = [[LPLLogFileWriter alloc] initWithFileName:kLogDataFileName
                                                      andDataSourceName:kDataSourceName
                                                      andDataTranslator:self.dataTranslator];
        if(self.logFileWriter == nil) {
            return nil;
        }
    }
    return self;
}

- (void)recordDataPoint
{
    unsigned char batteryPercentage = (unsigned char)[self getBatteryPercentage];
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Battery percentage: %d", (int)batteryPercentage];
    
    BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedChar:batteryPercentage]];
    if(!writeSuccess) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't append the latest datapoint to the log file!"];
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully recorded the datapoint"];
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
    
    const void *powerSourceValue = (CFStringRef)CFDictionaryGetValue(powerSource, CFSTR(kIOPSNameKey));
    
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

@end
