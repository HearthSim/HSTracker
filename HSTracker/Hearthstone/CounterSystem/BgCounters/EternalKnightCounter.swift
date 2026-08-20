//
//  EternalKnightCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

class EternalKnightCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool { true }
    override var cardIdToShowInUI: String? { CardIds.NonCollectible.Neutral.EternalKnight }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.EternalKnight,
            CardIds.NonCollectible.Neutral.EternalSummoner,
        ]
    }

    private static let sources: [String] = [
        CardIds.NonCollectible.Neutral.EternalSummoner,
        CardIds.NonCollectible.Neutral.EternalSummoner_EternalSummoner,
    ]

    private let knightBaseAttack: Int
    private let knightBaseHealth: Int
    private let attackPerDeath: Int
    private let healthPerDeath: Int

    required init(controlledByPlayer: Bool, game: Game) {
        let knightCard = Cards.by(cardId: CardIds.NonCollectible.Neutral.EternalKnight)
        knightBaseAttack = knightCard?.attack ?? 4
        knightBaseHealth = knightCard?.health ?? 2
        attackPerDeath = 1
        healthPerDeath = 1
        super.init(controlledByPlayer: controlledByPlayer, game: game)
        attackCounter = knightBaseAttack
        healthCounter = knightBaseHealth
    }

    override func shouldShow() -> Bool {
        guard game.isBattlegroundsMatch() else { return false }
        return (attackCounter > knightBaseAttack || healthCounter > knightBaseHealth)
            && game.player.board.contains { EternalKnightCounter.sources.contains($0.cardId) }
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(attackCounter) / \(healthCounter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }

        if tag == .zone,
           value == Zone.play.rawValue || (value == Zone.setaside.rawValue && prevValue == Zone.play.rawValue),
           EternalKnightCounter.sources.contains(entity.cardId) {
            onCounterChanged()
        }

        guard entity.card.id == CardIds.NonCollectible.Neutral.EternalKnight_EternalKnightPlayerEnchant else { return }

        if tag == .tag_script_data_num_1 {
            attackCounter = knightBaseAttack + value * attackPerDeath
            healthCounter = knightBaseHealth + value * healthPerDeath
        }
    }
}
