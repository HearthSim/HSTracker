//
//  ValstannStaghelm.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class ValstannStaghelm: ICardWithHighlight {
	required init() { }

	func getCardId() -> String {
		return CardIds.Collectible.Neutral.ValstannStaghelm
	}

	func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
		return HighlightColorHelper.getHighlightColor(card.hasTaunt())
	}
}
