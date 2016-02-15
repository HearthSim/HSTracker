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
#import "Game.h"

@class PlayCard;

@interface CardCellView : NSTableCellView

@property(nonatomic)PlayerType playerType;
@property(nonatomic)PlayCard *playCard;

@end
