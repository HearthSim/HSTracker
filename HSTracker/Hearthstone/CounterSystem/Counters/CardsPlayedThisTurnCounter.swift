//
//  CardsPlayedThisTurnCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardsPlayedThisTurnCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_CardsPlayedThisTurn", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Rogue.EdwinVancleef
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Rogue.EdwinVancleef,
            CardIds.Collectible.Rogue.EdwinVancleefVanilla,
            CardIds.Collectible.Rogue.PrizePlunderer,
            CardIds.Collectible.Rogue.SinstoneGraveyard,
            CardIds.Collectible.Rogue.SinstoneGraveyardCorePlaceholder,
            CardIds.Collectible.Rogue.ShadowSculptor,
            CardIds.Collectible.Rogue.EverburningPhoenix,
            CardIds.Collectible.Rogue.Biteweed,
            CardIds.Collectible.Rogue.NecrolordDraka,
            CardIds.Collectible.Rogue.NecrolordDrakaCorePlaceholder,
            CardIds.Collectible.Rogue.SpectralPillager,
            CardIds.Collectible.Rogue.SpectralPillagerCorePlaceholder,
            CardIds.Collectible.Rogue.ScribblingStenographer,
            CardIds.Collectible.Rogue.ScribblingStenographerCorePlaceholder,
            CardIds.Collectible.Neutral.FrostwolfWarmaster
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        return isPlayerCounter && inPlayerDeckOrKnown(cardIds: relatedCards)
    }

    override func getCardsToDisplay() -> [String] {
        return getCardsInDeckOrKnown(cardIds: relatedCards)
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }
        
        if discountIfCantPlay(tag: tag, value: value, entity: entity) {
            return
        }

        if tag == .num_turns_in_play {
            counter = 0
            return
        }

        if tag != .zone {
            return
        }

        if prevValue != Zone.hand.rawValue {
            return
        }

        if value == Zone.play.rawValue || value == Zone.secret.rawValue,
           AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" {
            lastEntityToCount = entity
            counter += 1
        }
    }
}
