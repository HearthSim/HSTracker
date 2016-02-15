/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "Game.h"
#import "Entity.h"
#import "Mulligan.h"

@interface Game ()
{
  NSInteger currentTurn;
}
@end

@implementation Game

+ (Game *)instance
{
  static Game *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      _instance = [[self alloc] init];
  });
  return _instance;
}

- (void)reset
{
  currentTurn = -1;
}

- (void)gameStart
{

}

- (void)gameEnd
{

}

- (void)setPlayerHero:(NSString *)cardId
{

}

- (void)setOpponentHero:(NSString *)cardId
{

}

- (void)setPlayerRank:(NSInteger)rank
{

}

- (void)setPlayerName:(NSString *)name
{

}

- (void)setOpponentName:(NSString *)name
{

}

- (NSNumber *)turnNumber
{
  if (![self isMulliganDone]) {
    return @0;
  }

  if (currentTurn == -1) {
    Entity *player;
    for (Entity *ent in self.entities) {
      if ([ent hasTag:EGameTag_FIRST_PLAYER]) {
        player = ent;
        break;
      }
    }
    if (player) {
      currentTurn = [[player getTag:EGameTag_CONTROLLER] isEqualToNumber:self.playerId] ? 0 : 1;
    }
  }

  Entity *entity = [[self.entities allValues] firstObject];
  if (entity) {
    return @(([[entity getTag:EGameTag_TURN] integerValue] + (currentTurn == -1 ? 0 : currentTurn)) / 2);
  }
  return @0;
}

- (void)opponentJoust:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)playerJoust:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)playerGetToDeck:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentGetToDeck:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentSecretTrigger:(NSString *)cardId turn:(NSNumber *)turn id:(NSNumber *)id
{

}

- (void)playerFatigue:(NSInteger)value
{

}

- (void)opponentFatigue:(NSInteger)value
{

}

- (void)turnStart:(PlayerType)player turn:(NSNumber *)turn
{

}

- (void)concede
{

}

- (void)win
{

}

- (void)loss
{

}

- (void)tied
{

}

- (BOOL)isMulliganDone
{
  Entity *player, *opponent;
  for (Entity *ent in self.entities) {
    if (ent.isPlayer) {
      player = ent;
    }
    else if ([ent hasTag:EGameTag_PLAYER_ID] && !ent.isPlayer) {
      opponent = ent;
    }
  }

  if (player == nil || opponent == nil) {
    return NO;
  }

  return [[player getTag:EGameTag_MULLIGAN_STATE] isEqualToNumber:@(EMulligan_DONE)]
    && [[opponent getTag:EGameTag_MULLIGAN_STATE] isEqualToNumber:@(EMulligan_DONE)];
}

- (void)playerGet:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentGet:(NSNumber *)turn id:(NSNumber *)id
{

}

- (void)playerBackToHand:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentPlayToHand:(NSString *)cardId turn:(NSNumber *)turn id:(NSNumber *)id
{

}

- (void)playerPlayToDeck:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentPlayToDeck:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentPlay:(NSString *)cardId from:(id)from turn:(NSNumber *)turn
{

}

- (void)playerHandDiscard:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentHandDiscard:(NSString *)cardId from:(id)from turn:(NSNumber *)turn
{

}

- (void)playerSecretPlayed:(NSString *)cardId turn:(NSNumber *)turn fromDeck:(BOOL)deck
{

}

- (void)opponentSecretPlayed:(NSString *)cardId from:(id)from turn:(NSNumber *)turn fromDeck:(BOOL)deck id:(NSNumber *)id
{

}

- (void)opponentMulligan:(id)tag
{

}

- (void)player_mulligan:(NSString *)cardId
{

}

- (void)playerPlay:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)playerDraw:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentDraw:(NSNumber *)turn
{

}

- (void)playerRemoveFromDeck:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentRemoveFromDeck:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentDeckDiscard:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)playerDeckDiscard:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)playerDeckToPlay:(NSString *)cardId turn:(NSNumber *)turn
{

}

- (void)opponentDeckToPlay:(NSString *)cardId turn:(NSNumber *)turn
{

}
@end
