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

+ (ECardType)parse:(NSString *)rawValue
{
  if ([rawValue isEqualToString:@"INVALID"]) { return ECardType_INVALID; }
  else if ([rawValue isEqualToString:@"GAME"]) { return ECardType_GAME; }
  else if ([rawValue isEqualToString:@"PLAYER"]) { return ECardType_PLAYER; }
  else if ([rawValue isEqualToString:@"HERO"]) { return ECardType_HERO; }
  else if ([rawValue isEqualToString:@"MINION"]) { return ECardType_MINION; }
  else if ([rawValue isEqualToString:@"ABILITY"]) { return ECardType_ABILITY; }
  else if ([rawValue isEqualToString:@"ENCHANTMENT"]) { return ECardType_ENCHANTMENT; }
  else if ([rawValue isEqualToString:@"WEAPON"]) { return ECardType_WEAPON; }
  else if ([rawValue isEqualToString:@"ITEM"]) { return ECardType_ITEM; }
  else if ([rawValue isEqualToString:@"TOKEN"]) { return ECardType_TOKEN; }
  else if ([rawValue isEqualToString:@"HERO_POWER"]) { return ECardType_HERO_POWER; }
  else {return (ECardType) 0;}
}

@end
