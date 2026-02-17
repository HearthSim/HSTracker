//
//  FreeRefreshCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class FreeRefreshCounter: NumericCounter {
    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.RefreshingAnomaly
    }

    override var localizedName: String {
        return String.localizedString("Counter_FreeRefresh", comment: "")
    }

    override var relatedCards: [String] {
        return []
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch() && counter > 0
    }

    override func getCardsToDisplay() -> [String] {
        return [
            CardIds.NonCollectible.Neutral.RefreshingAnomaly,
            CardIds.NonCollectible.Neutral.GhostlyYmirjar,
            CardIds.NonCollectible.Neutral.LeafThroughThePages
        ]
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }
        
        if entity[.zone] == Zone.setaside.rawValue {
            return
        }

        if tag == .bacon_free_refresh_count {
            counter = value
            onCounterChanged()
        }
    }
}
