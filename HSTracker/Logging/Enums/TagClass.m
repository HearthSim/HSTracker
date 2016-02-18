/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */
#import "TagClass.h"

@implementation TagClass

+ (BOOL)tryParse:(NSString *)rawValue out:(ETagClass *)out
{
  if ([rawValue isEqualToString:@"INVALID"]) {*out = ETagClass_INVALID;}
  else if ([rawValue isEqualToString:@"DEATHKNIGHT"]) {*out = ETagClass_DEATHKNIGHT;}
  else if ([rawValue isEqualToString:@"DRUID"]) {*out = ETagClass_DRUID;}
  else if ([rawValue isEqualToString:@"HUNTER"]) {*out = ETagClass_HUNTER;}
  else if ([rawValue isEqualToString:@"MAGE"]) {*out = ETagClass_MAGE;}
  else if ([rawValue isEqualToString:@"PALADIN"]) {*out = ETagClass_PALADIN;}
  else if ([rawValue isEqualToString:@"PRIEST"]) {*out = ETagClass_PRIEST;}
  else if ([rawValue isEqualToString:@"ROGUE"]) {*out = ETagClass_ROGUE;}
  else if ([rawValue isEqualToString:@"SHAMAN"]) {*out = ETagClass_SHAMAN;}
  else if ([rawValue isEqualToString:@"WARLOCK"]) {*out = ETagClass_WARLOCK;}
  else if ([rawValue isEqualToString:@"WARRIOR"]) {*out = ETagClass_WARRIOR;}
  else if ([rawValue isEqualToString:@"DREAM"]) {*out = ETagClass_DREAM;}
  else {
    *out = ETagClass_INVALID;
    return NO;
  }
  return YES;
}

@end
