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

+ (BOOL)tryParse:(NSString *)rawValue out:(EPlayState *)out
{
  if ([rawValue isEqualToString:@"INVALID"]) {*out =  EPlayState_INVALID;}
  else if ([rawValue isEqualToString:@"PLAYING"]) {*out =  EPlayState_PLAYING;}
  else if ([rawValue isEqualToString:@"WINNING"]) {*out =  EPlayState_WINNING;}
  else if ([rawValue isEqualToString:@"LOSING"]) {*out =  EPlayState_LOSING;}
  else if ([rawValue isEqualToString:@"WON"]) {*out =  EPlayState_WON;}
  else if ([rawValue isEqualToString:@"LOST"]) {*out =  EPlayState_LOST;}
  else if ([rawValue isEqualToString:@"TIED"]) {*out =  EPlayState_TIED;}
  else if ([rawValue isEqualToString:@"DISCONNECTED"]) {*out =  EPlayState_DISCONNECTED;}
  else if ([rawValue isEqualToString:@"CONCEDED"]) {*out =  EPlayState_CONCEDED;}
  else if ([rawValue isEqualToString:@"QUIT"]) {*out =  EPlayState_QUIT;}
  else {
    *out = EPlayState_INVALID;
    return NO;
  }
  return YES;
}

@end
