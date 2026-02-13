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
    
    var isBattlegroundsCounter: Bool {
        return false
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
    
    func handleChoicePicked(choice: IHsCompletedChoice) {
        
    }

    required init(controlledByPlayer: Bool, game: Game) {
        self.isPlayerCounter = controlledByPlayer
        self.game = game
    }

    // Helper methods
    private func inDeckOrKnown(cardId: String) -> Bool {
        let deckContains = game.currentDeck?.cards.any { x in x.id == cardId } ?? false
        
        let playerEntitiesContains = game.player.playerEntities.any { x in
            x.cardId == cardId &&
            x.info.originalZone != nil &&
            // non-picked discover option entities now go to the graveyard
            !x.isInSetAside && !x.isInGraveyard
        }
        
        let discoverEntitiesContains = game.player.offeredEntities.any { x in x.cardId == cardId }

        return deckContains || playerEntitiesContains || discoverEntitiesContains
    }

    func inPlayerDeckOrKnown(cardIds: [String]) -> Bool {
        return cardIds.contains { inDeckOrKnown(cardId: $0) }
    }

    func getCardsInDeckOrKnown(cardIds: [String]) -> [String] {
        return cardIds.filter { inDeckOrKnown(cardId: $0) }
    }

    func opponentMayHaveRelevantCards(ignoreNeutral: Bool = false) -> Bool {
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass, ignoreNeutral: ignoreNeutral).count > 0
    }

    func filterCardsByClassAndFormat(cardIds: [String], playerClass: CardClass?, ignoreNeutral: Bool = false) -> [String] {
        return cardIds.compactMap({ cardId in Cards.by(cardId: cardId )})
            .filterCardsByFormat(gameType: game.currentGameType, format: game.currentFormatType)
            .filterCardsByPlayerClass(playerClass: playerClass, ignoreNeutral: ignoreNeutral)
            .compactMap({ card in card.id })
    }
    
    final let _alwaysAvailableCards = [ CardIds.NonCollectible.Neutral.BoonofBeetles_BeetleToken1, CardIds.NonCollectible.Neutral.BloodGem1, CardIds.NonCollectible.Neutral.TwilightHatchling_TwilightWhelpToken ]

    private var _availableCardIds: Set<Int>?
    
    private func getAvailableCardIds() -> Set<Int> {
        if let availableCardIds = _availableCardIds {
            return availableCardIds
        }
        let availableRaces = game.availableRaces ?? [Race]()
        let currentRaces = Set<Race>(availableRaces) + [ .all, .invalid ]
        let availableCards = BattlegroundsDbSingleton.instance.getCardsByRaces(currentRaces, game.isBattlegroundsDuosMatch()) + BattlegroundsDbSingleton.instance.getSpells(game.isBattlegroundsDuosMatch())
        
        let availableCardIds = Set<Int>(availableCards.compactMap({ $0.dbfId }))
        _availableCardIds = availableCardIds
        return availableCardIds
    }
    
    var cardsToDisplay: [Card] {
        return getCardsToDisplay().compactMap({ cardId in
            if let card = Cards.by(cardId: cardId) {
                if isBattlegroundsCounter && !getAvailableCardIds().contains(card.dbfId) && !_alwaysAvailableCards.contains(where: {$0 == cardId }) {
                    return nil
                }
                card.baconCard = isBattlegroundsCounter
                return card
            }
            return nil
        })
    }
    
    // Event handling in Swift
    var counterChanged: (() -> Void)?
    var propertyChanged: ((String?) -> Void)?

    // Method to raise events
    func onCounterChanged() {
        DispatchQueue.main.async {
            self.counterChanged?()
            self.onPropertyChanged("counterValue")
            self.onPropertyChanged("cardsToDisplay")
        }
    }

    func onPropertyChanged(_ propertyName: String? = nil) {
        propertyChanged?(propertyName)
    }
}
