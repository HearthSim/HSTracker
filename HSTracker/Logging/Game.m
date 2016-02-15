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
#import "Tracker.h"
#import "Card.h"

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
  self.entities = [NSMutableDictionary dictionary];
  self.tmpEntities = [NSMutableArray array];
  self.joustReveals = 0;
  self.gameMode = GameMode_Unknow;
  self.rankFound = NO;
  self.awaitingRankedDetection = NO;
  self.lastAssetUnload = -1;
  self.opponentId = nil;
  self.playerId = nil;
  self.waitController = nil;
  self.gameStarted = NO;
  self.gameResult = GameResult_Unknow;
  self.gameStartDate = nil;
  self.gameEndDate = nil;
}

- (void)gameStart
{
  if (self.gameStarted) {
    return;
  }
  self.gameStarted = YES;
  [self reset];
  self.gameStartDate = [NSDate date];

  DDLogInfo(@"----- Game Started -----");

  [self.playerTracker gameStart];
  [self.opponentTracker gameStart];
}

- (void)gameEnd
{
  DDLogInfo(@"----- Game End -----");
  self.gameStarted = NO;
  self.gameEndDate = [NSDate date];

  //@opponent_cards = opponent_tracker.cards
  [self handleEndGame];

  [self.playerTracker gameEnd];
  [self.opponentTracker gameEnd];
  // TODO [self.timerHud gameEnd]
}

- (void)handleEndGame
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

- (void)setPlayerHero:(NSString *)cardId
{
  DDLogInfo(@"Player Hero is %@", [self cardName:cardId]);
}

- (void)setOpponentHero:(NSString *)cardId
{
  DDLogInfo(@"Opponent Hero is %@", [self cardName:cardId]);
}

- (void)setPlayerRank:(NSInteger)rank
{
  DDLogInfo(@"Player Hero is %ld", rank);
}

- (void)setPlayerName:(NSString *)name
{
  DDLogInfo(@"Player name is %@", name);
}

- (void)setOpponentName:(NSString *)name
{
  DDLogInfo(@"Opponent Hero is %@", name);
}

- (void)playerJoust:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player joust %@ on turn %@", [self cardName:cardId], turn);
}

- (void)opponentJoust:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent joust %@ on turn %@", [self cardName:cardId], turn);
}

- (void)playerGetToDeck:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player get %@ to deck on turn %@", [self cardName:cardId], turn);
}

- (void)opponentGetToDeck:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent get %@ to deck on turn %@", [self cardName:cardId], turn);
}

- (void)opponentSecretTrigger:(NSString *)cardId turn:(NSNumber *)turn id:(NSNumber *)id
{
  DDLogInfo(@"Opponent secret %@ triger on turn %@ / id %@", [self cardName:cardId], turn, id);
}

- (void)playerFatigue:(NSInteger)value
{
  DDLogInfo(@"Player get %ld fatigue", value);
}

- (void)opponentFatigue:(NSInteger)value
{
  DDLogInfo(@"Opponent get %ld fatigue", value);
}

- (void)turnStart:(PlayerType)player turn:(NSNumber *)turn
{
  DDLogInfo(@"Turn %@ start for player %@", turn, player);
}

- (void)concede
{
  DDLogInfo(@"Game has been conceded :(");
}

- (void)win
{
  DDLogInfo(@"You win ¯\\_(ツ)_/¯");
  self.gameResult = GameResult_Win;
}

- (void)loss
{
  DDLogInfo(@"You lose :(");
  self.gameResult = GameResult_Loss;
}

- (void)tied
{
  DDLogInfo(@"You lose :( / game tied:(");
  self.gameResult = GameResult_Tied;
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
  DDLogInfo(@"Player get %@ on turn %@", [self cardName:cardId], turn);
}

- (void)opponentGet:(NSNumber *)turn id:(NSNumber *)id
{
  DDLogInfo(@"Opponent get %@ on turn %@", id, turn);
}

- (void)playerBackToHand:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player %@ back to hand on turn %@", [self cardName:cardId], turn);
}

- (void)opponentPlayToHand:(NSString *)cardId turn:(NSNumber *)turn id:(NSNumber *)id
{
  DDLogInfo(@"Opponent %@ back to hand on turn %@ / id %@", [self cardName:cardId], turn, id);
}

- (void)playerPlayToDeck:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player play %@ to deck on turn %@", [self cardName:cardId], turn);
}

- (void)opponentPlayToDeck:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent play %@ to deck on turn %@", [self cardName:cardId], turn);
}

- (void)opponentPlay:(NSString *)cardId from:(id)from turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent play %@ on turn %@ from %@", [self cardName:cardId], turn, from);
}

- (void)playerPlay:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player play %@ on turn %@", [self cardName:cardId], turn);
}

- (void)playerHandDiscard:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player discard %@ from hand on turn %@", [self cardName:cardId], turn);
}

- (void)opponentHandDiscard:(NSString *)cardId from:(id)from turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent discard %@ from hand on turn %@ from %@", [self cardName:cardId], turn, from);
}

- (void)playerSecretPlayed:(NSString *)cardId turn:(NSNumber *)turn fromDeck:(BOOL)deck
{
  DDLogInfo(@"Player play secret %@ on turn %@ from %@", [self cardName:cardId], turn, deck ? @"deck" : @"hand");
}

- (void)opponentSecretPlayed:(NSString *)cardId from:(id)from turn:(NSNumber *)turn fromDeck:(BOOL)deck id:(NSNumber *)id
{
  DDLogInfo(@"Opponent play secret %@ on turn %@ from %@ (from %@, id %@)", [self cardName:cardId], turn, deck ? @"deck" : @"hand", from, id);
}

- (void)playerMulligan:(NSString *)cardId
{
  DDLogInfo(@"Player mulligan %@", [self cardName:cardId]);
}

- (void)opponentMulligan:(id)tag
{
  DDLogInfo(@"Opponent mulligan id %@", tag);
}

- (void)playerDraw:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player draw %@ on turn %@", [self cardName:cardId], turn);
}

- (void)opponentDraw:(NSNumber *)turn
{
  DDLogInfo(@"Opponent draw on turn %@", turn);
}

- (void)playerRemoveFromDeck:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player remove %@ from deck on turn %@", [self cardName:cardId], turn);
}

- (void)opponentRemoveFromDeck:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent remove %@ from deck on turn %@", [self cardName:cardId], turn);
}

- (void)playerDeckDiscard:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player discard %@ from deck on turn %@", [self cardName:cardId], turn);
}

- (void)opponentDeckDiscard:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent discard %@ from deck on turn %@", [self cardName:cardId], turn);
}

- (void)playerDeckToPlay:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Player play %@ from deck on turn %@", [self cardName:cardId], turn);
}

- (void)opponentDeckToPlay:(NSString *)cardId turn:(NSNumber *)turn
{
  DDLogInfo(@"Opponent play %@ from deck on turn %@", [self cardName:cardId], turn);
}

- (NSString *)cardName:(NSString *)cardId
{
  if (cardId == nil) {
    return @"N/A";
  }
  Card *card = [Card byId:cardId];
  if (card) {
    return card.name;
  }
  return @"N/A";
}
@end
