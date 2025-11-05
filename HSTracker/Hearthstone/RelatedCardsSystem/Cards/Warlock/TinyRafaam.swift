//
//  TinyRafaam.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class TinyRafaam: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.NonCollectible.Warlock.TimethiefRafaam_TinyRafaamToken
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(TinyRafaam._rafaams.contains(card.id))
    }

    private static let _rafaams: [String] = [
        CardIds.NonCollectible.Warlock.TimethiefRafaam_TinyRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_GreenRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_MurlocRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_ExplorerRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_WarchiefRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_CalamitousRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_MindflayerRfaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_GiantRafaamToken,
        CardIds.NonCollectible.Warlock.TimethiefRafaam_ArchmageRafaamToken
    ]

    required init() {}
}
