//
//  LPLLogFileHeader.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogFileHeader.h"

#define kMagicNumber @"BOLL"
#define kMagicNumberLength 4 // Probably a better way to do this
#define kVersionNumber 1
#define kVersionNumberLength 1
#define kDataPointLengthLength 2
#define kHeaderLength (kMagicNumberLength + kVersionNumberLength + kDataPointLengthLength)

@implementation LPLLogFileHeader

- (id)initFromFileContents:(NSData *)fileContents
{
    self = [super init];
    if(self) {
        BOOL couldReadFileHeader = [self readHeaderFromFileContents:fileContents];
        if(!couldReadFileHeader) {
            return nil;
        }
    }
    return self;
}

- (BOOL)readHeaderFromFileContents:(NSData*)fileContents;
{
    if(fileContents.length < kHeaderLength) {
        return NO;
    }
    
    // Read the magic number
    char* magicNumber = malloc((kMagicNumberLength + 1) * sizeof(char));
    [fileContents getBytes:magicNumber range:NSMakeRange(0, kMagicNumberLength)];
    magicNumber[kMagicNumberLength] = '\0';
    self.magicNumber = [NSString stringWithCString:magicNumber encoding:NSUTF8StringEncoding];
    BOOL magicNumberIsCorrect = ([self.magicNumber isEqualToString:kMagicNumber]);
    
    // Read the version number
    char* versionNumber = malloc(kVersionNumberLength * sizeof(char));
    [fileContents getBytes:versionNumber range:NSMakeRange(kMagicNumberLength, kVersionNumberLength)];
    self.versionNumber = (unsigned int)(versionNumber[0]);
    BOOL versionNumberIsCorrect = (self.versionNumber <= kVersionNumber);
    
    // Read the data point length
    char* dataPointLength = malloc(kDataPointLengthLength * sizeof(char));
    [fileContents getBytes:dataPointLength range:NSMakeRange(kMagicNumberLength + kVersionNumberLength, kDataPointLengthLength)];
    self.dataPointLength = (unsigned int)(short)(*dataPointLength);
    
    // Read the data source name
    NSInteger dataSourceNameStart = kHeaderLength;
    NSInteger dataSourceNameLength = 0;
    
    for(dataSourceNameLength = 0; ((char*)fileContents.bytes)[dataSourceNameStart + dataSourceNameLength] != '\0'; dataSourceNameLength++) { }
    dataSourceNameLength++;
    
    char* dataSourceName = malloc(dataSourceNameLength * sizeof(char));
    [fileContents getBytes:dataSourceName range:NSMakeRange(dataSourceNameStart, dataSourceNameLength)];
    self.dataSourceName = [NSString stringWithCString:dataSourceName encoding:NSUTF8StringEncoding];
    
    // Free up the malloc'd memory
    free(magicNumber);
    free(versionNumber);
    free(dataPointLength);
    free(dataSourceName);
    
    return (magicNumberIsCorrect && versionNumberIsCorrect && self.dataSourceName.length > 0);
}

@end