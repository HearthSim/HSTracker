/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

#import "CardMechanic.h"

NS_ASSUME_NONNULL_BEGIN
@class Card;

@interface CardMechanic (CoreDataProperties)

@property(nullable, nonatomic, retain) NSString *name;
@property(nullable, nonatomic, retain) NSSet<Card *> *cards;

@end

@interface CardMechanic (CoreDataGeneratedAccessors)

- (void)addCardsObject:(Card *)value;

- (void)removeCardsObject:(Card *)value;

- (void)addCards:(NSSet<Card *> *)values;

- (void)removeCards:(NSSet<Card *> *)values;

@end

NS_ASSUME_NONNULL_END
