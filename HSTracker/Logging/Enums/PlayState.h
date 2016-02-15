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

typedef NS_ENUM(NSInteger, EPlayState)
{
    EPlayState_INVALID = 0,
    EPlayState_PLAYING = 1,
    EPlayState_WINNING = 2,
    EPlayState_LOSING = 3,
    EPlayState_WON = 4,
    EPlayState_LOST = 5,
    EPlayState_TIED = 6,
    EPlayState_DISCONNECTED = 7,
    EPlayState_CONCEDED = 8,
    EPlayState_QUIT = EPlayState_CONCEDED,
};

@interface PlayState : NSObject
+ (EPlayState)parse:(NSString *)rawValue;
@end
