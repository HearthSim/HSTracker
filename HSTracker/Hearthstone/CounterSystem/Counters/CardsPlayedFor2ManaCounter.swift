//
//  CardsPlayedFor2ManaCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/12/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class CardsPlayedFor2ManaCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Rogue.JadeGuardians
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Rogue.JadeGuardians]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 2 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return getCardsInDeckOrKnown(cardIds: relatedCards)
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    private var cardTypes: [CardType] {
        return [.spell, .location, .minion, .weapon]
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard entity.isControlled(by: game.player.id) == isPlayerCounter else { return }
        guard !discountIfCantPlay(tag: tag, value: value, entity: entity) else { return }
        guard tag == .num_resources_spent_this_game else { return }
        guard let currentBlock = AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock, currentBlock.type == "PLAY" else { return }
        guard value - prevValue == 2 else { return }

        let playedCard = Card(id: currentBlock.cardId ?? "")

        // Cleaned up the type constraint check using Swift's array containment rule
        guard cardTypes.contains(playedCard.type) else { return }

        lastEntityToCount = entity
        counter += 1
    }
}
