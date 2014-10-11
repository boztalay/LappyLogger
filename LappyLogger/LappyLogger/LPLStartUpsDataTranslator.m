//
//  LPLStartUpsDataTranslator.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/11/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLStartUpsDataTranslator.h"

@implementation LPLStartUpsDataTranslator

#define kDataPointLength 1

- (NSData*)translateObjectToData:(id)objectToTranslate
{
    if(![objectToTranslate isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    unsigned char startedUp = [objectToTranslate unsignedCharValue];
    return [NSData dataWithBytes:&startedUp length:[self dataLengthInBytes]];
}

- (id)translateDataToObject:(NSData *)dataToTranslate
{
    if(dataToTranslate.length != [self dataLengthInBytes]) {
        return nil;
    }
    
    unsigned char startedUp = ((char*)dataToTranslate.bytes)[0];
    return [NSNumber numberWithUnsignedChar:startedUp];
}

- (NSUInteger)dataLengthInBytes
{
    return kDataPointLength;
}

@end
