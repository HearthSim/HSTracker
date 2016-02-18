/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import "Zone.h"

@implementation Zone

+ (BOOL)tryParse:(NSString *)rawValue out:(EZone *)out
{
  if ([rawValue isEqualToString:@"INVALID"]) {*out = EZone_INVALID;}
  else if ([rawValue isEqualToString:@"CREATED"]) {*out = EZone_CREATED;}
  else if ([rawValue isEqualToString:@"PLAY"]) {*out = EZone_PLAY;}
  else if ([rawValue isEqualToString:@"DECK"]) {*out = EZone_DECK;}
  else if ([rawValue isEqualToString:@"HAND"]) {*out = EZone_HAND;}
  else if ([rawValue isEqualToString:@"GRAVEYARD"]) {*out = EZone_GRAVEYARD;}
  else if ([rawValue isEqualToString:@"REMOVEDFROMGAME"]) {*out = EZone_REMOVEDFROMGAME;}
  else if ([rawValue isEqualToString:@"SETASIDE"]) {*out = EZone_SETASIDE;}
  else if ([rawValue isEqualToString:@"SECRET"]) {*out = EZone_SECRET;}
  else {
    *out = EZone_CREATED;
    return NO;
  }
  return YES;
}

@end
