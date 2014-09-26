//
//  LPLFileManager.h
//  LappyLogger
//
//  Created by Ben Oztalay on 9/22/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPLFileManager : NSObject

@property (strong, nonatomic) NSString* filePath;
@property (strong, nonatomic) NSString* dataSourceName;
@property (nonatomic) NSUInteger dataPointLength;

- (id)initWithFileName:(NSString*)fileName
     andDataSourceName:(NSString*)dataSourceName
    andDatapointLength:(NSUInteger)dataPointLength;

- (BOOL)appendDatapointAndReturnSuccess:(NSData*)datapoint;

@end
