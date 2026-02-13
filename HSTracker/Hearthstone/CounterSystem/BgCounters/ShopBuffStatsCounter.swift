//
//  ShopBuffStatsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ShopBuffStatsCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool {
        return true
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.NomiKitchenNightmare
    }
    
    override var relatedCards: [String] {
        return [ CardIds.NonCollectible.Neutral.ElementalShopBuffPlayerEnchantmentDnt ]
    }
    
    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }
    
    override var localizedName: String {
        return String.localizedString("Counter_ElementalTavernBuff", comment: "")
    }
    
    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && (attackCounter > 1 || healthCounter > 1)
    }
    
    override func getCardsToDisplay() -> [String] {
        return [
            CardIds.NonCollectible.Neutral.NomiKitchenNightmare,
            CardIds.NonCollectible.Neutral.DazzlingLightspawn,
            CardIds.NonCollectible.Neutral.DancingBarnstormer,
            CardIds.NonCollectible.Neutral.LivingAzerite,
            CardIds.NonCollectible.Neutral.DuneDweller,
            CardIds.NonCollectible.Neutral.BlazingGreasefire,
            CardIds.NonCollectible.Neutral.AlignTheElements
        ]
    }
    
    override func valueToShow() -> String {
        return "+\(max(1, attackCounter)) / +\(max(1, healthCounter))"
    }
    
    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }
        
        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }
        
        if tag == .zone,
           value == Zone.play.rawValue || (value == Zone.setaside.rawValue && prevValue == Zone.play.rawValue),
           relatedCards.contains(entity.cardId) {
            onCounterChanged()
        }
        
        guard relatedCards.contains(entity.cardId) else { return }
        
        let buffValue = value - prevValue
        
        if tag == .tag_script_data_num_1,
           entity.cardId == CardIds.NonCollectible.Neutral.NomiSticker_NomiStickerPlayerEnchantDnt {
            attackCounter += buffValue
            healthCounter += buffValue
        } else {
            if tag == .tag_script_data_num_1 {
                attackCounter += buffValue
            }
            
            if tag == .tag_script_data_num_2 {
                healthCounter += buffValue
            }
        }
    }
}
