//
//  LPLBatteryPercentageDataTranslator.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLBatteryPercentageDataTranslator.h"

#define kDataPointLength 1

@implementation LPLBatteryPercentageDataTranslator

- (NSData*)translateObjectToData:(id)objectToTranslate
{
    char batteryPercentage = [objectToTranslate charValue];
    return [NSData dataWithBytes:&batteryPercentage length:[self dataLengthInBytes]];
}

- (id)translateDataToObject:(NSData *)dataToTranslate
{
    if(dataToTranslate.length != [self dataLengthInBytes]) {
        return nil;
    }
    
    char batteryPercentage = ((char*)dataToTranslate.bytes)[0];
    return [NSNumber numberWithUnsignedChar:batteryPercentage];
}

- (NSUInteger)dataLengthInBytes
{
    return kDataPointLength;
}

@end
