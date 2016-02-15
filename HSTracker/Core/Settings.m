/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "Settings.h"

NSString *const HearthstoneLanguage = @"hearthstone_language";
NSString *const HSTrackerLanguage = @"hstracker_language";
NSString *const HearthstoneLogPath = @"hearthstone_log_path";

@implementation Settings

+ (void)setObject:(nullable id)value forKey:(nonnull NSString *)key
{
  [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (nullable id)objectForKey:(nonnull NSString *)key
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

+ (BOOL)hasKey:(nonnull NSString *)key
{
  return [self objectForKey:key] != NULL;
}

@end
