//
//  LPLStartUpsDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/11/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLStartUpsDataSource.h"
#import "LPLStartUpsDataTranslator.h"
#import "LPLLogger.h"

#define kLoggingPrefix @"LPLStartUpsDataSource"

#define kLogDataFileName @"startUps"
#define kDataSourceName @"StartUps"

@implementation LPLStartUpsDataSource

- (id)init
{
    self = [super init];
    if(self) {
        BOOL initializationSucceeded = [self initializeDataSourceWithName:kDataSourceName
                                                           andLogFileName:kLogDataFileName
                                                        andDataTranslator:[[LPLStartUpsDataTranslator alloc] init]];
        if(!initializationSucceeded) {
            return nil;
        }
    }
    return self;
}

- (void)recordDataPoint
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Recording the start up..."];
    
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL writeSuccess = [self.logFileWriter appendDataPointAndReturnSuccess:[NSNumber numberWithUnsignedChar:1]];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(!writeSuccess) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't append the latest datapoint to the log file!"];
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully recorded the datapoint"];
    }
}

@end
