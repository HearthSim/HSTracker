/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import "Entity.h"
#import "GameTag.h"

@implementation Entity

- (instancetype)initWithId:(NSInteger)id
{
  if (self = [super init]) {
    self.id = id;
    self.tags = [NSMutableDictionary dictionary];
  }
  return self;
}

- (BOOL)hasTag:(NSInteger) tag
{
  return [self getTag:tag] != NSNotFound;
}

- (NSInteger)getTag:(NSInteger)tag
{
  return self.tags[@(tag)] == nil ? 0 : [self.tags[@(tag)] integerValue];
}

- (void)setValue:(NSInteger)value forTag:(NSInteger)key
{
  self.tags[@(key)] = @(value);
}

- (BOOL)isInZone:(EZone)zone
{
  return [self hasTag:EGameTag_ZONE] && [self getTag:EGameTag_ZONE] == zone;
}

- (BOOL)isControllerBy:(NSInteger)controller
{
  return [self hasTag:EGameTag_CONTROLLER] && [self getTag:EGameTag_CONTROLLER] == controller;
}

- (BOOL)isSecret
{
  return [self hasTag:EGameTag_SECRET];
}

- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.id=%ld", self.id];
  [description appendFormat:@", self.isPlayer=%@", self.isPlayer ? @"YES" : @"NO"];
  [description appendFormat:@", self.cardId=%@", self.cardId];
  [description appendFormat:@", self.name=%@", self.name];
  //[description appendFormat:@", self.tags=%@", self.tags];
  [description appendString:@">"];
  return description;
}

@end

@implementation TempEntity
- (id)initWithTag:(NSString *)tag id:(NSInteger)id value:(NSString *)value
{
  if (self = [super init]) {
    self.tag = tag;
    self.id = id;
    self.value = value;
  }
  return self;
}
@end
