//
//  ExceptionCatcher.m
//  HSTracker
//
//  Created by flytam on 1/10/2024.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

#import "ExceptionCatcher.h"

@implementation ExceptionCatcher

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end

