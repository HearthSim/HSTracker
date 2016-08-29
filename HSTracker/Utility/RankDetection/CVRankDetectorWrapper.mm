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