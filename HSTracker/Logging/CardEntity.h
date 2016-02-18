/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */
#import <Foundation/Foundation.h>
#import "CardMark.h"

@class Entity;

@interface CardEntity : NSObject
@property(nonatomic, strong) NSString *cardId;
@property(nonatomic, strong) Entity *entity;
@property(nonatomic) NSInteger turn;
@property(nonatomic, readonly) NSInteger prevTurn;

@property(nonatomic) ECardMark cardMark;
@property(nonatomic) BOOL discarded;

@property(nonatomic, readonly) BOOL inHand;
@property(nonatomic, readonly) BOOL inDeck;
@property(nonatomic, readonly) BOOL unkown;
@property(nonatomic) BOOL created;

- (instancetype)initWithEntity:(Entity *)entity;
- (instancetype)initWithCardId:(NSString *)cardId entity:(Entity *)entity;

- (void)update:(Entity *)entity;
- (void)reset;

- (NSComparisonResult)zonePosComparison:(CardEntity *)other;

- (NSString *)description;

@end
