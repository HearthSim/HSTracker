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

typedef NS_ENUM(NSInteger, ETagClass)
{
    ETagClass_INVALID,
    ETagClass_DEATHKNIGHT,
    ETagClass_DRUID,
    ETagClass_HUNTER,
    ETagClass_MAGE,
    ETagClass_PALADIN,
    ETagClass_PRIEST,
    ETagClass_ROGUE,
    ETagClass_SHAMAN,
    ETagClass_WARLOCK,
    ETagClass_WARRIOR,
    ETagClass_DREAM
};

@interface TagClass : NSObject
+ (BOOL)tryParse:(NSString *)rawValue out:(ETagClass *)out;
@end
