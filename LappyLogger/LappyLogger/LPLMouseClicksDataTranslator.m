//
//  LPLMouseClicksDataTranslator.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/11/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLMouseClicksDataTranslator.h"

@implementation LPLMouseClicksDataTranslator

#define kDataPointLength 2

- (NSData*)translateObjectToData:(id)objectToTranslate
{
    if(![objectToTranslate isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    unsigned short mouseClicks = [objectToTranslate unsignedShortValue];
    return [NSData dataWithBytes:&mouseClicks length:[self dataLengthInBytes]];
}

- (id)translateDataToObject:(NSData *)dataToTranslate
{
    if(dataToTranslate.length != [self dataLengthInBytes]) {
        return nil;
    }
    
    unsigned short mouseClicks = ((short*)dataToTranslate.bytes)[0];
    return [NSNumber numberWithUnsignedShort:mouseClicks];
}

- (NSUInteger)dataLengthInBytes
{
    return kDataPointLength;
}

@end
