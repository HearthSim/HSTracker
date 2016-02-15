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

@class LogReaderManager;

@interface LogReader : NSObject

- (instancetype)initWithName:(NSString *)name logReaderManager:(LogReaderManager *)logReaderManager;

- (instancetype)initWithName:(NSString *)name logReaderManager:(LogReaderManager *)logReaderManager startFilters:(NSArray *)startFilters containsFilters:(NSArray *)containsFilters;

- (NSTimeInterval)findEntryPoint:(NSString *)str;

- (void)start:(NSTimeInterval)entryPoint;

- (void)stop;

@end
