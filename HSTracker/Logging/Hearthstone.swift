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
import CleanroomLogger

final class Hearthstone: NSObject {
    let applicationName = "Hearthstone"

    var logReaderManager: LogReaderManager?

    var hearthstoneActive = false
    var queue: dispatch_queue_t?

    static let instance = Hearthstone()

    static func findHearthstone() -> String? {
        let path = "/Applications/Hearthstone/Hearthstone.app"
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            return "/Applications/Hearthstone"
        }
        return nil
    }

    static func validatedHearthstonePath() -> Bool {
        let path = "\(Settings.instance.hearthstoneLogPath)/Hearthstone.app"
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }

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
        var missingZones = [LogLineZone]()

        var fileContent = ""
        if !NSFileManager.defaultManager().fileExistsAtPath(self.configPath) {
            for zone in zones {
                missingZones.append(LogLineZone(namespace: zone))
            }
        } else {
            do {
                fileContent = try String(contentsOfFile: self.configPath)

                // swiftlint:disable line_length
                var zonesFound = [LogLineZone]()
                let splittedZones = fileContent.characters.split { $0 == "[" }.map(String.init)
                for splittedZone in splittedZones {
                    let splittedZoneLines = splittedZone.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                    if let zone = splittedZoneLines.first {
                        let startPos = zone.startIndex.advancedBy(0)
                        let endPos = zone.endIndex.advancedBy(-1)
                        let range = startPos ..< endPos
                        if let currentZone = LogLineNamespace(rawValue: zone.substringWithRange(range)) {
                            let logLineZone = LogLineZone(namespace: currentZone)
                            for splittedZoneLine in splittedZoneLines {
                                let kv = splittedZoneLine.characters.split { $0 == "=" }.map(String.init)
                                if let key = kv.first, value = kv.last {
                                    switch key {
                                    case "LogLevel": logLineZone.logLevel = Int(value) ?? 1
                                    case "FilePrinting": logLineZone.filePrinting = value
                                    case "ConsolePrinting": logLineZone.consolePrinting = value
                                    case "ScreenPrinting": logLineZone.screenPrinting = value
                                    default: break
                                    }
                                }
                            }
                            zonesFound.append(logLineZone)
                        }
                    }
                }

                for zone in zones {
                    var currentZoneFound: LogLineZone? = nil

                    for zoneFound in zonesFound {
                        if zoneFound.namespace == zone {
                            currentZoneFound = zoneFound
                            break
                        }
                    }

                    if let currentZone = currentZoneFound {
                        if !currentZone.isValid() {
                            missingZones.append(currentZone)
                        }
                    } else {
                        missingZones.append(LogLineZone(namespace: zone))
                    }
                }
                // swiftlint:enable line_length
            } catch {
            }
        }

        Log.verbose?.message("Missing zones : \(missingZones)")
        if !missingZones.isEmpty {
            var fileContent: String = ""
            for zone in zones {
                fileContent += LogLineZone(namespace: zone).toString()
            }

            do {
                try fileContent.writeToFile(self.configPath,
                                            atomically: true,
                                            encoding: NSUTF8StringEncoding)
            } catch {
                // TODO error handling
            }

            if isHearthstoneRunning {
                dispatch_async(dispatch_get_main_queue()) {
                    let alert = NSAlert()
                    alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                    // swiftlint:disable line_length
                    alert.informativeText = NSLocalizedString("You must restart Hearthstone for logs to be used", comment: "")
                    // swiftlint:enable line_length
                    alert.alertStyle = NSAlertStyle.InformationalAlertStyle
                    NSRunningApplication.currentApplication().activateWithOptions([
                        NSApplicationActivationOptions.ActivateAllWindows,
                        NSApplicationActivationOptions.ActivateIgnoringOtherApps])
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
        if logReaderManager == nil {
            logReaderManager = LogReaderManager()
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

    // MARK: - Events
    func startListeners() {
        let notificationCenter = NSWorkspace.sharedWorkspace().notificationCenter
        let notifications = [
            // swiftlint:disable line_length
            NSWorkspaceActiveSpaceDidChangeNotification: #selector(Hearthstone.spaceChange(_:)),
            NSWorkspaceDidLaunchApplicationNotification: #selector(Hearthstone.appLaunched(_:)),
            NSWorkspaceDidTerminateApplicationNotification: #selector(Hearthstone.appTerminated(_:)),
            NSWorkspaceDidActivateApplicationNotification: #selector(Hearthstone.appActivated(_:)),
            NSWorkspaceDidDeactivateApplicationNotification: #selector(Hearthstone.appDeactivated(_:)),
            // swiftlint:enable line_length
        ]
        for (name, selector) in notifications {
            notificationCenter.addObserver(self,
                                           selector: selector,
                                           name: name,
                                           object: nil)
        }
    }

    func spaceChange(notification: NSNotification) {
        Game.instance.hearthstoneIsActive(self.hearthstoneActive)
    }

    func appLaunched(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"]
            where application.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now launched")
            self.startTracking()
            SizeHelper.hearthstoneWindow.reload()
            Game.instance.hearthstoneIsActive(true)
            NSNotificationCenter.defaultCenter()
                .postNotificationName("hearthstone_running", object: nil)
        }
    }

    func appTerminated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"]
            where application.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now closed")
            self.stopTracking()
            Game.instance.hearthstoneIsActive(false)
            NSNotificationCenter.defaultCenter()
                .postNotificationName("hearthstone_running", object: nil)
        }
    }

    func appActivated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"]
            where application.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now active")
            self.hearthstoneActive = true
            SizeHelper.hearthstoneWindow.reload()
            Game.instance.hearthstoneIsActive(true)
            NSNotificationCenter.defaultCenter()
                .postNotificationName("hearthstone_active", object: nil)
        }
    }

    func appDeactivated(notification: NSNotification) {
        if let application = notification.userInfo!["NSWorkspaceApplicationKey"]
            where application.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now inactive")
            self.hearthstoneActive = false
            Game.instance.hearthstoneIsActive(false)
            NSNotificationCenter.defaultCenter()
                .postNotificationName("hearthstone_active", object: nil)
        }
    }

    // MARK: - Paths / Utils
    var configPath: String {
        return NSString(string: "~/Library/Preferences/Blizzard/Hearthstone/log.config")
            .stringByExpandingTildeInPath
    }

    var logPath: String {
        return Settings.instance.hearthstoneLogPath
    }

    var isHearthstoneRunning: Bool {
        let apps = NSWorkspace.sharedWorkspace().runningApplications
        return apps.any({$0.localizedName == self.applicationName})
    }
}
