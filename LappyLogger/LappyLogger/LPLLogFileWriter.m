//
//  LPLLogFileWriter.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/3/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogFileWriter.h"
#import "LPLLogFileReader.h"
#import "LPLLogFileHeader.h"
#import "LPLConfigManager.h"
#import "LPLLogger.h"

#define kLoggingPrefix @"LPLLogFileWriter"

@implementation LPLLogFileWriter

- (id)initWithFileName:(NSString*)fileName
     andDataSourceName:(NSString*)dataSourceName
     andDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    self = [super init];
    if(self) {
        self.dataTranslator = dataTranslator;
        self.filePath = [[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] stringByAppendingPathComponent:fileName];
        
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the file..."];
        [[LPLLogger sharedInstance] incrementIndent];
        
        LPLLogFileReader* logFileReader = [[LPLLogFileReader alloc] initWithFileName:fileName andDataTranslator:self.dataTranslator];
        
        [[LPLLogger sharedInstance] decrementIndent];
        
        if(logFileReader == nil) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Failed to read the file, attempting to create a new one..."];
            
            LPLLogFileHeader* logFileHeader = [LPLLogFileHeader logFileHeaderFromDataPointLength:[self.dataTranslator dataLengthInBytes] andDataSourceName:dataSourceName];
            BOOL couldWriteNewFile = [[logFileHeader rawData] writeToFile:self.filePath atomically:YES];
            if(!couldWriteNewFile) {
                [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Failed to create a new file!"];
                return nil;
            }
        } else {
            if(![logFileReader.logFileHeader.dataSourceName isEqualToString:dataSourceName] || logFileReader.logFileHeader.dataPointLength != [self.dataTranslator dataLengthInBytes]) {
                [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"The file's header doesn't match the given parameters!"];
                return nil;
            }
        }
        
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully initialized"];
    }
    return self;
}

- (BOOL)appendDataPointAndReturnSuccess:(id)dataToWrite
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Appending new data point..."];
    
    CFAbsoluteTime timestamp = CFAbsoluteTimeGetCurrent();
    unsigned int timestampToWrite = (unsigned int)timestamp;
    
    LPLLogDataPoint* dataPointToWrite = [LPLLogDataPoint dataPointFromTimestamp:timestampToWrite andData:dataToWrite withDataTranslator:self.dataTranslator];
    if(dataPointToWrite == nil) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't create the data point!"];
        return NO;
    }
    
    @try {
        NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:dataPointToWrite.rawData];
        [fileHandle closeFile];
    } @catch(NSException* e) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Error writing to the file: %@", e];
        return NO;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully appended the data point"];
    return YES;
}

@end
