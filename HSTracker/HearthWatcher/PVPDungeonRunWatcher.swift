//
//  PVPDungeonRunWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PVPDungeonRunWatcher: Watcher {
    var pvpDungeonInfoChanged: ((_ dungeonInfo: MirrorDungeonInfo) -> Void)?
    var pvpDungeonRunMatchStarted: ((_ newRun: Bool, _ cardSet: CardSet) -> Void)?
    private var _prevCards: [Int]?
    private var _prevLootChoice: Int?
    private var _prevTreasureChoice: Int?

    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }

    override func setup() {
        _prevCards = nil
        _prevLootChoice = nil
        _prevTreasureChoice = nil
    }

    override func update() -> Bool {
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
