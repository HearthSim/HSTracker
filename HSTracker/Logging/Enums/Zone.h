/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 14/02/16.
 */
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EZone)
{
    EZone_INVALID = -1,
    EZone_CREATED = 0,
    EZone_PLAY = 1,
    EZone_DECK = 2,
    EZone_HAND = 3,
    EZone_GRAVEYARD = 4,
    EZone_REMOVEDFROMGAME = 5,
    EZone_SETASIDE = 6,
    EZone_SECRET = 7,
};

@interface Zone : NSObject
+ (BOOL)tryParse:(NSString *)rawValue out:(EZone *)out;
@end
