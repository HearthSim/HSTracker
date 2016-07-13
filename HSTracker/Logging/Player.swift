/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 17/02/16.
 */

import Foundation
import CleanroomLogger

class DynamicEntity: Hashable {
    var cardId: String
    var stolen, hidden, created, isInHand, discarded: Bool
    var cardMark: CardMark
    var entity: Entity?

    init(cardId: String, hidden: Bool = false, created: Bool = false,
         cardMark: CardMark = CardMark.None, discarded: Bool = false,
         stolen: Bool = false, isInHand: Bool = false, entity: Entity? = nil) {
        self.cardId = cardId
        self.hidden = hidden
        self.created = created
        self.discarded = discarded
        self.cardMark = cardMark
        self.stolen = stolen
        self.isInHand = isInHand
        self.entity = entity
    }

    var hashValue: Int {
        return cardId.hashValue ^
            hidden.hashValue ^
            created.hashValue ^
            discarded.hashValue ^
            stolen.hashValue ^
            cardMark.hashValue ^
            isInHand.hashValue
    }
}
func == (lhs: DynamicEntity, rhs: DynamicEntity) -> Bool {
    return lhs.cardId == rhs.cardId &&
        lhs.hidden == rhs.hidden &&
        lhs.created == lhs.created &&
        lhs.discarded == rhs.discarded &&
        lhs.cardMark == rhs.cardMark &&
        lhs.stolen == rhs.stolen &&
        lhs.isInHand == rhs.isInHand
}

class DeckState {
    private(set) var remainingInDeck: [Card]
    private(set) var removedFromDeck: [Card]

    init(remainingInDeck: [Card], removedFromDeck: [Card]) {
        self.removedFromDeck = removedFromDeck
        self.remainingInDeck = remainingInDeck
    }
}

class PredictedCard: Hashable {
    var cardId: String
    var turn: Int

    init(cardId: String, turn: Int) {
        self.cardId = cardId
        self.turn = turn
    }

    var hashValue: Int {
        return cardId.hashValue ^ turn.hashValue
    }
}
func == (lhs: PredictedCard, rhs: PredictedCard) -> Bool {
    return lhs.cardId == rhs.cardId && lhs.turn == rhs.turn
}

final class Player {
    var playerClass: CardClass?
    var playerClassId: String?
    var isLocalPlayer: Bool
    var id = -1
    var goingFirst = false
    var fatigue = 0
    private(set) var spellsPlayedCount = 0
    private(set) var deathrattlesPlayedCount = 0

    var hasCoin: Bool {
        return hand.any { $0.cardId == CardIds.NonCollectible.Neutral.TheCoin }
    }

    var handCount: Int {
        return hand.filter({ $0.isControlledBy(self.id) }).count
    }

    var deckCount: Int {
        return deck.filter({ $0.isControlledBy(self.id) }).count
    }

    var playerEntities: [Entity] {
        return Game.instance.entities.map({ $0.1 }).filter({
            return !$0.info.hasOutstandingTagChanges && $0.isControlledBy(self.id)
        })
    }

    var revealedEntities: [Entity] {
        return Game.instance.entities.map({ $0.1 })
            .filter({
                return !$0.info.hasOutstandingTagChanges
                    && ($0.isControlledBy(self.id) || $0.info.originalController == self.id)
            }).filter({ $0.hasCardId })
    }

    var hand: [Entity] { return playerEntities.filter({ $0.isInHand }) }
    var board: [Entity] { return playerEntities.filter({ $0.isInPlay }) }
    var deck: [Entity] { return playerEntities.filter({ $0.isInDeck }) }
    var graveyard: [Entity] { return playerEntities.filter({ $0.isInGraveyard }) }
    var secrets: [Entity] { return playerEntities.filter({ $0.isInSecret }) }
    var setAside: [Entity] { return playerEntities.filter({ $0.isInSetAside }) }

    private(set) lazy var inDeckPredictions = [PredictedCard]()

    var name: String?
    var tracker: Tracker?
    var drawnCardsMatchDeck = true

    init(local: Bool) {
        isLocalPlayer = local
        reset()
    }

    func reset(resetID: Bool = true) {
        if resetID { id = -1 }
        name = ""
        playerClass = nil
        goingFirst = false
        fatigue = 0
        spellsPlayedCount = 0
        deathrattlesPlayedCount = 0

        inDeckPredictions.removeAll()
    }

    var displayRevealedCards: [Card] {
        return revealedEntities.filter({ x in
            return !x.info.created
                && (x.isMinion || x.isSpell || x.isWeapon)
                && (!x.isInDeck || (x.info.stolen && x.info.originalController == self.id))
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                    hidden: (e.isInHand || e.isInDeck),
                    created: e.info.created ||
                        (e.info.stolen && e.info.originalController != self.id),
                    discarded: e.info.discarded && Settings.instance.highlightDiscarded)
            })
            .groupBy { (d: DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.jousted = g.key.hidden
                    card.isCreated = g.key.created
                    card.wasDiscarded = g.key.discarded
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
            .sortCardList()
    }

    var predictedCardsInDeck: [Card] {
        return inDeckPredictions.map { g -> Card? in
            if let card = Cards.byId(g.cardId) {
                card.jousted = true
                return card
            } else {
                return nil
            }
            }
            .filter { $0 != nil }
            .map { $0! }
    }

    var knownCardsInDeck: [Card] {
        return deck.filter({ $0.hasCardId })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                    created: e.info.created || e.info.stolen)
            })
            .groupBy { (d: DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.isCreated = g.key.created
                    card.jousted = true
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
    }

    var revealedCards: [Card] {
        return revealedEntities.filter({ x in
            let created = x.info.created
            let type = (x.isMinion || x.isSpell || x.isWeapon)
            let zone = ((!x.isInDeck
                && (!x.info.stolen || x.info.originalController == self.id))
                || (x.info.stolen && x.info.originalController == self.id))

            return !created && type && zone
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                    stolen: e.info.stolen && e.info.originalController != self.id,
                    entity: e)
            })
            .groupBy { (d: DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.isCreated = g.key.stolen
                    card.highlightInHand = g.items.any({
                        $0.isInHand && $0.entity!.isControlledBy(self.id)
                    })
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
    }

    var createdCardsInHand: [Card] {
        return hand.filter { ($0.info.created || $0.info.stolen) }
            .groupBy { (e: Entity) in e.cardId }
            .map { g -> Card? in
                if let card = Cards.byId(g.key) {
                    card.count = g.items.count
                    card.isCreated = true
                    card.highlightInHand = true
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }
    }

    func getHighlightedCardsInHand(cardsInDeck: [Card]) -> [Card] {
        return Game.instance.activeDeck!.sortedCards.filter({ (c) -> Bool in
            cardsInDeck.all({ $0.id != c.id }) && hand.any({ $0.cardId == c.id })
        })
            .map { g -> Card in
                let card = g.copy()
                card.count = 0
                card.highlightInHand = true
                return card
            }
    }

    var playerCardList: [Card] {
        let settings = Settings.instance
        let createdInHand = settings.showPlayerGet ? createdCardsInHand : [Card]()
        if Game.instance.activeDeck == nil {
            return (revealedCards + createdInHand
                + knownCardsInDeck + predictedCardsInDeck).sortCardList()
        }
        let deckState = getDeckState()
        let inDeck = deckState.remainingInDeck
        let notInDeck = deckState.removedFromDeck.filter({ x in inDeck.all({ x.id != $0.id }) })
        if !settings.removeCardsFromDeck {
            return (inDeck + notInDeck + createdInHand).sortCardList()
        }
        if settings.highlightCardsInHand {
            return (inDeck + getHighlightedCardsInHand(inDeck) + createdInHand).sortCardList()
        }
        return (inDeck + createdInHand).sortCardList()
    }

    var opponentCardList: [Card] {
        let revealed = revealedEntities.filter({ (e: Entity) in
            (e.isMinion || e.isSpell || e.isWeapon || !e.hasTag(.CARDTYPE))
                && (e.getTag(.CREATOR) == 1
                    || ((!e.info.created || (Settings.instance.showOpponentCreated
                        && (e.info.createdInDeck || e.info.createdInHand)))
                    && e.info.originalController == self.id)
                    || e.isInHand || e.isInDeck) && !(e.info.created && e.isInSetAside)
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                    hidden: (e.isInHand || e.isInDeck) && e.isControlledBy(self.id),
                    created: e.info.created ||
                        (e.info.stolen && e.info.originalController != self.id),
                    discarded: e.info.discarded && Settings.instance.highlightDiscarded
                )
            })
            .groupBy { (d: DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.jousted = g.key.hidden
                    card.isCreated = g.key.created
                    card.wasDiscarded = g.key.discarded
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }

            let inDeck = inDeckPredictions.map({ g -> Card? in
                if let card = Cards.byId(g.cardId) {
                    card.jousted = true
                    return card
                } else {
                    return nil
                }
            })
                .filter { $0 != nil }
                .map { $0! }

        return (revealed + inDeck).sortCardList()
    }

    private func getDeckState() -> DeckState {
        let createdCardsInDeck: [Card] = deck.filter({
            $0.hasCardId && ($0.info.created || $0.info.stolen)
        })
            .map({ (e: Entity) -> (DynamicEntity) in
                DynamicEntity(cardId: e.cardId,
                    created: e.info.created || e.info.stolen,
                    discarded: e.info.discarded
                )
            })
            .groupBy { (d: DynamicEntity) in d }
            .map { g -> Card? in
                if let card = Cards.byId(g.key.cardId) {
                    card.count = g.items.count
                    card.isCreated = g.key.created
                    card.highlightInHand = hand.any({ $0.cardId == g.key.cardId })
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! }

        var originalCardsInDeck: [String] = Game.instance.activeDeck!.sortedCards.flatMap {
                Array(count: $0.count, repeatedValue: $0.id)
            }
            .map({ $0 })

        let revealedNotInDeck = revealedEntities.filter {
            !$0.info.created && ($0.isSpell || $0.isWeapon || $0.isMinion)
                && ((!$0.isInDeck || $0.info.stolen) && $0.info.originalController == self.id)
        }

        var removedFromDeck = [String]()
        revealedNotInDeck.forEach({
            originalCardsInDeck.remove($0.cardId)
            if !$0.info.stolen || $0.info.originalController == self.id {
                removedFromDeck.append($0.cardId)
            }
        })

        let cardsInDeck: [Card] = createdCardsInDeck + (originalCardsInDeck
            .groupBy { (c: String) in c }
            .map { g -> Card? in
                if let card = Cards.byId(g.key) {
                    card.count = g.items.count
                    if hand.any({ $0.cardId == g.key }) {
                        card.highlightInHand = true
                    }
                    return card
                } else {
                    return nil
                }
            }
            .filter { $0 != nil }
            .map { $0! } as [Card])

        let cardsNotInDeck = removedFromDeck.groupBy { (c: String) in c }
            .map({ g -> Card? in
                if let card = Cards.byId(g.key) {
                    card.count = 0
                    if hand.any({ e in e.cardId == g.key }) {
                        card.highlightInHand = true
                    }
                    return card
                } else {
                    return nil
                }
            })
            .filter({ $0 != nil })
            .map({ $0! })

        return DeckState(remainingInDeck: cardsInDeck, removedFromDeck: cardsNotInDeck)
    }

    private var debugName: String {
        return isLocalPlayer ? "Player" : "Opponent"
    }

    func createInDeck(entity: Entity, turn: Int) {
        entity.info.created = entity.info.created || turn > 1
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func createInHand(entity: Entity, turn: Int) {
        entity.info.created = true
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func boardToDeck(entity: Entity, turn: Int) {
        entity.info.turn = turn
        entity.info.returned = true
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func play(entity: Entity, turn: Int) {
        if !isLocalPlayer {
            updateKnownEntitesInDeck(entity.cardId, turn: turn)
        }

        if let cardType = CardType(rawValue: entity.getTag(.CARDTYPE)) {
            switch cardType {
            case .TOKEN: entity.info.created = true
            case .SPELL: spellsPlayedCount += 1
            default: break
            }
        }
        entity.info.hidden = false
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func handDiscard(entity: Entity, turn: Int) {
        if !isLocalPlayer {
            updateKnownEntitesInDeck(entity.cardId, turn: entity.info.turn)
        }
        entity.info.turn = turn
        entity.info.discarded = true
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func secretPlayedFromDeck(entity: Entity, turn: Int) {
        updateKnownEntitesInDeck(entity.cardId)
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func secretPlayedFromHand(entity: Entity, turn: Int) {
        entity.info.turn = turn
        spellsPlayedCount += 1
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func mulligan(entity: Entity) {
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func draw(entity: Entity, turn: Int) {
        if isLocalPlayer {
            updateKnownEntitesInDeck(entity.cardId)
        } else {
            if Game.instance.opponentEntity?.getTag(.MULLIGAN_STATE) == Mulligan.DEALING.rawValue {
                entity.info.mulliganed = true
            } else {
                entity.info.hidden = true
            }
        }
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func removeFromDeck(entity: Entity, turn: Int) {
        // Do not check for KnownCardIds here, this is how jousted cards get removed from the deck
        entity.info.turn = turn
        entity.info.discarded = true

        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func removeFromPlay(entity: Entity, turn: Int) {
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func deckDiscard(entity: Entity, turn: Int) {
        updateKnownEntitesInDeck(entity.cardId)
        entity.info.turn = turn
        entity.info.discarded = true
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func deckToPlay(entity: Entity, turn: Int) {
        updateKnownEntitesInDeck(entity.cardId)
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func playToGraveyard(entity: Entity, cardId: String?, turn: Int) {
        entity.info.turn = turn
        if entity.isMinion && entity.hasTag(.DEATHRATTLE) {
            deathrattlesPlayedCount += 1
        }
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func joustReveal(entity: Entity, turn: Int) {
        entity.info.turn = turn
        if let card = inDeckPredictions.firstWhere({ $0.cardId == entity.cardId }) {
            card.turn = turn
        } else {
            inDeckPredictions.append(PredictedCard(cardId: entity.cardId, turn: turn))
        }
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func createInPlay(entity: Entity, turn: Int) {
        entity.info.created = true
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func createInSecret(entity: Entity, turn: Int) {
        entity.info.created = true
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func stolenByOpponent(entity: Entity, turn: Int) {
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func stolenFromOpponent(entity: Entity, turn: Int) {
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func boardToHand(entity: Entity, turn: Int) {
        entity.info.turn = turn
        entity.info.returned = true
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    func secretTriggered(entity: Entity, turn: Int) {
        entity.info.turn = turn
        Log.info?.message("\(debugName) \(#function) \(entity)")
    }

    private func updateKnownEntitesInDeck(cardId: String?, turn: Int = Int.max) {
        if let card = inDeckPredictions.firstWhere({ $0.cardId == cardId && turn >= $0.turn }) {
            inDeckPredictions.remove(card)
        }
    }
}
