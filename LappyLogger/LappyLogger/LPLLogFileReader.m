//
//  LPLLogFileReader.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogFileReader.h"
#import "LPLConfigManager.h"
#import "LPLLogDataPoint.h"
#import "LPLLogger.h"

#define kLoggingPrefix @"LPLLogFileReader"

@interface LPLLogFileReader()

@property (strong, nonatomic) NSMutableArray* unvalidatedDataPoints;

@end

@implementation LPLLogFileReader

- (id)initWithFileName:(NSString *)fileName andDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    self = [super init];
    if(self) {
        self.dataTranslator = dataTranslator;
        self.logFileHeader = [[LPLLogFileHeader alloc] init];
        self.unvalidatedDataPoints = [[NSMutableArray alloc] init];
        self.filePath = [[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] stringByAppendingPathComponent:fileName];
        
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading and validating the file at %@", self.filePath];
        
        BOOL isFileValid = [self readAndValidateFile:fileName];
        if(!isFileValid) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Failed to read the file"];
            
            [self.unvalidatedDataPoints removeAllObjects];
            return nil;
        }
        
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully read the file"];
    }
    return self;
}

- (BOOL)readAndValidateFile:(NSString*)fileName
{
    // Generate the file path and check if the file exists
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:NULL];
    if(!fileExists) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't read the file, it doesn't exist!"];
        return NO;
    }
    
    // Try to read the file in
    NSData* fileContents = [NSData dataWithContentsOfFile:self.filePath];
    if(fileContents == nil) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't read the file"];
        return NO;
    }
    
    // Try to read the file's header
    self.logFileHeader = [LPLLogFileHeader logFileHeaderFromFileContents:fileContents];
    if(self.logFileHeader == nil) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the file's header failed"];
        return NO;
    }
    
    // Try to read the file's data points
    BOOL couldReadDataPoints = [self readDataPointsFromFile:(NSData*)fileContents startingAt:(NSUInteger)self.logFileHeader.rawData.length];
    if(!couldReadDataPoints) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the file's data points failed"];
        return NO;
    }
    
    return YES;
}

- (BOOL)readDataPointsFromFile:(NSData*)fileContents startingAt:(NSUInteger)startIndex
{
    NSUInteger currentIndex = startIndex;
    while(currentIndex < fileContents.length) {
        LPLLogDataPoint* dataPoint = [LPLLogDataPoint dataPointFromFileContents:fileContents
                                                                        atIndex:currentIndex
                                                             withDataTranslator:self.dataTranslator];
        
        if(dataPoint == nil) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't read in data point at byte %ld", currentIndex];
            return NO;
        }
        
        [self.unvalidatedDataPoints addObject:dataPoint];
        
        currentIndex += dataPoint.rawData.length;
    }
    
    self.dataPoints = self.unvalidatedDataPoints;
    return [self validateDataPointTimestamps];
}

- (BOOL)validateDataPointTimestamps
{
    unsigned int lastTimestamp = 0;
    
    for(LPLLogDataPoint* dataPoint in self.dataPoints) {
        if(dataPoint.timestamp < lastTimestamp) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"The data points' timestamps are out of order"];
            return NO;
        }

        lastTimestamp = dataPoint.timestamp;
    }
    
    return YES;
}

@end