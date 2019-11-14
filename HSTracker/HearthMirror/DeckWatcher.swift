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

class CollectionWatcher: Watcher {
    private var sent: Bool = false
    private var mirrorCollection: MirrorCollection? = nil
    
    private(set) static var lastUploadedCollection: MirrorCollection?
    internal var uploadingInterval: TimeInterval = 5

    private let windowManager: WindowManager
    private let game: Game
    private var hideWindowWorkItem: DispatchWorkItem?
    
    static private var _instance: CollectionWatcher?

    static func start(game: Game) {
        if _instance == nil {
            _instance = CollectionWatcher(game: game)
        }
        
        guard let instance = _instance else {
            return
        }
        instance.startWatching()
    }
    
    init(game: Game) {
        self.game = game
        self.windowManager = game.windowManager
    }

    static func stop() {
        guard let instance = _instance else {
            return
        }
        instance.stopWatching()
    }

    func sendMessage(message: String) {
        if let workItem = hideWindowWorkItem {
            workItem.cancel()
        }
        DispatchQueue.main.async { [unowned(unsafe) self] in
            let collectionFeedback = self.windowManager.collectionFeedBack
            let rect = SizeHelper.collectionFeedbackFrame()

            self.windowManager.show(controller: collectionFeedback, show: true, frame: rect, title: nil, overlay: true)
            collectionFeedback.setMessage(message: message)
        }
    }
    
    func hideWindow() {
        let workItem = DispatchWorkItem(block: {
            self.windowManager.show(controller: self.windowManager.collectionFeedBack, show: self.game.shouldShowGUIElement)
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

    override func run() {
        while isRunning {
            
            if self.mirrorCollection == nil {
                mirrorCollection = MirrorHelper.getCollection()
                if mirrorCollection == nil  {
                    Thread.sleep(forTimeInterval: refreshInterval)
                }
            } else if !sent, let collection = mirrorCollection {
                sent = true
                sendMessage(message: "Uploading collection...")

                // convert mirror data into collection
                let data = UploadCollectionData(collection: collection.cards, favoriteHeroes: collection.favoriteHeroes, cardbacks: collection.cardbacks, favoriteCardback: collection.favoriteCardback.intValue, dust: collection.dust.intValue, gold: collection.gold.intValue)

                CollectionUploader.upload(collectionData: data) { result in
                    switch result {
                    case .successful:
                        NotificationManager.showNotification(type: .hsReplayCollectionUploaded)
                        self.sendMessage(message: "Collection uploaded successfully")
                    case .failed(let error):
                        self.sendMessage(message: "Error while uploading the collection")
                        NotificationManager.showNotification(type: .hsReplayCollectionUploadFailed(error: error))
                    }
                }
            } else {
                Thread.sleep(forTimeInterval: refreshInterval)
            }
        }

        queue = nil
    }
}
