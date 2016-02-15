/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CardMechanic;

NS_ASSUME_NONNULL_BEGIN

@interface Card : NSManagedObject

+ (Card *)byId:(NSString *)cardId;

@end

NS_ASSUME_NONNULL_END

#import "Card+CoreDataProperties.h"
