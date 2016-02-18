/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import "Mulligan.h"

@implementation Mulligan

+ (BOOL)tryParse:(NSString *)rawValue out:(EMulligan *)out
{
  if ([rawValue isEqualToString:@"INVALID"]) {*out = EMulligan_INVALID;}
  else if ([rawValue isEqualToString:@"INPUT"]) {*out = EMulligan_INPUT;}
  else if ([rawValue isEqualToString:@"DEALING"]) {*out = EMulligan_DEALING;}
  else if ([rawValue isEqualToString:@"WAITING"]) {*out = EMulligan_WAITING;}
  else if ([rawValue isEqualToString:@"DONE"]) {*out = EMulligan_DONE;}
  else {
    *out = EMulligan_INVALID;
    return NO;
  }
  return YES;
}

@end
