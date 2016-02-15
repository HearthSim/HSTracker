/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import <AppKit/AppKit.h>
#import "Hearthstone.h"
#import "Settings.h"
#import "LogReaderManager.h"

@interface Hearthstone ()

@property(nonatomic, strong, nonnull) LogReaderManager *logReaderManager;

@end

@implementation Hearthstone

+ (Hearthstone *)instance
{
  static Hearthstone *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      _instance = [[self alloc] init];
  });
  return _instance;
}

#pragma mark - Initialisation

- (void)start
{
  [self setup];
  [self startListeners];
  [self startTracking];
}

- (void)setup
{
  NSArray *zones = @[@"Zone", @"Bob", @"Power", @"Asset", @"Rachelle", @"Arena"];

  NSMutableArray *missingZones;
  NSMutableString *fileContent;
  NSError *error;
  if (![[NSFileManager defaultManager] fileExistsAtPath:[self configPath]]) {
    NSString *path = [[self configPath] stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];

    // TODO check error

    missingZones = [NSMutableArray arrayWithArray:zones];
    fileContent = [NSMutableString string];
  }
  else {
    fileContent = [NSMutableString stringWithContentsOfFile:[self configPath]
                                                   encoding:NSUTF8StringEncoding
                                                      error:&error];

    // TODO check error
    NSArray *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *zoneFound = [NSMutableArray array];
    for (NSString *zone in zones) {
      for (NSString *line in lines) {
        NSString *reg = [NSString stringWithFormat:@"^\\[%@\\]$", zone];
        if ([line isMatch:RX(reg)]) {
          DDLogVerbose(@"Found %@", reg);
          [zoneFound addObject:zone];
        }
      }
    }
    missingZones = [NSMutableArray arrayWithArray:zones];
    [missingZones removeObjectsInArray:zoneFound];
  }

  DDLogVerbose(@"Missing zones : %@", missingZones);
  if ([missingZones count] > 0) {
    for (NSString *zone in zones) {
      [fileContent appendString:[NSString stringWithFormat:@"\n[%@]", zone]];
      [fileContent appendString:@"\nLogLevel=1"];
      [fileContent appendString:@"\nFilePrinting=true"];
      [fileContent appendString:@"\nConsolePrinting=false"];
      [fileContent appendString:@"\nScreenPrinting=false"];
    }
    [fileContent writeToFile:[self configPath]
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&error];

    if ([self isHearthstoneRunning]) {
      dispatch_async(dispatch_get_main_queue(), ^{
          NSAlert *alert = [NSAlert new];
          [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
          [alert setInformativeText:NSLocalizedString(@"You must restart Hearthstone for logs to be used", nil)];
          [alert setAlertStyle:NSInformationalAlertStyle];
          [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps | NSApplicationActivateAllWindows];
          [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
          [alert runModal];
      });
    }
  }
}

- (void)startTracking
{
  self.logReaderManager = [LogReaderManager new];
  [self.logReaderManager start];
}

- (void)stopTracking
{
  [self.logReaderManager stop];
}

- (void)restartTracking
{
  [self.logReaderManager stop];
  [self.logReaderManager start];
}

// observe for HS starting/leaving
- (void)startListeners
{
  NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
  [notificationCenter addObserver:self
                         selector:@selector(appLaunched:)
                             name:NSWorkspaceDidLaunchApplicationNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(appTerminated:)
                             name:NSWorkspaceDidTerminateApplicationNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(appActivated:)
                             name:NSWorkspaceDidActivateApplicationNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(appDeactivated:)
                             name:NSWorkspaceDidDeactivateApplicationNotification
                           object:nil];
}

- (void)appLaunched:(NSNotification *)notification
{
  NSRunningApplication *application = notification.userInfo[@"NSWorkspaceApplicationKey"];
  if (application && [application.localizedName isEqualToString:@"Hearthstone"]) {
    DDLogVerbose(@"Hearthstone is now launched");
  }
}

- (void)appTerminated:(NSNotification *)notification
{
  NSRunningApplication *application = notification.userInfo[@"NSWorkspaceApplicationKey"];
  if (application && [application.localizedName isEqualToString:@"Hearthstone"]) {
    DDLogVerbose(@"Hearthstone is now closed");
  }
}

- (void)appActivated:(NSNotification *)notification
{
  NSRunningApplication *application = notification.userInfo[@"NSWorkspaceApplicationKey"];
  if (application && [application.localizedName isEqualToString:@"Hearthstone"]) {
    DDLogVerbose(@"Hearthstone is now active");
  }
}

- (void)appDeactivated:(NSNotification *)notification
{
  NSRunningApplication *application = notification.userInfo[@"NSWorkspaceApplicationKey"];
  if (application && [application.localizedName isEqualToString:@"Hearthstone"]) {
    DDLogVerbose(@"Hearthstone is now inactive");
  }
}


#pragma mark - Paths / Utils

- (NSString *)configPath
{
  return [@"~/Library/Preferences/Blizzard/Hearthstone/log.config" stringByExpandingTildeInPath];
}

- (NSString *)logPath
{
  NSString *logPath = [Settings objectForKey:HearthstoneLogPath];
  if (logPath == nil) {
    logPath = @"/Applications/Hearthstone/Logs/";
  }
  return logPath;
}

- (BOOL)isHearthstoneRunning
{
  NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
  for (NSRunningApplication *app in apps) {
    if ([app.localizedName isEqualToString:@"Hearthstone"]) {
      return YES;
    }
  }
  return NO;
}


@end
