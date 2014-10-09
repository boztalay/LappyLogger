//
//  LPLACConnectionStatusDataTranslator.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/9/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLACConnectionStatusDataTranslator.h"

@implementation LPLACConnectionStatusDataTranslator

#define kDataPointLength 1

- (NSData*)translateObjectToData:(id)objectToTranslate
{
    if(![objectToTranslate isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    unsigned char acConnectionStatus = [objectToTranslate unsignedCharValue];
    
    return [NSData dataWithBytes:&acConnectionStatus length:[self dataLengthInBytes]];
}

- (id)translateDataToObject:(NSData *)dataToTranslate
{
    if(dataToTranslate.length != [self dataLengthInBytes]) {
        return nil;
    }
    
    unsigned char acConnectionStatus = ((char*)dataToTranslate.bytes)[0];
    return [NSNumber numberWithUnsignedChar:acConnectionStatus];
}

- (NSUInteger)dataLengthInBytes
{
    return kDataPointLength;
}

@end
