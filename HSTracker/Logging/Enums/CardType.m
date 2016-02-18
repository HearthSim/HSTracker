/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import "CardType.h"

@implementation CardType

+ (BOOL)tryParse:(NSString *)rawValue out:(ECardType *)out
{
  if ([rawValue isEqualToString:@"INVALID"]) {*out = ECardType_INVALID;}
  else if ([rawValue isEqualToString:@"GAME"]) {*out = ECardType_GAME;}
  else if ([rawValue isEqualToString:@"PLAYER"]) {*out = ECardType_PLAYER;}
  else if ([rawValue isEqualToString:@"HERO"]) {*out = ECardType_HERO;}
  else if ([rawValue isEqualToString:@"MINION"]) {*out = ECardType_MINION;}
  else if ([rawValue isEqualToString:@"SPELL"]) {*out = ECardType_SPELL;}
  else if ([rawValue isEqualToString:@"ENCHANTMENT"]) {*out = ECardType_ENCHANTMENT;}
  else if ([rawValue isEqualToString:@"WEAPON"]) {*out = ECardType_WEAPON;}
  else if ([rawValue isEqualToString:@"ITEM"]) {*out = ECardType_ITEM;}
  else if ([rawValue isEqualToString:@"TOKEN"]) {*out = ECardType_TOKEN;}
  else if ([rawValue isEqualToString:@"HERO_POWER"]) {*out = ECardType_HERO_POWER;}
  else {
    *out = ECardType_INVALID;
    return NO;
  }

  return YES;
}

@end
