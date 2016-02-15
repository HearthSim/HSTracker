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

typedef NS_ENUM(NSInteger, GameMode) {
    GameMode_Unknow,
    GameMode_Ranked,
    GameMode_Casual,
    GameMode_Arena,
    GameMode_Brawl,
    GameMode_Spectator,
    GameMode_Friendly,
    GameMode_Practice
};
