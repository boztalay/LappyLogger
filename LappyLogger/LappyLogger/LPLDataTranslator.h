//
//  LPLDataTranslator.h
//  LappyLogger
//
//  Created by Ben Oztalay on 10/2/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LPLDataTranslator <NSObject>

@required

- (NSData*)translateObjectToData:(id)objectToTranslate;
- (id)translateDataToObject:(NSData*)dataToTranslate;
- (NSUInteger)dataPointLength;

@end