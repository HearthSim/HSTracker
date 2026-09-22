//
//  DeitySizeCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

class DeitySizeCounter: StatsCounter {
    private static let minStatsToShow = 25
    private static let minAberrationsToShow = 3

    override var isBattlegroundsCounter: Bool { true }

    override var localizedName: String { String.localizedString("Counter_Deity", comment: "") }

    // Until the sigil tells us which Deity it holds, fall back to generic Aberration art.
    override var cardIdToShowInUI: String? {
        deityCardId ?? CardIds.NonCollectible.Neutral.ATaleofKings_KingOfAberrationsTavernBrawl
    }

    override var relatedCards: [String] {
        return [
            CardIds.NonCollectible.Neutral.Joyous,
            CardIds.NonCollectible.Neutral.DriftingSacrifice,
            CardIds.NonCollectible.Neutral.ViciousMindslasher,
            CardIds.NonCollectible.Neutral.BrainRotter,
            CardIds.NonCollectible.Neutral.CutthroatKthir,
            CardIds.NonCollectible.Neutral.FacelessConverter,
            CardIds.NonCollectible.Neutral.TheShadowOfDoubt,
            CardIds.NonCollectible.Neutral.HarbingerAphlass,
            CardIds.NonCollectible.Neutral.ShaOfFear,
            CardIds.NonCollectible.Neutral.EnergizingChamber
        ]
    }

    private var deityCardId: String?

    override func shouldShow() -> Bool {
        return game.isBattlegroundsMatch()
            && (attackCounter >= DeitySizeCounter.minStatsToShow || healthCounter >= DeitySizeCounter.minStatsToShow
                || (hasValue && aberrationsOnBoard() >= DeitySizeCounter.minAberrationsToShow))
    }

    private func aberrationsOnBoard() -> Int {
        let board = isPlayerCounter ? game.player.board : game.opponent.board
        return board.filter(DeitySizeCounter.isAberration).count
    }

    // The static race misses a minion turned into an Aberration by an enchantment (Faceless
    // Converter), which only the live CARDRACE tag carries.
    private static func isAberration(_ entity: Entity) -> Bool {
        if !entity.isMinion {
            return false
        }
        let liveRace = Race.allCases[safeIndex: entity[.cardrace]] ?? .invalid
        return entity.card.isAberration() || liveRace == .aberration || liveRace == .all
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
        guard entity.cardId == CardIds.NonCollectible.Neutral.SecretDeityDnt else { return }

        // The stats are the Deity's current total, not a bonus on top of the printed ones.
        if tag == .bacon_evolution_card_overwrite_atk {
            attackCounter = value
        }

        if tag == .bacon_evolution_card_overwrite_health {
            healthCounter = value
        }

        if tag == .bacon_evolution_card_id {
            deityCardId = Cards.by(dbfId: value, collectible: false)?.id
            onPropertyChanged("cardToShowInUi")
            onPropertyChanged("cardAsset")
        }
    }
}
