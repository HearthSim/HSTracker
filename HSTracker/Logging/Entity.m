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

@implementation Entity

- (instancetype)initWithId:(NSNumber *)id
{
  if (self = [super init]) {
    self.id = id;
  }
  return self;
}

- (BOOL)hasTag:(NSInteger) tag
{
  return [self getTag:tag] != nil;
}

- (id)getTag:(NSInteger)tag
{
  return self.tags[@(tag)];
}

- (void)setValue:(id)value forTag:(NSInteger)key
{
  self.tags[@(key)] = value;
}

- (BOOL)isInZone:(enum EGameTag)zone
{
  return [self hasTag:EGameTag_ZONE] && [[self getTag:EGameTag_ZONE] isEqualToNumber:@(zone)];
}

- (BOOL)isControllerBy:(NSNumber *)controller
{
  return [self hasTag:EGameTag_CONTROLLER] && [[self getTag:EGameTag_CONTROLLER] isEqualToNumber:controller];
}
@end

@implementation TempEntity
- (id)initWithTag:(NSString *)tag id:(NSNumber *)id value:(NSString *)value
{
  if (self = [super init]) {
    self.tag = tag;
    self.id = id;
    self.value = value;
  }
  return nil;
}
@end
