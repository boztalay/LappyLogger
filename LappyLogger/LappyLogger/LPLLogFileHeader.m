//
//  LPLLogFileHeader.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogFileHeader.h"

#define kMagicNumber @"BOLL"
#define kMagicNumberLength kMagicNumber.length
#define kVersionNumber 1
#define kVersionNumberLength 1
#define kDataPointLengthLength 2
#define kBasicHeaderLength (kMagicNumberLength + kVersionNumberLength + kDataPointLengthLength)
#define kMinDataSourceNameLength 2

@implementation LPLLogFileHeader

+ (LPLLogFileHeader*)logFileHeaderFromFileContents:(NSData*)fileContents
{
    if(fileContents.length < kBasicHeaderLength + kMinDataSourceNameLength) {
        return nil;
    }
    
    LPLLogFileHeader* logFileHeader = [[LPLLogFileHeader alloc] init];
    
    // Read the magic number
    char* magicNumber = malloc((kMagicNumberLength + 1) * sizeof(char));
    [fileContents getBytes:magicNumber range:NSMakeRange(0, kMagicNumberLength)];
    magicNumber[kMagicNumberLength] = '\0';
    logFileHeader.magicNumber = [NSString stringWithCString:magicNumber encoding:NSUTF8StringEncoding];
    BOOL magicNumberIsCorrect = ([logFileHeader.magicNumber isEqualToString:kMagicNumber]);
    
    // Read the version number
    char* versionNumber = malloc(kVersionNumberLength * sizeof(char));
    [fileContents getBytes:versionNumber range:NSMakeRange(kMagicNumberLength, kVersionNumberLength)];
    logFileHeader.versionNumber = (unsigned int)(versionNumber[0]);
    BOOL versionNumberIsCorrect = (logFileHeader.versionNumber <= kVersionNumber);
    
    // Read the data point length
    char* dataPointLength = malloc(kDataPointLengthLength * sizeof(char));
    [fileContents getBytes:dataPointLength range:NSMakeRange(kMagicNumberLength + kVersionNumberLength, kDataPointLengthLength)];
    logFileHeader.dataPointLength = (unsigned int)(short)(*dataPointLength);
    
    // Read the data source name
    NSInteger dataSourceNameStart = kBasicHeaderLength;
    NSInteger dataSourceNameLength = 0;
    
    for(dataSourceNameLength = 0; ((char*)fileContents.bytes)[dataSourceNameStart + dataSourceNameLength] != '\0'; dataSourceNameLength++) { }
    dataSourceNameLength++;
    
    char* dataSourceName = malloc(dataSourceNameLength * sizeof(char));
    [fileContents getBytes:dataSourceName range:NSMakeRange(dataSourceNameStart, dataSourceNameLength)];
    logFileHeader.dataSourceName = [NSString stringWithCString:dataSourceName encoding:NSUTF8StringEncoding];
    
    // Free up the malloc'd memory
    free(magicNumber);
    free(versionNumber);
    free(dataPointLength);
    free(dataSourceName);
    
    logFileHeader.rawData = [fileContents subdataWithRange:NSMakeRange(0, kBasicHeaderLength + dataSourceNameLength)];
    
    if(magicNumberIsCorrect && versionNumberIsCorrect && logFileHeader.dataSourceName.length > 0) {
        return logFileHeader;
    } else {
        return nil;
    }
}

+ (LPLLogFileHeader*)logFileHeaderFromDataPointLength:(NSUInteger)dataPointLength andDataSourceName:(NSString*)dataSourceName
{
    if(dataPointLength < 1 || dataSourceName.length < 1) {
        return nil;
    }
    
    NSMutableData* logFileHeaderRawData = [[NSMutableData alloc] init];
    [logFileHeaderRawData appendBytes:[kMagicNumber cStringUsingEncoding:NSUTF8StringEncoding] length:kMagicNumberLength];
    char versionNumber = kVersionNumber;
    [logFileHeaderRawData appendBytes:&versionNumber length:kVersionNumberLength];
    [logFileHeaderRawData appendBytes:&dataPointLength length:kDataPointLengthLength];
    [logFileHeaderRawData appendBytes:[dataSourceName cStringUsingEncoding:NSUTF8StringEncoding] length:dataSourceName.length + 1];
    
    LPLLogFileHeader* logFileHeader = [[LPLLogFileHeader alloc] init];
    logFileHeader.magicNumber = kMagicNumber;
    logFileHeader.versionNumber = kVersionNumber;
    logFileHeader.dataPointLength = dataPointLength;
    logFileHeader.dataSourceName = dataSourceName;
    logFileHeader.rawData = logFileHeaderRawData;
    
    return logFileHeader;
}

@end