/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "DeckCard.h"

NS_ASSUME_NONNULL_BEGIN

@interface DeckCard (CoreDataProperties)

@property(nullable, nonatomic, retain) NSNumber *count;
@property(nullable, nonatomic, retain) NSString *cardId;

@end

NS_ASSUME_NONNULL_END
