/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "BobHandler.h"
#import "Game.h"

@implementation BobHandler

+ (void)handle:(NSString *)line
{
  if (![line isMatch:RX(@"---Register")]) {
    return;
  }

  Game *game = [Game instance];
  if ([line isMatch:RX(@"---RegisterScreenBox---")]) {
    if (game.gameMode == GameMode_Spectator) {
      [game gameEnd];
    }
  }
  else if ([line isMatch:RX(@"---RegisterScreenForge---")]) {
    game.gameMode = GameMode_Arena;
  }
  else if ([line isMatch:RX(@"---RegisterScreenPractice---")]) {
    game.gameMode = GameMode_Practice;
  }
  else if ([line isMatch:RX(@"---RegisterScreenTourneys---")]) {
    game.gameMode = GameMode_Casual;
  }
  else if ([line isMatch:RX(@"---RegisterScreenFriendly---")]) {
    game.gameMode = GameMode_Friendly;
  }
}

@end
