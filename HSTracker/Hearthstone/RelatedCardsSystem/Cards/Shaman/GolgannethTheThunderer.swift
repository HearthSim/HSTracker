//
//  GolgannethTheThunderer.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/19/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class GolgannethTheThunderer: ICardWithHighlight {
	required init() { }

	func getCardId() -> String {
		return CardIds.Collectible.Shaman.GolgannethTheThunderer
	}

	func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
		return HighlightColorHelper.getHighlightColor(card.overload > 0)
	}
}
