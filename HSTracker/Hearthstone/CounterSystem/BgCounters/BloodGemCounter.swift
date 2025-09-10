//
//  BloodGemCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BloodGemCounter: StatsCounter {
    override var isBattlegroundsCounter: Bool {
        return true
    }

    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.BloodGem1
    }

    override var relatedCards: [String] {
        return []
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isBattlegroundsMatch() else { return false }
        
        let boardHasQuilboar = game.player.board.contains(where: { e in e.card.isQuillboar() && !e.card.isAllRace() })
        let handHasQuilboar = game.player.hand.contains(where: { $0.card.isQuillboar() && !$0.card.isAllRace() })
        
        return attackCounter > 3 || healthCounter > 3 || boardHasQuilboar || handHasQuilboar
    }

    override func getCardsToDisplay() -> [String] {
        return [CardIds.NonCollectible.Neutral.BloodGem1]
    }

    override func valueToShow() -> String {
        return "+\(max(1, attackCounter)) / +\(max(1, healthCounter))"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isBattlegroundsMatch() else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }
        
        if tag == .bacon_bloodgembuffatkvalue {
            attackCounter = value + 1
            onCounterChanged()
        }

        if tag == .bacon_bloodgembuffhealthvalue {
            healthCounter = value + 1
            onCounterChanged()
        }
     
        if game.isBattlegroundsCombatPhase {
            return
        }
        
        if !entity.isMinion {
            return
        }
        
        if tag != .zone {
            return
        }
        
        if prevValue != Zone.play.rawValue && prevValue != Zone.hand.rawValue {
            return
        }
        
        onCounterChanged()
    }
}
