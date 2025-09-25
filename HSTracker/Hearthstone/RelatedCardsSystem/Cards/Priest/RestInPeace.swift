//
//  RestInPeace.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class RestInPeace: ICardWithRelatedCards {
	required init() {}

	func getCardId() -> String {
		CardIds.Collectible.Priest.RestInPeace
	}

	func shouldShowForOpponent(opponent: Player) -> Bool {
        let game = AppDelegate.instance().coreManager.game

        guard let card = Cards.by(cardId: getCardId()) else { return false }
        return CardUtils.mayCardBeRelevant(card: card, gameType: game.currentGameType, format: game.currentFormatType, playerClass: opponent.originalClass)
			&& getRelatedCards(player: opponent).count > 0
	}

	private var opponentHero: String {
        let game = AppDelegate.instance().coreManager.game

		return game.opponentHeroId
	}

	private var playerHero: String {
        let game = AppDelegate.instance().coreManager.game

		return game.playerHeroId
	}

	func getRelatedCards(player: Player) -> [Card?] {
		var retval = [Card?]()
        let game = AppDelegate.instance().coreManager.game
        
        let isPlayer = game.player.id == player.id

        guard let opponent = isPlayer ? game.opponent : game.player else {
            return retval
        }

		let playerMinions = player.deadMinionsCards
			.compactMap { entity in
				CardUtils.getProcessedCardFromEntity(entity, player)
			}

		let opponentMinions = opponent.deadMinionsCards
			.compactMap { entity in
				CardUtils.getProcessedCardFromEntity(entity, opponent)
			}

		if !playerMinions.isEmpty {
            retval.append(Card(id: isPlayer ? playerHero : opponentHero))
			let highestCost = playerMinions.map { $0.cost }.max()
			let minionsWithHighestCost = playerMinions.filter { $0.cost == highestCost }
			retval.append(contentsOf: minionsWithHighestCost)
		}

		if !opponentMinions.isEmpty {
            retval.append(Card(id: isPlayer ? opponentHero : playerHero))
			let highestCost = opponentMinions.map { $0.cost }.max()
			let minionsWithHighestCost = opponentMinions.filter { $0.cost == highestCost }
			retval.append(contentsOf: minionsWithHighestCost)
		}

		return retval
	}
}
