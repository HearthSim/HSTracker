//
//  AmitusThePeacekeeper.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class AmitusThePeacekeeper: ICardWithHighlight {
	required init() { }

	func getCardId() -> String {
		return CardIds.Collectible.Paladin.AmitusThePeacekeeper
	}

	func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion  )
	}
}
