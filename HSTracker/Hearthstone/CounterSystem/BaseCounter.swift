//
//  BaseCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BaseCounter: NSObject {
    let game: Game
    let isPlayerCounter: Bool

    // Abstract properties
    var localizedName: String {
        return Cards.by(cardId: cardIdToShowInUI)?.name ?? ""
    }
    var cardIdToShowInUI: String? {
        return nil
    }
    
    var cardToShowInUi: Card? {
        return Cards.by(cardId: cardIdToShowInUI)
    }

    var cardAsset: NSImage? {
        return nil
    }

    var counterValue: String {
        return valueToShow()
    }

    var isDisplayValueLong: Bool {
        return false
    }

    // Abstract methods (must be overridden by subclasses)
    var relatedCards: [String] {
        fatalError("Must override relatedCards")
    }

    func shouldShow() -> Bool {
        fatalError("Must override shouldShow()")
    }

    func valueToShow() -> String {
        fatalError("Must override valueToShow()")
    }

    func getCardsToDisplay() -> [String] {
        fatalError("Must override getCardsToDisplay()")
    }

    func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        // Empty by default, can be overridden
    }

    required init(controlledByPlayer: Bool, game: Game) {
        self.isPlayerCounter = controlledByPlayer
        self.game = game
    }

    // Helper methods
    private func inDeckOrKnown(cardId: String) -> Bool {
        guard let activeDeck = game.currentDeck else {
            return false
        }

        let contains = activeDeck.cards.contains { $0.id == cardId }

        return contains || game.player.playerEntities.contains { $0.cardId == cardId && $0.info.originalZone != nil }
    }

    func inPlayerDeckOrKnown(cardIds: [String]) -> Bool {
        return cardIds.contains { inDeckOrKnown(cardId: $0) }
    }

    func getCardsInDeckOrKnown(cardIds: [String]) -> [String] {
        return cardIds.filter { inDeckOrKnown(cardId: $0) }
    }

    func opponentMayHaveRelevantCards(ignoreNeutral: Bool = false) -> Bool {
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.playerClass, ignoreNeutral: ignoreNeutral).count > 0
    }

    func filterCardsByClassAndFormat(cardIds: [String], playerClass: CardClass?, ignoreNeutral: Bool = false) -> [String] {
        return cardIds.compactMap({ cardId in Cards.by(cardId: cardId )})
            .filterCardsByFormat(format: game.currentFormat)
            .filterCardsByPlayerClass(playerClass: playerClass, ignoreNeutral: ignoreNeutral)
            .compactMap({ card in card.id })
    }

    // Event handling in Swift
    var counterChanged: (() -> Void)?
    var propertyChanged: ((String?) -> Void)?

    // Method to raise events
    func onCounterChanged() {
        DispatchQueue.main.async {
            self.counterChanged?()
            self.onPropertyChanged("counterValue")
        }
    }

    func onPropertyChanged(_ propertyName: String? = nil) {
        propertyChanged?(propertyName)
    }
}
