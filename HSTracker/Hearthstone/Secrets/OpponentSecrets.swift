//
//  OpponentSecrets.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 9/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class OpponentSecrets : CustomStringConvertible {
    private(set) lazy var secrets = [SecretHelper]()
    var proposedAttackerEntityId: Int = 0
    var proposedDefenderEntityId: Int = 0
    private(set) var game: Game

    init(game: Game) {
        self.game = game
    }

    var displayedClasses: [HeroClass] {
        return secrets.map({ $0.heroClass }).sort { $0.rawValue < $1.rawValue }
    }

    func getIndexOffset(heroClass: HeroClass) -> Int {
        switch heroClass {
        case .Hunter:
            return 0

        case .Mage:
            if displayedClasses.contains(.Hunter) {
                return SecretHelper.getMaxSecretCount(.Hunter)
            }
            return 0

        case .Paladin:
            if displayedClasses.contains(.Hunter) && displayedClasses.contains(.Mage) {
                return SecretHelper.getMaxSecretCount(.Hunter) + SecretHelper.getMaxSecretCount(.Mage)
            }
            if displayedClasses.contains(.Hunter) {
                return SecretHelper.getMaxSecretCount(.Hunter)
            }
            if displayedClasses.contains(.Mage) {
                return SecretHelper.getMaxSecretCount(.Mage)
            }
            return 0

        default: break
        }
        return 0
    }

    func getHeroClass(cardId: String) -> HeroClass? {
        if let card = Cards.byId(cardId) {
            return HeroClass(rawValue: card.playerClass)
        }
        return nil
    }

    func trigger(cardId: String) {
        if secrets.any({ $0.possibleSecrets[cardId] != nil ? $0.possibleSecrets[cardId]! : false }) {
            setZero(cardId)
        }
        else {
            setMax(cardId)
        }
    }

    func newSecretPlayed(heroClass: HeroClass, _ id: Int, _ turn: Int, _ knownCardId: String? = nil) {
        let helper = SecretHelper(heroClass: heroClass, id: id, turnPlayed: turn)
        if let knownCardId = knownCardId {
            SecretHelper.getSecretIds(heroClass).forEach({
                helper.possibleSecrets[$0] = $0 == knownCardId
            })
        }
        secrets.append(helper)
        Log.info?.message("Added secret with id: \(id)")
    }

    func secretRemoved(id: Int, _ cardId: String) {
        if let index = secrets.indexOf({ $0.id == id }) {
            if index == -1 {
                Log.warning?.message("Secret with id=\(id), cardId=\(cardId) not found when trying to remove it.")
                return
            }
            let attacker = game.entities[proposedAttackerEntityId]
            let defender = game.entities[proposedDefenderEntityId]

            // see http://hearthstone.gamepedia.com/Advanced_rulebook#Combat for fast vs. slow secrets

            // a few fast secrets can modify combat
            // freezing trap and vaporize remove the attacking minion
            // misdirection, noble sacrifice change the target

            // if multiple secrets are in play and a fast secret triggers,
            // we need to eliminate older secrets which would have been triggered by the attempted combat
            if CardIds.Secrets.FastCombat.contains(cardId) && attacker != nil && defender != nil {
                zeroFromAttack(game.entities[proposedAttackerEntityId]!, game.entities[proposedDefenderEntityId]!, true, index)
            }

            secrets.remove(secrets[index])
            Log.info?.message("Removed secret with id:\(id)")
        }
    }

    func zeroFromAttack(attacker: Entity, _ defender: Entity, _ fastOnly: Bool = false, _ _stopIndex: Int = -1) {
        if !Settings.instance.autoGrayoutSecrets {
            return
        }

        var stopIndex = _stopIndex
        if _stopIndex == -1 {
            stopIndex = secrets.count
        }

        if game.opponentMinionCount < 7 {
            setZeroOlder(CardIds.Secrets.Paladin.NobleSacrifice, stopIndex)
        }

        if defender.isHero {
            if !fastOnly {
                setZeroOlder(CardIds.Secrets.Hunter.BearTrap, stopIndex)
                setZeroOlder(CardIds.Secrets.Mage.IceBarrier, stopIndex)
            }

            setZeroOlder(CardIds.Secrets.Hunter.ExplosiveTrap, stopIndex)

            if game.isMinionInPlay {
                setZeroOlder(CardIds.Secrets.Hunter.Misdirection, stopIndex)
            }

            if attacker.isMinion {
                setZeroOlder(CardIds.Secrets.Mage.Vaporize, stopIndex)
                setZeroOlder(CardIds.Secrets.Hunter.FreezingTrap, stopIndex)
            }
        }
        else
        {
            if !fastOnly && game.opponentMinionCount < 7 {
                setZeroOlder(CardIds.Secrets.Hunter.SnakeTrap, stopIndex)
            }

            if attacker.isMinion {
                setZeroOlder(CardIds.Secrets.Hunter.FreezingTrap, stopIndex)
            }
        }

        Game.instance.showSecrets(true)
    }

    func clearSecrets() {
        secrets.removeAll()
        Log.info?.message("Cleared secrets")
    }

    func setMax(cardId: String) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        for secret in secrets {
            secret.possibleSecrets[cardId] = true
        }
    }

    func setZero(cardId: String) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        setZeroOlder(cardId, secrets.count)
    }

    func setZeroOlder(cardId: String, _ stopIndex: Int) {
        if String.isNullOrEmpty(cardId) {
            return
        }
        for index in 0 ..< stopIndex {
            secrets[index].possibleSecrets[cardId] = false
        }
        if stopIndex > 0 {
            Log.info?.message("Set secret to zero: \(Cards.byId(cardId))")
        }
    }

    func getSecrets() -> [Secret] {
        let returnThis = displayedClasses.expand({
            SecretHelper.getSecretIds($0).map { Secret(cardId: $0, count: 0) }
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

    func getDefaultSecrets(heroClass: HeroClass) -> [Secret] {
        return SecretHelper.getSecretIds(heroClass).map { Secret(cardId: $0, count: 1) }
    }

    var description: String {
        return "<\(NSStringFromClass(self.dynamicType)): "
            + "secrets=\(secrets)"
            + ", proposedAttackerEntityId=\(proposedAttackerEntityId)"
            + ", proposedDefenderEntityId=\(proposedDefenderEntityId)>"
    }
}