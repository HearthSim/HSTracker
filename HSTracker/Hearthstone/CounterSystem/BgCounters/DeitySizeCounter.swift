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

    // The sigil only appears a minute into the game, so until then we go by the lobby's Old God,
    // and by generic Aberration art before the game entity even has that.
    override var cardIdToShowInUI: String? {
        deityCardId ?? game.battlegroundsGlobalOldGod?.id
            ?? CardIds.NonCollectible.Neutral.ATaleofKings_KingOfAberrationsTavernBrawl
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

        // The game entity has no controller, so this has to come before the controller check.
        if tag == .bacon_global_old_god_dbid {
            notifyDeityChanged()
            return
        }

        if tag == .bacon_old_god_attack || tag == .bacon_old_god_health {
            handleDeitySize(tag: tag, entity: entity, value: value)
            return
        }

        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }
        guard entity.cardId == CardIds.NonCollectible.Neutral.SecretDeityDnt else { return }

        if tag == .bacon_evolution_card_id {
            deityCardId = Cards.by(dbfId: value, collectible: false)?.id
            notifyDeityChanged()
        }
    }

    // The size lives on the player entity rather than the sigil, and is the Deity's current total
    // rather than a bonus on top of the printed stats.
    private func handleDeitySize(tag: GameTag, entity: Entity, value: Int) {
        guard entity.id == (isPlayerCounter ? game.playerEntity : game.opponentEntity)?.id else { return }

        // The opponent entity only carries a size while we are facing them and drops back to 0 once
        // their board is hidden again, so keep the last one we saw.
        if value == 0 && !isPlayerCounter {
            return
        }

        if tag == .bacon_old_god_attack {
            attackCounter = value
        } else {
            healthCounter = value
        }
    }

    private func notifyDeityChanged() {
        onPropertyChanged("cardToShowInUi")
        onPropertyChanged("cardAsset")
    }
}
