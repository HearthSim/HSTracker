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

typedef NS_ENUM(NSInteger, EMulligan)
{
    EMulligan_INVALID = 0,
    EMulligan_INPUT = 1,
    EMulligan_DEALING = 2,
    EMulligan_WAITING = 3,
    EMulligan_DONE = 4,
};


@interface Mulligan : NSObject
+ (EMulligan)parse:(NSString *)rawValue;
@end
