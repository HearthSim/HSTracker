/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 18/02/16.
 */
#import "CardMark.h"

@implementation CardMark

+ (NSString *)toString:(ECardMark)mark
{
  switch (mark) {
    default:
    case ECardMark_None:
      return @" ";
    case ECardMark_Coin:
      return @"c";
    case ECardMark_Returned:
      return @"R";
    case ECardMark_Mulliganed:
      return @"M";
    case ECardMark_Created:
      return @"C";
    case ECardMark_Kept:
      return @"K";
  }
}

@end
