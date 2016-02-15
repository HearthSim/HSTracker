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

@implementation AssetHandler

+ (void)handle:(NSString *)line
{
  Game *game = [Game instance];
  if (game.awaitingRankedDetection) {
    game.lastAssetUnload = [NSDate date].timeIntervalSince1970;
    game.awaitingRankedDetection = NO;
  }

  RxMatch *match;
  if ((match = [line firstMatchWithDetails:RX(@"Medal_Ranked_(\\d+)")]) != nil) {
    NSInteger rank = [match.value integerValue];
    [game setPlayerRank:rank];
  }
  else if ([line isMatch:RX(@"rank_window")]) {
    game.rankFound = YES;
    game.gameMode = GameMode_Ranked;
  }
  else if ((match = [line firstMatchWithDetails:RX(@"unloading name=(\\w+_\\w+) family=CardPrefab persistent=False")]) != nil) {
    NSString *cardId = match.value;
    if (game.gameMode == GameMode_Arena) {
      DDLogInfo(@"Possible arena card draft : %@ ?", cardId);
    }
    else {
      DDLogInfo(@"Possible constructed card draft : %@ ?", cardId);
    }
  }
  else if ([line isMatch:RX(@"unloading name=Tavern_Brawl")]) {
    game.gameMode = GameMode_Brawl;
  }
}

@end
