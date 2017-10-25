//
//  SecretsManager.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/10/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import AwaitKit

class SecretsManager {
    let avengeDelay: Double = 50
    private var _avengeDeathRattleCount = 0
    private var _awaitingAvenge = false
    private var _lastCompetitiveSpiritCheck = 0

    private var game: Game
    private(set) var secrets: [Secret] = []

    var onChanged: (([Card]) -> Void)?

    init(game: Game) {
        self.game = game
    }

    private var freeSpaceOnBoard: Bool { return game.opponentMinionCount < 7 }
    private var freeSpaceInHand: Bool { return game.opponentHandCount < 10 }
    private var handleAction: Bool { return hasActiveSecrets }

    private var hasActiveSecrets: Bool {
        return secrets.count > 0
    }

    func exclude(cardId: String, invokeCallback: Bool = true) {
        if cardId.isBlank {
            return
        }

        secrets.forEach {
            $0.exclude(cardId: cardId)
        }

        if invokeCallback {
            onChanged?(getSecretList())
        }
    }

    func exclude(cardIds: [String]) {
        cardIds.enumerated().forEach {
            exclude(cardId: $1, invokeCallback: $0 == cardIds.count - 1)
        }
    }

    func reset() {
        _avengeDeathRattleCount = 0
        _awaitingAvenge = false
        _lastCompetitiveSpiritCheck = 0
        secrets.removeAll()
    }

    @discardableResult
    func newSecret(entity: Entity) -> Bool {
        if !entity.isSecret || !entity.has(tag: .class) {
            return false
        }

        if entity.hasCardId {
            exclude(cardId: entity.cardId)
        }
        do {
            try secrets.append(Secret(entity: entity))
            Log.info?.message("new secret : \(entity)")
            onChanged?(getSecretList())
            return true
        } catch {
            Log.error?.message("\(error)")
            return false
        }
    }

    @discardableResult
    func removeSecret(entity: Entity) -> Bool {
        guard let secret = secrets.first({ $0.entity.id == entity.id }) else {
            Log.info?.message("Secret not found \(entity)")
            return false
        }

        handleFastCombat(entity: entity)
        secrets.remove(secret)
        if secret.entity.hasCardId {
            exclude(cardId: secret.entity.cardId, invokeCallback: false)
        }
        onChanged?(getSecretList())
        return true
    }

    func toggle(cardId: String) {
        let excluded = secrets.any { $0.isExcluded(cardId: cardId) }
        if excluded {
            secrets.forEach { $0.include(cardId: cardId) }
        } else {
            exclude(cardId: cardId, invokeCallback: false)
        }
    }

    func getSecretList() -> [Card] {
        let wildSets = CardSet.wildSets()
        let gameMode = game.currentGameType
        let format = game.currentFormat

        let opponentEntities = game.opponent.revealedEntities.filter {
            $0.id < 68 && $0.isSecret && $0.hasCardId
        }
        let gameModeHasCardLimit = [GameType.gt_casual, GameType.gt_ranked, GameType.gt_vs_friend, GameType.gt_vs_ai].contains(gameMode)

        let createdSecrets = secrets
            .filter { $0.entity.info.created }
            .flatMap { $0.excluded }
            .filter { !$0.value }
            .map { $0.key }
            .unique()
        let hasPlayedTwoOf: ((_ cardId: String) -> Bool) = { cardId in
            opponentEntities.filter { $0.cardId == cardId && !$0.info.created }.count >= 2
        }
        let adjustCount: ((_ cardId: String, _ count: Int) -> Int) = { cardId, count in
            gameModeHasCardLimit && hasPlayedTwoOf(cardId) && !createdSecrets.contains(cardId) ? 0 : count
        }

        var cards: [Card] = secrets.flatMap { $0.excluded }
            .group { $0.key }
            .flatMap {
                let card = Cards.by(cardId: $0.key)
                card?.count = adjustCount($0.key, $0.value.filter({ !$0.value }).count)
                return card
        }

        if format == .standard || gameMode == .gt_arena {
            cards = cards.filter { !wildSets.contains($0.set ?? .invalid) }
        }
        if gameMode == .gt_arena {
            cards = cards.filter { !CardIds.Secrets.arenaExcludes.contains($0.id) }
        }

        return cards
    }

    func handleAttack(attacker: Entity, defender: Entity, fastOnly: Bool = false) {
        guard handleAction else { return }

        if attacker[.controller] == defender[.controller] {
            return
        }

        var exclude: [String] = []

        if freeSpaceOnBoard {
            exclude.append(CardIds.Secrets.Paladin.NobleSacrifice)
        }

        if defender.isHero {
            if !fastOnly {
                if freeSpaceOnBoard {
                    exclude.append(CardIds.Secrets.Hunter.BearTrap)
                }
                exclude.append(CardIds.Secrets.Mage.IceBarrier)
            }

            exclude.append(CardIds.Secrets.Hunter.ExplosiveTrap)

            if game.isMinionInPlay {
                exclude.append(CardIds.Secrets.Hunter.Misdirection)
            }

            if attacker.isMinion {
                exclude.append(CardIds.Secrets.Mage.Vaporize)
                exclude.append(CardIds.Secrets.Hunter.FreezingTrap)
            }
        } else {
            if !fastOnly && freeSpaceOnBoard {
                exclude.append(CardIds.Secrets.Hunter.SnakeTrap)
                exclude.append(CardIds.Secrets.Hunter.VenomstrikeTrap)
            }

            if attacker.isMinion {
                exclude.append(CardIds.Secrets.Hunter.FreezingTrap)
            }
        }
        self.exclude(cardIds: exclude)
    }

    func handleFastCombat(entity: Entity) {
        guard handleAction else { return }

        if !entity.hasCardId || game.proposedAttacker == 0 || game.proposedDefender == 0 {
            return
        }
        if !CardIds.Secrets.fastCombat.contains(entity.cardId) {
            return
        }
        if let attacker = game.entities[game.proposedAttacker],
            let defender = game.entities[game.proposedDefender] {
            handleAttack(attacker: attacker, defender: defender, fastOnly: true)
        }
    }

    func handleMinionPlayed() {
        guard handleAction else { return }

        var exclude: [String] = []

        //Hidden cache will only trigger if the opponent has a minion in hand.
        //We might not know this for certain - requires additional tracking logic.
        //TODO: _game.SecretsManager.SetZero(Hunter.HiddenCache);
        exclude.append(CardIds.Secrets.Hunter.Snipe)
        exclude.append(CardIds.Secrets.Mage.PotionOfPolymorph)
        exclude.append(CardIds.Secrets.Paladin.Repentance)

        if freeSpaceOnBoard {
            exclude.append(CardIds.Secrets.Mage.MirrorEntity)
        }

        if freeSpaceInHand {
            exclude.append(CardIds.Secrets.Mage.FrozenClone)
        }

        self.exclude(cardIds: exclude)
    }

    func handleMinionDeath(entity: Entity) {
        guard handleAction else { return }

        var exclude: [String] = []
        if freeSpaceInHand {
            exclude.append(CardIds.Secrets.Mage.Duplicate)
            exclude.append(CardIds.Secrets.Paladin.GetawayKodo)
        }

        var numDeathrattleMinions = 0
        if entity.isActiveDeathrattle {
            if let count = CardIds.DeathrattleSummonCardIds[entity.cardId] {
                numDeathrattleMinions = count
            } else if entity.cardId == CardIds.Collectible.Neutral.Stalagg
                && game.opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Feugen })
                || entity.cardId == CardIds.Collectible.Neutral.Feugen
                && game.opponent.graveyard.any({ $0.cardId == CardIds.Collectible.Neutral.Stalagg }) {
                numDeathrattleMinions = 1
            }

            if game.entities.map({ $0.value }).any({ $0.cardId == CardIds.NonCollectible.Druid.SouloftheForest_SoulOfTheForestEnchantment
                && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
            if game.entities.map({ $0.value }).any({ $0.cardId == CardIds.NonCollectible.Shaman.AncestralSpirit_AncestralSpiritEnchantment
                && $0[.attached] == entity.id }) {
                numDeathrattleMinions += 1
            }
        }

        if let opponentEntity = game.opponentEntity,
            opponentEntity.has(tag: .extra_deathrattles) {
            numDeathrattleMinions *= opponentEntity[.extra_deathrattles] + 1
        }

        handleAvengeAsync(deathRattleCount: numDeathrattleMinions)

        // redemption never triggers if a deathrattle effect fills up the board
        // effigy can trigger ahead of the deathrattle effect, but only if effigy was played before the deathrattle minion
        if game.opponentMinionCount < 7 - numDeathrattleMinions {
    exclude.append(CardIds.Secrets.Paladin.Redemption)
        }

        // TODO: break ties when Effigy + Deathrattle played on the same turn
        exclude.append(CardIds.Secrets.Mage.Effigy)

        self.exclude(cardIds: exclude)
    }

    func handleAvengeAsync(deathRattleCount: Int) {
        guard handleAction else { return }

        _avengeDeathRattleCount += deathRattleCount
        if _awaitingAvenge {
            return
        }
        _awaitingAvenge = true
        if game.opponentMinionCount != 0 {
            do {
                try await {
                    Thread.sleep(forTimeInterval: self.avengeDelay)
                }
                if game.opponentMinionCount - _avengeDeathRattleCount > 0 {
                    exclude(cardId: CardIds.Secrets.Paladin.Avenge)
                }
            } catch {
                Log.error?.message("\(error)")
            }
        }
        _awaitingAvenge = false;
        _avengeDeathRattleCount = 0;
    }

    func handleOpponentDamage(entity: Entity) {
        guard handleAction else { return }

        if entity.isHero && entity.isControlled(by: game.opponent.id) {
            exclude(cardId: CardIds.Secrets.Paladin.EyeForAnEye)
        }
    }

    func handleTurnsInPlayChange(entity: Entity, turn: Int) {
        guard handleAction else { return }

        if turn <= _lastCompetitiveSpiritCheck || !entity.isMinion
            || !entity.isControlled(by: game.opponent.id)
            || !(game.opponentEntity?.isCurrentPlayer ?? false) {
            return
        }
        _lastCompetitiveSpiritCheck = turn
        exclude(cardId: CardIds.Secrets.Paladin.CompetitiveSpirit)
    }

    func handleCardPlayed(entity: Entity) {
        guard handleAction else { return }

        var exclude: [String] = []
        if entity.isSpell {
            exclude.append(CardIds.Secrets.Mage.Counterspell)

            if game.opponentHandCount < 10 {
                exclude.append(CardIds.Secrets.Mage.ManaBind)
            }

            if game.opponentMinionCount < 7 {
                // CARD_TARGET is set after ZONE, wait for 50ms gametime before checking
                do {
                    try await {
                        Thread.sleep(forTimeInterval: 0.2)
                    }
                    if let target = game.entities[entity[.card_target]],
                        entity.has(tag: .card_target),
                        target.isMinion {
                        exclude.append(CardIds.Secrets.Mage.Spellbender)
                    }
                    exclude.append(CardIds.Secrets.Hunter.CatTrick)
                } catch {
                    Log.error?.message("\(error)")
                }
            }
        } else if entity.isMinion && game.playerMinionCount > 3 {
            exclude.append(CardIds.Secrets.Paladin.SacredTrial)
        }
        self.exclude(cardIds: exclude)
    }

    func handleHeroPower() {
        guard handleAction else { return }
        exclude(cardId: CardIds.Secrets.Hunter.DartTrap)
    }
}
