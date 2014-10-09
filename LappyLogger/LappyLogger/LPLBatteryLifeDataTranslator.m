//
//  LPLBatteryLifeDataTranslator.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/9/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLBatteryLifeDataTranslator.h"

@implementation LPLBatteryLifeDataTranslator

#define kDataPointLength 2

- (NSData*)translateObjectToData:(id)objectToTranslate
{
    if(![objectToTranslate isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    unsigned short batteryLife = [objectToTranslate unsignedShortValue];
    return [NSData dataWithBytes:&batteryLife length:[self dataLengthInBytes]];
}

- (id)translateDataToObject:(NSData *)dataToTranslate
{
    if(dataToTranslate.length != [self dataLengthInBytes]) {
        return nil;
    }
    
    unsigned short batteryLife = ((short*)dataToTranslate.bytes)[0];
    return [NSNumber numberWithUnsignedShort:batteryLife];
}

- (NSUInteger)dataLengthInBytes
{
    return kDataPointLength;
}

@end
