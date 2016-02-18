/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 16/02/16.
 */
#import <Foundation/Foundation.h>

@class Card;

@interface ImageCache : NSObject

+ (NSImage *)frameImageMask;
+ (NSImage *)smallCardImage:(Card *)card;
+ (NSImage *)gemImage:(NSString *)rarity;

+ (NSImage *)frameDeckImage;

+ (NSImage *)frameImage:(NSString *)rarity;

+ (NSImage *)frameLegendary;

+ (NSImage *)frameCount:(NSNumber *)number;

+ (NSImage *)frameCountbox;

+ (NSImage *)frameCountboxDeck;
@end
