//
//  CardMissingDetectorWrapper.m
//  HSTracker
//
//  Created by Benjamin Michotte on 31/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import "CardMissingDetectorWrapper.hpp"
#include "CardMissingDetector.hpp"

@interface CardMissingDetectorWrapper()
@property CardMissingDetector *cppItem;
@end

@implementation CardMissingDetectorWrapper
- (instancetype)init
{
    if (self = [super init]) {
        self.cppItem = new CardMissingDetector();
    }
    return self;
}

- (int)detectLock: (NSString*) temppath
{
    return self.cppItem->detectLocks(std::string([temppath cStringUsingEncoding:NSUTF8StringEncoding]));
}

- (bool)didInit
{
    return self.cppItem->getDidInit();
}

@end
