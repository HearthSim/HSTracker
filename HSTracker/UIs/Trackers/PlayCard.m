/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 15/02/16.
 */
#import "PlayCard.h"
#import "Card.h"

@implementation PlayCard

- (NSString *)description
{
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.count=%ld", self.count];
  [description appendFormat:@", self.handCount=%ld", self.handCount];
  [description appendFormat:@", self.card=%@", self.card];
  [description appendFormat:@", self.hasChanged=%d", self.hasChanged];
  [description appendFormat:@", self.isStolen=%d", self.isStolen];
  [description appendString:@">"];
  return description;
}

@end
