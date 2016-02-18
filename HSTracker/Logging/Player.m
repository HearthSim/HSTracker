/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */
#import "Player.h"
#import "Card.h"
#import "Tracker.h"
#import "CardEntity.h"
#import "CardMark.h"
#import "Entity.h"
#import "NSString+HSTracker.h"
#import "GameTag.h"
#import "CardType.h"
#import "PlayCard.h"

@interface Player ()
@property(nonatomic, strong) NSMutableArray *_revealedCards;
@property(nonatomic, strong) NSMutableArray *_hand;
@property(nonatomic, strong) NSMutableArray *_board;
@property(nonatomic, strong) NSMutableArray *_deck;
@property(nonatomic, strong) NSMutableArray *_graveyard;
@property(nonatomic, strong) NSMutableArray *_secrets;
@property(nonatomic, strong) NSMutableArray *_removed;
@property(nonatomic, strong) NSMutableArray *_drawnCardIds;
@property(nonatomic, strong) NSMutableArray *_drawnCardIdsTotal;
@property(nonatomic, strong) NSMutableArray *_createdInHandCardIds;
@end

static NSInteger DeckSize = 30;

@implementation Player

- (instancetype)initWithLocal:(BOOL)isLocalPlayer
{
  if (self = [super init]) {
    self.localPlayer = isLocalPlayer;
    self._hand = [NSMutableArray array];
    self._board = [NSMutableArray array];
    self._deck = [NSMutableArray array];
    self._graveyard = [NSMutableArray array];
    self._secrets = [NSMutableArray array];
    self._drawnCardIds = [NSMutableArray array];
    self._drawnCardIdsTotal = [NSMutableArray array];
    self._revealedCards = [NSMutableArray array];
    self._createdInHandCardIds = [NSMutableArray array];
    self._removed = [NSMutableArray array];
  }
  return self;
}

- (BOOL)hasCoin
{
  CardEntity *cardEntity;
  for (CardEntity *ce in self._hand) {
    if ([ce.cardId isEqualToString:@"GAME_005"]
      || (ce.entity != nil && [ce.entity.cardId isEqualToString:@"GAME_005"])) {
      cardEntity = ce;
      break;
    }
  }
  return cardEntity != nil;
}

- (NSInteger)handCount
{
  return self.hand.count;
}

- (NSInteger)deckCount
{
  return self.deck.count;
}

- (NSArray *)revealedCards
{
  return self._revealedCards;
}

- (NSArray *)hand
{
  return self._hand;
}

- (NSArray *)board
{
  return self._board;
}

- (NSArray *)deck
{
  return self._deck;
}

- (NSArray *)graveyard
{
  return self._graveyard;
}

- (NSArray *)secrets
{
  return self._secrets;
}

- (NSArray *)removed
{
  return self._removed;
}

- (NSArray *)drawnCardIds
{
  return self._drawnCardIds;
}

- (NSArray *)drawnCardIdsTotal
{
  return self._drawnCardIdsTotal;
}

- (NSArray *)createdInHandCardIds
{
  return self._createdInHandCardIds;
}

- (NSArray *)drawnCards
{
  NSMutableDictionary *temp = [NSMutableDictionary dictionary];


  for (NSString *str in self._drawnCardIds) {
    if (str != nil && ![str isEmpty]) {
      if (temp[str]) {
        ((PlayCard *) temp[str]).count += 1;
      }
      else {
        Card *card = [Card byId:str];
        if (![card.name isEqualToString:@"UNKNOWN"]) {
          PlayCard *playCard = [[PlayCard alloc] init];
          playCard.card = card;
          playCard.count = 1;
          temp[str] = playCard;
        }
      }
    }
  }
  return [temp allValues];
}

- (NSArray *)displayCards
{
  return @[];
}

- (void)reset
{
  self.id = NSNotFound;
  self.name = @"";
  self.playerClass = nil;
  self.goingFirst = NO;
  self.fatigue = 0;
  //self.drawnCardsMatchDeck = true;
  [self._hand removeAllObjects];
  [self._board removeAllObjects];
  [self._deck removeAllObjects];
  [self._graveyard removeAllObjects];
  [self._secrets removeAllObjects];
  [self._drawnCardIds removeAllObjects];
  [self._drawnCardIdsTotal removeAllObjects];
  [self._revealedCards removeAllObjects];
  [self._createdInHandCardIds removeAllObjects];
  [self._removed removeAllObjects];

  for (NSInteger i = 0; i < DeckSize; i++) {
    [self._deck addObject:[[CardEntity alloc] initWithEntity:nil]];
  }
}

- (void)gameStart
{
  [self.tracker gameStart];
}

- (void)gameEnd
{
  [self.tracker gameEnd];
}

- (void)setPlayerClass:(Card *)playerClass
{
  DDLogInfo(@"%@ hero is %@", [self debugName], playerClass.name);
  _playerClass = playerClass;
}

- (void)setName:(NSString *)name
{
  DDLogInfo(@"%@ name is %@", [self debugName], name);
  _name = name;
}

- (NSString *)debugName
{
  return self.isLocalPlayer ? @"Player" : @"Opponent";
}

- (void)createInDeck:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity;
  if (self.isLocalPlayer) {
    cardEntity = [[CardEntity alloc] initWithEntity:entity];
    cardEntity.turn = turn;
    [self._deck addObject:cardEntity];
    CardEntity *ce = [[CardEntity alloc] initWithEntity:entity];
    ce.turn = turn;
    [self._revealedCards addObject:ce];
  }
  else {
    [self._deck addObject:[[CardEntity alloc] initWithEntity:nil]];
    [self revealDeckCard:entity.cardId turn:turn];
    cardEntity = [[CardEntity alloc] initWithCardId:entity.cardId entity:nil];
    cardEntity.turn = turn;
    [self._revealedCards addObject:cardEntity];
  }
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)revealDeckCard:(NSString *)cardId turn:(NSInteger)turn
{
  CardEntity *cardEntity;
  for (CardEntity *ce in self._deck) {
    if (ce.unkown) {
      cardEntity = ce;
      break;
    }
  }
  if (cardEntity != nil) {
    cardEntity.cardId = cardId;
    cardEntity.turn = turn;
  }
}

- (void)createInHand:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [[CardEntity alloc] initWithEntity:entity];
  cardEntity.turn = turn;
  cardEntity.cardMark = ECardMark_Created;
  cardEntity.created = YES;
  if (entity != nil &&
    ([entity.cardId isEqualToString:@"GAME_005"] || [entity.cardId isEqualToString:@"GVG_028t"])) {
    cardEntity.cardMark = ECardMark_Coin;
  }

  [self._hand addObject:cardEntity];

  if (self.isLocalPlayer) {
    [self._createdInHandCardIds addObject:entity.cardId];
  }

  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)boardToDeck:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._board
                                             to:self._deck
                                           turn:turn];
  [self updateRevealedEntity:cardEntity turn:turn];

  if ((entity.cardId != nil && ![entity.cardId isEmpty]) && [self._drawnCardIds containsObject:entity.cardId]) {
    [self._drawnCardIds removeObject:entity.cardId];
  }
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)play:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._hand
                                             to:entity.isSecret ? self._secrets : self._board
                                           turn:turn];
  if ([entity getTag:EGameTag_CARDTYPE == ECardType_TOKEN]) {
    cardEntity.cardMark = ECardMark_Created;
    cardEntity.created = YES;
  }
  [self updateRevealedEntity:cardEntity turn:turn];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)handDiscard:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._hand
                                             to:self._graveyard
                                           turn:turn];
  [self updateRevealedEntity:cardEntity turn:turn discarded:YES];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)secretPlayedFromDeck:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._deck
                                             to:self._secrets
                                           turn:turn];
  [self updateRevealedEntity:cardEntity turn:turn];
  if (entity.cardId != nil && ![entity.cardId isEmpty]) {
    /*if (self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
      DrawnCardsMatchDeck = false;
    }*/
    [self._drawnCardIds addObject:entity.cardId];
    [self._drawnCardIdsTotal addObject:entity.cardId];
  }
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)secretPlayedFromHand:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._hand
                                             to:self._secrets
                                           turn:turn];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)mulligan:(Entity *)entity
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._hand
                                             to:self._deck
                                           turn:0];

  //new cards are drawn first
  CardEntity *newCard;
  for (CardEntity *ent in self._hand) {
    if ([ent.entity getTag:EGameTag_ZONE_POSITION] == [entity getTag:EGameTag_ZONE_POSITION]) {
      newCard = ent;
      break;
    }
  }

  if (newCard != nil) {
    newCard.cardMark = ECardMark_Mulliganed;
  }
  if (entity.cardId != nil && ![entity.cardId isEmpty]
    && [self._drawnCardIds containsObject:entity.cardId]) {
    [self._drawnCardIds removeObject:entity.cardId];
  }
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)draw:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._deck
                                             to:self._hand
                                           turn:turn];

  if (self.isLocalPlayer) {
    [self highlight:entity.cardId];
  }
  else {
    [cardEntity reset];
  }

  if (entity.cardId != nil && ![entity.cardId isEmpty] && cardEntity.cardMark != ECardMark_Created
    && cardEntity.cardMark != ECardMark_Returned && !cardEntity.created) {
    /*if(self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
      DrawnCardsMatchDeck = false;
    }*/
    [self._drawnCardIds addObject:entity.cardId];
    [self._drawnCardIdsTotal addObject:entity.cardId];
  }
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)highlight:(NSString *)cardId
{

}

- (void)removeFromDeck:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *revealed;
  for (CardEntity *ent in self._revealedCards) {
    if ([ent.entity isEqual:entity]) {
      revealed = ent;
      break;
    }
  }

  if (revealed != nil) {
    [self._revealedCards removeObject:revealed];
  }
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._deck
                                             to:self._removed
                                           turn:turn];

  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)deckDiscard:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._deck
                                             to:self._graveyard
                                           turn:turn];
  [self updateRevealedEntity:cardEntity turn:turn discarded:YES];

  if (entity.cardId != nil && ![entity.cardId isEmpty] && cardEntity.cardMark != ECardMark_Created
    && cardEntity.cardMark != ECardMark_Returned) {
    /*if(self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
      DrawnCardsMatchDeck = false;
    }*/
    [self._drawnCardIds addObject:entity.cardId];
    [self._drawnCardIdsTotal addObject:entity.cardId];
  }
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)deckToPlay:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._deck
                                             to:self._board
                                           turn:turn];
  [self updateRevealedEntity:cardEntity turn:turn];

  if (entity.cardId != nil && ![entity.cardId isEmpty] && cardEntity.cardMark != ECardMark_Created
    && cardEntity.cardMark != ECardMark_Returned) {
    /*if(self.isLocalPlayer && !CardMatchesActiveDeck(entity.CardId)) {
      DrawnCardsMatchDeck = false;
    }*/
    [self._drawnCardIds addObject:entity.cardId];
    [self._drawnCardIdsTotal addObject:entity.cardId];
  }
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)playToGraveyard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._board
                                             to:self._graveyard
                                           turn:turn];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)joustReveal:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *ce;
  for (CardEntity *ent in self._deck) {
    if (ent.inDeck && ![ent.cardId isEqualToString:entity.cardId]) {
      ce = ent;
      break;
    }
  }
  if (ce) {
    [self revealDeckCard:entity.cardId turn:turn];
    CardEntity *cardEntity = [[CardEntity alloc] initWithCardId:entity.cardId entity:nil];
    cardEntity.turn = turn;
    [self._revealedCards addObject:cardEntity];
    DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
  }
}

- (void)createInPlay:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [[CardEntity alloc] initWithEntity:entity];
  cardEntity.turn = turn;
  [self._board addObject:cardEntity];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)stolenByOpponent:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._board
                                             to:self._removed
                                           turn:turn];
  [self updateRevealedEntity:cardEntity turn:turn];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)stolenFromOpponent:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._removed
                                             to:self._board
                                           turn:turn];
  cardEntity.created = YES;
  [self updateRevealedEntity:cardEntity turn:turn];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)boardToHand:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._board
                                             to:self._hand
                                           turn:turn];
  cardEntity.cardMark = ECardMark_Returned;
  [self updateRevealedEntity:cardEntity turn:turn cardMark:ECardMark_Returned];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (void)secretTriggered:(Entity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self moveCardEntity:entity
                                           from:self._secrets
                                             to:self._graveyard
                                           turn:turn];
  [self updateRevealedEntity:cardEntity turn:turn];
  DDLogInfo(@"%@ %s %@ ", [self debugName], __FUNCTION__, cardEntity);
}

- (CardEntity *)updateRevealedEntity:(CardEntity *)entity turn:(NSInteger)turn
{
  CardEntity *cardEntity;
  for (CardEntity *ent in self._revealedCards) {
    if ([ent.entity isEqualTo:entity.entity] ||
      ([ent.cardId isEqualToString:entity.cardId] && ent.entity == nil && ent.turn <= entity.prevTurn)) {
      cardEntity = ent;
      break;
    }
  }

  if (cardEntity != nil) {
    [cardEntity update:entity.entity];
  }
  else {
    cardEntity = [[CardEntity alloc] initWithEntity:entity.entity];
    cardEntity.turn = turn;
    cardEntity.created = entity.created;
    cardEntity.discarded = entity.discarded;
    NSInteger cardType = [entity.entity getTag:EGameTag_CARDTYPE];
    if (cardType != ECardType_HERO && cardType != ECardType_ENCHANTMENT &&
      cardType != ECardType_HERO_POWER && cardType != ECardType_PLAYER) {
      [self._revealedCards addObject:entity];
    }
  }

  return cardEntity;
}

- (CardEntity *)updateRevealedEntity:(CardEntity *)entity turn:(NSInteger)turn discarded:(BOOL)discarded
{
  CardEntity *cardEntity = [self updateRevealedEntity:entity turn:turn];
  cardEntity.discarded = discarded;
  return cardEntity;
}

- (CardEntity *)updateRevealedEntity:(CardEntity *)entity turn:(NSInteger)turn cardMark:(ECardMark)cardMark
{
  CardEntity *cardEntity = [self updateRevealedEntity:entity turn:turn];
  cardEntity.cardMark = cardMark;
  return cardEntity;
}

- (CardEntity *)moveCardEntity:(Entity *)entity from:(NSMutableArray *)from to:(NSMutableArray *)to turn:(NSInteger)turn
{
  CardEntity *cardEntity = [self getEntityFromCollection:from entity:entity];
  if (cardEntity != nil) {
    [from removeObject:cardEntity];
  }
  else {
    for (CardEntity *ce in from) {
      if (ce.cardId != nil && ![ce.cardId isEmpty] && ce.entity == nil) {
        cardEntity = ce;
        break;
      }
    }
    if (cardEntity != nil) {
      [from removeObject:cardEntity];
      [cardEntity update:entity];
    }
    else {
      cardEntity = [[CardEntity alloc] initWithEntity:entity];
      cardEntity.turn = turn;
    }

  }
  [to addObject:cardEntity];
  [to sortUsingSelector:@selector(zonePosComparison:)];
  cardEntity.turn = turn;
  return cardEntity;
}

- (CardEntity *)getEntityFromCollection:(NSMutableArray *)array entity:(Entity *)entity
{
  CardEntity *cardEntity;
  for (CardEntity *ce in array) {
    if ([ce.entity isEqualTo:entity]) {
      cardEntity = ce;
      break;
    }
  }
  if (cardEntity == nil) {
    for (CardEntity *ce in array) {
      if (ce.cardId != nil && ![ce.cardId isEmpty] && [ce.cardId isEqualToString:entity.cardId]) {
        cardEntity = ce;
        break;
      }
    }
  }

  if (cardEntity == nil) {
    for (CardEntity *ce in array) {
      if ((ce.cardId == nil || [ce.cardId isEmpty]) && ce.entity == nil) {
        cardEntity = ce;
        break;
      }
    }
  }

  if (cardEntity) {
    [cardEntity update:entity];
  }
  return cardEntity;
}

@end
