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
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Creating the battery percentage data source..."];
        
        self.dataTranslator = [[LPLBatteryPercentageDataTranslator alloc] init];
        
        [[LPLLogger sharedInstance] incrementIndent];
        self.logFileWriter = [[LPLLogFileWriter alloc] initWithFileName:kLogDataFileName
                                                      andDataSourceName:kDataSourceName
                                                      andDataTranslator:self.dataTranslator];
        [[LPLLogger sharedInstance] decrementIndent];
        
        if(self.logFileWriter == nil) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create the data source, making the file writer failed!"];
            return nil;
        }
        
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully created the data source"];
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
    
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedChar:(unsigned char)batteryPercentage]];
    [[LPLLogger sharedInstance] decrementIndent];
    
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
