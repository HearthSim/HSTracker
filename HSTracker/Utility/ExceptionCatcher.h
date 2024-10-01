//
//  ExceptionCatcher.h
//  HSTracker
//
//  Created by flytam on 1/10/2024.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExceptionCatcher : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;


@end

NS_ASSUME_NONNULL_END
