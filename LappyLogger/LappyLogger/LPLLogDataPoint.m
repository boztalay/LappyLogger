//
//  LPLLogDataPoint.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/3/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogDataPoint.h"

#define kTimestampLength 4

@implementation LPLLogDataPoint

+ (LPLLogDataPoint*)dataPointFromFileContents:(NSData*)fileContents
                                      atIndex:(NSUInteger)index
                           withDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    LPLLogDataPoint* dataPoint = [[LPLLogDataPoint alloc] init];
    
    NSUInteger dataPointLengthInBytes = kTimestampLength + [dataTranslator dataLengthInBytes];
    if(fileContents.length < index + dataPointLengthInBytes) {
        return nil;
    }
    
    dataPoint.rawData = [fileContents subdataWithRange:NSMakeRange(index, dataPointLengthInBytes)];
    dataPoint.timestamp = *(unsigned int*)(dataPoint.rawData.bytes);
    dataPoint.data = [dataTranslator translateDataToObject:[dataPoint.rawData subdataWithRange:NSMakeRange(kTimestampLength, [dataTranslator dataLengthInBytes])]];
    
    return dataPoint;
}

+ (LPLLogDataPoint*)dataPointFromTimestamp:(unsigned int)timestamp
                                   andData:(id)data
                        withDataTranslator:(id<LPLDataTranslator>)dataTranslator
{
    LPLLogDataPoint* dataPoint = [[LPLLogDataPoint alloc] init];
    
    NSData* dataToWrite = [dataTranslator translateObjectToData:data];
    if(dataToWrite == nil) {
        return nil;
    }
    
    NSMutableData* dataPointRawData = [[NSMutableData alloc] init];
    [dataPointRawData appendBytes:&timestamp length:kTimestampLength];
    [dataPointRawData appendData:dataToWrite];
    
    dataPoint.rawData = dataPointRawData;
    dataPoint.timestamp = timestamp;
    dataPoint.data = data;
    
    return dataPoint;
}

@end