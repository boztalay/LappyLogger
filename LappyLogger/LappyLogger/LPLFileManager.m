//
//  LPLFileManager.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLFileManager.h"
#import "LPLConfigManager.h"

#define kMagicNumber "BOLL"
#define kMagicNumberLength 4 // Probably a better way to do this
#define kVersionNumber "\x01"
#define kVersionNumberLength 1
#define kDataPointLengthLength 2
#define kHeaderLength (kMagicNumberLength + kVersionNumberLength + kDataPointLengthLength)
#define kTimestampLength 4

// Oh yeah we're doing this custom file format thing

@implementation LPLFileManager

#pragma mark - Init, creating and/or validating the file

- (id)initWithFileName:(NSString*)fileName
     andDataSourceName:(NSString*)dataSourceName
    andDatapointLength:(NSUInteger)dataPointLength
{
    self = [super init];
    if(self) {
        self.dataSourceName = dataSourceName;
        self.dataPointLength = dataPointLength;
        
        if(self.dataPointLength < 1) {
            NSLog(@"Data point length %ld is too short!", (long)self.dataPointLength);
            return nil;
        }
        
        BOOL validFileExists = [self validateOrCreateFile:fileName];
        if(!validFileExists) {
            NSLog(@"Valid file doesn't exist for file name %@!", fileName);
            return nil;
        }
        NSLog(@"Valid file does exist for file name %@", fileName);
    }
    return self;
}

- (BOOL)validateOrCreateFile:(NSString*)fileName
{
    self.filePath = [[LPLConfigManager sharedInstance].configValues[LPLConfigLogDataDirectoryKey] stringByAppendingPathComponent:fileName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:NULL];

    if(!fileExists) {
        NSLog(@"File %@ is empty or doesn't exist, making it", fileName);
        
        BOOL newFileExists = [self createNewLogFile];
        if(!newFileExists) {
            NSLog(@"Couldn't make file %@!", fileName);
            return NO;
        }
    } else {
        NSLog(@"File %@ exists, validating it", fileName);
        
        NSData* fileContents = [NSData dataWithContentsOfFile:self.filePath];
        BOOL fileContentsAreValid = [self validateFileContents:fileContents];
        if(!fileContentsAreValid) {
            NSLog(@"File %@ isn't valid!", fileName);
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)createNewLogFile
{
    NSMutableData* newFileData = [[NSMutableData alloc] init];
    
    [newFileData appendBytes:kMagicNumber length:kMagicNumberLength];
    [newFileData appendBytes:kVersionNumber length:kVersionNumberLength];
    [newFileData appendBytes:&_dataPointLength length:kDataPointLengthLength];
    [newFileData appendBytes:[self.dataSourceName cStringUsingEncoding:NSUTF8StringEncoding] length:self.dataSourceName.length + 1];

    // Sanity check
    BOOL fileContentsAreValid = [self validateFileContents:newFileData];
    if(!fileContentsAreValid) {
        NSLog(@"New file isn't valid!");
        return NO;
    }
    
    return [newFileData writeToFile:self.filePath atomically:YES];
}

# pragma mark - Guts of file validation

- (BOOL)validateFileContents:(NSData*)fileContents
{
    BOOL isFileHeaderCorrect = [self validateFileHeader:fileContents];
    if(!isFileHeaderCorrect) {
        NSLog(@"File header is invalid!");
        return NO;
    }
    NSLog(@"File header is valid");
    
    NSInteger startIndexOfDataPoints = [self readAndValidateDataSourceName:fileContents];
    if(startIndexOfDataPoints < 0) {
        NSLog(@"The data source name wasn't right!");
        return NO;
    }
    NSLog(@"The data source name was correct");
    
    return [self validateDataPointsInFile:fileContents startingAtIndex:startIndexOfDataPoints];
}

- (BOOL)validateFileHeader:(NSData*)fileContents
{
    char* magicNumber = malloc((kMagicNumberLength + 1) * sizeof(char));
    [fileContents getBytes:magicNumber range:NSMakeRange(0, kMagicNumberLength)];
    magicNumber[kMagicNumberLength] = '\0';
    BOOL magicNumberIsCorrect = (strcmp(magicNumber, kMagicNumber) == 0);
    
    char* versionNumber = malloc(kVersionNumberLength * sizeof(char));
    [fileContents getBytes:versionNumber range:NSMakeRange(kMagicNumberLength, kVersionNumberLength)];
    BOOL versionNumberIsCorrect = (versionNumber[0] <= kVersionNumber[0]);
    
    char* dataPointLength = malloc(kDataPointLengthLength * sizeof(char));
    [fileContents getBytes:dataPointLength range:NSMakeRange(kMagicNumberLength + kVersionNumberLength, kDataPointLengthLength)];
    BOOL dataPointLengthIsCorrect = ((short)(*dataPointLength) == self.dataPointLength);
    
    free(magicNumber);
    free(versionNumber);
    free(dataPointLength);
    
    return (magicNumberIsCorrect && versionNumberIsCorrect && dataPointLengthIsCorrect);
}

- (NSInteger)readAndValidateDataSourceName:(NSData*)fileContents
{
    NSInteger dataSourceNameStart = kHeaderLength;
    NSInteger dataSourceNameLength = 0;
    
    for(dataSourceNameLength = 0; ((char*)fileContents.bytes)[dataSourceNameStart + dataSourceNameLength] != '\0'; dataSourceNameLength++) { }
    dataSourceNameLength++;
    
    char* dataSourceName = malloc(dataSourceNameLength * sizeof(char));
    [fileContents getBytes:dataSourceName range:NSMakeRange(dataSourceNameStart, dataSourceNameLength)];
    BOOL isDataSourceNameValid = (strcmp(dataSourceName, [self.dataSourceName cStringUsingEncoding:NSUTF8StringEncoding]) == 0);
    
    free(dataSourceName);
    
    if(!isDataSourceNameValid) {
        return -1;
    }
    
    return (dataSourceNameStart + dataSourceNameLength);
}

// TODO this might need to do a little more validation than checking that the timestamps are
// monotonic, but that also might be enough to catch most formatting issues
- (BOOL)validateDataPointsInFile:(NSData*)fileContents startingAtIndex:(NSUInteger)startIndexOfDataPoints
{
    NSUInteger lastTimestamp = 0;
    NSUInteger sizeOfDataPoint = kTimestampLength + self.dataPointLength;
    
    char* currentDataPointTimestamp = malloc(kTimestampLength * sizeof(char));
    char* currentDataPointData = malloc(self.dataPointLength * sizeof(char));
    
    BOOL areDataPointsValid = YES;
    
    for(NSUInteger currentIndex = startIndexOfDataPoints; currentIndex < fileContents.length; currentIndex += sizeOfDataPoint) {
        [fileContents getBytes:currentDataPointTimestamp range:NSMakeRange(currentIndex, kTimestampLength)];
        [fileContents getBytes:currentDataPointData range:NSMakeRange(currentIndex + kTimestampLength, self.dataPointLength)];
        
        NSUInteger* currentTimestamp = (NSUInteger*)(currentDataPointTimestamp);
        if(lastTimestamp > *currentTimestamp) {
            NSLog(@"Bad timestamp at byte %lu!", (unsigned long)currentIndex);
            areDataPointsValid = NO;
            break;
        }
        lastTimestamp = *currentTimestamp;
    }
    
    free(currentDataPointTimestamp);
    free(currentDataPointData);
    
    return areDataPointsValid;
}

#pragma mark - Writing new datapoints to the file

- (BOOL)appendDataPointAndReturnSuccess:(NSData*)dataPoint
{
    if(dataPoint.length != self.dataPointLength) {
        return NO;
    }
    
    CFAbsoluteTime timestamp = CFAbsoluteTimeGetCurrent();
    NSUInteger timestampToWrite = (NSUInteger)timestamp;

    @try {
        NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[NSData dataWithBytes:&timestampToWrite length:kTimestampLength]];
        [fileHandle writeData:dataPoint];
        [fileHandle closeFile];
    } @catch(NSException* e) {
        NSLog(@"Error writing to the file: %@", e);
        return NO;
    }
    
    return YES;
}

@end
