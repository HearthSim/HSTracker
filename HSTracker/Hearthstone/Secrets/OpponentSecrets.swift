//
//  OpponentSecrets.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class OpponentSecrets {
    private(set) lazy var secrets = [SecretHelper]()
    var proposedAttackerEntityId: Int = 0
    var proposedDefenderEntityId: Int = 0
    private(set) var game: Game

    init(game: Game) {
        self.game = game
    }

    var displayedClasses: [CardClass] {
        return secrets.map({ $0.heroClass }).sorted {
            $0.rawValue < $1.rawValue
        }
    }

    func getIndexOffset(heroClass: CardClass) -> Int {
        switch heroClass {
        case .hunter:
            return 0

        case .mage:
            if displayedClasses.contains(.hunter) {
                return SecretHelper.getMaxSecretCount(heroClass: .hunter)
            }
            return 0

        case .paladin:
            if displayedClasses.contains(.hunter) && displayedClasses.contains(.mage) {
                return SecretHelper.getMaxSecretCount(heroClass: .hunter)
                    + SecretHelper.getMaxSecretCount(heroClass: .mage)
            }
            if displayedClasses.contains(.hunter) {
                return SecretHelper.getMaxSecretCount(heroClass: .hunter)
            }
            if displayedClasses.contains(.mage) {
                return SecretHelper.getMaxSecretCount(heroClass: .mage)
            }
            return 0

        default: break
        }
        return 0
    }

    func getHeroClass(cardId: String) -> CardClass? {
        if let card = Cards.by(cardId: cardId) {
            return card.playerClass
        }
        return nil
    }

    func trigger(cardId: String) {
        if secrets.any({ $0.tryGetSecret(cardId: cardId) }) {
            setZero(cardId: cardId)
        } else {
            setMax(cardId)
        }
    }

    func newSecretPlayed(heroClass: CardClass, id: Int, turn: Int,
                         knownCardId: String? = nil) {
        let helper = SecretHelper(heroClass: heroClass, id: id, turnPlayed: turn)
        if let knownCardId = knownCardId {
            SecretHelper.getSecretIds(heroClass: heroClass).forEach({
                helper.trySetSecret(cardId: $0, active: $0 == knownCardId)
            })
        }
        secrets.append(helper)
        Log.info?.message("Added secret with id: \(id)")
    }

    func secretRemoved(id: Int, cardId: String) {
        if let index = secrets.index(where: { $0.id == id }) {
            if index == -1 {
                Log.warning?.message("Secret with id=\(id), cardId=\(cardId)"
                    + " not found when trying to remove it.")
                return
            }
            let attacker = game.entities[proposedAttackerEntityId]
            let defender = game.entities[proposedDefenderEntityId]

            // see http://hearthstone.gamepedia.com/Advanced_rulebook#Combat
            // for fast vs. slow secrets

            // a few fast secrets can modify combat
            // freezing trap and vaporize remove the attacking minion
            // misdirection, noble sacrifice change the target

            // if multiple secrets are in play and a fast secret triggers,
            // we need to eliminate older secrets which would have
            // been triggered by the attempted combat
            if CardIds.Secrets.FastCombat.contains(cardId) && attacker != nil && defender != nil {
                zeroFromAttack(attacker: game.entities[proposedAttackerEntityId]!,
                        defender: game.entities[proposedDefenderEntityId]!,
                        fastOnly: true,
                        _stopIndex: index)
            }

            secrets.remove(secrets[index])
            Log.info?.message("Removed secret with id:\(id)")
        }
    }

    func zeroFromAttack(attacker: Entity, defender: Entity,
                        fastOnly: Bool = false, _stopIndex: Int = -1) {
        var stopIndex = _stopIndex
        if _stopIndex == -1 {
            stopIndex = secrets.count
        }

        if game.opponentMinionCount < 7 {
            setZeroOlder(cardId: CardIds.Secrets.Paladin.NobleSacrifice, stopIndex: stopIndex)
        }

        if defender.isHero {
            if !fastOnly {
                if game.opponentMinionCount < 7 {
                    setZeroOlder(cardId: CardIds.Secrets.Hunter.BearTrap, stopIndex: stopIndex)
                }
                setZeroOlder(cardId: CardIds.Secrets.Mage.IceBarrier, stopIndex: stopIndex)
            }

            setZeroOlder(cardId: CardIds.Secrets.Hunter.ExplosiveTrap, stopIndex: stopIndex)

            if game.isMinionInPlay {
                setZeroOlder(cardId: CardIds.Secrets.Hunter.Misdirection, stopIndex: stopIndex)
            }

            if attacker.isMinion {
                setZeroOlder(cardId: CardIds.Secrets.Mage.Vaporize, stopIndex: stopIndex)
                setZeroOlder(cardId: CardIds.Secrets.Hunter.FreezingTrap, stopIndex: stopIndex)
            }
        } else {
            if !fastOnly && game.opponentMinionCount < 7 {
                setZeroOlder(cardId: CardIds.Secrets.Hunter.SnakeTrap, stopIndex: stopIndex)
            }

            if attacker.isMinion {
                setZeroOlder(cardId: CardIds.Secrets.Hunter.FreezingTrap, stopIndex: stopIndex)
            }
        }

        guard let game = (NSApp.delegate as? AppDelegate)?.game,
              let windowManager = game.windowManager else {
            return
        }
        windowManager.updateTrackers()
    }

    func clearSecrets() {
        secrets.removeAll()
        Log.info?.message("Cleared secrets")
    }

    func setMax(_ cardId: String) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        secrets.forEach {
            $0.trySetSecret(cardId: cardId, active: true)
        }
    }

    func setZero(cardId: String) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        setZeroOlder(cardId: cardId, stopIndex: secrets.count)
    }

    func setZeroOlder(cardId: String, stopIndex: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        for index in 0 ..< stopIndex {
            secrets[index].trySetSecret(cardId: cardId, active: false)
        }
        if stopIndex > 0 {
            Log.info?.message("Set secret to zero: \(String(describing: Cards.by(cardId: cardId)))")
        }
    }

    func getSecrets() -> [Secret] {
        let returnThis = displayedClasses.expand({
            SecretHelper.getSecretIds(heroClass: $0).map { Secret(cardId: $0, count: 0) }
        })

        for secret in secrets {
            for (cardId, possible) in secret.possibleSecrets {
                if possible {
                    returnThis.firstWhere({ $0.cardId == cardId })?.count += 1
                }
            }
        }

        return returnThis
    }

    func allSecrets() -> [Card] {
        var cards: [Card] = []
        getSecrets().forEach({ (secret) in
                    if let card = Cards.by(cardId: secret.cardId), secret.count > 0 {
                        card.count = secret.count
                        cards.append(card)
                    }
                })
        return cards
    }

    func getDefaultSecrets(heroClass: CardClass) -> [Secret] {
        return SecretHelper.getSecretIds(heroClass: heroClass).map { Secret(cardId: $0, count: 1) }
    }
}

extension OpponentSecrets: CustomStringConvertible {
    var description: String {
        return "[OpponentSecret: "
            + "secrets=\(secrets)"
            + ", proposedAttackerEntityId=\(proposedAttackerEntityId)"
            + ", proposedDefenderEntityId=\(proposedDefenderEntityId)]"
    }
}
