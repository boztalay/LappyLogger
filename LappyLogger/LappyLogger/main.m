//
//  main.m
//  LappyLogger
//
//  Created by Ben Oztalay on 9/19/14.
//  Copyright (c) 2014 Ben Oztalay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPLLappyLogger.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[LPLLappyLogger sharedInstance] start];
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}