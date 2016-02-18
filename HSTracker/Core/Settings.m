/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "Settings.h"
#import "NSUserDefaults+ColorSupport.h"

@implementation Settings

+ (Settings *)instance
{
  static Settings *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      _instance = [[self alloc] init];
  });
  return _instance;
}

- (instancetype)init
{
  if (self = [super init]) {
    [self initDefaults];
  }
  return self;
}

- (void)initDefaults
{
  [[self userDefaults] registerDefaults:@{
    @"flash_color" : [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedRed:55 green:189 blue:223 alpha:1]],
    @"card_size" : @(CardSize_Big),
    @"rarity_colors" : @YES,
    @"show_one_card" : @NO,
    @"in_hand_as_played" : @NO,
    @"window_locked": @YES,
  }];
}

- (NSUserDefaults *)userDefaults
{
  return [NSUserDefaults standardUserDefaults];
}

- (void)setFlashColor:(NSColor *)flashColor
{
  [[self userDefaults] setColor:flashColor forKey:@"flash_color"];
}

- (NSColor *)flashColor
{
  return [[self userDefaults] colorForKey:@"flash_color"];
}

- (void)setCardSize:(CardSize)size
{
  [[self userDefaults] setObject:@(size) forKey:@"card_size"];
}

- (CardSize)cardSize
{
  return (CardSize) [[[self userDefaults] objectForKey:@"card_size"] integerValue];
}

- (void)setHearthstoneLogPath:(NSString *)path
{
  [[self userDefaults] setObject:path forKey:@"hearthstone_log_path"];
}

- (NSString *)hearthstoneLogPath
{
  return [[self userDefaults] objectForKey:@"hearthstone_log_path"];
}

- (void)setHearthstoneLanguage:(NSString *)hearthstoneLanguage
{
  [[self userDefaults] setObject:hearthstoneLanguage forKey:@"hearthstone_language"];
}

- (NSString *)hearthstoneLanguage
{
  return [[self userDefaults] objectForKey:@"hearthstone_language"];
}

- (void)setHsTrackerLanguage:(NSString *)hsTrackerLanguage
{
  [[self userDefaults] setObject:hsTrackerLanguage forKey:@"hstracker_language"];
}

- (NSString *)hsTrackerLanguage
{
  return [[self userDefaults] objectForKey:@"hstracker_language"];
}

- (void)setDatabaseVersion:(NSNumber *)version
{
  [[self userDefaults] setObject:version forKey:@"database_version"];
}

- (NSNumber *)databaseVersion
{
  return [[self userDefaults] objectForKey:@"database_version"];
}

- (void)setShowRarityColors:(BOOL)value
{
  [[self userDefaults] setObject:@(value) forKey:@"rarity_colors"];
}

- (BOOL)showRarityColors
{
  return [[[self userDefaults] objectForKey:@"rarity_colors"] boolValue];
}

- (void)setShowOneCard:(BOOL)value
{
  [[self userDefaults] setObject:@(value) forKey:@"show_one_card"];
}

- (BOOL)showOneCard
{
  return [[[self userDefaults] objectForKey:@"show_one_card"] boolValue];
}

- (void)setInHandAsPlayed:(BOOL)value
{
  [[self userDefaults] setObject:@(value) forKey:@"in_hand_as_played"];
}

- (BOOL)inHandAsPlayed
{
  return [[[self userDefaults] objectForKey:@"in_hand_as_played"] boolValue];
}

- (BOOL)isCyrillicOrAsian
{
  return [self.hearthstoneLanguage isMatch:RX(@"^(zh|ko|ru|ja)")];
}

- (void)setWindowsLocked:(BOOL)value
{
  [[self userDefaults] setObject:@(value) forKey:@"window_locked"];
}

- (BOOL)windowsLocked
{
  return [[[self userDefaults] objectForKey:@"window_locked"] boolValue];
}

- (void)setHandCountWindow:(HandCountPosition)position
{
  [[self userDefaults] setObject:@(position) forKey:@"hand_count_window"];
}

- (HandCountPosition)handCountWindow
{
  return (HandCountPosition) [[[self userDefaults] objectForKey:@"hand_count_window"] integerValue];
}

- (void)setFixedWindowNames:(BOOL)value
{
  [[self userDefaults] setObject:@(value) forKey:@"fixed_window_names"];
}

- (BOOL)fixedWindowNames
{
  return [[[self userDefaults] objectForKey:@"fixed_window_names"] boolValue];
}
@end
