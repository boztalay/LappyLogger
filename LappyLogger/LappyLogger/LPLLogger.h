//
//  LPLLogger.h
//  LappyLogger
//
//  Created by Ben Oztalay on 10/6/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LPLLogger : NSObject {
    NSUInteger currentIndent;
}

@property (strong, nonatomic) NSString* filePath;
@property (strong, nonatomic) NSFileHandle* fileHandle;
@property (nonatomic) dispatch_queue_t logFileWritingQueue;

+ (LPLLogger*)sharedInstance;
- (id)initWithFileName:(NSString*)fileName;

- (void)logFromClass:(NSString*)className withMessage:(NSString*)message, ...;

- (void)incrementIndent;
- (void)decrementIndent;

@end
