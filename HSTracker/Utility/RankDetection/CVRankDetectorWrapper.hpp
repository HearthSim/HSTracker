//
//  CVRankDetector.cpp
//  HSTracker
//
//  Created by Matthew Welborn on 6/17/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CVRankDetectorWrapper : NSObject
- (instancetype)init;
- (int)detectRank: (NSString*) temppath;
- (bool)didInit;
@end
