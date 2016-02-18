/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */
#import "GameMode.h"

@implementation GameMode

+ (NSString *)toString:(EGameMode)gameMode
{
  switch (gameMode) {
    case EGameMode_Unknow:
      return @"Unknown";
    case EGameMode_Ranked:
      return @"Ranked";
    case EGameMode_Casual:
      return @"Casual";
    case EGameMode_Arena:
      return @"Arena";
    case EGameMode_Brawl:
      return @"Brawl";
    case EGameMode_Spectator:
      return @"Spectator";
    case EGameMode_Friendly:
      return @"Friendly";
    case EGameMode_Practice:
      return @"Practice";
  }
}
@end
