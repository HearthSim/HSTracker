//
//  HeraldCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class HeraldCounter: NumericCounter {

    override var localizedName: String {
        return String.localizedString("Counter_Herald", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Invalid.EnvoyOfTheEnd
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Deathknight.ObsessiveTechnician,
            CardIds.Collectible.Deathknight.ExperimentalAnimation,
            CardIds.Collectible.Deathknight.ArisenOnyxia,

            CardIds.Collectible.DemonHunter.FelInfusion,
            CardIds.Collectible.DemonHunter.ArmoredBloodletter,
            CardIds.Collectible.DemonHunter.AzsharaOceanLord,

            CardIds.Collectible.Rogue.RiteOfTwilight,
            CardIds.Collectible.Rogue.ManiacalFollower,
            CardIds.Collectible.Rogue.Sinestra,

            CardIds.Collectible.Shaman.SkywallSentinel,
            CardIds.Collectible.Shaman.RitualOfPower,
            CardIds.Collectible.Shaman.AlakirLordOfStorms,

            CardIds.Collectible.Warlock.ShadowswornDisciple,
            CardIds.Collectible.Warlock.ShrineOfTwilight,
            CardIds.Collectible.Warlock.ChogallMastermind,

            CardIds.Collectible.Warrior.CataclysmicWarAxe,
            CardIds.Collectible.Warrior.ScorchingRavager,
            CardIds.Collectible.Warrior.RagnarosTheGreatFire,

            CardIds.Collectible.Invalid.EnvoyOfTheEnd,
            CardIds.Collectible.Invalid.Ultraxion,
            CardIds.Collectible.Invalid.DeathwingWorldbreakerHeroic
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if tag != .herald_colossal_amount {
            return
        }

        if value == 0 {
            return
        }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter = value
        }
    }
}
