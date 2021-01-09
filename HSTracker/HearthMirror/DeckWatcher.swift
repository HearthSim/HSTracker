//
//  DeckWatcher.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 19/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

class Watcher {
    internal var isRunning = false
    internal var queue: DispatchQueue?
    internal var refreshInterval: TimeInterval = 0.5

    func startWatching() {
        if isRunning {
            return
        }

        logger.info("Starting \(type(of: self))")

        queue = DispatchQueue(label: "net.hearthsim.hstracker.watchers.\(type(of: self))",
            attributes: [])
        if let queue = queue {
            isRunning = true
            queue.async { [weak self] in
                self?.run()
            }
        }
    }

    func stopWatching() {
        if isRunning {
            isRunning = false
            logger.info("Stopping \(type(of: self))")

            clean()
        }
    }

    internal func run() {
    }

    internal func clean() {
    }
}

class DeckWatcher: Watcher {
    static var selectedDeckId: Int64 = 0

    static let _instance = DeckWatcher()

    static func start() {
        _instance.startWatching()
    }

    static func stop() {
        _instance.stopWatching()
    }

    override func run() {
        while isRunning {
            guard let deckId = MirrorHelper.getSelectedDeck() else {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }

            if deckId > 0 {
                if deckId != DeckWatcher.selectedDeckId {
                    logger.info("found deck id: \(deckId)")
                }
                DeckWatcher.selectedDeckId = deckId
            }

            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
}

class ArenaDeckWatcher: Watcher {

    private(set) static var selectedDeck: MirrorDeck?

    private(set) static var selectedDeckId: Int64 = 0

    static let _instance = ArenaDeckWatcher()

    static func start() {
        _instance.startWatching()
    }

    static func stop() {
        _instance.stopWatching()
    }

    override func run() {
        while isRunning {
            guard let arenaInfo = MirrorHelper.getArenaDeck() else {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }

            ArenaDeckWatcher.selectedDeck = arenaInfo.deck

            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
}

class DungeonRunDeckWatcher: Watcher {
    private(set) static var dungeonRunDeck: [Card] = []
    private(set) static var currentModeId: AdventureModeDbId = .invalid
    
    static var dungeonInfoChanged: ((_ dungeonInfo: MirrorDungeonInfo) -> Void)?
    static var dungeonRunMatchStarted: ((_ newRun: Bool, _ set: CardSet) -> Void)?
    
    var _delay: TimeInterval
    var _prevCards: [Int]?
    var _prevLootChoice = 0
    var _prevTreasureChoice = 0
    var _prevAdventure: AdventureDbId = .invalid
    var _currentInfo: MirrorDungeonInfo?
    
    static var initialOpponents: [String] =  [
            CardIds.NonCollectible.Rogue.BinkTheBurglarHeroic,
            CardIds.NonCollectible.Hunter.GiantRatHeroic,
            CardIds.NonCollectible.Hunter.WeeWhelpHeroic,
            
            CardIds.NonCollectible.Druid.AMangyWolfHeroic,
            CardIds.NonCollectible.Hunter.GobblesHeroic,
            CardIds.NonCollectible.Druid.RottoothHeroic
    ]
        
    static let saveKeys: [AdventureDbId: GameSaveKeyId] = [ .loot: .adventure_data_server_loot,
                                                            .gil: .adventure_data_server_gil,
                                                            .trl: .adventure_data_server_trl,
                                                            .dalaran: .adventure_data_server_dalaran,
                                                            .uldum: .adventure_data_server_uldum,
                                                            .boh: .adventure_data_server_boh
    ]
    
    static let saveKeysHeroic: [AdventureDbId: GameSaveKeyId] = [ .dalaran: .adventure_data_server_dalaran_heroic,
                                                                  .uldum: .adventure_data_server_uldum_heroic
    ]
    
    static var currentAdventure: AdventureConfig?
    static var saveKey: GameSaveKeyId = .invalid

    static let _instance = DungeonRunDeckWatcher()

    init(delay: TimeInterval = 0.5) {
        _delay = delay
    }

    static func start() {
        _instance.startWatching()
    }

    static func stop() {
        _instance.stopWatching()
    }

    override func run() {
        _prevCards = nil
        _prevLootChoice = 0
        _prevTreasureChoice = 0
        DungeonRunDeckWatcher.dungeonRunDeck.removeAll()
        
        while isRunning {
            Thread.sleep(forTimeInterval: _delay)
            if !isRunning {
                break
            }
            if update() {
                break
            }
        }
        isRunning = false
        DungeonRunDeckWatcher.dungeonRunDeck.removeAll()
        queue = nil
        DungeonRunDeckWatcher.saveKey = .invalid
    }
    
    private func update() -> Bool {
        let game = AppDelegate.instance().coreManager.game
        guard var config = MirrorHelper.getAdventureConfig() else {
            return false
        }
        if config.adventureId != .invalid {
            DungeonRunDeckWatcher.currentAdventure = config
            DungeonRunDeckWatcher.currentModeId = config.adventureModeId
            if _prevAdventure != config.adventureId {
                _prevAdventure = config.adventureId
            }
        } else if let cfg = DungeonRunDeckWatcher.currentAdventure {
            config = cfg
        } else {
            return false
        }
        var key = GameSaveKeyId.invalid
        var isDungeonCrawl = false
        var isBOH = false
        if config.adventureModeId == .dungeon_crawl || config.adventureModeId == .dungeon_crawl_heroic {
            if config.adventureId != .boh {
                isDungeonCrawl = true
                if config.adventureModeId == .dungeon_crawl {
                    key = DungeonRunDeckWatcher.saveKeys[config.adventureId] ?? .invalid
                } else {
                    key = DungeonRunDeckWatcher.saveKeysHeroic[config.adventureId] ?? .invalid
                }
                DungeonRunDeckWatcher.saveKey = key
            } else {
                isBOH = true
                // BOH actually has a save key but for now we don't need it. The very first deck is not
                // available initially, so we request it from the scenario deck id instead
                DungeonRunDeckWatcher.saveKey = .invalid
            }
        } else {
            DungeonRunDeckWatcher.saveKey = .invalid
            if let deckId = MirrorHelper.getSelectedDeck() {
                DeckWatcher.selectedDeckId = deckId
            }
        }
        if game.inAdventureScreen && isDungeonCrawl && key != .invalid {
            let shouldBreak = updateDungeonInfo(key: key)
            if shouldBreak {
                return true
            }
        } else if game.inAiMatch && !game.opponentHeroId.isBlank {
            if let card = Cards.by(cardId: game.opponentHeroId) {
                if isDungeonCrawl && card.id.contains("BOSS") || card.set == CardSet.troll && card.id.hasSuffix("h") {
                    if config.adventureId == AdventureDbId.dalaran {
                        _ = updateDungeonInfo(key: key)
                        Thread.sleep(forTimeInterval: 0.5)
                    } else if _currentInfo == nil {
                        _ = updateDungeonInfo(key: key)
                    }
                    var newRun = false
                    if let info = _currentInfo, info.bossesDefeated.count == 0 {
                        newRun = true
                        logger.info("New run detected for adventure \(config.adventureId), opp \(game.opponentHeroId), health \(game.opponentHeroHealth)")
                    } else if _currentInfo == nil {
                        logger.debug("Current adventure info is nil, new run?")
                        newRun = true
                    }
                    DungeonRunDeckWatcher.dungeonRunMatchStarted?(newRun, card.set ?? .invalid)
                    return true
                } else if isBOH && card.id.contains("Story_") {
                    if config.selectedMission > 0, let deckId = MirrorHelper.getScenarioDeckId(id: config.selectedMission) {
                        if let dbfids = MirrorHelper.getDungeonDeck(id: deckId) {
                            let cards = dbfids.compactMap({ x in
                                let c = Cards.by(dbfId: x, collectible: false)
                                if c?.type == CardType.hero {
                                    return nil
                                }
                                return c
                            }).sortCardList()
                            DungeonRunDeckWatcher.dungeonRunDeck = cards
                            DungeonRunDeckWatcher.dungeonRunMatchStarted?(false, card.set ?? .invalid)
                        }
                    }
                    return true
                }
            }
        }
        return false
    }
    
    public func updateDungeonInfo(key: GameSaveKeyId) -> Bool {
        if let info = MirrorHelper.getDungeonRunInfo(key: key.rawValue), info.gameSaveId.intValue == key.rawValue {
            if info.runActive || info.selectedDeckId.intValue != 0 {
                _currentInfo = info
                switch DungeonRunDeckWatcher.currentAdventure?.adventureId {
                case .loot:
                    info.cardSet = NSNumber(value: CardSetInt.lootapalooza.rawValue)
                case .gil:
                    info.cardSet = NSNumber(value: CardSetInt.gilneas.rawValue)
                case .trl:
                    info.cardSet = NSNumber(value: CardSetInt.troll.rawValue)
                case .dalaran:
                    info.cardSet = NSNumber(value: CardSetInt.dalaran.rawValue)
                case .uldum:
                    info.cardSet = NSNumber(value: CardSetInt.uldum.rawValue)
                default:
                    info.cardSet = NSNumber(value: CardSetInt.invalid.rawValue)
                }
                if _prevCards == nil || _prevCards?.count != info.dbfIds.count || _prevLootChoice != info.playerChosenLoot.intValue || _prevTreasureChoice != info.playerChosenTreasure.intValue {
                    if info.heroClass.intValue == 0 && info.heroCardClass.intValue == 0 {
                        logger.debug("Hero is neutral")
                    }
                    _prevCards = info.dbfIds.compactMap({ x in x.intValue})
                    _prevLootChoice = info.playerChosenLoot.intValue
                    _prevTreasureChoice = info.playerChosenTreasure.intValue
                    DungeonRunDeckWatcher.dungeonInfoChanged?(info)
                }
            } else {
                _prevCards = nil
                _currentInfo = nil
            }
            if _prevLootChoice > 0 && _prevTreasureChoice > 0 {
                return true
            }
        } else {
            _prevCards = nil
        }
        
        return false
    }
}

class PVPDungeonRunWatcher: Watcher {
    static let _instance = PVPDungeonRunWatcher()
    
    static var pvpDungeonInfoChanged: ((_ dungeonInfo: MirrorDungeonInfo) -> Void)?
    static var pvpDungeonRunMatchStarted: ((_ newRun: Bool, _ cardSet: CardSet) -> Void)?

    static func start() {
        _instance.startWatching()
    }

    static func stop() {
        _instance.stopWatching()
    }
    
    private var _delay: TimeInterval
    private var _prevCards: [Int]?
    private var _prevLootChoice: Int?
    private var _prevTreasureChoice: Int?

    init(delay: TimeInterval = 0.5) {
        _delay = delay
    }

    override func run() {
        _prevCards = nil
        _prevLootChoice = nil
        _prevTreasureChoice = nil
        while isRunning {
            Thread.sleep(forTimeInterval: _delay)
            if !isRunning {
                break
            }
            if update() {
                break
            }
        }
        isRunning = false
        queue = nil
    }
    
    private func update() -> Bool {
        let game = AppDelegate.instance().coreManager.game
        
        if game.inPVPDungeonRunScreen {
            let shouldBreak = updatePVPDungeonInfo()
            if shouldBreak {
                return true
            }
        } else if game.inPVPDungeonRunMatch && !game.opponentHeroId.isBlank && (AppDelegate.instance().coreManager.game.player.board.first(where: { x in x.isHero })?.card) != nil {
            PVPDungeonRunWatcher.pvpDungeonRunMatchStarted?(false, CardSet.darkmoon_faire)
            return true
        }
        return false
    }
    
    private func updatePVPDungeonInfo() -> Bool {
        if let pvpDungeonInfo = MirrorHelper.getPVPDungeonInfo() {
            if pvpDungeonInfo.runActive {
                if _prevCards == nil || _prevCards?.count != pvpDungeonInfo.dbfIds.count || _prevLootChoice! as NSNumber != pvpDungeonInfo.playerChosenLoot || _prevTreasureChoice! as NSNumber != pvpDungeonInfo.playerChosenTreasure {
                    _prevCards = pvpDungeonInfo.dbfIds.map({ x in Int(truncating: x) })
                    _prevLootChoice = Int(truncating: pvpDungeonInfo.playerChosenLoot)
                    _prevTreasureChoice = Int(truncating: pvpDungeonInfo.playerChosenTreasure)
                    PVPDungeonRunWatcher.pvpDungeonInfoChanged?(pvpDungeonInfo)
                }
            } else if pvpDungeonInfo.selectedLoadoutTreasureDbId.intValue > 0 {
                guard let deck = MirrorHelper.getPVPDungeonSeedDeck() else {
                    return false
                }
                let dbfids = deck.cards.compactMap({ x in Cards.by(cardId: x.cardId)?.dbfId })
                if dbfids.any({ x in x == -1 }) {
                    return false
                }
                if dbfids.count == 15 {
                    pvpDungeonInfo.dbfIds = dbfids.compactMap({ x in NSNumber(value: x) })
                    PVPDungeonRunWatcher.pvpDungeonInfoChanged?(pvpDungeonInfo)
                    // this is the only scenario in which we can stop the watcher
                    // if a new deck is created the only options are to a) play a game or b) exit the PVPDR scene
                    return true
                }
            } else {
                _prevCards = nil
            }
            // We can not exit the watcher here if loot and treasures are selected like we do in the DungeonRunWatcher
            // because retiring the run will NOT leave the PVPDR scene and thus we would not restart the watcher through
            // the LoadingScreenHandler.
        } else {
            _prevCards = nil
        }
        return false
    }
}
