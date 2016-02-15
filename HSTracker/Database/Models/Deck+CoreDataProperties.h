/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "Deck.h"

NS_ASSUME_NONNULL_BEGIN

@interface Deck (CoreDataProperties)

@property(nullable, nonatomic, retain) NSNumber *hearthstatsId;
@property(nullable, nonatomic, retain) NSNumber *hearthstatsVersionId;
@property(nullable, nonatomic, retain) NSNumber *isActive;
@property(nullable, nonatomic, retain) NSNumber *isArena;
@property(nullable, nonatomic, retain) NSString *name;
@property(nullable, nonatomic, retain) NSString *playerClass;
@property(nullable, nonatomic, retain) NSString *version;

@end

NS_ASSUME_NONNULL_END
