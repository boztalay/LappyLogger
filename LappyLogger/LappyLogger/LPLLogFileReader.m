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
        
        BOOL isFileValid = [self readAndValidateFile:fileName];
        if(!isFileValid) {
            [self.unvalidatedDataPoints removeAllObjects];
            return nil;
        }
    }
    return self;
}

- (BOOL)readAndValidateFile:(NSString*)fileName
{
    // Generate the file path and check if the file exists
    self.filePath = [[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] stringByAppendingPathComponent:fileName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:NULL];
    if(!fileExists) {
        return NO;
    }
    
    // Try to read the file in
    NSData* fileContents = [NSData dataWithContentsOfFile:self.filePath];
    if(fileContents == nil) {
        return NO;
    }
    
    // Try to read the file's header
    self.logFileHeader = [LPLLogFileHeader logFileHeaderFromFileContents:fileContents];
    if(self.logFileHeader == nil) {
        return NO;
    }
    
    // Try to read the file's data points
    BOOL couldReadDataPoints = [self readDataPointsFromFile:(NSData*)fileContents startingAt:(NSUInteger)self.logFileHeader.rawData.length];
    if(!couldReadDataPoints) {
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
            return NO;
        }
        
        [self.unvalidatedDataPoints addObject:dataPoint];
        
        currentIndex += dataPoint.rawData.length;
    }
    
    self.dataPoints = self.unvalidatedDataPoints;
    
    return YES;
}

@end