//
//  LPLLogger.m
//  LappyLogger
//
//  Created by Ben Oztalay on 10/6/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import "LPLLogger.h"
#import "LPLConfigManager.h"

#define kLogFileName @"LappyLogger.log"
#define kLogFileWritingQueueName "com.boztalay.LappyLogger.logFileWriting"

@implementation LPLLogger

#pragma mark - Init

+ (LPLLogger*)sharedInstance
{
    static LPLLogger* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LPLLogger alloc] initWithFileName:kLogFileName];
    });
    
    return instance;
}

- (id)initWithFileName:(NSString*)fileName
{
    self = [super init];
    if(self) {
        self.filePath = [[LPLConfigManager sharedInstance].dotDirectoryPath stringByAppendingPathComponent:fileName];
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
            [[NSFileManager defaultManager] createFileAtPath:self.filePath contents:nil attributes:nil];
        }
        
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
        
        self.logFileWritingQueue = dispatch_queue_create(kLogFileWritingQueueName, DISPATCH_QUEUE_SERIAL);
        currentIndent = 0;
        
        [self logDateLineToFile];
    }
    return self;
}

- (void)logDateLineToFile
{
    NSDate* today= [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:today];
    
    [self logMessageToFile:[NSString stringWithFormat:@"\n%@\n", dateString]];
}

- (void)dealloc
{
    [self.fileHandle closeFile];
}

#pragma mark - Logging

- (void)logFromClass:(NSString*)className withMessage:(NSString*)message, ...
{
    va_list args;
    va_start(args, message);
    
    NSString* indents = [@"" stringByPaddingToLength:(currentIndent + 1) * 2 withString:@"-" startingAtIndex:0];
    NSString* fullMessage = [NSString stringWithFormat:@"%@ %@: %@", indents, className, message];
    NSString* expandedMessage = [[NSString alloc] initWithFormat:fullMessage arguments:args];
    NSLog(@"%@", expandedMessage);
    
    [self logMessageToFile:expandedMessage];
    
    va_end(args);
}

- (void)logMessageToFile:(NSString*)message
{
    if(self.fileHandle == nil) {
        return;
    }
    
    dispatch_async(self.logFileWritingQueue, ^{
        NSString* messageWithNewline = [message stringByAppendingString:@"\n"];
        
        @try {
            [self.fileHandle seekToEndOfFile];
            [self.fileHandle writeData:[messageWithNewline dataUsingEncoding:NSUTF8StringEncoding]];
        } @catch(NSException* e) {
            
        }
    });
}

#pragma mark - Indentation

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
