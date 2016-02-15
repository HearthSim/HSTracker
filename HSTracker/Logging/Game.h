/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import <Foundation/Foundation.h>
#import "GameMode.h"
#import "GameResult.h"

@class TempEntity;
@class Tracker;

typedef NS_ENUM(NSInteger, PlayerType)
{
    Player,
    Opponent,
};

@interface Game : NSObject

@property(nonatomic, strong) NSMutableDictionary *entities;
@property(nonatomic, strong) NSMutableArray *tmpEntities;
@property(nonatomic) NSInteger joustReveals;
@property(nonatomic, assign) GameMode gameMode;
@property(nonatomic) BOOL rankFound;
@property(nonatomic) BOOL awaitingRankedDetection;
@property(nonatomic) NSTimeInterval lastAssetUnload;
@property(nonatomic, strong) NSNumber *opponentId;
@property(nonatomic, strong) NSNumber *playerId;
@property(nonatomic, strong) TempEntity *waitController;
@property(nonatomic) BOOL gameStarted;
@property(nonatomic, strong) NSDate *gameStartDate;
@property(nonatomic) enum GameResult gameResult;
@property(nonatomic, strong) NSDate *gameEndDate;
@property(nonatomic, strong) Tracker *playerTracker;
@property(nonatomic, strong) Tracker *opponentTracker;

+ (Game *)instance;

- (void)gameStart;

- (void)gameEnd;

- (void)setPlayerHero:(NSString *)cardId;

- (void)setOpponentHero:(NSString *)cardId;

- (void)setPlayerRank:(NSInteger)rank;

- (void)setPlayerName:(NSString *)name;

- (void)setOpponentName:(NSString *)name;

- (NSNumber *)turnNumber;

- (void)opponentJoust:(NSString *)cardId turn:(NSNumber *)turn;

- (void)playerJoust:(NSString *)cardId turn:(NSNumber *)turn;

- (void)playerGetToDeck:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentGetToDeck:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentSecretTrigger:(NSString *)cardId turn:(NSNumber *)turn id:(NSNumber *)id;

- (void)playerFatigue:(NSInteger)value;

- (void)opponentFatigue:(NSInteger)value;

- (void)turnStart:(PlayerType)player turn:(NSNumber *)turn;

- (void)concede;

- (void)win;

- (void)loss;

- (void)tied;

- (BOOL)isMulliganDone;

- (void)playerGet:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentGet:(NSNumber *)turn id:(NSNumber *)id;

- (void)playerBackToHand:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentPlayToHand:(NSString *)cardId turn:(NSNumber *)turn id:(NSNumber *)id;

- (void)playerPlayToDeck:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentPlayToDeck:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentPlay:(NSString *)cardId from:(id)from turn:(NSNumber *)turn;

- (void)playerHandDiscard:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentHandDiscard:(NSString *)cardId from:(id)from turn:(NSNumber *)turn;

- (void)playerSecretPlayed:(NSString *)cardId turn:(NSNumber *)turn fromDeck:(BOOL)deck;

- (void)opponentSecretPlayed:(NSString *)cardId from:(id)from turn:(NSNumber *)turn fromDeck:(BOOL)deck id:(NSNumber *)id;

- (void)opponentMulligan:(id)tag;

- (void)playerMulligan:(NSString *)cardId;

- (void)playerPlay:(NSString *)cardId turn:(NSNumber *)turn;

- (void)playerDraw:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentDraw:(NSNumber *)turn;

- (void)playerRemoveFromDeck:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentRemoveFromDeck:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentDeckDiscard:(NSString *)cardId turn:(NSNumber *)turn;

- (void)playerDeckDiscard:(NSString *)cardId turn:(NSNumber *)turn;

- (void)playerDeckToPlay:(NSString *)cardId turn:(NSNumber *)turn;

- (void)opponentDeckToPlay:(NSString *)cardId turn:(NSNumber *)turn;
@end
