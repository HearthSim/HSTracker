//
//  BattlegroundsDeityState.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Tracks the last known Deity of every hero. A Deity has no entity of its own until it
/// awakens, so until then it only exists as tags on its sigil: the card it is going to be,
/// plus the stats it has accumulated. An opponent's sigil is only readable while we are
/// fighting them.
class BattlegroundsDeityState {
    private var lastKnownDeity = SynchronizedDictionary<Int, DeitySnapshot>()
    private let game: Game

    init(game: Game) {
        self.game = game
    }

    func snapshotCurrentDeity() {
        guard let opponentHero = game.entities.values.first(where: { x in
            x.isHero && x.isInZone(zone: .play) && x.isControlled(by: game.opponent.id)
        }), !opponentHero.cardId.isEmpty else {
            return
        }
        let playerId = opponentHero[.player_id]
        if playerId == 0 {
            return
        }

        // The sigil is copied into the combat and dropped again right after, so take the
        // newest one.
        guard let sigil = game.entities.values.filter({ x in
            x.cardId == CardIds.NonCollectible.Neutral.SecretDeityDnt && x.isControlled(by: game.opponent.id)
        }).sorted(by: { $0.id > $1.id }).first else {
            return
        }

        guard let card = Cards.by(dbfId: sigil[.bacon_evolution_card_id], collectible: false) else {
            return
        }

        // The stats are the Deity's current total, not a bonus on top of the printed ones.
        let attack = sigil[.bacon_evolution_card_overwrite_atk]
        let health = sigil[.bacon_evolution_card_overwrite_health]

        // The sigil itself stays non-golden: Mask of Ancient Ones only turns the Deity
        // golden as it awakens, so the trinket is the one thing that tells us ahead of
        // time.
        let isGolden = game.opponent.trinkets.any { x in
            x.cardId == CardIds.NonCollectible.Neutral.MaskOfAncientOnes
        }

        logger.info("Snapshotting \(card.name) (\(attack)/\(health)\(isGolden ? ", golden" : "")) as the Deity of \(opponentHero.card.name) with player id \(playerId)")
        lastKnownDeity[playerId] = DeitySnapshot(card: card, attack: attack, health: health,
                                                 isGolden: isGolden, turn: game.turnNumber())
    }

    func getSnapshot(entityId: Int) -> DeitySnapshot? {
        guard let entity = game.entities[entityId] else {
            return nil
        }
        return lastKnownDeity[entity[.player_id]]
    }

    func reset() {
        lastKnownDeity.removeAll()
    }
}
