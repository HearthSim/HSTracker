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
#import "GameTag.h"

@interface Entity : NSObject
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic) BOOL isPlayer;
@property(nonatomic, strong) NSString *cardId;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSMutableDictionary *tags;

- (instancetype)initWithId:(NSNumber *)id;
- (BOOL)hasTag:(NSInteger) tag;
- (id)getTag:(NSInteger)tag;
- (void)setValue:(id)value forTag:(NSInteger)key;
- (BOOL)isControllerBy:(NSNumber *)controller;
- (BOOL)isInZone:(enum EGameTag)zone;
@end

@interface TempEntity : NSObject
@property(nonatomic, strong) NSString *tag;
@property(nonatomic, strong) NSNumber *id;
@property(nonatomic, strong) NSString *value;

- (id)initWithTag:(NSString *)tag id:(NSNumber *)id value:(NSString *)value;
@end
