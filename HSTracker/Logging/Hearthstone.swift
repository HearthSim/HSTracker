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

class Hearthstone : NSObject {

    var logReaderManager: LogReaderManager?

    var hearthstoneActive = false

    static let instance = Hearthstone()

    //MARK: - Initialisation
    func start() {
        setup()
        startListeners()
        startTracking()
    }

    func setup() {
        let zones = ["Zone", "Bob", "Power", "Asset", "Rachelle", "Arena", "LoadingScreen", "Net"]

        var missingZones = [String]()

        var fileContent = ""
        if !NSFileManager.defaultManager().fileExistsAtPath(self.configPath) {
            missingZones = zones
            fileContent = ""
        } else {
            do {
                fileContent = try String(contentsOfFile: self.configPath)
                var zonesFound = [String]()
                fileContent.enumerateLines({
                    (line, stop) -> () in
                    for zone in zones {
                        if line.containsString("[\(zone)]") {
                            zonesFound.append(zone)
                            DDLogVerbose("Found \(zone)")
                        }
                    }
                })
                for zone in zones {
                    if !zonesFound.contains(zone) {
                        missingZones.append(zone)
                    }
                }
            } catch {
            }

        }

        DDLogVerbose("Missing zones : \(missingZones)")
        if missingZones.count > 0 {
            for zone in missingZones {
                fileContent += "\n[\(zone)]"
                        + "\nLogLevel=1"
                        + "\nFilePrinting=true"
                        + "\nConsolePrinting=false"
                        + "\nScreenPrinting=false"
            }
            do {
                try fileContent.writeToFile(self.configPath, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                // TODO error handling
            }

            if isHearthstoneRunning {
                dispatch_async(dispatch_get_main_queue()) {
                    let alert = NSAlert()
                    alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                    alert.informativeText = NSLocalizedString("You must restart Hearthstone for logs to be used", comment: "")
                    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
                    NSRunningApplication.currentApplication().activateWithOptions([NSApplicationActivationOptions.ActivateAllWindows, NSApplicationActivationOptions.ActivateIgnoringOtherApps])
                    NSApplication.sharedApplication().activateIgnoringOtherApps(true)
                    alert.runModal()
                }
            }
        }
    }

    func startTracking() {
        self.logReaderManager = LogReaderManager()
        self.logReaderManager!.start()
    }

    func stopTracking() {
        logReaderManager!.stop()
    }

    func restartTracking() {
        logReaderManager!.stop()
        logReaderManager!.start()
    }

    //MARK: - Events
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
