//
//  LPLKeystrokesDataTranslator.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/10/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLKeystrokesDataTranslator.h"

@implementation LPLKeystrokesDataTranslator

#define kDataPointLength 2

- (NSData*)translateObjectToData:(id)objectToTranslate
{
    if(![objectToTranslate isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    unsigned short keystrokes = [objectToTranslate unsignedShortValue];
    return [NSData dataWithBytes:&keystrokes length:[self dataLengthInBytes]];
}

- (id)translateDataToObject:(NSData *)dataToTranslate
{
    if(dataToTranslate.length != [self dataLengthInBytes]) {
        return nil;
    }
    
    unsigned short keystrokes = ((short*)dataToTranslate.bytes)[0];
    return [NSNumber numberWithUnsignedShort:keystrokes];
}

- (NSUInteger)dataLengthInBytes
{
    return kDataPointLength;
}

@end
