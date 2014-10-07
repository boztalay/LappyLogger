//
//  LPLLogFileWriter.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/3/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogFileWriter.h"
#import "LPLLogFileReader.h"

#define kLoggingPrefix @"LPLConfigManager"

@implementation LPLLogFileWriter

- (id)initWithFileName:(NSString*)fileName
     andDataSourceName:(NSString*)dataSourceName
     andDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    self = [super init];
    if(self) {
        self.dataTranslator = dataTranslator;
        
        LPLLogFileReader* logFileReader = [[LPLLogFileReader alloc] initWithFileName:fileName andDataTranslator:self.dataTranslator];
        if(logFileReader == nil) {
            return nil;
        }
        
        if(![logFileReader.logFileHeader.dataSourceName isEqualToString:dataSourceName] || logFileReader.logFileHeader.dataPointLength != [self.dataTranslator dataLengthInBytes]) {
            return nil;
        }
        
        self.filePath = logFileReader.filePath;
    }
    return self;
}

- (BOOL)appendDataPointAndReturnSuccess:(id)dataToWrite
{
    CFAbsoluteTime timestamp = CFAbsoluteTimeGetCurrent();
    unsigned int timestampToWrite = (unsigned int)timestamp;
    
    LPLLogDataPoint* dataPointToWrite = [LPLLogDataPoint dataPointFromTimestamp:timestampToWrite andData:dataToWrite withDataTranslator:self.dataTranslator];
    if(dataPointToWrite == nil) {
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
    
    return YES;
}

@end
