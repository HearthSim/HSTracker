//
//  AxeOfCenarius.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class AxeOfCenarius: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.NonCollectible.DemonHunter.Broxigar_AxeOfCenariusToken
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(portals.contains(card.id))
    }

    private let portals: Set<String> = [
        CardIds.NonCollectible.DemonHunter.Broxigar_FirstPortalToArgusToken,
        CardIds.NonCollectible.DemonHunter.Broxigar_SecondPortalToArgusToken,
        CardIds.NonCollectible.DemonHunter.Broxigar_ThirdPortalToArgusToken,
        CardIds.NonCollectible.DemonHunter.Broxigar_FinalPortalToArgusToken
    ]

    required init() {}
}
