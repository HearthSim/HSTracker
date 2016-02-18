/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

#import "Card.h"
#import "CardMechanic.h"

@implementation Card

+ (Card *)byId:(NSString *)cardId
{
  // TODO lang
  NSString *lang = @"frFR";
  return [Card MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"cardId = %@ and lang = %@", cardId, lang]];
}

- (NSString *)englishName
{
  if ([self.lang isEqualToString:@"enUS"]) {
    return self.name;
  }

  Card *card = [Card MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"cardId = %@ and lang = %@", self.cardId, @"enUS"]];
  return card.name;
}

@end
