//
//  SpellsPlayedForNagasCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SpellsPlayedForNagasCounter: NumericCounter {
    override var isBattlegroundsCounter: Bool { true }
    override var cardIdToShowInUI: String? { CardIds.NonCollectible.Neutral.Thaumaturgist }
    override var localizedName: String { String.localizedString("Counter_PlayedSpells", comment: "") }
    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.Thaumaturgist,
            CardIds.NonCollectible.Neutral.ArcaneCannoneer,
            CardIds.NonCollectible.Neutral.ShowyCyclist,
            CardIds.NonCollectible.Neutral.Groundbreaker
        ]
    }

    lazy var relatedCardsWithTriples: [String] = (self.relatedCards + self.relatedCards.compactMap({ card in Cards.by(cardId: Cards.by(cardId: card)?.id ?? "")?.id }))

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isBattlegroundsMatch() else { return false }
        return counter > 1 &&
            game.player.board.contains { entity in
                relatedCardsWithTriples.contains(entity.cardId)
            }
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(1 + (counter / 4)) (\(counter % 4)/4)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }

        if tag == .zone,
           value == Zone.play.rawValue || (value == Zone.setaside.rawValue && prevValue == Zone.play.rawValue),
           relatedCards.contains(entity.cardId) {
            onCounterChanged()
        }

        if tag.rawValue == 3809 {
            counter = value
        }
    }
}
