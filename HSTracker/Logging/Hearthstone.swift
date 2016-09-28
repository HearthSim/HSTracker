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

enum HearthstoneLogError: ErrorType {
    case CanNotCreateDir,
    CanNotReadFile,
    CanNotCreateFile
}

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
        logReaderManager = LogReaderManager()
        startListeners()
        if self.isHearthstoneRunning {
            startTracking()
            dispatch_async(dispatch_get_main_queue()) {
                Game.instance.hearthstoneIsActive(true)
            }
        }
    }

    func setup() throws -> Bool {
        let fileManager = NSFileManager.defaultManager()
        let requireVerbose = [LogLineNamespace.Power]

        // make sure the path exists
        let dir = NSString(string: configPath).stringByDeletingLastPathComponent
        Log.verbose?.message("Check if \(dir) exists")
        var isDir: ObjCBool = false
        if !fileManager.fileExistsAtPath(dir, isDirectory: &isDir) || !isDir {
            do {
                Log.verbose?.message("Creating \(dir)")
                try fileManager.createDirectoryAtPath(dir,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
            } catch let error as NSError {
                Log.error?.message("\(error.description)")
                throw HearthstoneLogError.CanNotCreateDir
            }
        }

        let zones = LogLineNamespace.usedValues()
        var missingZones: [LogLineZone] = []

        Log.verbose?.message("Check if \(configPath) exists")
        if !fileManager.fileExistsAtPath(configPath) {
            for zone in zones {
                missingZones.append(LogLineZone(namespace: zone))
            }
        } else {
            var fileContent: String?
            do {
                fileContent = try String(contentsOfFile: configPath)
            } catch let error as NSError {
                Log.error?.message("\(error.description)")
            }
            if let fileContent = fileContent {

                // swiftlint:disable line_length
                var zonesFound: [LogLineZone] = []
                let splittedZones = fileContent.characters.split { $0 == "[" }
                    .map(String.init)
                    .map {
                        $0.stringByReplacingOccurrencesOfString("]", withString: "")
                            .characters.split { $0 == "\n" }.map(String.init)
                }

                for splittedZone in splittedZones {
                    var zoneData = splittedZone.filter {!String.isNullOrEmpty($0) }
                    if zoneData.count < 1 {
                        continue
                    }
                    let zone = zoneData.removeFirst()
                    if let currentZone = LogLineNamespace(rawValue: zone) {
                        let logLineZone = LogLineZone(namespace: currentZone)
                        logLineZone.requireVerbose = requireVerbose.contains(currentZone)
                        for line in zoneData {
                            let kv = line.characters.split { $0 == "=" }.map(String.init)
                            if let key = kv.first, value = kv.last {
                                switch key {
                                case "LogLevel": logLineZone.logLevel = Int(value) ?? 1
                                case "FilePrinting": logLineZone.filePrinting = value
                                case "ConsolePrinting": logLineZone.consolePrinting = value
                                case "ScreenPrinting": logLineZone.screenPrinting = value
                                case "Verbose": logLineZone.verbose = value == "true"
                                default: break
                                }
                            }
                        }
                        zonesFound.append(logLineZone)
                    }
                }
                Log.verbose?.message("Zones found : \(zonesFound)")

                for zone in zones {
                    var currentZoneFound: LogLineZone?

                    for zoneFound in zonesFound {
                        if zoneFound.namespace == zone {
                            currentZoneFound = zoneFound
                            break
                        }
                    }

                    if let currentZone = currentZoneFound {
                        Log.verbose?.message("Is \(currentZone.namespace) valid ? \(currentZone.isValid())")
                        if !currentZone.isValid() {
                            missingZones.append(currentZone)
                        }
                    } else {
                        Log.verbose?.message("Zone \(zone) is missing")
                        missingZones.append(LogLineZone(namespace: zone))
                    }
                }
                // swiftlint:enable line_length
            }
        }

        Log.verbose?.message("Missing zones : \(missingZones)")
        if !missingZones.isEmpty {
            var fileContent: String = ""
            for zone in zones {
                let logZone = LogLineZone(namespace: zone)
                logZone.requireVerbose = requireVerbose.contains(zone)
                fileContent += logZone.toString()
            }

            do {
                try fileContent.writeToFile(configPath,
                                            atomically: true,
                                            encoding: NSUTF8StringEncoding)
            } catch let error as NSError {
                Log.error?.message("\(error.description)")
                throw HearthstoneLogError.CanNotCreateFile
            }

            if isHearthstoneRunning {
                return false
            }
        }

        return true
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

            if Settings.instance.quitWhenHearthstoneCloses {
                NSApplication.sharedApplication().terminate(self)
            } else {
                Log.info?.message("Not closing app since setting says so.")
            }
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
    
    func bringToFront() {
        if let hsapp = NSWorkspace.sharedWorkspace().runningApplications
            .first({$0.localizedName! == self.applicationName}) {
            hsapp.activateWithOptions(NSApplicationActivationOptions.ActivateIgnoringOtherApps)
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
    
    var getHearthstoneApp: NSRunningApplication? {
        let apps = NSWorkspace.sharedWorkspace().runningApplications
        return apps.first({$0.localizedName! == self.applicationName})
    }
}
