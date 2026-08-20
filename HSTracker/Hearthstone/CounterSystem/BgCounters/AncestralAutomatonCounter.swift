//
//  AncestralAutomatonCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

class AncestralAutomatonCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool { true }
    override var cardIdToShowInUI: String? { CardIds.NonCollectible.Neutral.AncestralAutomaton }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.AncestralAutomaton,
            CardIds.NonCollectible.Neutral.AutoAssembler,
            CardIds.NonCollectible.Neutral.AutomatonPortrait,
        ]
    }

    // the magnetized Auto Assembler only shows up as its enchantment on the host minion
    private static let sources: [String] = [
        CardIds.NonCollectible.Neutral.AutomatonPortrait,
        CardIds.NonCollectible.Neutral.AutoAssembler,
        CardIds.NonCollectible.Neutral.AutoAssembler_AutoAssembler1,
        CardIds.NonCollectible.Neutral.AutoAssembler_AutoAssemblerEnchantment,
        CardIds.NonCollectible.Neutral.AutoAssembler_AutoAssembler2,
    ]

    // unlike Eternal Legion, the Ancestral Technology enchantment carries no script data, so the
    // per-automaton buff is only in the card text
    private static let attackPerAutomaton = 3
    private static let healthPerAutomaton = 2

    private let automatonBaseAttack: Int
    private let automatonBaseHealth: Int

    required init(controlledByPlayer: Bool, game: Game) {
        let card = Cards.by(cardId: CardIds.NonCollectible.Neutral.AncestralAutomaton)
        automatonBaseAttack = card?.attack ?? 3
        automatonBaseHealth = card?.health ?? 4
        super.init(controlledByPlayer: controlledByPlayer, game: game)
        attackCounter = automatonBaseAttack
        healthCounter = automatonBaseHealth
    }

    override func shouldShow() -> Bool {
        guard game.isBattlegroundsMatch() else { return false }
        return (attackCounter > automatonBaseAttack || healthCounter > automatonBaseHealth)
            && game.player.board.contains { AncestralAutomatonCounter.sources.contains($0.cardId) }
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
           AncestralAutomatonCounter.sources.contains(entity.cardId) {
            onCounterChanged()
        }

        guard entity.card.id == CardIds.Invalid.AncestralAutomaton_AncestralAutomatonPlayerEnchantDnt else { return }

        if tag == .tag_script_data_num_1 {
            // the next automaton counts every one summoned so far as another one
            attackCounter = automatonBaseAttack + value * AncestralAutomatonCounter.attackPerAutomaton
            healthCounter = automatonBaseHealth + value * AncestralAutomatonCounter.healthPerAutomaton
        }
    }
}
