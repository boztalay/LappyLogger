//
//  LPLDataSource.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLDataSource.h"
#import "LPLLogger.h"

#define kLoggingPrefix @"LPLDataSource"

@implementation LPLDataSource

- (BOOL)initializeDataSourceWithName:(NSString*)dataSourceName
                      andLogFileName:(NSString*)logFileName
                   andDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Creating the %@ data source...", dataSourceName];
    
    self.restartRequested = NO;
    self.dataTranslator = dataTranslator;
    
    [[LPLLogger sharedInstance] incrementIndent];
    self.logFileWriter = [[LPLLogFileWriter alloc] initWithFileBaseName:logFileName
                                                  andDataSourceName:dataSourceName
                                                  andDataTranslator:self.dataTranslator];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(self.logFileWriter == nil) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create the data source, making the file writer failed!"];
        return NO;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully created the data source"];
    return YES;
}

- (void)recordDataPoint
{
    [NSException raise:@"Not Implemented" format:@"You must implement recordDataPoint!"];
}

+ (NSString*)fileBaseName
{
    [NSException raise:@"Not Implemented" format:@"You must implement fileBaseName!"];
    return nil;
}

+ (id<LPLDataTranslator>)dataTranslator
{
    [NSException raise:@"Not Implemented" format:@"You must implement dataTranslator!"];
    return nil;
}

@end
