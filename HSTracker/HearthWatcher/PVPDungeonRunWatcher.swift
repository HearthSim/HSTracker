//
//  PVPDungeonRunWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

class PVPDungeonRunWatcher {
    var pvpDungeonInfoChanged: ((_ dungeonInfo: MirrorDungeonInfo) -> Void)?
    var pvpDungeonRunMatchStarted: ((_ newRun: Bool, _ cardSet: CardSet) -> Void)?
    private let delay: TimeInterval
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    private var _prevCards: [Int]?
    private var _prevLootChoice: Int?
    private var _prevTreasureChoice: Int?
    internal var queue: DispatchQueue?
    
    init(delay: TimeInterval = 0.200) {
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
    
    private func watch() {
        _running.store(true, ordering: .sequentiallyConsistent)
        _prevCards = nil
        _prevLootChoice = nil
        _prevTreasureChoice = nil
        while _watch.load(ordering: .sequentiallyConsistent) {
            Thread.sleep(forTimeInterval: delay)
            if !_watch.load(ordering: .sequentiallyConsistent) {
                break
            }
            if update() {
                break
            }
        }
        _running.store(false, ordering: .sequentiallyConsistent)
    }
    
    private func update() -> Bool {
        let game = AppDelegate.instance().coreManager.game
        
        if game.inPVPDungeonRunScreen {
            let shouldBreak = updatePVPDungeonInfo()
            if shouldBreak {
                return true
            }
        } else if game.inPVPDungeonRunMatch && !game.opponentHeroId.isBlank && (AppDelegate.instance().coreManager.game.player.hero?.card) != nil {
            pvpDungeonRunMatchStarted?(false, CardSet.darkmoon_faire)
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
                    pvpDungeonInfoChanged?(pvpDungeonInfo)
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
                    pvpDungeonInfoChanged?(pvpDungeonInfo)
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
