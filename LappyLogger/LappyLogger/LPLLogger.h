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

+ (LPLLogger*)sharedInstance;

- (void)logFromClass:(NSString*)className withMessage:(NSString*)message, ...;

- (void)incrementIndent;
- (void)decrementIndent;

@end
