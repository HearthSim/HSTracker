//
//  Chogall.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/19/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class Chogall: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warlock.Chogall
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        guard let card = Cards.by(cardId: getCardId()) else { return false }
        let game = AppDelegate.instance().coreManager.game
        return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass)
            && getRelatedCards(player: opponent).count > 2
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.entitiesDiscardedFromHand
            .compactMap { entity in CardUtils.getProcessedCardFromEntity(entity, player) }
    }
}

class ChogallWONDERS: Chogall {

    required init() {
        super.init()
    }

    override func getCardId() -> String {
        return CardIds.Collectible.Warlock.ChogallWONDERS
    }
    
    override func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
}
