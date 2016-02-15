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

+ (EZone)parse:(NSString *)rawValue
{
  if ([rawValue isEqualToString:@"INVALID"]) {return EZone_INVALID;}
  else if ([rawValue isEqualToString:@"CREATED"]) {return EZone_CREATED;}
  else if ([rawValue isEqualToString:@"PLAY"]) {return EZone_PLAY;}
  else if ([rawValue isEqualToString:@"DECK"]) {return EZone_DECK;}
  else if ([rawValue isEqualToString:@"HAND"]) {return EZone_HAND;}
  else if ([rawValue isEqualToString:@"GRAVEYARD"]) {return EZone_GRAVEYARD;}
  else if ([rawValue isEqualToString:@"REMOVEDFROMGAME"]) {return EZone_REMOVEDFROMGAME;}
  else if ([rawValue isEqualToString:@"SETASIDE"]) {return EZone_SETASIDE;}
  else if ([rawValue isEqualToString:@"SECRET"]) {return EZone_SECRET;}
  else { return (EZone) 0; }
}

@end
