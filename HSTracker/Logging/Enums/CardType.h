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

typedef NS_ENUM(NSInteger, ECardType)
{
    ECardType_INVALID = 0,
    ECardType_GAME = 1,
    ECardType_PLAYER = 2,
    ECardType_HERO = 3,
    ECardType_MINION = 4,
    ECardType_ABILITY = 5,
    ECardType_ENCHANTMENT = 6,
    ECardType_WEAPON = 7,
    ECardType_ITEM = 8,
    ECardType_TOKEN = 9,
    ECardType_HERO_POWER = 10,
};

@interface CardType : NSObject
+ (ECardType)parse:(NSString *)rawValue;
@end
