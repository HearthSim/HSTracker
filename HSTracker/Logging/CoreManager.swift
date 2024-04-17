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
    var toaster: Toaster!
    
    var timer = RepeatingTimer(timeInterval: 300.0)

    var queue = DispatchQueue(label: "net.hearthsim.hstracker.readers", attributes: [])
    
    override init() {
        self.game = Game(hearthstoneRunState: HearthstoneRunState(isRunning: CoreManager.isHearthstoneRunning(),
                                                                  isActive: CoreManager.isHearthstoneActive()))
        super.init()
        
        let ok = Helper.ensureClientLogConfig()
        if CoreManager.isHearthstoneRunning() && !ok {
            NotificationManager.showNotification(type: .restartRequired)
        }
        
        let logPath = MirrorHelper.getLogSessionDir()
        logReaderManager = LogReaderManager(logPath: logPath, coreManager: self)
        
        self.toaster = Toaster(windowManager: game.windowManager)
        
        DungeonRunDeckWatcher.dungeonRunMatchStarted = { newrun, set in CoreManager.dungeonRunMatchStarted(newRun: newrun, set: set, isPVPDR: false)
        }
        DungeonRunDeckWatcher.dungeonInfoChanged = { info in
            CoreManager.updateDungeonRunDeck(info: info, isPVPDR: false)
        }
        PVPDungeonRunWatcher.pvpDungeonRunMatchStarted = { newrun, set in
            CoreManager.dungeonRunMatchStarted(newRun: newrun, set: set, isPVPDR: true)
        }
        PVPDungeonRunWatcher.pvpDungeonInfoChanged = { info in
            CoreManager.updateDungeonRunDeck(info: info, isPVPDR: true)
        }
        
        QueueWatcher.inQueueChanged = { _, args in
            self.game.queueEvents.handle(args)
        }
        
        BaconWatcher.change = { _, args in
            if #available(macOS 10.15, *) {
                self.game.setBaconState(args.selectedBattlegroundsGameMode, args.isAnyOpen())
            }
        }
        DeckPickerWatcher.change = { _, args in
            self.game.setDeckPickerState(args.selectedFormatType, args.decksOnPage, args.isModalOpen)
        }
        
        SceneWatcher.change = { _, args in
            SceneHandler.onSceneUpdate(prevMode: Mode.allCases[args.prevMode], mode: Mode.allCases[args.mode], sceneLoaded: args.sceneLoaded, transitioning: args.transitioning)
        }
        
        ExperienceWatcher.newExperienceHandler = { args in
            AppDelegate.instance().coreManager.game.experienceChangedAsync(experience: args.experience, experienceNeeded: args.experienceNeeded, level: args.level, levelChange: args.levelChange, animate: args.animate)
        }
        
        timer.eventHandler = {
            logger.debug(self.formattedMemoryFootprint())
        }
        timer.resume()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func memoryFootprint() -> Float? {
        // The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
        // complex for the Swift C importer, so we have to define them ourselves.
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT
        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard
            kr == KERN_SUCCESS,
            count >= TASK_VM_INFO_REV1_COUNT
        else { return nil }
        
        let usedBytes = Float(info.phys_footprint)
        return usedBytes
        
    }

    func formattedMemoryFootprint() -> String {
        let usedBytes: UInt64? = UInt64(self.memoryFootprint() ?? 0)
        let usedMB = Double(usedBytes ?? 0) / 1024 / 1024
        let usedMBAsString: String = "Memory Used by App: \(String(format: "%.2f", usedMB))MB"
        return usedMBAsString
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
            ExperienceWatcher._instance.startWatching()
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
    
    private func internalStartTracking() {
        var retry = true
        if CoreManager.isHearthstoneRunning() {
            let logPath = MirrorHelper.getLogSessionDir()
            if !logPath.isEmpty {
                logger.info("Starting log reader with path \(logPath)")
                self.logReaderManager = LogReaderManager(logPath: logPath, coreManager: self)
                self.logReaderManager.start()
                if game.currentRegion == .unknown {
                    game.currentRegion = Helper.getCurrentRegion()
                }
                retry = false
                SceneWatcher.start()
            }
        }
        if retry {
            let time = DispatchTime.now() + .seconds(1)
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.internalStartTracking()
            }
        }
    }

    func startTracking() {
		// Starting logreaders after short delay is as game might be still in loading state
        let time = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: time) {
            logger.info("Start Tracking")
            if self.logReaderManager.running {
                self.logReaderManager.stop(eraseLogFile: !CoreManager.isHearthstoneRunning())
            }
            self.internalStartTracking()
        }
    }

    func stopTracking() {
        logger.info("Stop Tracking")
		logReaderManager.stop(eraseLogFile: !CoreManager.isHearthstoneRunning())
        DeckWatcher.stop()
        ArenaDeckWatcher.stop()
        DungeonRunDeckWatcher.stop()
        PVPDungeonRunWatcher.stop()
        ExperienceWatcher.stop()
        QueueWatcher.stop()
        BaconWatcher.stop()
        SceneWatcher.stop()
        DeckPickerWatcher.stop()
        MirrorHelper.destroy()
        game.windowManager.battlegroundsHeroPicking.viewModel.reset()
        game.windowManager.battlegroundsQuestPicking.viewModel.reset()
        game.windowManager.constructedMulliganGuide.viewModel.reset()
        game.windowManager.constructedMulliganGuidePreLobby.viewModel.reset()
        game.currentRegion = .unknown
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
            game.buildNumber = 0
            if let url = app.bundleURL, let dict = NSDictionary(contentsOf: url.appendingPathComponent("Contents/Info.plist")), let version = dict["CFBundleVersion"] as? String {
                let split = version.split(separator: ".")
                if split.count == 3 {
                    let build = String(split[2])
                    if let number = Int(build) {
                        game.buildNumber = number
                    }
                }
            }
            if !Helper.ensureClientLogConfig() {
                NotificationManager.showNotification(type: .restartRequired)
            }
            self.startTracking()
            self.game.setHearthstoneRunning(flag: true)
            ExperienceWatcher._instance.startWatching()
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
            ExperienceWatcher._instance.stopWatching()
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
    func autoDetectDeck(mode: Mode, playerClass: CardClass? = nil) -> Deck? {
        let deck = CoreManager.autoDetectDeckWithMirror(mode: mode, playerClass: playerClass)
        if deck != nil {
            return deck
        }
        
        return nil
    }
    
    static func getMissingCards(revealed: [String: [Entity]], deck: Deck) -> [String: [Entity]] {
        return revealed.filter({ x in deck.cards.filter({ c in c.id == x.key && c.count >= x.value.count}).count == 0 })
    }
    
    static func filterDeck(x: Deck, isPVPDR: Bool, playerClass: CardClass, newRun: Bool, revealed: [String: [Entity]]) -> Bool {
        guard x.isActive else {
            return false
        }
        if isPVPDR && x.isDuels || !isPVPDR && x.isDungeon {
            if x.playerClass == playerClass {
                if !(x.isDungeonRunCompleted() || x.isDuelsRunCompleted()) {
                    if !newRun || x.cards.count == 10 || x.cards.count == 11 {
                        let missing = getMissingCards(revealed: revealed, deck: x)
                        if missing.count == 0 {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    static func dungeonRunMatchStarted(newRun: Bool, set: CardSet, isPVPDR: Bool, recursive: Bool = false) {
        logger.info("Dungeon run detected! New=\(newRun), PVPDR: \(isPVPDR), Recursive=\(recursive)")
        guard let core = AppDelegate.instance().coreManager else {
            return
        }
        guard let boardHero = core.game.player.hero?.card else {
            logger.info("Dungeon run started but player entity not found")
            return
        }
        let opponentId = core.game.opponentHeroId
        if opponentId != "" {
            core.game.adventureOpponentId = opponentId
        }
        let playerClass = set == CardSet.uldum ? DefaultDecks.DungeonRun.getUldumHeroPlayerClass(playerClass: boardHero.playerClass) : boardHero.playerClass
        let adventureId = DungeonRunDeckWatcher.currentAdventure?.adventureId ?? .invalid
        let modeId = DungeonRunDeckWatcher.currentAdventure?.adventureModeId ?? .invalid
        if adventureId != AdventureDbId.boh && adventureId != AdventureDbId.bom && (playerClass == .invalid || playerClass == .neutral) {
            logger.info("Dungeon run started but player class is invalid")
            return
        }
        
        if !isPVPDR && ((adventureId == AdventureDbId.boh || adventureId == AdventureDbId.bom) || modeId == .linear || modeId == .linear_heroic) {
            logger.info("Book of Heroes/Mercenaries/Linear match started with playerClass \(playerClass)")
            let cards = DungeonRunDeckWatcher.dungeonRunDeck
            
            if cards.count > 0 {
                let deck = Deck()
                cards.group({ (c: Card) in c.id }).forEach({
                    let realmCard = RealmCard()
                    realmCard.id = $0.key
                    realmCard.count = $0.value.count
                    deck.cards.append(realmCard)
                })
                deck.playerClass = playerClass
                deck.heroId = playerClass.defaultHeroCardId
                if let hero = core.game.player.revealedEntities.first(where: { x in
                    x.isHero && !x.card.collectible
                }) {
                    deck.heroId = hero.cardId
                    deck.name = hero.card.name
                }
                
                core.game.set(activeDeck: deck, autoDetected: true)
                return
            }

        }
        
        let revealed = core.game.player.revealedEntities.filter({ x in x.isPlayableCard && !x.info.created && !x.info.stolen && x.card.collectible }).group({ (e: Entity) in e.cardId })
        
        let existingDeck = RealmHelper.getDecks()?.filter({ x in
            return filterDeck(x: x, isPVPDR: isPVPDR, playerClass: playerClass, newRun: newRun, revealed: revealed)
        }).sorted(by: { a, b in a.lastEdited > b.lastEdited }).first
        if existingDeck == nil {
            if newRun {
//                let hero = core.game.opponent.playerEntities.first(where: { x in x.isHero })?.cardId
                if set == CardSet.dalaran || set == CardSet.uldum {
                    _ = DungeonRunDeckWatcher._instance.updateDungeonInfo(key: DungeonRunDeckWatcher.saveKey)
                    if !recursive {
                        dungeonRunMatchStarted(newRun: newRun, set: set, isPVPDR: isPVPDR, recursive: true)
                        return
                    }
                } else {
                    _ = CoreManager.createDungeonDeck(playerClass: playerClass, hero: boardHero.id, set: set, isPVPDR: isPVPDR)
                }
            } else {
                logger.info("We don't have an existing deck for this run, but it's not a new run")
            }
        } else if let existingDeck = existingDeck {
            logger.info("Selecting existing deck: \(existingDeck.name)")
            core.game.set(activeDeckId: existingDeck.deckId, autoDetected: true)
        }
    }
    
    static func tryGetHeroClass(dbfId: Int) -> CardClass? {
        var result: CardClass?
        
        if let heroCard = Cards.by(dbfId: dbfId), heroCard.playerClass != .invalid {
            result = heroCard.playerClass
        }
        return result
    }
    
    static func updateDungeonRunDeck(info: MirrorDungeonInfo, isPVPDR: Bool) {
        let isNewPVPDR = isPVPDR && !info.runActive && info.selectedLoadoutTreasureDbId.intValue > 0
        logger.info("Found dungeon run deck Set=\(info.cardSet), PVPDR=\(isPVPDR) new=\(isNewPVPDR)")

        var allCards = info.dbfIds.compactMap({ x in x.intValue })

        // New PVPDR runs have all non-loadout cards in the DbfIds. We still add the picked loadout below.
        // So we don't want to replace allCards with baseDeck, as backDeck is empty, and we don't want to add
        // any loot or treasure, as these will be the ones from a previous run, if they exist.
        if !isNewPVPDR {
            let baseDeck = info.selectedDeckId.intValue > 0 ? MirrorHelper.getDungeonDeck(id: info.selectedDeckId.intValue) ?? [Int]() : [Int]()
            if allCards.count == 0 {
                allCards.append(contentsOf: baseDeck)
            }
            if info.playerChosenLoot.intValue > 0 {
                let loot = [ info.lootA, info.lootB, info.lootC ]
                let chosen = loot[info.playerChosenLoot.intValue - 1]
                for i in 1..<chosen.count {
                    allCards.append(chosen[i].intValue)
                }
            }
            if info.playerChosenTreasure.intValue > 0 {
                allCards.append(info.treasure[info.playerChosenTreasure.intValue - 1].intValue)
            }
        }

        var cards: [Card] = allCards.group({ x in x }).compactMap({ x in
            guard let card = Cards.by(dbfId: x.key, collectible: false) else {
                return nil
            }
            card.count = x.value.count
            return card
        })

        let loadout = info.selectedLoadoutTreasureDbId.intValue != 0 ? Cards.by(dbfId: info.selectedLoadoutTreasureDbId.intValue, collectible: false) : nil
        if let loadout = loadout, !allCards.contains(loadout.dbfId) {
            cards.append(loadout)
        }

        if !Settings.importDungeonIncludePassives {
            cards.removeAll(where: { c in !c.collectible && c.hideStats })
        }

        let cardSet = CardSetInt(rawValue: info.cardSet.intValue) ?? .invalid

        var playerClass: CardClass = .invalid
        if cardSet == CardSetInt.uldum, let loadout = loadout {
            playerClass = DefaultDecks.DungeonRun.getUldumHeroPlayerClass(playerClass: loadout.playerClass)
        } else if isPVPDR {
            if info.heroClass.intValue != 0 {
                playerClass = CardClass.allCases[info.heroClass.intValue]

            } else if info.heroCardDbId.intValue != 0, let cc = tryGetHeroClass(dbfId: info.heroCardDbId.intValue) {
                playerClass = cc
            } else if info.playerSelectedHeroDbId.intValue != 0, let cc = tryGetHeroClass(dbfId: info.playerSelectedHeroDbId.intValue) {
                playerClass = cc
            } else if info.heroCardClass.intValue != 0 {
                playerClass = CardClass.allCases[info.heroCardClass.intValue]
            }
        } else {
            playerClass = CardClass.allCases[info.heroClass.intValue != 0 ? info.heroClass.intValue : info.heroCardClass.intValue]
        }
        var deck = RealmHelper.getDecks()?.filter({ x in x.isActive && (!isPVPDR && x.isDungeon || isPVPDR && x.isDuels)
                                                    &&  x.playerClass == playerClass
                                                    && !x.isDungeonRunCompleted()
                                                    && !x.isDuelsRunCompleted() }).first
        let baseDeck = info.selectedDeckId.intValue > 0 ? MirrorHelper.getDungeonDeck(id: info.selectedDeckId.intValue) ?? [Int]() : [Int]()
        
        let baseDbfids = isPVPDR ? info.dbfIds.map({ x in x.intValue}) : baseDeck
        if deck == nil {
            let hero = playerClass.defaultHeroCardId
            let cardset = CardSet(rawValue: "\(cardSet)") ?? .invalid
            logger.debug("Creating new dungeon deck for hero \(hero), playerClass \(playerClass), cardset \(cardset), cardSet \(cardSet)")
            deck = createDungeonDeck(playerClass: playerClass, hero: hero, set: cardset, isPVPDR: isPVPDR, selectedDeck: baseDbfids, loadout: loadout)
        }
        if deck == nil {
            logger.info("No existing deck - can't find default deck for \(playerClass)")
            return
        }
        if !info.runActive && (cardSet == CardSetInt.uldum || cardSet == CardSetInt.dalaran) {
            logger.info("Inactive run for Set=\(cardSet) - this is a new run")
            return
        }
        if cards.all({ c in deck?.cards.filter({ e in c.id == e.id && c.count == e.count}).first != nil }) {
            logger.info("No new cards")
            return
        }
        if let deck = deck {
            RealmHelper.update(deck: deck, with: cards.sortCardList())
            logger.info("Updated dungeon run deck")
        }
    }

    static func createDungeonDeck(playerClass: CardClass, hero: String, set: CardSet, isPVPDR: Bool, selectedDeck: [Int]? = nil, loadout: Card? = nil) -> Deck? {
        guard let core = AppDelegate.instance().coreManager else {
            return nil
        }

        let shrine = core.game.player.board.first(where: { x in x.has(tag: GameTag.shrine) })?.cardId
        logger.info("Creating new \(playerClass) dungeon run deck CardSet=\(set), Shrine=\(String(describing: shrine)), SelectedDeck=\(selectedDeck != nil)")
        let tmpdeck = selectedDeck == nil
            ? DefaultDecks.DungeonRun.getDefaultDeck(playerClass: playerClass, set: set, shrineCardId: shrine)
            : DefaultDecks.DungeonRun.getDeckFromDbfIds(playerClass: playerClass, set: set, isPVPDR: isPVPDR, dbfIds: selectedDeck)
        guard let deck = tmpdeck else {
            logger.info("Could not find default deck for \(playerClass) in card set \(set) with Shrine=\(String(describing: shrine))")
            return nil
        }
        if let loadout = loadout, let selectedDeck = selectedDeck, !selectedDeck.contains(loadout.dbfId) {
            deck.tmpCards.append(loadout)
        }
        deck.heroId = hero
        deck.playerClass = playerClass
        RealmHelper.add(deck: deck, with: deck.tmpCards.sortCardList())
        core.game.set(activeDeckId: deck.deckId, autoDetected: true)
        return deck
    }
    
    static func autoDetectDeckWithMirror(mode: Mode, playerClass: CardClass? = nil) -> Deck? {
		
		let selectedModes: [Mode] = [.tavern_brawl, .tournament,
		                             .friendly, .adventure, .gameplay]
		if selectedModes.contains(mode) {
            
            // Try dungeon run deck
            if mode == .gameplay && AppDelegate.instance().coreManager.game.previousMode == .adventure
                && (DungeonRunDeckWatcher.currentModeId == .dungeon_crawl || DungeonRunDeckWatcher.currentModeId == .dungeon_crawl_heroic) {
                return nil
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
                } else {
                    selectedDeckId = MirrorHelper.getEditedDeck()?.id.int64Value ?? 0
                }
			}
			
			if let decks = MirrorHelper.getDecks() {
                guard let selectedDeck = decks.first(where: { $0.id as? Int64 ?? 0 == selectedDeckId }) else {
					logger.warning("No deck with id=\(selectedDeckId) found")
					return nil
				}
                if Deck.isExactlyWhizbang(selectedDeck) {
                    return nil // Cannot be imported here (will need to happen in the context of a game with a deck id)
                }
                logger.info("Found selected Mirror deck : \(selectedDeck.name) \(selectedDeck.id) \(selectedDeck.cards.count)")
				
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
    
    func autoSelectTemplateDeckById(deckId: Int) {
        if let selectedDeck = fromTemplateDeck(deckId: deckId) {
            game.set(activeDeck: selectedDeck, autoDetected: true)
            game.playerDeckAutodetected = true
        }
    }
    
    private func fromTemplateDeck(deckId: Int) -> Deck? {
        let deck = getTemplateDeck(deckId: deckId)
        return deck
    }
    
    private func getTemplateDeck(deckId: Int) -> Deck? {
        guard let deck = MirrorHelper.getTemplateDeckById(deckId: deckId) else {
            return nil
        }
        
        let ret = Deck()
        ret.name = deck.title
        ret.heroId = CardClass.allCases[deck.clazz.intValue].defaultHeroCardId
        
        let tmpCards = Dictionary(grouping: deck.cards, by: { x in x }).compactMap { (key: NSNumber, value: [NSNumber]) -> RealmCard? in
            guard let card = Cards.by(dbfId: key.intValue, collectible: false) else {
                return nil
            }
            let res = RealmCard()
            res.id = card.id
            res.count = value.count
            return res
        }
        for tmpCard in tmpCards {
            ret.cards.append(tmpCard)
        }
        return ret
    }
}
