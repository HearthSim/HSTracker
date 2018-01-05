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
//import HearthAssets
import HearthMirror

enum HearthstoneLogError: Error {
    case canNotCreateDir,
    canNotReadFile,
    canNotCreateFile
}

struct HearthstoneRunState {
    var isRunning = false
    var isActive = false
    init(isRunning: Bool, isActive: Bool) {
        self.isRunning = isRunning
        self.isActive = isActive
    }
}

final class CoreManager: NSObject {
    static let applicationName = "Hearthstone"

    var logReaderManager: LogReaderManager!
    //static var assetGenerator: HearthAssets?
    
    // watchers
    let packWatcher = PackWatcher()
    
    let game: Game

    var queue = DispatchQueue(label: "be.michotte.hstracker.readers", attributes: [])
    
    override init() {
        self.game = Game(hearthstoneRunState: HearthstoneRunState(isRunning: CoreManager.isHearthstoneRunning(),
                                                                  isActive: CoreManager.isHearthstoneActive()))
        super.init()
		logReaderManager = LogReaderManager(logPath: Settings.hearthstonePath, coreManager: self)
		
		/*if CoreManager.assetGenerator == nil && Settings.useHearthstoneAssets {
			let path = Settings.hearthstonePath
			CoreManager.assetGenerator = try? HearthAssets(path: path)
			CoreManager.assetGenerator?.locale = (Settings.hearthstoneLanguage ?? .enUS).rawValue
		}*/
    }

    static func validatedHearthstonePath(_ path: String = "\(Settings.hearthstonePath)/Hearthstone.app") -> Bool {
        let exists = FileManager.default.fileExists(atPath: path)
        AppHealth.instance.setHSInstalled(flag: exists)
        return exists
    }

    // MARK: - Initialisation
    func start() {
        startListeners()
        if CoreManager.isHearthstoneRunning() {
            logger.info("Hearthstone is running, starting trackers now.")

            startTracking()
        }
    }

	/** Configures Hearthstone app logging so we can read them */
    func setup() throws -> Bool {
        let fileManager = FileManager.default
        let requireVerbose = [LogLineNamespace.power]

        // make sure the path exists
        let dir = NSString(string: configPath).deletingLastPathComponent
        logger.verbose("Check if \(dir) exists")
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: dir, isDirectory: &isDir) || !isDir.boolValue {
            do {
                logger.verbose("Creating \(dir)")
                try fileManager.createDirectory(atPath: dir,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
            } catch let error as NSError {
                AppHealth.instance.setLoggerWorks(flag: false)
                logger.error("\(error.description)")
                throw HearthstoneLogError.canNotCreateDir
            }
        }

        let zones = LogLineNamespace.usedValues()
        var missingZones: [LogLineZone] = []

        logger.verbose("Check if \(configPath) exists")
        if !fileManager.fileExists(atPath: configPath) {
            for zone in zones {
                missingZones.append(LogLineZone(namespace: zone))
            }
        } else {
            var fileContent: String?
            do {
                fileContent = try String(contentsOfFile: configPath)
            } catch {
                logger.error("\(error)")
            }
            if let fileContent = fileContent {
                var zonesFound: [LogLineZone] = []
                let splittedZones = fileContent.components(separatedBy: "[")
                    .map {
                        $0.replacingOccurrences(of: "]", with: "")
                            .components(separatedBy: "\n")
                            .filter { !$0.isEmpty }
                    }
                    .filter { !$0.isEmpty }

                for splittedZone in splittedZones {
                    var zoneData = splittedZone.filter { !$0.isBlank }
                    if zoneData.count < 1 {
                        continue
                    }
                    let zone = zoneData.removeFirst()
                    if let currentZone = LogLineNamespace(rawValue: zone) {
                        let logLineZone = LogLineZone(namespace: currentZone)
                        logLineZone.requireVerbose = requireVerbose.contains(currentZone)
                        for line in zoneData {
                            let kv = line.components(separatedBy: "=")
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
                logger.verbose("Zones found : \(zonesFound)")

                for zone in zones {
                    var currentZoneFound: LogLineZone?

                    for zoneFound in zonesFound where zoneFound.namespace == zone {
                        currentZoneFound = zoneFound
                        break
                    }

                    if let currentZone = currentZoneFound {
                        logger.verbose("Is \(currentZone.namespace) valid ? "
                            + "\(currentZone.isValid())")
                        if !currentZone.isValid() {
                            missingZones.append(currentZone)
                        }
                    } else {
                        logger.verbose("Zone \(zone) is missing")
                        missingZones.append(LogLineZone(namespace: zone))
                    }
                }
            }
        }

        logger.verbose("Missing zones : \(missingZones)")
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
                logger.error("\(error)")
                throw HearthstoneLogError.canNotCreateFile
            }

            if CoreManager.isHearthstoneRunning() {
                AppHealth.instance.setLoggerWorks(flag: false)
                return false
            }
        }
        AppHealth.instance.setLoggerWorks(flag: true)

        return true
    }

    func startTracking() {
		// Starting logreaders after short delay is as game might be still in loading state
        let time = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: time) { [unowned(unsafe) self] in
            logger.info("Start Tracking")

            self.logReaderManager.start()
        }
    }

    func stopTracking() {
        logger.info("Stop Tracking")
		logReaderManager.stop(eraseLogFile: !CoreManager.isHearthstoneRunning())
        DeckWatcher.stop()
        ArenaDeckWatcher.stop()
        MirrorHelper.destroy()
    }

    // MARK: - Events
    func startListeners() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let notifications = [
            NSWorkspace.activeSpaceDidChangeNotification: #selector(spaceChange),
            NSWorkspace.didLaunchApplicationNotification: #selector(appLaunched(_:)),
            NSWorkspace.didTerminateApplicationNotification: #selector(appTerminated(_:)),
            NSWorkspace.didActivateApplicationNotification: #selector(appActivated(_:)),
            NSWorkspace.didDeactivateApplicationNotification: #selector(appDeactivated(_:))
        ]
        for (name, selector) in notifications {
            notificationCenter.addObserver(self,
                                           selector: selector,
                                           name: name,
                                           object: nil)
        }
    }

    @objc func spaceChange() {
        logger.verbose("Receive space changed event")
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.space_changed), object: nil)
    }

    @objc func appLaunched(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication,
            app.localizedName == CoreManager.applicationName {
            logger.verbose("Hearthstone is now launched")
            self.startTracking()
            self.game.setHearthstoneRunning(flag: true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hearthstone_running), object: nil)
        }
    }

    @objc func appTerminated(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication,
            app.localizedName == CoreManager.applicationName {
            logger.verbose("Hearthstone is now closed")
            self.stopTracking()
            
            self.game.setHearthstoneRunning(flag: false)
            AppHealth.instance.setHearthstoneRunning(flag: false)

            if Settings.quitWhenHearthstoneCloses {
                NSApplication.shared.terminate(self)
            } else {
                logger.info("Not closing app since setting says so.")
            }
        }
    }

    @objc func appActivated(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication {
			
			if app.localizedName == CoreManager.applicationName {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hearthstone_active), object: nil)
                // TODO: add observer here as well
				self.game.setHearthstoneActived(flag: true)
                self.game.setSelfActivated(flag: false)
			}
			
			if app.bundleIdentifier == Bundle.main.bundleIdentifier {
				self.game.setSelfActivated(flag: true)
			}
        }
    }

    @objc func appDeactivated(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication {
			if app.localizedName == CoreManager.applicationName {
				self.game.setHearthstoneActived(flag: false)
			}
			if app.bundleIdentifier == Bundle.main.bundleIdentifier {
				self.game.setSelfActivated(flag: false)
			}
        }
    }

    static func bringHSToFront() {
        if let hsapp = CoreManager.hearthstoneApp {
            hsapp.activate(options: NSApplication.ActivationOptions.activateIgnoringOtherApps)
        }
    }

    // MARK: - Paths / Utils
    var configPath: String {
        return NSString(string: "~/Library/Preferences/Blizzard/Hearthstone/log.config")
            .expandingTildeInPath
    }

    private static func isHearthstoneRunning() -> Bool {
        return CoreManager.hearthstoneApp != nil
    }

    static var hearthstoneApp: NSRunningApplication? {
        let apps = NSWorkspace.shared.runningApplications
        return apps.first { $0.bundleIdentifier == "unity.Blizzard Entertainment.Hearthstone" }
    }
    
    static func isHearthstoneActive() -> Bool {
        return CoreManager.hearthstoneApp?.isActive ?? false
    }
	
	// MARK: - Deck detection
	static func autoDetectDeck(mode: Mode) -> Deck? {
		
		let selectedModes: [Mode] = [.tavern_brawl, .tournament,
		                             .friendly, .adventure, .gameplay]
		if selectedModes.contains(mode) {
			
			logger.info("Trying to import deck from Hearthstone")
			
			var selectedDeckId: Int64 = 0
			if let selectedId = MirrorHelper.getSelectedDeck() {
				selectedDeckId = selectedId
                logger.info("Found selected deck id via mirror: \(selectedDeckId)")
			} else {
				selectedDeckId = DeckWatcher.selectedDeckId
                logger.info("Found selected deck id via watcher: \(selectedDeckId)")
			}
			
			if selectedDeckId <= 0 {
				if mode != .tavern_brawl {
					return nil
				}
			}
			
			if let decks = MirrorHelper.getDecks() {
                guard let selectedDeck = decks.first(where: { $0.id as? Int64 ?? 0 == selectedDeckId }) else {
					logger.warning("No deck with id=\(selectedDeckId) found")
					return nil
				}
				logger.info("Found selected deck : \(selectedDeck.name)")
				
				if let deck = RealmHelper.checkAndUpdateDeck(deckId: selectedDeckId, selectedDeck: selectedDeck) {
					return deck
				}
				
				// deck does not exist, add it
				return RealmHelper.add(mirrorDeck: selectedDeck)
			} else {
                logger.warning("Mirror returned no decks")
				return nil
			}
			
		} else if mode == .draft {
			logger.info("Trying to import arena deck from Hearthstone")
			
			var hsMirrorDeck: MirrorDeck?
			if let mDeck = MirrorHelper.getArenaDeck()?.deck {
				hsMirrorDeck = mDeck
			} else {
				hsMirrorDeck = ArenaDeckWatcher.selectedDeck
			}
			
			guard let hsDeck = hsMirrorDeck else {
				logger.warning("Can't get arena deck")
				return nil
			}
			
			return RealmHelper.checkOrCreateArenaDeck(mirrorDeck: hsDeck)
		}
		
		logger.error("Auto-importing deck of \(mode) is not supported")
		return nil
	}
}
