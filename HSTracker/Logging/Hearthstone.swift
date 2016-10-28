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

enum HearthstoneLogError: Error {
    case canNotCreateDir,
    canNotReadFile,
    canNotCreateFile
}

final class Hearthstone: NSObject {
    let applicationName = "Hearthstone"

    lazy var logReaderManager = LogReaderManager()

    var hearthstoneActive = false
    var queue = DispatchQueue(label: "be.michotte.hstracker.readers", attributes: [])

    static let instance = Hearthstone()

    static func findHearthstone() -> String? {
        let path = "/Applications/Hearthstone/Hearthstone.app"
        if FileManager.default.fileExists(atPath: path) {
            return "/Applications/Hearthstone"
        }
        return nil
    }

    static func validatedHearthstonePath() -> Bool {
        let path = "\(Settings.instance.hearthstoneLogPath)/Hearthstone.app"
        let exists = FileManager.default.fileExists(atPath: path)
        AppHealth.instance.setHSInstalled(flag: exists)
        return exists
    }

    // MARK: - Initialisation
    func start() {
        startListeners()
        if isHearthstoneRunning {
            hearthstoneActive = true
            Log.info?.message("Hearthstone is running, starting trackers now.")
            startTracking()
        }
    }

    func setup() throws -> Bool {
        let fileManager = FileManager.default
        let requireVerbose = [LogLineNamespace.power]

        // make sure the path exists
        let dir = NSString(string: configPath).deletingLastPathComponent
        Log.verbose?.message("Check if \(dir) exists")
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: dir, isDirectory: &isDir) || !isDir.boolValue {
            do {
                Log.verbose?.message("Creating \(dir)")
                try fileManager.createDirectory(atPath: dir,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
            } catch let error as NSError {
                AppHealth.instance.setLoggerWorks(flag: false)
                Log.error?.message("\(error.description)")
                throw HearthstoneLogError.canNotCreateDir
            }
        }

        let zones = LogLineNamespace.usedValues()
        var missingZones: [LogLineZone] = []

        Log.verbose?.message("Check if \(configPath) exists")
        if !fileManager.fileExists(atPath: configPath) {
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
                var zonesFound: [LogLineZone] = []
                let splittedZones = fileContent.characters.split { $0 == "[" }
                    .map(String.init)
                    .map {
                        $0.replacingOccurrences(of: "]", with: "")
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
                            if let key = kv.first, let value = kv.last {
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
                        Log.verbose?.message("Is \(currentZone.namespace) valid ? "
                            + "\(currentZone.isValid())")
                        if !currentZone.isValid() {
                            missingZones.append(currentZone)
                        }
                    } else {
                        Log.verbose?.message("Zone \(zone) is missing")
                        missingZones.append(LogLineZone(namespace: zone))
                    }
                }
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
                try fileContent.write(toFile: configPath,
                                            atomically: true,
                                            encoding: .utf8)
            } catch {
                Log.error?.message("\(error)")
                throw HearthstoneLogError.canNotCreateFile
            }

            if isHearthstoneRunning {
                AppHealth.instance.setLoggerWorks(flag: false)
                return false
            }
        }
        AppHealth.instance.setLoggerWorks(flag: true)

        return true
    }

    func startTracking() {
        Log.info?.message("Start Tracking")
        //queue.async {
            self.logReaderManager.start()
        //}
    }

    func stopTracking() {
        Log.info?.message("Stop Tracking")
        logReaderManager.stop()
    }

    // MARK: - Events
    func startListeners() {
        let notificationCenter = NSWorkspace.shared().notificationCenter
        let notifications = [
            NSNotification.Name.NSWorkspaceActiveSpaceDidChange: #selector(spaceChange),
            NSNotification.Name.NSWorkspaceDidLaunchApplication: #selector(appLaunched(_:)),
            NSNotification.Name.NSWorkspaceDidTerminateApplication: #selector(appTerminated(_:)),
            NSNotification.Name.NSWorkspaceDidActivateApplication: #selector(appActivated(_:)),
            NSNotification.Name.NSWorkspaceDidDeactivateApplication: #selector(appDeactivated(_:)),
        ]
        for (name, selector) in notifications {
            notificationCenter.addObserver(self,
                                           selector: selector,
                                           name: name,
                                           object: nil)
        }
    }

    func spaceChange() {
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: "space_changed"), object: nil)
    }

    func appLaunched(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication,
            app.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now launched")
            self.startTracking()
            SizeHelper.hearthstoneWindow.reload()
            NotificationCenter.default.post(name:
                Notification.Name(rawValue: "hearthstone_running"), object: nil)
            AppHealth.instance.setHearthstoneRunning(flag: true)
        }
    }

    func appTerminated(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication,
            app.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now closed")
            self.stopTracking()
            NotificationCenter.default
                .post(name: Notification.Name(rawValue: "hearthstone_closed"), object: nil)
            AppHealth.instance.setHearthstoneRunning(flag: false)

            if Settings.instance.quitWhenHearthstoneCloses {
                NSApplication.shared().terminate(self)
            } else {
                Log.info?.message("Not closing app since setting says so.")
            }
        }
    }

    func appActivated(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication,
            app.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now active")
            self.hearthstoneActive = true
            AppHealth.instance.setHearthstoneRunning(flag: true)
            SizeHelper.hearthstoneWindow.reload()
            NotificationCenter.default
                .post(name: Notification.Name(rawValue: "hearthstone_active"), object: nil)
        }
    }

    func appDeactivated(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication,
            app.localizedName == applicationName {
            Log.verbose?.message("Hearthstone is now inactive")
            self.hearthstoneActive = false
            NotificationCenter.default
                .post(name: Notification.Name(rawValue: "hearthstone_deactived"), object: nil)
        }
    }

    func bringToFront() {
        if let hsapp = hearthstoneApp {
            hsapp.activate(options: .activateIgnoringOtherApps)
        }
    }

    // MARK: - Paths / Utils
    var configPath: String {
        return NSString(string: "~/Library/Preferences/Blizzard/Hearthstone/log.config")
            .expandingTildeInPath
    }

    var logPath: String {
        return Settings.instance.hearthstoneLogPath
    }

    var isHearthstoneRunning: Bool {
        return hearthstoneApp != nil
    }

    var hearthstoneApp: NSRunningApplication? {
        let apps = NSWorkspace.shared().runningApplications
        return apps.first({$0.localizedName! == self.applicationName})
    }
}
