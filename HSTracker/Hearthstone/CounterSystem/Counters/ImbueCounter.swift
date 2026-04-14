//
//  ImbueCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ImbueCounter: NumericCounter {
   override var cardIdToShowInUI: String? {
       isHamuul ? CardIds.NonCollectible.Druid.DreamboundDisciple_BlessingOfTheGolem : CardIds.Collectible.Neutral.MalorneTheWaywatcher
    }
    
    override var localizedName: String {
        String.localizedString("Counter_Imbue", comment: "")
    }
    
    override var relatedCards: [String] {
        [
            CardIds.NonCollectible.Druid.DreamboundDisciple_BlessingOfTheGolem,
            CardIds.NonCollectible.Hunter.BlessingOfTheWolf,
            CardIds.NonCollectible.Mage.BlessingOfTheWisp,
            CardIds.NonCollectible.Paladin.BlessingOfTheDragon,
            CardIds.NonCollectible.Priest.LunarwingMessenger_BlessingOfTheMoon,
            CardIds.NonCollectible.Shaman.BlessingOfTheWind,
            CardIds.NonCollectible.Deathknight.Finality_BlessingOfTheInfinite,
            CardIds.NonCollectible.Rogue.Eventuality_BlessingOfTheBronze,
            CardIds.Collectible.Neutral.MalorneTheWaywatcher
        ]
    }
    
    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }
    
    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        return counter > 0
    }
    
    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }
    
    override func valueToShow() -> String {
        return isHamuul ? "\(counter) \(subCounter)/3" : "\(counter)"
    }
    
    private var isHamuul = false
    private var subCounter = 0
    
    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        let controller = entity[.controller]
        let isCounterFromController = controller == game.player.id && isPlayerCounter || controller == game.opponent.id && !isPlayerCounter

        guard isCounterFromController else { return }
        
        if entity.cardId == CardIds.Collectible.Druid.HamuulRunetotem && tag == GameTag.has_activate_power && value == 1 {
            isHamuul = true
            return
        }
        
        if tag == GameTag.imbue_sub_counter && isHamuul {
            subCounter = value
            onCounterChanged()
            return
        }
        
        guard tag == GameTag.gametag_3527 else { return }
        guard value != 0 else { return }
        
        
        counter = value
    }
}
