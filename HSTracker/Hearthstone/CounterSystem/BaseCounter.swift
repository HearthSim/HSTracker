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
        return cardDisplayName ?? fallbackDisplayName
    }

    /// Whether the counter's portrait card is missing from the card database, which leaves
    /// `localizedName` with nothing better than the type name unless a subclass names itself.
    var usesFallbackDisplayName: Bool {
        return cardDisplayName == nil
    }

    private var cardDisplayName: String? {
        guard let name = Cards.by(cardId: cardIdToShowInUI)?.name, !name.isEmpty else {
            return nil
        }
        return name
    }

    private var fallbackDisplayName: String {
        let name = counterId
        let suffix = "Counter"
        return name.hasSuffix(suffix) && name.count > suffix.count
            ? String(name.dropLast(suffix.count))
            : name
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
    
    var sortValue: Int {
        return 0
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

    /// The key the counter's visibility override is stored under: its type name, as in HDT.
    class var counterId: String {
        return String(describing: self)
    }

    var counterId: String {
        return type(of: self).counterId
    }

    var isAvailableInCurrentGameMode: Bool {
        return isBattlegroundsCounter ? game.isBattlegroundsMatch() : game.isTraditionalHearthstoneMatch
    }

    var visibilityOverride: CounterVisibility {
        return CounterVisibilitySettings.instance.get(counterId, isPlayer: isPlayerCounter)
    }

    /// Final visibility for this counter: the game-mode gate, then the user's override, then
    /// the counter's own heuristic.
    func isVisible() -> Bool {
        if !isAvailableInCurrentGameMode {
            return false
        }
        return CounterVisibilitySettings.resolve(visibilityOverride) {
            shouldShow() || mirrorsPlayerDeckKnowledge
        }
    }

    func shouldShow() -> Bool {
        fatalError("Must override shouldShow()")
    }

    var hasValue: Bool {
        return false
    }

    /// Opponent counters normally have to guess from the opponent's class and the format, because we
    /// cannot see their deck. Azalina Soulsever copies half of our deck into theirs, so a payoff
    /// sitting in our deck becomes a payoff they may hold too - judge those counters with the
    /// player's deck knowledge on top of their own heuristic.
    var mirrorsPlayerDeckKnowledge: Bool {
        return !isPlayerCounter
            && mirrorsPlayerDeck
            && game.isTraditionalHearthstoneMatch
            && game.opponent.deckCopiedFromEnemy
            && hasValue
            && inPlayerDeckOrKnown(cardIds: relatedCards)
    }

    /// Whether this counter takes part in the mirroring above. Opt out for counters that are
    /// deliberately player-only.
    var mirrorsPlayerDeck: Bool {
        return true
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
        let activeDeck = game.currentDeck
        let deckContains = activeDeck?.cards.any { x in x.id == cardId } ?? false
        let sideboardsContain = activeDeck?.sideboards.any { sb in sb.cards.any { x in x.id == cardId }} ?? false
        
        let playerEntitiesContains = game.player.playerEntities.any { x in
            x.cardId == cardId &&
            x.info.originalZone != nil &&
            // non-picked discover option entities now go to the graveyard
            !x.isInSetAside && !x.isInGraveyard
        }
        
        let discoverEntitiesContains = game.player.offeredEntities.any { x in x.cardId == cardId }

        return deckContains || sideboardsContain || playerEntitiesContains || discoverEntitiesContains
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
    
    private func getAvailableCardIds() -> Set<Int>? {
        if let availableCardIds = _availableCardIds {
            return availableCardIds
        }
        guard let availableRaces = game.availableRaces else {
            return nil
        }
        let currentRaces = Set<Race>(availableRaces) + [ .all, .invalid ]
        let availableCards = BattlegroundsDbSingleton.instance.getCardsByRaces(currentRaces, game.isBattlegroundsDuosMatch()) + BattlegroundsDbSingleton.instance.getSpells(game.isBattlegroundsDuosMatch())
        
        let availableCardIds = Set<Int>(availableCards.compactMap({ $0.dbfId }))
        _availableCardIds = availableCardIds
        return availableCardIds
    }
    
    var cardsToDisplay: [Card] {
        let availableCardIds = getAvailableCardIds()

        // The opponent branch of getCardsToDisplay() filters by their class, which would drop the
        // cards Azalina copied out of our deck and leave the tooltip empty under the pill.
        let cardIdsToDisplay = mirrorsPlayerDeckKnowledge
            ? Array(Set(getCardsToDisplay() + getCardsInDeckOrKnown(cardIds: relatedCards)))
            : getCardsToDisplay()

        return cardIdsToDisplay.compactMap({ cardId in
            if let card = Cards.by(cardId: cardId) {
                if isBattlegroundsCounter, let availableCardIds, !availableCardIds.contains(card.dbfId) && !_alwaysAvailableCards.contains(where: {$0 == cardId }) {
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
