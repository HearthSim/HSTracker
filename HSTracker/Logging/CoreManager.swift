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
import kotlin_hslog

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

class MacOSConsole: Kotlin_consoleConsole {
    func debug(message: String) {
        logger.debug(message)
    }
    
    func error(message: String) {
        logger.error(message)
    }
    
    func error(throwable: KotlinThrowable) {
        throwable.printStackTrace()
    }
}

class MacOSAnalytics: Kotlin_analyticsAnalytics {
    func logEvent(name: String, params: [String : Any]) {
    }
}

class MacOSPreferences: Kotlin_hsreplay_apiPreferences {
    func getBoolean(key: String) -> KotlinBoolean? {
        return KotlinBoolean(value: UserDefaults.standard.bool(forKey: key))
    }
    
    func getString(key: String) -> String? {
        return UserDefaults.standard.string(forKey: key)
    }
    
    func putBoolean(key: String, value: KotlinBoolean?) {
        if let v = value {
            UserDefaults.standard.set(v, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    func putString(key: String, value: String?) {
        if let v = value {
            UserDefaults.standard.set(v, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
}

final class CoreManager: NSObject {
    static let applicationName = "Hearthstone"

    var logReaderManager: LogReaderManager!
    //static var assetGenerator: HearthAssets?
    
    // watchers
    let packWatcher = PackWatcher()
    
    let game: Game
    var cardJson: CardJson!
    var exposedHsReplay: ExposedHsReplay!

    var hsLog: HSLog!
    
    var queue = DispatchQueue(label: "net.hearthsim.hstracker.readers", attributes: [])
    
    override init() {
        self.game = Game(hearthstoneRunState: HearthstoneRunState(isRunning: CoreManager.isHearthstoneRunning(),
                                                                  isActive: CoreManager.isHearthstoneActive()))
        super.init()
		logReaderManager = LogReaderManager(logPath: Settings.hearthstonePath, coreManager: self)
        
        let lang: Language.Hearthstone
        if Settings.hearthstoneLanguage == nil {
            lang = Language.Hearthstone.enUS
        } else {
            lang = Settings.hearthstoneLanguage!
        }
        
        let maybeUrl = Bundle(for: type(of: self))
            .url(forResource: "Resources/Cards/cardsDB.\(lang)",
                withExtension: "json")
        
        let console = MacOSConsole()
        if let url = maybeUrl, let fileHandle = try? FileHandle(forReadingFrom: url) {
            let input = PosixInputKt.Input(fileDescriptor: fileHandle.fileDescriptor)
            logger.debug("building CardJson...")
            self.cardJson = CardJson.Companion().fromLocalizedJson(input: input)
            FreezeHelperKt.freeze(self.cardJson)
            logger.debug("building HSLog...")
            hsLog = HSLog(console: console, cardJson: cardJson, debounceDelay: 100)
            hsLog.setListener(listener: HSTLogListener(windowManager: game.windowManager))
        }
        
        self.exposedHsReplay = ExposedHsReplay(
            preferences: MacOSPreferences(),
            console: console,
            analytics: MacOSAnalytics(),
            userAgent: Http.userAgent()
        )
        
        if let refreshToken = Settings.hsReplayOAuthRefreshToken, let oauthToken = Settings.hsReplayOAuthToken {
            exposedHsReplay.setTokens(accessToken: oauthToken, refreshToken: refreshToken)
        }
    }
    
    func processPower(rawLine: String) {
        DispatchQueue.main.async {
            self.hsLog.processPower(rawLine: rawLine, isOldData: false)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        CollectionWatcher.stop()
        MirrorHelper.destroy()
    }
    
    var triggers: [NSObjectProtocol] = []

    // MARK: - Events
    func startListeners() {
        if self.triggers.count == 0 {
            let center = NSWorkspace.shared.notificationCenter
            let notifications = [
                NSWorkspace.activeSpaceDidChangeNotification: spaceChange,
                NSWorkspace.didLaunchApplicationNotification: appLaunched,
                NSWorkspace.didTerminateApplicationNotification: appTerminated,
                NSWorkspace.didActivateApplicationNotification: appActivated,
                NSWorkspace.didDeactivateApplicationNotification: appDeactivated
            ]
            for (event, trigger) in notifications {
                let observer = center.addObserver(forName: event, object: nil, queue: OperationQueue.main) { note in
                    trigger(note)
                }
                triggers.append(observer)
            }
        }
    }

    func spaceChange(_ notification: Notification) {
        logger.verbose("Receive space changed event")
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.space_changed), object: nil)
    }

    func appLaunched(_ notification: Notification) {
        if let app = notification.userInfo!["NSWorkspaceApplicationKey"] as? NSRunningApplication,
            app.localizedName == CoreManager.applicationName {
            logger.verbose("Hearthstone is now launched")
            self.startTracking()
            self.game.setHearthstoneRunning(flag: true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hearthstone_running), object: nil)
        }
    }

    func appTerminated(_ notification: Notification) {
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

    func appActivated(_ notification: Notification) {
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

    func appDeactivated(_ notification: Notification) {
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
    static func autoDetectDeck(mode: Mode, playerClass: CardClass? = nil) -> Deck? {
		
		let selectedModes: [Mode] = [.tavern_brawl, .tournament,
		                             .friendly, .adventure, .gameplay]
		if selectedModes.contains(mode) {
            
            // Try dungeon run deck
            if mode == .adventure && Settings.autoImportDungeonRun {
                if let opponentId = MirrorHelper.getMatchInfo()?.opposingPlayer.playerId.intValue {
                    if DungeonRunDeckWatcher.initialOpponents.contains(opponentId), let playerClass = playerClass {
                        // get player class MirrorHelper.get
                        let cards = DefaultDecks.DungeonRun.deck(for: playerClass)
                        logger.info("Found starter dungeon run deck")
                        return RealmHelper.checkAndUpdateDungeonRunDeck(cards: cards, reset: true)
                    }
                }
                let cards = DungeonRunDeckWatcher.dungeonRunDeck
                if cards.count > 0 {
                    logger.info("Found dungeon run deck via watcher")
                    return RealmHelper.checkAndUpdateDungeonRunDeck(cards: cards)
                }
            }
			
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
