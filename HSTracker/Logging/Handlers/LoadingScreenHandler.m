/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */
#import "LoadingScreenHandler.h"
#import "GameMode.h"
#import "Game.h"

@implementation LoadingScreenHandler

+ (void)handle:(NSString *)line
{
  NSString *regex = @"prevMode=(\\w+).*currMode=(\\w+)";
  if (![line isMatch:RX(regex)]) {
    return;
  }

  RxMatch *match = [line firstMatchWithDetails:RX(regex)];
  NSString *prev = ((RxMatchGroup *)match.groups[1]).value;
  EGameMode newMode = [self parseGameMode:((RxMatchGroup *)match.groups[2]).value];

  Game *game = [Game instance];
  if (newMode != NSNotFound && !(game.gameMode == EGameMode_Ranked && newMode == EGameMode_Casual)) {
    game.gameMode = newMode;
  }
  if ([prev isEqualToString:@"GAMEPLAY"]) {
    //gameState.GameHandler.HandleInMenu();
  }
}

+ (EGameMode)parseGameMode:(NSString *)mode
{
  if ([mode isEqualToString:@"ADVENTURE"]) {
    return EGameMode_Practice;
  }
  else if ([mode isEqualToString:@"TAVERN_BRAWL"]) {
    return EGameMode_Brawl;
  }
  else if ([mode isEqualToString:@"TOURNAMENT"]) {
    return EGameMode_Casual;
  }
  else if ([mode isEqualToString:@"DRAFT"]) {
    return EGameMode_Arena;
  }
  else if ([mode isEqualToString:@"FRIENDLY"]) {
    return EGameMode_Friendly;
  }
  return (EGameMode) NSNotFound;
}


@end
