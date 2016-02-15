/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 15/02/16.
 */
#import <Foundation/Foundation.h>

@class Card;

@interface PlayCard : NSObject
@property(nonatomic) NSNumber *count;
@property(nonatomic,strong) Card *card;
@end
