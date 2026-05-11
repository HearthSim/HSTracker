//
//  SilverHandRecruitBuffCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class SilverHandRecruitBuffCounter: StatsCounter {

    override var localizedName: String {
        return String.localizedString("Counter_SilverHandRecruitBuff", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Paladin.SilverHandRecruitLegacyToken1
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Paladin.BrashBattlemaster,
            CardIds.Collectible.Paladin.ResilientSavior,
            CardIds.Collectible.Paladin.EmboldeningBlade
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isTraditionalHearthstoneMatch && (attackCounter > 0 || healthCounter > 0)
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }

    override func valueToShow() -> String {
        return "+\(max(0, attackCounter)) / +\(max(0, healthCounter))"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        guard tag == .zone else { return }
        guard value == Zone.play.rawValue else { return }

        let cardId = entity.card.id
        
        if cardId == CardIds.NonCollectible.Paladin.EmboldeningBlade_EmboldenedEnchantment1 {
            attackCounter += 1
            healthCounter += 1
        } else if cardId == CardIds.NonCollectible.Paladin.BrashBattlemaster_RecruitsMightEnchantment {
            attackCounter += 1
        } else if cardId == CardIds.NonCollectible.Paladin.ResilientSavior_RecruitsResilienceEnchantment {
            healthCounter += 1
        }
    }
}
