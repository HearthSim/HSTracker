//
//  IceFishing.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class IceFishing: ICardWithHighlight {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Shaman.IceFishing
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isMurloc())
    }
}

class IceFishingCorePlaceholder: IceFishing {

    override func getCardId() -> String {
        return CardIds.Collectible.Shaman.IceFishingCorePlaceholder
    }
}
