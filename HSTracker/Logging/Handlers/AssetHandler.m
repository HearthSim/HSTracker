/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "AssetHandler.h"
#import "Game.h"

static NSString *const MedalRank = @"Medal_Ranked_(\\d+)";
static NSString *const UnloadingCard = @"unloading name=(\\w+_\\w+) family=CardPrefab persistent=False";

@implementation AssetHandler

+ (void)handle:(NSString *)line
{
  Game *game = [Game instance];
  if (game.awaitingRankedDetection) {
    game.lastAssetUnload = [NSDate date].timeIntervalSince1970;
    game.awaitingRankedDetection = NO;
  }

  if ([line isMatch:RX(MedalRank)]) {
    NSNumber *rank = @([[line firstMatch:RX(MedalRank)] integerValue]);
    [game setPlayerRank:rank];
  }
  else if ([line isMatch:RX(@"rank_window")]) {
    game.rankFound = YES;
    game.gameMode = EGameMode_Ranked;
  }
  else if ([line isMatch:RX(UnloadingCard)]) {
    RxMatch *match = [line firstMatchWithDetails:RX(UnloadingCard)];
    NSString *cardId = ((RxMatchGroup *) match.groups[1]).value;
    if (game.gameMode == EGameMode_Arena) {
      DDLogInfo(@"Possible arena card draft : %@ ?", cardId);
    }
    else {
      DDLogInfo(@"Possible constructed card draft : %@ ?", cardId);
    }
  }
  else if ([line isMatch:RX(@"unloading name=Tavern_Brawl")]) {
    game.gameMode = EGameMode_Brawl;
  }
}

@end
