//
//  CardMissingDetectorWrapper.hpp
//  HSTracker
//
//  Created by Benjamin Michotte on 31/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CardMissingDetectorWrapper : NSObject
- (instancetype)init;
- (int)detectLock: (NSString*) temppath;
- (bool)didInit;
@end
