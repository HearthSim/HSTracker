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
#import "CardSize.h"
#import "HandCountPosition.h"

@interface Settings : NSObject

+ (Settings *)instance;

- (void)setFlashColor:(NSColor *)flashColor;
- (NSColor *)flashColor;

- (void)setCardSize:(CardSize)size;
- (CardSize)cardSize;

- (void)setHearthstoneLogPath:(NSString *)path;
- (NSString *)hearthstoneLogPath;

- (void)setHearthstoneLanguage:(NSString *)hearthstoneLanguage;
- (NSString *)hearthstoneLanguage;

- (void)setHsTrackerLanguage:(NSString *)hsTrackerLanguage;
- (NSString *)hsTrackerLanguage;

- (void)setDatabaseVersion:(NSNumber *)version;
- (NSNumber *)databaseVersion;

- (void)setShowRarityColors:(BOOL)value;
- (BOOL)showRarityColors;

- (void)setShowOneCard:(BOOL)value;
- (BOOL)showOneCard;

- (void)setInHandAsPlayed:(BOOL)value;
- (BOOL)inHandAsPlayed;

- (BOOL)isCyrillicOrAsian;

- (void)setWindowsLocked:(BOOL)value;
- (BOOL)windowsLocked;

- (void)setHandCountWindow:(HandCountPosition)position;
- (HandCountPosition)handCountWindow;

- (void)setFixedWindowNames:(BOOL)value;
- (BOOL)fixedWindowNames;
@end
