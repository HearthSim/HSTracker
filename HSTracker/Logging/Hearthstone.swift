/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Foundation

class Hearthstone {

    var logReaderManager: LogReaderManager?

    var hearthstoneActive = false

    static let instance = Hearthstone()

//MARK: Initialisation

    func start() {
        setup()
        startListeners()
        startTracking()
    }

    func setup() {
        var zones = ["Zone", "Bob", "Power", "Asset", "Rachelle", "Arena", "LoadingScreen", "Net"]

        var missingZones = [String]()
        /*NSMutableString *fileContent;
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
        }*/
    }

    func startTracking() {
        self.logReaderManager! = LogReaderManager()
        self.logReaderManager!.start()
    }

    func stopTracking() {
        logReaderManager!.stop()
    }

    func restartTracking() {
        logReaderManager!.stop()
        logReaderManager!.start()
    }

    // observe for HS starting/leaving
    func startListeners() {
        let notificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
        notificationCenter.addObserver(self,
                selector: "appLaunched:",
                name: NSWorkspaceDidLaunchApplicationNotification,
                object: nil)
        notificationCenter.addObserver(self,
                selector: "appTerminated:",
                name: NSWorkspaceDidTerminateApplicationNotification,
                object: nil)
        notificationCenter.addObserver(self,
                selector: "appActivated:",
                name: NSWorkspaceDidActivateApplicationNotification,
                object: nil)
        notificationCenter.addObserver(self,
                selector: "appDeactivated:",
                name: NSWorkspaceDidDeactivateApplicationNotification,
                object: nil)
    }

    func appLaunched(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now launched")
        }
    }

    func appTerminated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now closed")
        }
    }

    func appActivated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now active")
            self.hearthstoneActive = true
        }
    }

    func appDeactivated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now inactive")
            self.hearthstoneActive = false
        }
    }

    //MARK: - Paths / Utils
    var configPath: String {
        return NSString(string: "~/Library/Preferences/Blizzard/Hearthstone/log.config").stringByExpandingTildeInPath
    }

    var logPath: String {
        return Settings.instance.hearthstoneLogPath
    }

    var isHearthstoneRunning: Bool {
        let apps = NSWorkspace.sharedWorkspace().runningApplications
        for app in apps {
            if app.localizedName == "Hearthstone" {
                return true
            }
        }
        return false
    }
}
