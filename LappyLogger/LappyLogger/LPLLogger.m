//
//  LPLLogger.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/6/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogger.h"

@implementation LPLLogger

+ (LPLLogger*)sharedInstance
{
    static LPLLogger* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LPLLogger alloc] init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if(self) {
        currentIndent = 0;
    }
    return self;
}

- (void)logFromClass:(NSString*)className withMessage:(NSString*)message, ...
{
    va_list args;
    va_start(args, message);
    
    NSString* indents = [@"" stringByPaddingToLength:currentIndent withString:@"-" startingAtIndex:0];
    NSString* spaceOrNoSpace = currentIndent > 0 ? @" " : @"";
    NSString* fullMessage = [NSString stringWithFormat:@"%@:%@%@ %@", className, spaceOrNoSpace, indents, message];
    NSLogv(fullMessage, args);
    
    va_end(args);
}

- (void)incrementIndent
{
    currentIndent++;
}

- (void)decrementIndent
{
    if(currentIndent > 0) {
        currentIndent--;
    }
}

@end
