/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */
#import <Foundation/Foundation.h>

@class Card;
@class Tracker;
@class Entity;

@interface Player : NSObject

@property(nonatomic, getter=isLocalPlayer) BOOL localPlayer;

@property(nonatomic) NSInteger id;
@property(nonatomic, strong) Card *playerClass;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) Tracker *tracker;

@property(nonatomic) BOOL goingFirst;
@property(nonatomic) NSInteger fatigue;
//@property(nonatomic) BOOL drawnCardsMatchDeck;

@property(nonatomic, readonly) BOOL hasCoin;
@property(nonatomic, readonly) NSInteger handCount;
@property(nonatomic, readonly) NSInteger deckCount;

@property(nonatomic, readonly) NSArray *revealedCards;
@property(nonatomic, readonly) NSArray *hand;
@property(nonatomic, readonly) NSArray *board;
@property(nonatomic, readonly) NSArray *deck;
@property(nonatomic, readonly) NSArray *graveyard;
@property(nonatomic, readonly) NSArray *secrets;
@property(nonatomic, readonly) NSArray *removed;
@property(nonatomic, readonly) NSArray *drawnCardIds;
@property(nonatomic, readonly) NSArray *drawnCardIdsTotal;
@property(nonatomic, readonly) NSArray *createdInHandCardIds;
@property(nonatomic, readonly) NSArray *drawnCards;
@property(nonatomic, readonly) NSArray *displayCards;

- (instancetype)initWithLocal:(BOOL)isLocalPlayer;

- (void)reset;

- (void)gameStart;

- (void)gameEnd;

- (void)createInDeck:(Entity *)entity turn:(NSInteger)turn;

- (void)createInHand:(Entity *)entity turn:(NSInteger)turn;

- (void)boardToDeck:(Entity *)entity turn:(NSInteger)turn;

- (void)play:(Entity *)entity turn:(NSInteger)turn;

- (void)handDiscard:(Entity *)entity turn:(NSInteger)turn;

- (void)secretPlayedFromDeck:(Entity *)entity turn:(NSInteger)turn;

- (void)secretPlayedFromHand:(Entity *)entity turn:(NSInteger)turn;

- (void)mulligan:(Entity *)entity;

- (void)draw:(Entity *)entity turn:(NSInteger)turn;

- (void)removeFromDeck:(Entity *)entity turn:(NSInteger)turn;

- (void)deckDiscard:(Entity *)entity turn:(NSInteger)turn;

- (void)deckToPlay:(Entity *)entity turn:(NSInteger)turn;

- (void)playToGraveyard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)joustReveal:(Entity *)entity turn:(NSInteger)turn;

- (void)createInPlay:(Entity *)entity turn:(NSInteger)turn;

- (void)stolenByOpponent:(Entity *)entity turn:(NSInteger)turn;

- (void)boardToHand:(Entity *)entity turn:(NSInteger)turn;

- (void)secretTriggered:(Entity *)entity turn:(NSInteger)turn;

- (void)stolenFromOpponent:(Entity *)entity turn:(NSInteger)turn;
@end
