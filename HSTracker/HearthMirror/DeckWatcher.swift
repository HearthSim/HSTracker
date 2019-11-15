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
        isRunning = false
        logger.info("Stopping \(type(of: self))")

        clean()
    }

    internal func run() {
    }

    internal func clean() {
    }
}

class DeckWatcher: Watcher {
    private(set) static var selectedDeckId: Int64 = 0

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

    static var initialOpponents: [Int] = {
        return [
            Cards.by(cardId: CardIds.NonCollectible.Rogue.BinkTheBurglarHeroic)!.dbfId,
            Cards.by(cardId: CardIds.NonCollectible.Hunter.GiantRatHeroic)!.dbfId,
            Cards.by(cardId: CardIds.NonCollectible.Hunter.WeeWhelpHeroic)!.dbfId]
    }()

    static let _instance = DungeonRunDeckWatcher()

    static func start() {
        _instance.startWatching()
    }

    static func stop() {
        _instance.stopWatching()
    }

    override func run() {
        outerLoop: while isRunning {
            guard let dungeonRunInfo = MirrorHelper.getDungeonRunInfo() else {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }

            // assembly dungeon deck
            var deck: [Card: Int] = [:]
            for dbfid in dungeonRunInfo.dbfIds {
                if let card = Cards.by(dbfId: dbfid.intValue, collectible: false) {
                    if let count = deck[card] {
                        deck[card] = count + 1
                    } else {
                        deck[card] = 1
                    }
                } else {
                    logger.error("Unknown dbfid: \(dbfid.intValue)")
                    Thread.sleep(forTimeInterval: refreshInterval)
                    continue outerLoop
                }
            }

            // add loot
            let selectedLoot = dungeonRunInfo.playerChosenLoot.intValue
            if selectedLoot > 0 {
                let lootBag = selectedLoot == 1 ? dungeonRunInfo.lootA : (selectedLoot == 2 ? dungeonRunInfo.lootB : dungeonRunInfo.lootC)
                for dbfid in lootBag[1...] {
                    if let card = Cards.by(dbfId: dbfid.intValue, collectible: false) {
                        if let count = deck[card] {
                            deck[card] = count + 1
                        } else {
                            deck[card] = 1
                        }
                    } else {
                        logger.error("Unknown dbfid: \(dbfid.intValue)")
                        Thread.sleep(forTimeInterval: refreshInterval)
                        continue outerLoop
                    }
                }
            }

            // add treasure
            let selectedTreasure = dungeonRunInfo.playerChosenTreasure.intValue
            if selectedTreasure > 0 {
                let dbfid = dungeonRunInfo.treasure[selectedTreasure - 1]
                if let card = Cards.by(dbfId: dbfid.intValue, collectible: false) {
                    if let count = deck[card] {
                        deck[card] = count + 1
                    } else {
                        deck[card] = 1
                    }
                } else {
                    logger.error("Unknown dbfid: \(dbfid.intValue)")
                    Thread.sleep(forTimeInterval: refreshInterval)
                    continue outerLoop
                }
            }

            let dungeonrundeck: [Card] = deck.map {
                $0.0.count = $0.1
                return $0.0
            }
            if dungeonrundeck != DungeonRunDeckWatcher.dungeonRunDeck {
                logger.info("Found new dungeon run deck: \(dungeonrundeck)")
            }
            DungeonRunDeckWatcher.dungeonRunDeck = dungeonrundeck
            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
}
