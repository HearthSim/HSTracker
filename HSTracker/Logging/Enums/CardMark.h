/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ECardMark)
{
    ECardMark_None,
    ECardMark_Coin,
    ECardMark_Returned,
    ECardMark_Mulliganed,
    ECardMark_Created,
    ECardMark_Kept
};

@interface CardMark : NSObject
+ (NSString *)toString:(ECardMark)mark;
@end
