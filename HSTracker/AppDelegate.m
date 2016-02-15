/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */
#import "AppDelegate.h"
#import "Language.h"
#import "Splashscreen.h"
#import "Database.h"
#import "Hearthstone.h"
#import "Tracker.h"

@interface AppDelegate ()
{
  Language *language;
}
@property(nonatomic, strong) Splashscreen *splashscreen;
@property(nonatomic, strong) Tracker *playerTracker;
@property(nonatomic, strong) Tracker *opponentTracker;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  // init core data stuff
  [MagicalRecord setupAutoMigratingCoreDataStack];

  // init logger
  [DDLog addLogger:[DDTTYLogger sharedInstance]];

  /*DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
  fileLogger.rollingFrequency = 60 * 60 * 24;
  fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
  [DDLog addLogger:fileLogger];*/

  // check for player locale
  language = [[Language alloc] init];
  DDLogDebug(@"Is user language set ? : %@", [language isLanguageSet] ? @"yes" : @"no");
  if ([language isLanguageSet]) {
    [self loadSplashscreen];
  }
  else {
    [language presentLanguageChooserWithCompletion:^{
        [self loadSplashscreen];
    }];
  }
}

- (void)loadSplashscreen
{
  self.splashscreen = [[Splashscreen alloc] init];
  [self.splashscreen showWindow:self];
  NSOperationQueue *operationQueue = [NSOperationQueue new];

  NSBlockOperation *startUpCompletionOperation = [NSBlockOperation blockOperationWithBlock:^{
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          DDLogInfo(@"HSTracker is now ready !");
          [self.splashscreen.window close];
      }];
  }];

  NSBlockOperation *databaseOperation = [NSBlockOperation blockOperationWithBlock:^{
      Database *database = [Database new];
      [database loadDatabaseIfNeeded:self.splashscreen];
  }];
  NSBlockOperation *loggingOperation = [NSBlockOperation blockOperationWithBlock:^{
      DDLogVerbose(@"Starting logging");
      [[Hearthstone instance] start];
      [Game instance].playerTracker = self.playerTracker;
      [Game instance].opponentTracker = self.opponentTracker;
  }];
  NSBlockOperation *trackerOperation = [NSBlockOperation blockOperationWithBlock:^{
      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          DDLogVerbose(@"Opening trackers");
          [self openTrackers];
      }];
  }];

  [startUpCompletionOperation addDependency:loggingOperation];
  [loggingOperation addDependency:trackerOperation];
  [trackerOperation addDependency:databaseOperation];
  [operationQueue addOperation:startUpCompletionOperation];
  [operationQueue addOperation:databaseOperation];
  [operationQueue addOperation:trackerOperation];
  [operationQueue addOperation:loggingOperation];
}

- (void)openTrackers
{
  self.playerTracker = [[Tracker alloc] init];
  self.playerTracker.playerType = Player;
  [self.playerTracker showWindow:self];

  self.opponentTracker = [[Tracker alloc] init];
  self.opponentTracker.playerType = Opponent;
  [self.opponentTracker showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

@end
