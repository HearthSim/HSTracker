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
#import "Card.h"
#import "GameTag.h"
#import "Player.h"
#import "NSString+HSTracker.h"

@interface Game ()
{
  NSInteger currentTurn;
}
@property(nonatomic, strong) NSNumber *currentRank;
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

- (instancetype)init
{
  if (self = [super init]) {
    self.player = [[Player alloc] initWithLocal:YES];
    self.opponent = [[Player alloc] initWithLocal:NO];
  }
  return self;
}

- (NSString *)cardName:(NSString *)cardId
{
  if (cardId == nil) {
    return @"N/A";
  }
  Card *card = [Card byId:cardId];
  if (card) {
    return [NSString stringWithFormat:@"%@ (%@)", card.name, cardId];
  }
  return @"N/A";
}

- (void)reset
{
  currentTurn = -1;
  self.entities = [NSMutableDictionary dictionary];
  self.tmpEntities = [NSMutableArray array];
  self.joustReveals = 0;
  self.gameMode = EGameMode_Unknow;
  self.rankFound = NO;
  self.awaitingRankedDetection = NO;
  self.lastAssetUnload = -1;
  self.waitController = nil;
  self.gameStarted = NO;
  self.gameResult = GameResult_Unknow;
  self.gameStartDate = nil;
  self.gameEndDate = nil;

  [self.player reset];
  [self.opponent reset];
}

- (void)setGameMode:(EGameMode)gameMode
{
  _gameMode = gameMode;
  DDLogInfo(@"Game mode found : %@", [GameMode toString:gameMode]);
}


- (Entity *)playerEntity
{
  for (Entity *ent in [self.entities allValues]) {
    if (ent.isPlayer) {
      return ent;
    }
  }
  return nil;
}

- (Entity *)opponentEntity
{
  for (Entity *ent in [self.entities allValues]) {
    if ([ent hasTag:EGameTag_PLAYER_ID] && !ent.isPlayer) {
      return ent;
    }
  }
  return nil;
}

- (void)gameStart
{
  if (self.gameStarted) {
    return;
  }
  [self reset];
  self.gameStarted = YES;
  self.gameStartDate = [NSDate date];

  DDLogInfo(@"----- Game Started -----");

  [self.player gameStart];
  [self.opponent gameStart];
}

- (void)gameEnd
{
  DDLogInfo(@"----- Game End -----");
  self.gameStarted = NO;
  self.gameEndDate = [NSDate date];

  //@opponent_cards = opponent_tracker.cards
  [self handleEndGame];

  [self.player gameEnd];
  [self.opponent gameEnd];
  // TODO [self.timerHud gameEnd]
}

- (void)handleEndGame
{
  if (self.gameMode == EGameMode_Unknow) {
    [self detectMode:3 completion:^{
        [self handleEndGame];
    }];
    return;
  }

  if (self.gameMode == EGameMode_Ranked && !self.rankFound) {
    [self waitForRank:5 completion:^{
        [self handleEndGame];
    }];
    return;
  }
}

- (void)waitForRank:(int)seconds completion:(void (^)())completion
{
  DDLogInfo(@"waiting for rank");
  self.rankFound = NO;
  NSTimeInterval timeout = [NSDate date].timeIntervalSince1970 + seconds;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      while ([NSDate date].timeIntervalSince1970 - self.lastAssetUnload < timeout) {
        [NSThread sleepForTimeInterval:0.1];
        if (self.rankFound) {
          break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
      }
  });
}

- (void)detectMode:(NSInteger)seconds completion:(void (^)())completion
{
  DDLogInfo(@"waiting for mode");
  self.awaitingRankedDetection = YES;
  self.rankFound = NO;
  self.lastAssetUnload = [NSDate date].timeIntervalSince1970;
  self.waitingForFirstAssetUnload = YES;
  NSTimeInterval timeout = [NSDate date].timeIntervalSince1970 + seconds;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      while (self.waitingForFirstAssetUnload || [NSDate date].timeIntervalSince1970 - self.lastAssetUnload < timeout) {
        [NSThread sleepForTimeInterval:0.1];
        if (self.rankFound) {
          break;
        }
      }

      dispatch_async(dispatch_get_main_queue(), ^{
          completion();
      });
  });
}

- (NSInteger)turnNumber
{
  if (![self isMulliganDone]) {
    return 0;
  }

  if (currentTurn == -1) {
    Entity *player;
    for (Entity *ent in [self.entities allValues]) {
      if ([ent hasTag:EGameTag_FIRST_PLAYER]) {
        player = ent;
        break;
      }
    }
    if (player) {
      currentTurn = [player getTag:EGameTag_CONTROLLER] == self.player.id ? 0 : 1;
    }
  }

  Entity *entity;
  for (Entity *ent in [self.entities allValues]) {
    if ([ent.name isEqualToString:@"GameEntity"]) {
      entity = ent;
      break;
    }
  }
  if (entity) {
    float turn = (float) ([entity getTag:EGameTag_TURN] + (currentTurn == -1 ? 0 : currentTurn)) / 2.0f;
    return (NSInteger) round(turn);
  }
  return 0;
}

- (void)turnStart:(PlayerType)player turn:(NSInteger)turn
{
  DDLogInfo(@"Turn %ld start for player %ld", turn, player);
  //timer_hud.restart(player)
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
  for (Entity *ent in [self.entities allValues]) {
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
  return [player getTag:EGameTag_MULLIGAN_STATE] == EMulligan_DONE
    && [opponent getTag:EGameTag_MULLIGAN_STATE] == EMulligan_DONE;
}

#pragma mark - player

- (void)setPlayerHero:(NSString *)cardId
{
  self.player.playerClass = [Card byId:cardId];
}

- (void)setPlayerRank:(NSNumber *)rank
{
  DDLogInfo(@"Player rank is %@", rank);
  self.currentRank = rank;
}

- (void)setPlayerName:(NSString *)name
{
  self.player.name = name;
}

- (void)playerGet:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  [self.player createInHand:entity turn:turn];
  /*if(cardId == "GAME_005" && _game.CurrentGameStats != null)
  {
    _game.CurrentGameStats.Coin = true;
    Logger.WriteLine("Got coin", "GameStats");
  }*/
}

- (void)playerBackToHand:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  DDLogInfo(@"Player %@ back to hand on turn %ld", [self cardName:cardId], turn);
  [self.player boardToHand:entity turn:turn];
}

- (void)playerPlayToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  DDLogInfo(@"Player play %@ to deck on turn %ld", [self cardName:cardId], turn);
  [self.player boardToDeck:entity turn:turn];
}

- (void)playerPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  DDLogInfo(@"Player play %@ on turn %ld", [self cardName:cardId], turn);
  [self.player play:entity turn:turn];
}

- (void)playerHandDiscard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  DDLogInfo(@"Player discard %@ from hand on turn %ld", [self cardName:cardId], turn);
  [self.player handDiscard:entity turn:turn];
}

- (void)playerSecretPlayed:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn fromDeck:(BOOL)fromDeck
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  DDLogInfo(@"Player play secret %@ on turn %ld from %@", [self cardName:cardId], turn, fromDeck ? @"deck" : @"hand");
  if (fromDeck) {
    [self.player secretPlayedFromDeck:entity turn:turn];
  }
  else {
    [self.player secretPlayedFromHand:entity turn:turn];
  }
}

- (void)playerMulligan:(Entity *)entity card:(NSString *)cardId
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  //TurnTimer.Instance.MulliganDone(ActivePlayer.Player);
  [self.player mulligan:entity];
}

- (void)playerDraw:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  if ([cardId isEqualToString:@"GAME_005"]) {
    [self playerGet:entity card:cardId turn:turn];
  }
  else {
    [self.player draw:entity turn:turn];
  }
}

- (void)playerRemoveFromDeck:(Entity *)entity turn:(NSInteger)turn
{
  [self.player removeFromDeck:entity turn:turn];
}

- (void)playerDeckDiscard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.player deckDiscard:entity turn:turn];
}

- (void)playerDeckToPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.player deckToPlay:entity turn:turn];
}

- (void)playerPlayToGraveyard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.player playToGraveyard:entity card:cardId turn:turn];
}

- (void)playerJoust:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.player joustReveal:entity turn:turn];
}

- (void)playerGetToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  if (cardId == nil || [cardId isEmpty]) {
    return;
  }
  [self.player createInDeck:entity turn:turn];
}

- (void)playerFatigue:(NSInteger)value
{
  DDLogInfo(@"Player get %ld fatigue", value);
  self.player.fatigue = value;
}

- (void)playerCreateInPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.player createInPlay:entity turn:turn];
}

- (void)playerStolen:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.player stolenByOpponent:entity turn:turn];
  [self.opponent stolenFromOpponent:entity turn:turn];
}

#pragma mark - opponent

- (void)setOpponentHero:(NSString *)cardId
{
  self.opponent.playerClass = [Card byId:cardId];
}

- (void)setOpponentName:(NSString *)name
{
  self.opponent.name = name;
}

- (void)opponentGet:(Entity *)entity turn:(NSInteger)turn id:(NSInteger)id
{
  [self.opponent createInHand:entity turn:turn];
}

- (void)opponentPlayToHand:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn id:(NSInteger)id
{
  [self.opponent boardToHand:entity turn:turn];
}

- (void)opponentPlayToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent boardToDeck:entity turn:turn];
}

- (void)opponentPlay:(Entity *)entity card:(NSString *)cardId from:(NSInteger)from turn:(NSInteger)turn
{
  [self.opponent play:entity turn:turn];
}

- (void)opponentHandDiscard:(Entity *)entity card:(NSString *)cardId from:(NSInteger)from turn:(NSInteger)turn
{
  // TODO exception ???
  [self.opponent play:entity turn:turn];
}

- (void)opponentSecretPlayed:(Entity *)entity card:(NSString *)cardId from:(NSInteger)from turn:(NSInteger)turn fromDeck:(BOOL)fromDeck id:(NSInteger)id
{
  if (fromDeck) {
    [self.opponent secretPlayedFromDeck:entity turn:turn];
  }
  else {
    [self.opponent secretPlayedFromHand:entity turn:turn];
  }
}

- (void)opponentMulligan:(Entity *)entity from:(NSInteger)from
{
  [self.opponent mulligan:entity];
}

- (void)opponentDraw:(Entity *)entity turn:(NSInteger)turn
{
  [self.opponent draw:entity turn:turn];
}

- (void)opponentRemoveFromDeck:(Entity *)entity turn:(NSInteger)turn
{
  [self.opponent removeFromDeck:entity turn:turn];
}

- (void)opponentDeckDiscard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent deckDiscard:entity turn:turn];
}

- (void)opponentDeckToPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent deckToPlay:entity turn:turn];
}

- (void)opponentPlayToGraveyard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent playToGraveyard:entity card:cardId turn:turn];
}

- (void)opponentJoust:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent joustReveal:entity turn:turn];
}

- (void)opponentGetToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent createInDeck:entity turn:turn];
}

- (void)opponentSecretTrigger:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn id:(NSInteger)id
{
  [self.opponent secretTriggered:entity turn:turn];
}

- (void)opponentFatigue:(NSInteger)value
{
  self.opponent.fatigue = value;
}

- (void)opponentCreateInPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent createInPlay:entity turn:turn];
}

- (void)opponentStolen:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  [self.opponent stolenByOpponent:entity turn:turn];
  [self.player stolenFromOpponent:entity turn:turn];
}
@end
