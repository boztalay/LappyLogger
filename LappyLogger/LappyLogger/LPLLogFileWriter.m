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

#define kLogFileExtension @"ll"

@implementation LPLLogFileWriter

#pragma mark - Init, validation

- (id)initWithFileBaseName:(NSString*)fileBaseName
         andDataSourceName:(NSString*)dataSourceName
         andDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    self = [super init];
    if(self) {
        self.dataTranslator = dataTranslator;
        self.baseFileName = fileBaseName;
        self.dataSourceName = dataSourceName;
        self.filePath = [self findMostRecentFilePath];
        
        if(self.filePath == nil) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't find the most recent file for %@!", self.baseFileName];
            return nil;
        }
        
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Reading the file..."];
        [[LPLLogger sharedInstance] incrementIndent];
        LPLLogFileReader* logFileReader = [[LPLLogFileReader alloc] initWithFilePath:self.filePath andDataTranslator:self.dataTranslator];
        [[LPLLogger sharedInstance] decrementIndent];
        
        if(logFileReader == nil) {
            [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Failed to read the file, attempting to create a new one..."];
            [[LPLLogger sharedInstance] incrementIndent];
            BOOL couldWriteNewFile = [self createNewEmptyFileWithIncrementedName];
            [[LPLLogger sharedInstance] decrementIndent];
            
            if(!couldWriteNewFile) {
                [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Failed to create a new file!"];
                return nil;
            }
        } else {
            if(![logFileReader.logFileHeader.dataSourceName isEqualToString:self.dataSourceName] || logFileReader.logFileHeader.dataPointLength != [self.dataTranslator dataLengthInBytes]) {
                [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"The file's header doesn't match the given parameters!"];
                return nil;
            }
        }
        
        self.lastRecordingDate = nil;
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully initialized"];
    }
    return self;
}

- (NSString*)findMostRecentFilePath
{
    NSString* baseFilePath = [LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey];
    
    NSArray* baseFilePathContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseFilePath error:nil];
    if(baseFilePathContents == nil) {
        return nil;
    }
    
    NSMutableArray* filesForThisFileName = [[NSMutableArray alloc] init];
    
    for(NSString* otherFileName in baseFilePathContents) {
        if([[otherFileName pathExtension] isEqualToString:kLogFileExtension]) {
            if([otherFileName hasPrefix:self.baseFileName]) {
                [filesForThisFileName addObject:otherFileName];
            }
        }
    }
    
    NSString* mostRecentFileName = nil;
    
    if(filesForThisFileName.count <= 0) {
        mostRecentFileName = [NSString stringWithFormat:@"%@.%@", self.baseFileName, kLogFileExtension];
    } else {
        NSArray* sortedFilesForThisFileName = [filesForThisFileName sortedArrayUsingComparator:^(id a, id b) {
            return [a compare:b options:NSNumericSearch];
        }];
        
        mostRecentFileName = [sortedFilesForThisFileName lastObject];
    }
    
    return [[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] stringByAppendingPathComponent:mostRecentFileName];
}

- (BOOL)createNewEmptyFileWithIncrementedName
{
    self.filePath = [self incrementFilePath:self.filePath withBaseFileName:self.baseFileName];
    
    LPLLogFileHeader* logFileHeader = [LPLLogFileHeader logFileHeaderFromDataPointLength:[self.dataTranslator dataLengthInBytes] andDataSourceName:self.dataSourceName];
    return [[logFileHeader rawData] writeToFile:self.filePath atomically:YES];
}

- (NSString*)incrementFilePath:(NSString*)filePath withBaseFileName:(NSString*)baseFileName
{
    NSString* fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSString* fileNumber = [fileName substringFromIndex:baseFileName.length];
    
    NSInteger nextFileNumber = 0;
    
    if(fileNumber.length <= 0) {
        nextFileNumber = 1;
    } else {
        nextFileNumber = [fileNumber integerValue] + 1;
    }
    
    NSString* newFileName = [NSString stringWithFormat:@"%@%ld.%@", baseFileName, nextFileNumber, kLogFileExtension];
    
    return [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
}

#pragma mark - Appending data points

- (BOOL)appendDataPointAndReturnSuccess:(id)dataToWrite
{
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Appending new data point..."];
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Checking if the file got corrupted since the last write..."];
    [[LPLLogger sharedInstance] incrementIndent];
    [self checkForFileCorruptionAndMakeNewFileIfNeeded];
    [[LPLLogger sharedInstance] decrementIndent];
    
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
    
    self.lastRecordingDate = [[NSDate alloc] init];
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully appended the data point"];
    return YES;
}

- (BOOL)checkForFileCorruptionAndMakeNewFileIfNeeded
{
    if(![self wasFileModifiedSinceLastRecording]) {
        return YES;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"The file was modified by someone else! Checking its integrity by reading it..."];
    [[LPLLogger sharedInstance] incrementIndent];
    LPLLogFileReader* logFileReader = [[LPLLogFileReader alloc] initWithFilePath:self.filePath andDataTranslator:self.dataTranslator];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(logFileReader != nil) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"The file isn't corrupted!"];
        return YES;
    }
    
    [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"The file is corrupted! Making a new one!"];
    [[LPLLogger sharedInstance] incrementIndent];
    BOOL couldCreateNewFile = [self createNewEmptyFileWithIncrementedName];
    [[LPLLogger sharedInstance] decrementIndent];
    
    if(!couldCreateNewFile) {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Couldn't make the new file!"];
        return NO;
    } else {
        [[LPLLogger sharedInstance] logFromClass:kLoggingPrefix withMessage:@"Successfully made the new file!"];
        return YES;
    }
}

- (BOOL)wasFileModifiedSinceLastRecording
{
    if(self.lastRecordingDate == nil) {
        return NO;
    }
    
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil];
    if(attributes == nil) {
        return YES;
    }
    
    NSDate* lastModifiedDate = (NSDate*)attributes[NSFileModificationDate];

    return ([lastModifiedDate compare:self.lastRecordingDate] == NSOrderedDescending);
}

@end
