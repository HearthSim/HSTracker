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

NS_ASSUME_NONNULL_BEGIN

@interface Card (CoreDataProperties)

@property(nullable, nonatomic, retain) NSString *cardId;
@property(nullable, nonatomic, retain) NSNumber *collectible;
@property(nullable, nonatomic, retain) NSNumber *cost;
@property(nullable, nonatomic, retain) NSString *faction;
@property(nullable, nonatomic, retain) NSString *flavor;
@property(nullable, nonatomic, retain) NSNumber *health;
@property(nullable, nonatomic, retain) NSString *lang;
@property(nullable, nonatomic, retain) NSString *name;
@property(nullable, nonatomic, retain) NSString *playerClass;
@property(nullable, nonatomic, retain) NSString *rarity;
@property(nullable, nonatomic, retain) NSString *text;
@property(nullable, nonatomic, retain) NSString *type;
@property(nullable, nonatomic, retain) NSString *set;
@property(nullable, nonatomic, retain) NSSet<CardMechanic *> *mechanics;

@end

@interface Card (CoreDataGeneratedAccessors)

- (void)addMechanicsObject:(CardMechanic *)value;

- (void)removeMechanicsObject:(CardMechanic *)value;

- (void)addMechanics:(NSSet<CardMechanic *> *)values;

- (void)removeMechanics:(NSSet<CardMechanic *> *)values;

@end

NS_ASSUME_NONNULL_END
