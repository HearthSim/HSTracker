#import <Foundation/Foundation.h>

@interface CVRankDetectorWrapper : NSObject
- (instancetype)init;
- (int)detectRank: (NSString*) temppath;
@end