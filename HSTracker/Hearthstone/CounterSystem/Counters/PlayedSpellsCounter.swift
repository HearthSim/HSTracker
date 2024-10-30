//
//  PlayedSpellsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PlayedSpellsCounter: NumericCounter {

    override var localizedName: String {
        return String.localizedString("Counter_PlayedSpells", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.YoggSaronHopesEnd
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.YoggSaronHopesEnd,
            CardIds.Collectible.Neutral.ArcaneGiant,
            CardIds.Collectible.Priest.GraveHorror,
            CardIds.Collectible.Druid.UmbralOwlDARKMOON_FAIRE,
            CardIds.Collectible.Druid.UmbralOwlPLACEHOLDER_202204,
            CardIds.Collectible.Neutral.YoggSaronMasterOfFate,
            CardIds.Collectible.DemonHunter.SaroniteShambler,
            CardIds.Collectible.Druid.ContaminatedLasher,
            CardIds.Collectible.Mage.MeddlesomeServant,
            CardIds.Collectible.Neutral.PrisonBreaker
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }

        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        } else {
            return counter > 7 && opponentMayHaveRelevantCards(ignoreNeutral: true)
        }
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.playerClass)
        }
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard tag == .zone else { return }
        guard value == Zone.play.rawValue || value == Zone.secret.rawValue else { return }
        guard AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" else { return }
        guard entity.isSpell else { return }

        let controller = entity[GameTag.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter += 1
        }
    }
}
