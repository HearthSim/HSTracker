/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 16/02/16.
 */
#import "NSUserDefaults+ColorSupport.h"

@implementation NSUserDefaults (ColorSupport)

- (void)setColor:(NSColor *)aColor forKey:(NSString *)aKey
{
  NSData *theData = [NSArchiver archivedDataWithRootObject:aColor];
  [self setObject:theData forKey:aKey];
}

- (NSColor *)colorForKey:(NSString *)aKey
{
  NSColor *theColor = nil;
  NSData *theData = [self dataForKey:aKey];
  if (theData != nil) {
    theColor = (NSColor *) [NSUnarchiver unarchiveObjectWithData:theData];
  }
  return theColor;
}

@end
