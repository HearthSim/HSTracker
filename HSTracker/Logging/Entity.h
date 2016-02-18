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
#import "Zone.h"

@interface Entity : NSObject
@property(nonatomic) NSInteger id;
@property(nonatomic) BOOL isPlayer;
@property(nonatomic, strong) NSString *cardId;
@property(nonatomic, strong) NSString *name;
@property(nonatomic, strong) NSMutableDictionary *tags;

@property(nonatomic, readonly) BOOL isSecret;

- (instancetype)initWithId:(NSInteger)id;
- (BOOL)hasTag:(NSInteger) tag;
- (NSInteger)getTag:(NSInteger)tag;
- (void)setValue:(NSInteger)value forTag:(NSInteger)key;
- (BOOL)isControllerBy:(NSInteger)controller;
- (BOOL)isInZone:(EZone)zone;

- (NSString *)description;
@end

@interface TempEntity : NSObject
@property(nonatomic, strong) NSString *tag;
@property(nonatomic) NSInteger id;
@property(nonatomic, strong) NSString *value;

- (id)initWithTag:(NSString *)tag id:(NSInteger)id value:(NSString *)value;
@end
