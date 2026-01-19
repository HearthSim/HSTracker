//
//  MagisterDawngrasp.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/19/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class MagisterDawngrasp: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Mage.MagisterDawngrasp
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else {
            return false
        }
        let game = AppDelegate.instance().coreManager.game
        return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass)
            && getRelatedCards(player: opponent).count >= 2
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.spellsPlayedCards
            .filter { $0.has(tag: .spell_school) }
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
            .unique()
            .sorted(by: {
                guard let a = $0, let b = $1 else { return false }
                if a.spellSchool != b.spellSchool {
                    return a.spellSchool.rawValue < b.spellSchool.rawValue
                }
                return a.cost < b.cost }
            )
    }
}
