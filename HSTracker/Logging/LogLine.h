/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import <Foundation/Foundation.h>

@interface LogLine : NSObject

@property(nonatomic) NSTimeInterval time;
@property(nonatomic, strong) NSString *namespace;
@property(nonatomic, strong) NSString *line;

- (instancetype)initWithNamespace:(NSString *)namespace time:(NSTimeInterval)time line:(NSString *)line;

- (NSString *)description;

@end
