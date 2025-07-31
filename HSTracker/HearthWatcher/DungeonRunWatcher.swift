//
//  DungeonRunWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

class DungeonRunDeckWatcher {
    private(set) var dungeonRunDeck: [Card] = []
    private(set) var currentModeId: AdventureModeDbId = .invalid
    
    var dungeonInfoChanged: ((_ dungeonInfo: MirrorDungeonInfo) -> Void)?
    var dungeonRunMatchStarted: ((_ newRun: Bool, _ set: CardSet) -> Void)?
    
    private let delay: TimeInterval
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    var _prevCards: [Int]?
    var _prevLootChoice = 0
    var _prevTreasureChoice = 0
    var _prevAdventure: AdventureDbId = .invalid
    var _currentInfo: MirrorDungeonInfo?
    
    internal var queue: DispatchQueue?
    
    init(delay: TimeInterval = 0.500) {
        self.delay = delay
    }
    
    func run() {
        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                guard let self else { return }
                Thread.current.name = queue.label
                self.watch()
            }
        }
    }
    
    func stop() {
        _watch.store(false, ordering: .sequentiallyConsistent)
    }

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
    
    var currentAdventure: AdventureConfig?
    var saveKey: GameSaveKeyId = .invalid
    
    private func watch() {
        _running.store(true, ordering: .sequentiallyConsistent)
        _prevCards = nil
        _prevLootChoice = 0
        _prevTreasureChoice = 0
        dungeonRunDeck.removeAll()
        
        while _watch.load(ordering: .sequentiallyConsistent) {
            Thread.sleep(forTimeInterval: delay)
            if !_watch.load(ordering: .sequentiallyConsistent) {
                break
            }
            if update() {
                break
            }
        }
        dungeonRunDeck.removeAll()
        saveKey = .invalid
        _running.store(false, ordering: .sequentiallyConsistent)
    }
    
    private func update() -> Bool {
        let game = AppDelegate.instance().coreManager.game
        guard var config = MirrorHelper.getAdventureConfig() else {
            return false
        }
        if config.adventureId != .invalid {
            currentAdventure = config
            currentModeId = config.adventureModeId
            if _prevAdventure != config.adventureId {
                _prevAdventure = config.adventureId
            }
        } else if let cfg = currentAdventure {
            config = cfg
        } else {
            return false
        }
        var key = GameSaveKeyId.invalid
        var isDungeonCrawl = false
        var isBOH = false
        if config.adventureModeId == .dungeon_crawl || config.adventureModeId == .dungeon_crawl_heroic {
            if config.adventureId != .boh && config.adventureId != .bom {
                isDungeonCrawl = true
                if config.adventureModeId == .dungeon_crawl {
                    key = DungeonRunDeckWatcher.saveKeys[config.adventureId] ?? .invalid
                } else {
                    key = DungeonRunDeckWatcher.saveKeysHeroic[config.adventureId] ?? .invalid
                }
                saveKey = key
            } else {
                isBOH = true
                // BOH actually has a save key but for now we don't need it. The very first deck is not
                // available initially, so we request it from the scenario deck id instead
                saveKey = .invalid
            }
        } else {
            saveKey = .invalid
//            if let deckId = MirrorHelper.getSelectedDeck() {
//                DeckWatcher.selectedDeckId = deckId
//            }
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
                    dungeonRunMatchStarted?(newRun, card.set ?? .invalid)
                    return true
                } else if (isBOH && (card.id.contains("Story_") || card.id.contains("BOM_"))) || (config.adventureModeId == .linear || config.adventureModeId == .linear_heroic) {
                    if config.selectedMission > 0, let deckId = MirrorHelper.getScenarioDeckId(id: config.selectedMission) {
                        if let dbfids = MirrorHelper.getDungeonDeck(id: deckId) {
                            let cards = dbfids.compactMap({ x in
                                let c = Cards.by(dbfId: x, collectible: false)
                                if c?.type == CardType.hero {
                                    return nil
                                }
                                return c
                            }).sortCardList()
                            dungeonRunDeck = cards
                            dungeonRunMatchStarted?(false, card.set ?? .invalid)
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
                switch currentAdventure?.adventureId {
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
                    dungeonInfoChanged?(info)
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
