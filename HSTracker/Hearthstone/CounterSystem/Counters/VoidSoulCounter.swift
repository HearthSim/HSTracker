//
//  VoidSoulCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/12/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class VoidSoulCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.DemonHunter.VoidSoul
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.DemonHunter.VoidSoul,
            CardIds.Collectible.DemonHunter.VoidBlast,
            CardIds.Collectible.DemonHunter.ViciousVoidscale,
            CardIds.Collectible.DemonHunter.StardustScythe
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
        self.counter = 1
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 1
    }

    override func getCardsToDisplay() -> [String] {
        return getCardsInDeckOrKnown(cardIds: relatedCards)
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard entity.info.latestCardId == CardIds.Collectible.DemonHunter.VoidSoul else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }
        guard !discountIfCantPlay(tag: tag, value: value, entity: entity) else { return }
        guard tag == .zone else { return }
        
        // C# pattern matching check: value is not (int)Zone.PLAY || gameState.CurrentBlock?.Type != "PLAY"
        guard value == Zone.play.rawValue else { return }
        guard AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type == "PLAY" else { return }

        lastEntityToCount = entity
        counter += 1
    }
}
