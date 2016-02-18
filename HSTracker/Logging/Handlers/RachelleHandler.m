/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "RachelleHandler.h"
#import "GameMode.h"
#import "Game.h"

static NSString *const TowardsGolds = @"(\\d)/3 wins towards 10 gold";
static NSString *const CardInCache = @".*somehow the card def for (\\w+_\\w+) was already in the cache\\.\\.\\.";

@implementation RachelleHandler

+ (void)handle:(NSString *)line
{
  if ([line isMatch:RX(TowardsGolds)]) {
    NSInteger victories = [[line firstMatch:RX(TowardsGolds)] integerValue];
    DDLogInfo(@"%ld / 3 -> 10 gold", victories);
  }

  if ([line isMatch:RX(CardInCache)]) {
    RxMatch *match = [line firstMatchWithDetails:RX(CardInCache)];
    NSString *cardId = ((RxMatchGroup *)match.groups[1]).value;
    if ([Game instance].gameMode == EGameMode_Arena){
      DDLogInfo(@"Possible arena card draft : %@ ?", cardId);
    }
    else {
      DDLogInfo(@"Possible constructed card draft : %@ ?", cardId);
    }
  }
}

@end
