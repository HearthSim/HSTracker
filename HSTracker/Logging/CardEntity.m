/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */
#import "CardEntity.h"
#import "Entity.h"
#import "GameTag.h"
#import "NSString+HSTracker.h"

@implementation CardEntity

- (instancetype)initWithEntity:(Entity *)entity
{
  return [self initWithCardId:nil entity:entity];
}

- (instancetype)initWithCardId:(NSString *)cardId entity:(Entity *)entity
{
  if (self = [super init]) {
    self.cardId = (cardId == nil || [cardId isEmpty]) && entity != nil ? entity.cardId : cardId;
    self.entity = entity;
    self.turn = -1;
    self.cardMark = (entity != nil && entity.id > 68) ? ECardMark_Created : ECardMark_None;
  }
  return self;
}

- (void)setTurn:(NSInteger)turn
{
  _prevTurn = _turn;
  _turn = turn;
}

- (BOOL)inHand
{
  return (self.entity != nil && [self.entity getTag:EGameTag_ZONE] == EZone_HAND);
}

- (BOOL)inDeck
{
  return (self.entity != nil && [self.entity getTag:EGameTag_ZONE] == EZone_DECK);
}

- (BOOL)unknown
{
  return (self.cardId == nil || [self.cardId isEmpty]) && self.entity == nil;
}

- (void)update:(Entity *)entity
{
  if (entity == nil) {
    return;
  }
  if (self.entity == nil) {
    self.entity = entity;
  }
  if (self.cardId == nil || [self.cardId isEmpty]) {
    self.cardId = entity.cardId;
  }
}

- (void)reset
{
  self.cardMark = ECardMark_None;
  self.created = NO;
  self.cardId = nil;
}

- (NSComparisonResult)zonePosComparison:(CardEntity *)other
{
  NSInteger v1 = self.entity ? [self.entity getTag:EGameTag_ZONE_POSITION] : 10;
  NSInteger v2 = other.entity ? [other.entity getTag:EGameTag_ZONE_POSITION] : 10;
  return [@(v1) compare:@(v2)];
}

- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.entity=%@", self.entity];
  [description appendFormat:@", self.cardId=%@", self.cardId];
  [description appendFormat:@", self.turn=%li", self.turn];
  if (self.entity) {
    [description appendFormat:@", self.zonePos=%li", [self.entity getTag:EGameTag_ZONE_POSITION]];
  }
  if (self.cardMark != ECardMark_None) {
    [description appendFormat:@", self.cardMark=%li", (NSInteger) self.cardMark];
  }
  if (self.discarded) {
    [description appendString:@", self.discarded=true"];
  }
  if (self.created) {
    [description appendString:@", self.created=true"];
  }
  [description appendString:@">"];
  return description;
}


@end
