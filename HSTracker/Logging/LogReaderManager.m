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
#import "AssetHandler.h"
#import "BobHandler.h"
#import "RachelleHandler.h"
#import "ArenaHandler.h"
#import "LoadingScreenHandler.h"
#import "NetHandler.h"

@interface LogReaderManager ()
{
  NSArray *readers;
}
@property(nonatomic, strong) LogReader *power;
@property(nonatomic, strong) LogReader *fullPower;
@property(nonatomic, strong) LogReader *bob;
@property(nonatomic, strong) LogReader *rachelle;
@property(nonatomic, strong) LogReader *asset;
@property(nonatomic, strong) LogReader *arena;
@property(nonatomic, strong) LogReader *loadScreen;
@property(nonatomic, strong) LogReader *net;
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
                                  startFilters:@[@"PowerTaskList."]
                               containsFilters:@[@"Begin Spectating", @"Start Spectator", @"End Spectator"]];

  self.fullPower = [[LogReader alloc] initWithName:@"Power"
                              logReaderManager:self];

  self.bob = [[LogReader alloc] initWithName:@"Bob" logReaderManager:self];
  self.rachelle = [[LogReader alloc] initWithName:@"Rachelle" logReaderManager:self];
  self.asset = [[LogReader alloc] initWithName:@"Asset" logReaderManager:self];
  self.arena = [[LogReader alloc] initWithName:@"Arena" logReaderManager:self];
  self.net = [[LogReader alloc] initWithName:@"Net" logReaderManager:self];

  self.loadScreen = [[LogReader alloc] initWithName:@"LoadingScreen"
                                   logReaderManager:self
                                       startFilters:@[@"LoadingScreen.OnSceneLoaded"]
                                    containsFilters:nil
  ];

  readers = @[self.fullPower, self.bob, self.rachelle, self.asset, self.arena, self.net, self.loadScreen];
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
  NSTimeInterval powerEntry = [self.power findEntryPoint:@[@"tag=GOLD_REWARD_STATE", @"End Spectator"]];
  NSTimeInterval netEntry = [self.net findEntryPoint:@[@"ConnectAPI.GotoGameServer"]];

  return powerEntry > netEntry ? powerEntry : netEntry;
}

- (void)processNewLine:(LogLine *)line
{
  //DDLogVerbose(@"processing line %@", line);
  dispatch_async(dispatch_get_main_queue(), ^{
      if ([line.namespace isEqualToString:@"Power"]) {
        [PowerGameStateHandler handle:line.line];
      }
      else if ([line.namespace isEqualToString:@"Net"]) {
        [NetHandler handle:line.line];
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
      else if ([line.namespace isEqualToString:@"LoadingScreen"]) {
        [LoadingScreenHandler handle:line.line];
      }
  });
}

@end
