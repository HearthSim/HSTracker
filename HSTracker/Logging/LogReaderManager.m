/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "LogReaderManager.h"
#import "LogReader.h"
#import "LogLine.h"
#import "PowerGameStateHandler.h"
#import "ZoneHandler.h"
#import "AssetHandler.h"
#import "BobHandler.h"
#import "RachelleHandler.h"
#import "ArenaHandler.h"

@interface LogReaderManager ()
{
  NSArray *readers;
}
@property(nonatomic, strong) LogReader *power;
@property(nonatomic, strong) LogReader *bob;
@property(nonatomic, strong) LogReader *rachelle;
@property(nonatomic, strong) LogReader *asset;
@property(nonatomic, strong) LogReader *arena;
@property(nonatomic, strong) LogReader *zone;
@end

@implementation LogReaderManager

- (instancetype)init
{
  if (self = [super init]) {
    [self initReaders];
  }
  return self;
}

- (void)initReaders
{
  self.power = [[LogReader alloc] initWithName:@"Power"
                              logReaderManager:self
                                  startFilters:@[@"GameState"]
                               containsFilters:@[@"Begin Spectating", @"Start Spectator", @"End Spectator"]];

  self.bob = [[LogReader alloc] initWithName:@"Bob" logReaderManager:self];
  self.rachelle = [[LogReader alloc] initWithName:@"Rachelle" logReaderManager:self];
  self.asset = [[LogReader alloc] initWithName:@"Asset" logReaderManager:self];
  self.arena = [[LogReader alloc] initWithName:@"Arena" logReaderManager:self];

  self.zone = [[LogReader alloc] initWithName:@"Zone"
                             logReaderManager:self
                                 startFilters:nil
                              containsFilters:@[@"zone from"]];

  readers = @[self.power, self.bob, self.rachelle, self.asset, self.arena, self.zone];
}

- (void)start
{
  NSTimeInterval entryPoint = [self entryPoint];
  for (LogReader *reader in readers) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        [reader start:entryPoint];
    });
  }
}

- (void)stop
{
  for (LogReader *reader in readers) {
    [reader stop];
  }
}

- (void)restart
{
  [self stop];
  [self start];
}

- (NSTimeInterval)entryPoint
{
  NSTimeInterval powerEntry = [self.power findEntryPoint:@"GameState.DebugPrintPower() - CREATE_GAME"];
  NSTimeInterval bobEntry = [self.bob findEntryPoint:@"legend rank"];

  return powerEntry > bobEntry ? powerEntry : bobEntry;
}

- (void)processNewLine:(LogLine *)line
{
  DDLogVerbose(@"processing line %@", line);
  dispatch_async(dispatch_get_main_queue(), ^{
      if ([line.namespace isEqualToString:@"Power"]) {
        [PowerGameStateHandler handle:line.line];
      }
      else if ([line.namespace isEqualToString:@"Zone"]) {
        [ZoneHandler handle:line.line];
      }
      else if ([line.namespace isEqualToString:@"Asset"]) {
        [AssetHandler handle:line.line];
      }
      else if ([line.namespace isEqualToString:@"Bob"]) {
        [BobHandler handle:line.line];
      }
      else if ([line.namespace isEqualToString:@"Rachelle"]) {
        [RachelleHandler handle:line.line];
      }
      else if ([line.namespace isEqualToString:@"Arena"]) {
        [ArenaHandler handle:line.line];
      }
  });
}

@end
