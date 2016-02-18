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

#define KFrameWidth 220.0
#define KFrameHeight 700.0
#define KRowHeight 37.0

#define KMediumRowHeight 29.0
#define KMediumFrameWidth (KFrameWidth / KRowHeight * KMediumRowHeight)

#define KSmallRowHeight 23.0
#define KSmallFrameWidth (KFrameWidth / KRowHeight * KSmallRowHeight)

typedef NS_ENUM(NSInteger, CardSize)
{
    CardSize_Small,
    CardSize_Medium,
    CardSize_Big
};
