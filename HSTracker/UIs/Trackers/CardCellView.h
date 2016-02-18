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
@class Card;
@protocol CardCellHover;

@interface CardCellView : NSTableCellView

@property(nonatomic) PlayerType playerType;
@property(nonatomic, strong) PlayCard *playCard;
@property(nonatomic, weak) id <CardCellHover> delegate;

- (void)flash;
@end

@protocol CardCellHover <NSObject>
- (void)hover:(Card *)card;

- (void)out:(Card *)card;
@end
