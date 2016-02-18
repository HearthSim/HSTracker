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
#import "GameTag.h"

@interface TagChangeHandler : NSObject

@property(nonatomic) BOOL currentEntityHasCardId;

@property(nonatomic) BOOL playerUsedHeroPower;

@property(nonatomic) BOOL opponentUsedHeroPower;

- (void)tagChange:(NSString *)rawTag id:(NSInteger)id rawValue:(NSString *)rawValue;
- (void)tagChange:(NSString *)rawTag id:(NSInteger)id rawValue:(NSString *)rawValue recurse:(BOOL)recurse;

- (BOOL)isEntity:(NSString *)entity;
- (NSDictionary *)parseEntity:(NSString *)entity;
- (NSInteger)parseTag:(EGameTag)tag rawValue:(NSString *)rawValue;
@end
