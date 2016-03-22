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
    var queue:dispatch_queue_t?

    static let instance = Hearthstone()

    // MARK: - Initialisation
    func start() {
        setup()
        logReaderManager = LogReaderManager()
        startListeners()
        if self.isHearthstoneRunning {
            startTracking()
            dispatch_async(dispatch_get_main_queue()) {
                Game.instance.hearthstoneIsActive(true)
            }
        }
    }

    func setup() {
        let zones = LogLineNamespace.allValues()

        var missingZones = [LogLineNamespace]()

        var fileContent = ""
        if !NSFileManager.defaultManager().fileExistsAtPath(self.configPath) {
            missingZones = zones
            fileContent = ""
        } else {
            do {
                fileContent = try String(contentsOfFile: self.configPath)
                var zonesFound = [LogLineNamespace]()
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
        if queue == nil {
            queue = dispatch_queue_create("be.michotte.hstracker.readers", nil)
        }
        if let queue = queue {
            dispatch_async(queue) {
                self.logReaderManager?.start()
            }
        }
    }

    func stopTracking() {
        logReaderManager?.stop()
    }

    func restartTracking() {
        stopTracking()
        startTracking()
    }

    // MARK: - Events
    func startListeners() {
        let notificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
        notificationCenter.addObserver(self,
            selector: #selector(Hearthstone.appLaunched(_:)),
            name: NSWorkspaceDidLaunchApplicationNotification,
            object: nil)
        notificationCenter.addObserver(self,
            selector: #selector(Hearthstone.appTerminated(_:)),
            name: NSWorkspaceDidTerminateApplicationNotification,
            object: nil)
        notificationCenter.addObserver(self,
            selector: #selector(Hearthstone.appActivated(_:)),
            name: NSWorkspaceDidActivateApplicationNotification,
            object: nil)
        notificationCenter.addObserver(self,
            selector: #selector(Hearthstone.appDeactivated(_:)),
            name: NSWorkspaceDidDeactivateApplicationNotification,
            object: nil)
    }

    func appLaunched(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now launched")
            self.restartTracking()
            Game.instance.hearthstoneIsActive(true)
            NSNotificationCenter.defaultCenter().postNotificationName("hearthstone_running", object: nil)
        }
    }

    func appTerminated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now closed")
            self.stopTracking()
            Game.instance.hearthstoneIsActive(false)
            NSNotificationCenter.defaultCenter().postNotificationName("hearthstone_running", object: nil)
        }
    }

    func appActivated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now active")
            self.hearthstoneActive = true
            Game.instance.hearthstoneIsActive(true)
            NSNotificationCenter.defaultCenter().postNotificationName("hearthstone_active", object: nil)
        }
    }

    func appDeactivated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"] where application.localizedName == "Hearthstone" {
            DDLogVerbose("Hearthstone is now inactive")
            self.hearthstoneActive = false
            Game.instance.hearthstoneIsActive(false)
            NSNotificationCenter.defaultCenter().postNotificationName("hearthstone_active", object: nil)
        }
    }

    // MARK: - Paths / Utils
    var configPath: String {
        return NSString(string: "~/Library/Preferences/Blizzard/Hearthstone/log.config").stringByExpandingTildeInPath
    }

    var logPath: String {
        return Settings.instance.hearthstoneLogPath
    }

    var isHearthstoneRunning: Bool {
        let apps = NSWorkspace.sharedWorkspace().runningApplications
        return apps.any({$0.localizedName == "Hearthstone"})
    }
}
