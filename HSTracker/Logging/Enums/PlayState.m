/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import "PlayState.h"

@implementation PlayState

+ (EPlayState)parse:(NSString *)rawValue
{
  if ([rawValue isEqualToString:@"INVALID"]) {return EPlayState_INVALID;}
  else if ([rawValue isEqualToString:@"PLAYING"]) {return EPlayState_PLAYING;}
  else if ([rawValue isEqualToString:@"WINNING"]) {return EPlayState_WINNING;}
  else if ([rawValue isEqualToString:@"LOSING"]) {return EPlayState_LOSING;}
  else if ([rawValue isEqualToString:@"WON"]) {return EPlayState_WON;}
  else if ([rawValue isEqualToString:@"LOST"]) {return EPlayState_LOST;}
  else if ([rawValue isEqualToString:@"TIED"]) {return EPlayState_TIED;}
  else if ([rawValue isEqualToString:@"DISCONNECTED"]) {return EPlayState_DISCONNECTED;}
  else if ([rawValue isEqualToString:@"CONCEDED"]) {return EPlayState_CONCEDED;}
  else if ([rawValue isEqualToString:@"QUIT"]) {return EPlayState_QUIT;}
  else {return (EPlayState) 0;}
}

@end
