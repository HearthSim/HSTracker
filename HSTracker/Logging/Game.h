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
@class Entity;
@class Player;
@class Player;

typedef NS_ENUM(NSInteger, PlayerType)
{
    PlayerType_Player,
    PlayerType_Opponent,
};

@interface Game : NSObject

@property(nonatomic, strong) NSMutableDictionary *entities;
@property(nonatomic, strong) NSMutableArray *tmpEntities;
@property(nonatomic) NSInteger joustReveals;
@property(nonatomic, assign) EGameMode gameMode;
@property(nonatomic) BOOL rankFound;
@property(nonatomic) BOOL awaitingRankedDetection;
@property(nonatomic) NSTimeInterval lastAssetUnload;
@property(nonatomic, strong) Player *player;
@property(nonatomic, strong) Player *opponent;
@property(nonatomic, strong) TempEntity *waitController;
@property(nonatomic) BOOL gameStarted;
@property(nonatomic, strong) NSDate *gameStartDate;
@property(nonatomic) enum GameResult gameResult;
@property(nonatomic, strong) NSDate *gameEndDate;

@property(nonatomic) BOOL waitingForFirstAssetUnload;

+ (Game *)instance;

- (Entity *)playerEntity;

- (Entity *)opponentEntity;

- (void)gameStart;

- (void)gameEnd;

- (void)setPlayerHero:(NSString *)cardId;

- (void)setOpponentHero:(NSString *)cardId;

- (void)setPlayerRank:(NSNumber *)rank;

- (void)setPlayerName:(NSString *)name;

- (void)setOpponentName:(NSString *)name;

- (NSInteger)turnNumber;

- (void)playerFatigue:(NSInteger)value;

- (void)opponentFatigue:(NSInteger)value;

- (void)turnStart:(PlayerType)player turn:(NSInteger)turn;

- (void)concede;

- (void)win;

- (void)loss;

- (void)tied;

- (BOOL)isMulliganDone;

- (void)playerGet:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentGet:(Entity *)entity turn:(NSInteger)turn id:(NSInteger)id;

- (void)playerBackToHand:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentPlayToHand:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn id:(NSInteger)id;

- (void)playerPlayToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentPlayToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentPlay:(Entity *)entity card:(NSString *)cardId from:(NSInteger)from turn:(NSInteger)turn;

- (void)playerHandDiscard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentHandDiscard:(Entity *)entity card:(NSString *)cardId from:(NSInteger)from turn:(NSInteger)turn;

- (void)playerSecretPlayed:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn fromDeck:(BOOL)fromDeck;

- (void)opponentSecretPlayed:(Entity *)entity card:(NSString *)cardId from:(NSInteger)from turn:(NSInteger)turn fromDeck:(BOOL)fromDeck id:(NSInteger)id;

- (void)playerMulligan:(Entity *)entity card:(NSString *)cardId;

- (void)opponentMulligan:(Entity *)entity from:(NSInteger)from;

- (void)playerDraw:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentDraw:(Entity *)entity turn:(NSInteger)turn;

- (void)playerRemoveFromDeck:(Entity *)entity turn:(NSInteger)turn;

- (void)opponentRemoveFromDeck:(Entity *)entity turn:(NSInteger)turn;

- (void)opponentDeckDiscard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerDeckDiscard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerDeckToPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentDeckToPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerPlayToGraveyard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentPlayToGraveyard:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerCreateInPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentCreateInPlay:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentStolen:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerStolen:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentJoust:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerJoust:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)playerGetToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentGetToDeck:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn;

- (void)opponentSecretTrigger:(Entity *)entity card:(NSString *)cardId turn:(NSInteger)turn id:(NSInteger)id;
@end
