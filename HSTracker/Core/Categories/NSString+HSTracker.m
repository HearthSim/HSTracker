/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */
#import "NSString+HSTracker.h"

@implementation NSString (HSTracker)
- (BOOL)isEmpty
{
  if ([self length] == 0) {
    return YES;
  }
  return [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0;
}

- (BOOL)tryParse:(NSInteger *)out
{
  *out = [self integerValue];
  return [self isEqualToString:[NSString stringWithFormat:@"%ld", *out]];
}
@end
