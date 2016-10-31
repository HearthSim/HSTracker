//
//  CVRankDetector.cpp
//  HSTracker
//
//  Created by Matthew Welborn on 6/17/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import "CVRankDetectorWrapper.hpp"
#include "CVRankDetector.hpp"

@interface CVRankDetectorWrapper()
@property CVRankDetector *cppItem;
@end

@implementation CVRankDetectorWrapper
- (instancetype)init
{
    if (self = [super init]) {
        self.cppItem = new CVRankDetector();
    }
    return self;
}
- (int)detectRank: (NSString*) temppath
{
    return self.cppItem->detectRank(std::string([temppath cStringUsingEncoding:NSUTF8StringEncoding]));
}

- (bool)didInit
{
    return self.cppItem->getDidInit();
}

@end
