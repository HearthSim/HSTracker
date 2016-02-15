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

extern NSString *__nonnull const HSTrackerLanguage;
extern NSString *__nonnull const HearthstoneLanguage;
extern NSString *__nonnull const HearthstoneLogPath;

@interface Settings : NSObject

+ (void)setObject:(nullable id)value forKey:(nonnull NSString *)key;

+ (nullable id)objectForKey:(nonnull NSString *)key;

+ (BOOL)hasKey:(nonnull NSString *)key;

@end
